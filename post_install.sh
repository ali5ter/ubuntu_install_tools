#!/usr/bin/env bash
# Post installation script to configure ubuntu

set -e

# ============================================================================
# Environment

VERSION="$(lsb_release -cs)"
HOSTNAME="$(hostname)"
DOMAIN=".local"
USER="admin"
PASSWD="\\!QAZ2wsx"
tmp="/tmp"

[ "$(id -u)" != "0" ] && {
    echo "This script should be run as root" 1>&2
    exit 1
}

[ $(grep -q "noninteractive" /proc/cmdline) ] || {
    stty sane
    read -ep "Preferred hostname: " -i "$HOSTNAME" HOSTNAME
    read -ep "Preferred domain: " -i "$DOMAIN" DOMAIN
    read -ep "Preferred admin username: " -i "$USER" USER
    read -ep "Preferred admin password: " -i "$PASSWD" PASSWD
}

FQDN="$HOSTNAME.$DOMAIN"

echo "Configuring this server..."

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

apt-get install -y openssh-server > /dev/null 2>&1
apt-get install -y open-vmware-tools > /dev/null 2>&1
apt-get install -y git > /dev/null 2>&1

echo "PermitRootLogin no" >> /etc/ssh/sshd_config
service ssh restart

ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 443/tcp
sudo ufw enable

fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

# ============================================================================
# Alternate root account

UDIR="~$USER"
EPASSWD="$(openssl passwd -crypt $PASSWD)"
adduser --defaults --password "$EPASSWD" "$USER" > /dev/null 2>&1
gpasswd -a "$USER" sudo > /dev/null 2>&1

SRC="$UDIR/src"
su "$USER" <<"END_OF_ADMIN_COMMANDS"
mkdir "$SRC" > /dev/null 2>&1
cd "$SRC" > /dev/null 2>&1
git clone http://gitlab.different.com/alister/carrybag.git > /dev/null 2>&1
./tools/install.sh -q > /dev/null 2>&1
END_OF_ADMIN_COMMANDS

exit 0

# ============================================================================
# Clean up

rm $0
echo "Configuration complete. Going to reboot..."
reboot
