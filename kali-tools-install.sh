#!/bin/bash
# This is by no means proper or professional bash syntax.

echo "Installing kali tools from the kali repo: \n"

sudo apt install dirbuster powersploit wpscan nmap wireshark metasploit-framework  sqlmap wordlists binwalk burpsuite zaproxy python-wappalyzer john john-data dnsutils armitage git tmux netcat-openbsd telnet nikto enum4linux nano vim jq responder pcredz

git clone https://github.com/PowerShellEmpire/PowerTools.git /opt/powertools
pip install truffleHog

echo "Installing empire: \n"
git clone https://github.com/EmpireProject/Empire.git /opt/empire
cd /opt/empire
sudo ./setup/install.sh

echo "Done!"

## Missing
##~~powerview~~
#~~responder~~
#~~pcreds~~
#~~trufflehog~~
#winscp
#xml to csv script 
#~~empire~~
#docker
#vectr 
