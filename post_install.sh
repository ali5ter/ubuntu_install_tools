#!/usr/bin/env bash
# @file post_install.sh
# Post installation script to configure Ubuntu
# @see https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers
# @see https://github.com/netson/ubuntu-unattended
# @see http://gitlab.different.com/alister/carrybag/

set -e

randomWord() {
    local file=/usr/share/dict/words
    length="$(cat $file | wc -l)"
    n=$(expr $RANDOM \* $length \/ 32768 + 1)
    head -n $n $file | tail -1
}

# ============================================================================
# Environment

HOSTNAME="${1:-$(randomWord)}"
DOMAIN="${2:-'.local'}"

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
sed -i "s@ubuntu.ubuntu@$FQDN@g" /etc/hosts
sed -i "s@ubuntu@$HOSTNAME@g" /etc/hosts
## TODO: append line instead of trying to replace
## 127.0.0.1    localhost
## 127.0.0.1    $FQDN   $HOSTNAME
hostname "$HOSTNAME"

apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get purge -y

apt-get install -y openssh-server
apt-get install -y open-vmware-tools
apt-get install -y git

# Default is now PermitRootLogin without-password
#echo "PermitRootLogin no" >> /etc/ssh/sshd_config
#service ssh restart

#ufw allow ssh
#ufw allow 80/tcp
#ufw allow 443/tcp
#ufw allow 25/tcp
#ufw enable

fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

apt-get install -y figlet
echo > /etc/motd
{ \
    figlet "$HOSTNAME"; \
    echo -n "\nWelcome to $HOSTNAME\n"; \
    echo "Any malicious and/or unauthorized activity is strictly forbidden."; \
    echo "All activity may be logged."; \
} >> /etc/motd
echo /etc/motd
apt-get purge figlet

# ============================================================================
# Alternate root account

USER="$SUDO_USER"

su "$USER" <<"END_OF_ADMIN_COMMANDS"
mkdir "$SRC" > /dev/null 2>&1
cd "$SRC" > /dev/null 2>&1
git clone http://gitlab.different.com/alister/carrybag.git > /dev/null 2>&1
cd carrybag > /dev/null 2>&1
./tools/install.sh -q > /dev/null 2>&1
END_OF_ADMIN_COMMANDS

exit 0

# ============================================================================
# Clean up

rm "$0"
echo "Configuration complete. Going to reboot..."
reboot
