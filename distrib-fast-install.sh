#!/bin/bash

# Check usage
if [[ $# -lt 3 ]]; then
    echo "USAGE: $1 <root_username> <root_password> [remote_host_1], ..., [remote_host_n]"
    exit 1
fi

# Ensure permissions
if [[ `id -u` -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

root_username="$1"
root_password="$2"
worker_hosts="${@:3}"
controller_ip="$(hostname -I | cut -d' ' -f1)"

echo "The central controller's IP address is: $controller_ip"
echo "Using creds: '$root_username:$root_password'"
echo "Controlling ${#worker_hosts[@]} Workers: $worker_hosts"
echo ""
echo "Does this look correct? [ENTER TO CONFIRM]"
read uinput

echo '#==============================================================================='
echo '#  Here we go!!!'
echo '#==============================================================================='

echo '###  Ensuring repo index is up to date'
apt update

echo '###  Setting up pushable environment for controller'
# install sshpass to easy ssh without interaction and parallel to run it all at once
apt install -y sshpass parallel &>/dev/null

# Ensure controller components exist and are in pwd
controller_script_filename="controller-install.sh"
if [[ ! -f "$controller_script_filename" ]]; then
    echo "Failed to locate '$controller_script_filename', make sure it's in your pwd"
    exit 2
fi

# Ensure worker components exist and are in pwd
worker_script_filename="worker-install.sh"
if [[ ! -f "$worker_script_filename" ]]; then
    echo "Failed to locate '$worker_script_filename', make sure it's in your pwd"
    exit 2
fi

# Reconfigure worker script to point to correct controller IP
echo "###  Auto-mutating worker install script... controller IP will be '$controller_ip'"
sed -i "s/CONTROLLER_IP_GOES_HERE/$controller_ip/" "$worker_script_filename"

echo '###  Building commands to run in parallel'
par_cmd_list=()
# add commands to configure controller
par_cmd_list+=("bash '$controller_script_filename'")

# build worker commands and run all in parallel
for worker in ${worker_hosts[@]}; do
    # Add public key to avoid issues w/ host verification
    ssh-keyscan $worker 2>/dev/null >> ~/.ssh/known_hosts  
    # Add command in the queue to scp file to remote host and then execute... got to love bash quoting...
    par_cmd_list+=('sshpass -p '"'""$root_password""'"' scp '"'""$worker_script_filename""'"' '"$root_username"'@'"$worker"':~/'"'""$worker_script_filename""'"' && sshpass -p '"'""$root_password""'"' ssh '"$root_username"'@'"$worker"' bash ~/'"'""$worker_script_filename""'"'  || echo "Worker failed auto install : "'"$worker")
done

echo '#==============================================================================='
echo '#  Performing distributed installation'
echo '#==============================================================================='

echo "###  Running all installation commands in parallel"
printf "%s\n" "${par_cmd_list[@]}" | parallel -j "${#par_cmd_list[@]}" -N1 --line-buffer '{}'


echo '#==============================================================================='
echo '#  Software has been installed on controller and workers, fully starting RADAR'
echo '#==============================================================================='

sleep 2 # give it a couple seconds to make sure the Uplinks have made themselves known
echo "###  $PREFIX Running radar auth sweep"
if [[ ! -x "/usr/local/bin/radar-ctl.py" ]]; then
    echo "!!!  $PREFIX radar-ctl.py is not executable... not running auth sweep"
else
    # Get info about clients and for all unauthorized clients, authorize them
    /usr/local/bin/radar-ctl.py get-data -d radar-control -c clients | jq -r '.[] | select(.authorized | not) | .key' | while read -r KEY; do
        echo "###  $PREFIX Authorizing RADAR client key: $KEY"
        /usr/local/bin/radar-ctl.py grant-auth "$KEY" &>/dev/null || echo "!!!  $PREFIX Something went wrong trying to authorize key: $KEY"
    done
fi

echo '#==============================================================================='
echo '#  END OF DISTRIBUTED INSTALL'
echo '#==============================================================================='