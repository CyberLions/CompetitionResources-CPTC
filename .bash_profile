# .bash_profile

# Setup environment variables and stuff
export PS1="[ \[$(tput sgr0)\]\[\033[38;5;2m\]\D{%F %T}\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput sgr0)\]\[\033[38;5;1m\]\H\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;6m\]\$PWD\[$(tput sgr0)\]\[\033[38;5;15m\] ]\n\[$(tput sgr0)\]\[\033[38;5;3m\]\\$>\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"

PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH


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


# Run bashrc too
if [ -f ~/.bashrc ]; then
	source ~/.bashrc
fi
