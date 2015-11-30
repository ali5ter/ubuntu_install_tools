#!/usr/bin/env bash
# Post installation script to configure ubuntu

set -e

VERSION="$(lsb_release -cs)"
HOSTNAME="$(hostname)"
DOMAIN=".local"
USER="admin"
tmp="/tmp"

[ "$(id -u)" != "0" ] && {
    echo "This script should be run as root" 1>&2
    exit 1
}

[ $(grep -q "noninteractive" /proc/cmdline) ] || {
    stty sane
    read -ep "Preferred hostname: " -i "$HOSTNAME" HOSTNAME
    read -ep "Preferred domain: " -i "$DOMAIN" DOMAIN
    read -ep "Preferred username: " -i "$USER" USER
}

FQDN="$HOSTNAME.$DOMAIN"

echo "Configuring this server..."

echo "$HOSTNAME" > /etc/hostname
sed -i "s@ubuntu.ubuntu@$FQDN@g" /etc/hosts
sed -i "s@ubuntu@$HOSTNAME@g" /etc/hosts
hostname "$HOSTNAME"

apt-get update -y > /dev/null 2>&1
apt-get upgrade -y > /dev/null 2>&1
apt-get dist-upgrade -y > /dev/null 2>&1
apt-get autoremove -y > /dev/null 2>&1
apt-get purge -y > /dev/null 2>&1

UDIR="~$USER"
## TODO: Set up alternate account
## TODO: Configure sshd
## TODO: Lock down

apt-get install -y open-vmware-tools > /dev/null 2>&1
apt-get install -y git > /dev/null 2>&1
apt-get install -y htop > /dev/null 2>&1

SRC="$UDIR/src"
su "$USER" <<"END_OF_ADMIN_COMMANDS"
mkdir "$SRC" > /dev/null 2>&1
cd "$SRC" > /dev/null 2>&1
git clone http://gitlab.different.com/alister/carrybag.git > /dev/null 2>&1
./tools/install.sh -q > /dev/null 2>&1
END_OF_ADMIN_COMMANDS

exit 0

rm $0
echo "Configuration complete. Going to reboot..."
reboot
