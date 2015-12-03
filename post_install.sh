#!/usr/bin/env bash
# @file post_install.sh
# Post installation script to configure Ubuntu
# @see https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers
# @see https://github.com/netson/ubuntu-unattended
# @see http://gitlab.different.com/alister/carrybag/
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

randomWord() {
    local file=/usr/share/dict/words
    length="$(cat $file | wc -l)"
    n=$(expr $RANDOM \* $length \/ 32768 + 1)
    head -n $n $file | tail -1 | tr "[:upper:]" "[:lower:]"
}

# ============================================================================
# Environment

HOSTNAME="${1:-$(randomWord)}"
DOMAIN="${2:-local}"

[ "$(id -u)" != "0" ] && {
    echo "This script should be run as root" 1>&2
    exit 1
}

echo
read -erp "Preferred hostname: " -i "$HOSTNAME" HOSTNAME
read -erp "Preferred domain: " -i "$DOMAIN" DOMAIN

FQDN="$HOSTNAME.$DOMAIN"

echo
echo "Configuring this $(lsb_release -ds) server with the dollowing spec:"
echo "  Hostname: $HOSTNAME ($FQDN)"
echo

# ============================================================================
# Patch the OS

echo "$HOSTNAME" > /etc/hostname
sed -i "/127.0.0.1\tlocalhost/a\\
127.0.0.1\t$FQDN\t$HOSTNAME" /etc/hosts
hostname "$HOSTNAME"

apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get purge -y

apt-get install -y openssh-server
if [ "$(lsb_release -cs)" == "trusty" ]; then
    apt-get install -y open-vm-tools-lts-trusty
else
    apt-get install -y open-vm-tools
fi
apt-get install -y git

sed -i s/without-password/no/ /etc/ssh/sshd_config
service ssh restart

#ufw allow ssh
#ufw allow 80/tcp
#ufw allow 443/tcp
#ufw allow 25/tcp
#ufw enable

[ -f /swapfile ] || {
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
}

[ -f /etc/motd ] || {
    apt-get install -y figlet
    { \
        figlet "$HOSTNAME"; \
        echo -e "Welcome to $FQDN\n"; \
        echo "Any malicious and/or unauthorized activity is strictly forbidden."; \
        echo -e "All activity may be logged.\n"; \
    } > /etc/motd
    apt-get purge -y figlet
}

# ============================================================================
# Alternate root account

USER="$SUDO_USER"

su "$USER" <<"END_OF_ADMIN_COMMANDS"
mkdir -p src
cd src
git clone http://gitlab.different.com/alister/carrybag.git
cd carrybag
./tools/install.sh -q
END_OF_ADMIN_COMMANDS

# ============================================================================
# Clean up

rm "$0"
echo "Configuration complete. Going to reboot..."
reboot
