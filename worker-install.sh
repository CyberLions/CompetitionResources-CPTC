CONTROLLER="CONTROLLER_IP_GOES_HERE"
PREFIX="$(hostname) - $(hostname -I | cut -d' ' -f1) -"

echo "\$\$\$  $PREFIX Installation has started on worker using controller $CONTROLLER"

if [[ `id -u` -ne 0 ]]; then
    echo "!!!  $PREFIX Installation failed due to lacking permissions"
    exit 1
fi

echo "###  $PREFIX Ensuring repos are updated..."
apt-get update &>/dev/null || echo "!!!  $PREFIX Failed to update repos"

echo "###  $PREFIX Installing python and pip3..."
apt-get install -y python3 python3-pip &>/dev/null || echo "!!!  $PREFIX Failed to install python3 and/or pip3"

echo "###  $PREFIX Installing kali tools from repo..."
# massive list of packages to install
# not included: wireshark
kali_packages=("dirbuster" "powersploit" "wpscan" "nmap" "metasploit-framework" "sqlmap" "wordlists" "binwalk" "burpsuite" "zaproxy" "python-wappalyzer" "john" "john-data" "dnsutils" "armitage" "git" "tmux" "netcat-openbsd" "telnet" "nikto" "enum4linux" "nano" "vim" "jq" "responder" "pcredz")
printf "%s\n" "${kali_packages[@]}" | while read -r package_name; do
    apt-get install -y "$package_name" &>/dev/null && echo "\$\$\$  $PREFIX Successfully installed kali package '$package_name'" || echo "!!!  $PREFIX Failed to install kali package '$package_name' from repo"
done

echo "###  $PREFIX Installing other tools"
pip3 install truffleHog &>/dev/null

# removed empire - not supported on recent distributions
#git clone https://github.com/PowerShellEmpire/PowerTools.git /opt/powertools
#git clone https://github.com/EmpireProject/Empire.git /opt/empire
#/opt/empire/setup/install.sh

echo "###  $PREFIX Installing RADAR"
# dependencies
apt-get install -y yara samba-common smbclient &>/dev/null || echo "!!!  $PREFIX Failed to install RADAR dependencies"

# Install cyber-radar
pip3 install cyber-radar &>/dev/null
chmod +x /usr/local/bin/radar*  # To solve git filesystem issues if these are wonky
# reconfigure uplink to use correct controller
# find correct config file and use sed to edit it
find /usr/local/lib/ -path "*cyber_radar/config/uplink_config.toml" -exec sed -i "s/localhost/$CONTROLLER/" {} \;

# Use template service from github to run uplink in background
curl 'https://raw.githubusercontent.com/Sevaarcen/RADAR/master/installation_components/radar-uplink.service' > /etc/systemd/system/radar-uplink.service 2>/dev/null
chmod +x /etc/systemd/system/radar-uplink.service
systemctl unmask radar-uplink.service  # Just to make sure it's not being weird with permissions
systemctl daemon-reload

# Check if RADAR Control Server is ready to accept the Uplink
c_port=$(find /usr/local/lib/ -path "*cyber_radar/config/uplink_config.toml" -exec grep "^port = " {} \; | rev | cut -d' ' -f1 | rev)  # get port number from config

# use netcat to check if port is open, if so start uplink
nc -z -w 3 $CONTROLLER $c_port && systemctl start radar-uplink.service || echo "!!!  $PREFIX cannot reach the RADAR Control Server at $CONTROLLER:$c_port"

echo "\$\$\$  $PREFIX End of installation sequence"