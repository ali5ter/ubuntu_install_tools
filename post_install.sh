#!/usr/bin/env bash
# Post installation script to configure ubuntu

set -e

# ============================================================================
# Environment

HOSTNAME="$(hostname)"
DOMAIN=".local"

[ "$(id -u)" != "0" ] && {
    echo "This script should be run as root" 1>&2
    exit 1
}

read -erp "Preferred hostname: " -i "$HOSTNAME" HOSTNAME
read -erp "Preferred domain: " -i "$DOMAIN" DOMAIN

FQDN="$HOSTNAME.$DOMAIN"

echo "Configuring this $(lsb_release -ds) server..."

# ============================================================================
# Patch the OS

echo "$HOSTNAME" > /etc/hostname
sed -i "s@ubuntu.ubuntu@$FQDN@g" /etc/hosts
sed -i "s@ubuntu@$HOSTNAME@g" /etc/hosts
hostname "$HOSTNAME"

apt-get update -y > /dev/null 2>&1
apt-get upgrade -y > /dev/null 2>&1
apt-get dist-upgrade -y > /dev/null 2>&1
apt-get autoremove -y > /dev/null 2>&1
apt-get purge -y > /dev/null 2>&1

#apt-get install -y openssh-server > /dev/null 2>&1
apt-get install -y open-vmware-tools > /dev/null 2>&1
apt-get install -y git > /dev/null 2>&1

echo "PermitRootLogin no" >> /etc/ssh/sshd_config
service ssh restart

ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/tcp
ufw enable

fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

# ============================================================================
# Alternate root account

USER="$SUDO_USER"

su "$USER" <<"END_OF_ADMIN_COMMANDS"
mkdir "$SRC" > /dev/null 2>&1
cd "$SRC" > /dev/null 2>&1
git clone http://gitlab.different.com/alister/carrybag.git > /dev/null 2>&1
./tools/install.sh -q > /dev/null 2>&1
END_OF_ADMIN_COMMANDS

exit 0

# ============================================================================
# Clean up

rm "$0"
echo "Configuration complete. Going to reboot..."
reboot
