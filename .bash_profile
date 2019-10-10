# .bash_profile

# CPTC Functions
# Print list of all hosts in target which respond to ICMP ping requests
function nmap-ping-sweep() { 
	if [[ $# -lt 1 ]]; then
		echo '!!!  No target specified'
		return
	fi
	nmap -sn $@ | grep -F "Nmap scan report for" | cut -d' ' -f5
}

# Scan for web services
function nmap-webscan() {
        if [[ $# -lt 1 ]]; then
                echo '!!!  No target specified'
                return
        fi
        sudo nmap $@ -p 80,8000,8080,443,8443,3000 -sV --script http-enum,http-vhosts
}

# Intense TCP port scan - all ports w/ version detection
function nmap-tcp-intense() {
	if [[ $# -lt 1 ]]; then
		echo '!!!  No target specified'
		return
	fi
	sudo nmap $@ -p1-65535 -sV -O
}

# Intense TCP port scan w/ scripts enabled
function nmap-tcp-intense-scripts() {
        if [[ $# -lt 1 ]]; then
                echo '!!!  No target specified'
                return
        fi
        sudo nmap $@ -p1-65535 -sV -O -sC
}

# Intense UDP port scan - all ports w/ version detection
function nmap-udp-intense() {
        if [[ $# -lt 1 ]]; then
                echo '!!!  No target specified'
                return
        fi
        sudo nmap $@ -p1-65535 -sU -sV -O
}

# Intense UDP port scan w/ scripts
function nmap-udp-intense-scripts() {
        if [[ $# -lt 1 ]]; then
                echo '!!!  No target specified'
                return
        fi
        sudo nmap $@ -p1-65535 -sU -sV -O -sC
}


# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/.local/bin:$HOME/bin

export PATH
