#!/usr/bin/env bash
# @file create_iso.sh
# Create an unattended Ubuntu Server ISO
# Credited work: Rinck Sonnenberg (Netson)
# @see https://github.com/netson/ubuntu-unattended

TMP="/tmp"
HOSTNAME="ubuntu"
TIMEZONE="America/New_York"
USER="admin"
PASSWD="\\!QAZ2wsx"

spinner() {
    # @see http://fitnr.com/showing-a-bash-spinner.html
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

download() {
    # @see http://fitnr.com/showing-file-download-progress-using-wget.html
    local url=$1
    echo -n "    "
    wget --progress=dot "$url" 2>&1 | grep --line-buffered "%" | \
        sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    echo -ne "\b\b\b\b"
    echo " Done"
}

program_is_installed() {
    # @see https://gist.github.com/JamieMason/4761049
    local return_=1
    type "$1" >/dev/null 2>&1 || { local return_=0; }
    echo $return_
}

UNAME=$(uname | tr "[:upper:]" "[:lower:]")
[ "$UNAME" == "linux" ] && {
    [ -f /etc/lsb-release ] && DISTRO=$(lsb-release -is)
}
[ "$DISTRO" == "" ] && {
    echo "Run this script on an Ubuntu system"
    exit 1;
}

while true; do
    echo "Which Ubuntu version should be remastered:"
    echo
    echo " [1] Ubuntu 14.04.3 LTS Server amd64 (Trusty Tahr)"
    echo " [2] Ubuntu 15.04 Server amd64 (Vivid Vervet)"
    echo " [3] Ubuntu 15.10 Server amd64 (Wily Werewolf)"
    echo
    read -rp " [1|2|3]: " ubver
    case $ubver in
        [1]* )  DL_FILE="ubuntu-14.04.3-server-amd64.iso"
                DL_LOC="http://releases.ubuntu.com/trusty/"
                ISO="ubuntu-14.04.3-server-amd64-unattended.iso"
                break;;
        [2]* )  DL_FILE="ubuntu-15.04-server-amd64.iso"
                DL_LOC="http://releases.ubuntu.com/vivid/"
                ISO="ubuntu-15.04-server-amd64-unattended.iso"
                break;;
        [3]* )  DL_FILE="ubuntu-15.10-server-amd64.iso"
                DL_LOC="http://releases.ubuntu.com/wily/"
                ISO="ubuntu-15.10-server-amd64-unattended.iso"
                break;;
        * ) echo " please answer 1 or 2 or 3";;
    esac
done

read -erp "Timezone: " -i "$TIMEZONE" TIMEZONE
read -erp "User name: " -i "$USER" USER
read -srp "Password: " -i "$PASSWD" PASSWD
read -erp "Make ISO bootable via USB [Y|n]: " -i 'Y' BOOTABLE

cd $TMP
[[ -f $TMP/$DL_FILE ]] || {
    echo -n "Downloading $DL_FILE: "
    download "$DL_LOC$DL_FILE"
}

DEFAULTS="ubuntu.seed"
if [[ ! -f $TMP/$DEFAULTS ]]; then
    echo -h " downloading $DEFAULTS: "
    download "http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/$DEFAULTS"
fi
 ======
# install required packages
echo " installing required packages"
if [ $(program_is_installed "mkpasswd") -eq 0 ] || [ $(program_is_installed "mkisofs") -eq 0 ]; then
    (apt-get -y update > /dev/null 2>&1) &
    spinner $!
    (apt-get -y install whois genisoimage > /dev/null 2>&1) &
    spinner $!
fi
if [[ $bootable == "yes" ]] || [[ $bootable == "y" ]]; then
    if [ $(program_is_installed "isohybrid") -eq 0 ]; then
        (apt-get -y install syslinux > /dev/null 2>&1) &
        spinner $!
    fi
fi


# create working folders
echo " remastering your iso file"
mkdir -p $TMP
mkdir -p $TMP/iso_org
mkdir -p $TMP/iso_new

# mount the image
if grep -qs $TMP/iso_org /proc/mounts ; then
    echo " image is already mounted, continue"
else
    (mount -o loop $TMP/$DL_FILE $TMP/iso_org > /dev/null 2>&1)
fi

# copy the iso contents to the working directory
(cp -rT $TMP/iso_org $TMP/iso_new > /dev/null 2>&1) &
spinner $!

# set the language for the installation menu
cd $TMP/iso_new
echo en > $TMP/iso_new/isolinux/lang

# set late command
late_command="chroot /target wget -O /home/$username/start.sh https://github.com/netson/ubuntu-unattended/raw/master/start.sh ;\
    chroot /target chmod +x /home/$username/start.sh ;"

# copy the netson seed file to the iso
cp -rT $TMP/$DEFAULTS $TMP/iso_new/preseed/$DEFAULTS

# include firstrun script
echo "
# setup firstrun script
d-i preseed/late_command                                    string      $late_command" >> $TMP/iso_new/preseed/$DEFAULTS

# generate the password hash
pwhash=$(echo $password | mkpasswd -s -m sha-512)

# update the seed file to reflect the users' choices
# the normal separator for sed is /, but both the password and the timezone may contain it
# so instead, I am using @
sed -i "s@{{username}}@$username@g" $TMP/iso_new/preseed/$DEFAULTS
sed -i "s@{{pwhash}}@$pwhash@g" $TMP/iso_new/preseed/$DEFAULTS
sed -i "s@{{hostname}}@$hostname@g" $TMP/iso_new/preseed/$DEFAULTS
sed -i "s@{{timezone}}@$timezone@g" $TMP/iso_new/preseed/$DEFAULTS

# calculate checksum for seed file
seed_checksum=$(md5sum $TMP/iso_new/preseed/$DEFAULTS)

# add the autoinstall option to the menu
sed -i "/label install/ilabel autoinstall\n\
  menu label ^Autoinstall NETSON Ubuntu Server\n\
  kernel /install/vmlinuz\n\
  append file=/cdrom/preseed/ubuntu-server.seed initrd=/install/initrd.gz auto=true priority=high preseed/file=/cdrom/preseed/netson.seed preseed/file/checksum=$seed_checksum --" $TMP/iso_new/isolinux/txt.cfg

echo " creating the remastered iso"
cd $TMP/iso_new
(mkisofs -D -r -V "NETSON_UBUNTU" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $TMP/$ISO . > /dev/null 2>&1) &
spinner $!

# make iso bootable (for dd'ing to  USB stick)
if [[ $bootable == "yes" ]] || [[ $bootable == "y" ]]; then
    isohybrid $TMP/$ISO
fi

# cleanup
umount $TMP/iso_org
rm -rf $TMP/iso_new
rm -rf $TMP/iso_org

# print info to user
echo " -----"
echo " finished remastering your ubuntu iso file"
echo " the new file is located at: $TMP/$ISO"
echo " your username is: $username"
echo " your password is: $password"
echo " your hostname is: $hostname"
echo " your timezone is: $timezone"
echo
