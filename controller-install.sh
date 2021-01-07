#!/bin/bash
PREFIX="CONTROLLER - $(hostname) - $(hostname -I | cut -d' ' -f1) -"

# Ensure permissions
if [[ `id -u` -ne 0 ]]; then
    echo "!!!  $PREFIX Installation failed due to lacking permissions"
    exit 1
fi
echo "\$\$\$  $PREFIX Installation has started"

echo "###  $PREFIX Ensuring repos are updated..."
apt-get update &>/dev/null

echo "###  $PREFIX Setting up Mongo database"
apt-get install -y mongodb jq &>/dev/null || echo "!!!  $PREFIX Failed to install mongodb"
systemctl start mongodb.service &>/dev/null
systemctl enable mongodb.service &>/dev/null

# ensure mongodb is up and running
if [[ `mongo --eval 'db.runCommand({ connectionStatus: 1 })' --quiet | jq '.ok'` -ne 1 ]]; then
    echo "###  $PREFIX Cannot reach Mongo database, investigate..."
fi

echo "###  $PREFIX Installing RADAR"
# dependencies
apt-get install -y python3 python3-pip yara samba-common smbclient &>/dev/null || echo "!!!  $PREFIX Failed to install RADAR dependencies"
pip3 install cyber-radar &>/dev/null
chmod +x /usr/local/bin/radar*

# overwrite db creds in config
find /usr/local/lib/ -path "*cyber_radar/config/server_config.toml" -exec sed -ri "s/^(username = )/#\\1/" {} \; -exec sed -ri "s/^(password =)/#\\1/" {} \;

# Grab service template files
# for server
curl 'https://raw.githubusercontent.com/Sevaarcen/RADAR/master/installation_components/radar-server.service' > /etc/systemd/system/radar-server.service 2>/dev/null
chmod +x /etc/systemd/system/radar-server.service

# for uplink
curl 'https://raw.githubusercontent.com/Sevaarcen/RADAR/master/installation_components/radar-uplink.service' > /etc/systemd/system/radar-uplink.service 2>/dev/null
chmod +x /etc/systemd/system/radar-uplink.service

# start RADAR services
systemctl unmask radar-server
systemctl unmask radar-uplink
systemctl daemon-reload
systemctl start radar-server.service
systemctl is-active --quiet radar-server.service && echo "\$\$\$  $PREFIX RADAR Control Server is running" || echo "\$\$\$  $PREFIX RADAR Control Server could not be started"
sleep 1  # give time for server to start
systemctl start radar-uplink.service
systemctl is-active --quiet radar-uplink.service && echo "\$\$\$  $PREFIX RADAR Uplink Server is running" || echo "\$\$\$  $PREFIX RADAR Uplink Server could not be started"


echo "###  $PREFIX Installing kali tools from repo..."
# massive list of packages to install
# not included: wireshark
kali_packages=("dirbuster" "powersploit" "wpscan" "nmap" "metasploit-framework" "sqlmap" "wordlists" "binwalk" "burpsuite" "zaproxy" "python-wappalyzer" "john" "john-data" "dnsutils" "armitage" "git" "tmux" "netcat-openbsd" "telnet" "nikto" "enum4linux" "nano" "vim" "jq" "responder" "pcredz")
printf "%s\n" "${kali_packages[@]}" | while read -r package_name; do
    apt-get install -y "$package_name" &>/dev/null && echo "###  $PREFIX Successfully installed kali package '$package_name'" || echo "!!!  $PREFIX Failed to install kali package '$package_name' from repo"
done


echo "###  $PREFIX Installing other tools"
pip3 install truffleHog &>/dev/null
# removed empire - not supported on recent distributions
#git clone https://github.com/PowerShellEmpire/PowerTools.git /opt/powertools
#git clone https://github.com/EmpireProject/Empire.git /opt/empire
#/opt/empire/setup/install.sh