#!/usr/bin/env bash
# @file create_iso.sh
# Create an unattended Ubuntu Server ISO
# Based on original work by Rinck Sonnenberg (Netson)
# @see https://github.com/netson/ubuntu-unattended
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

set -e

spinner(){
    # @see http://fitnr.com/showing-a-bash-spinner.html
    local pid=$1
    local delay=0.25
    while [ $(ps -eo pid | grep $pid) ]; do
        for i in \| / - \\; do
            printf ' [%c]\b\b\b\b' $i
            sleep $delay
        done
    done
    echo -ne "\b\b\b\b"
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

# ============================================================================
# Environment

TMP="/tmp"
HOSTNAME="ubuntu"
TIMEZONE="America/New_York"
USER="admin"
PASSWD="\\!QAZ2wsx"

[ "$(id -u)" != "0" ] && {
    echo "This script should be run as root" 1>&2
    exit 1
}

UNAME=$(uname | tr "[:upper:]" "[:lower:]")
[ "$UNAME" == "linux" ] && {
    [ -f /etc/lsb-release ] && DISTRO=$(lsb_release -is)
}
[ "$DISTRO" == "" ] && {
    echo "Run this script on an Ubuntu system"
    exit 1;
}

[ "$(program_is_installed "mkpasswd")" -eq 0 ] || \
        [ "$(program_is_installed "mkisofs")" -eq 0 ] && {
    (apt-get -y update > /dev/null 2>&1) &
    spinner $!
    (apt-get -y install whois genisoimage > /dev/null 2>&1) &
    spinner $!
}

# ============================================================================
# User prompts

echo
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

echo
read -erp "Timezone: " -i "$TIMEZONE" TIMEZONE
read -erp "User name: " -i "$USER" USER
read -erp "Password: " -i "$PASSWD" PASSWD
read -erp "Make ISO bootable via USB [Y|n]: " -i 'Y' BOOTABLE

# ============================================================================
# Download files

cd "$TMP"
[[ -f "$TMP/$DL_FILE" ]] || {
    echo
    echo -n "Downloading $DL_FILE: "
    download "$DL_LOC$DL_FILE"
}

DEFAULTS="ubuntu.seed"
[[ -f "$TMP/$DEFAULTS" ]] || {
    echo
    echo -n "Downloading $DEFAULTS: "
    download "http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/$DEFAULTS"
}

# ============================================================================
# Optional software for bootable USB

[[ $BOOTABLE == "Y" ]] && {
    [ "$(program_is_installed isohybrid)" -eq 0 ] && {
        echo
        (apt-get -y install syslinux > /dev/null 2>&1) &
        spinner $!
    }
}

# ============================================================================
# Reconstruct the ISO image

ISO_SRC="$TMP/iso_src"
ISO_NEW="$TMP/iso_new"
mkdir -p "$ISO_SRC"
mkdir -p "$ISO_NEW"

## Mount the downloaded ISO image and copy the contents to tmp directory
grep -qs "$ISO_SRC" /proc/mounts || \
         mount -o loop "$TMP/$DL_FILE" "$ISO_SRC" > /dev/null 2>&1
(cp -rT "$ISO_SRC" "$ISO_NEW" > /dev/null 2>&1) &
spinner $!

## Set the language for the installation menu
echo en > "$ISO_NEW/isolinux/lang"

## Create the late command for post installation configuration
LATE_CMD="chroot /target wget -O /home/$USER/post_install.sh http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh;\
    chroot /target chmod +x /home/$USER/post_install.sh ;"

## Copy the defaults file to the ISO
cp -rT "$TMP/$DEFAULTS" "$TMP/iso_new/preseed/$DEFAULTS"

## Append the late command
echo "
# Post installation script
d-i preseed/late_command                                    string      $LATE_CMD" >> "$ISO_NEW/preseed/$DEFAULTS"

## Generate the password hash
EPASSWD="$(echo $PASSWD | mkpasswd -s -m sha-512)"

## Update the defaults with the user prompted data
sed -i "s%{{username}}%$USER%g" "$ISO_NEW/preseed/$DEFAULTS"
sed -i "s%{{pwhash}}%$EPASSWD%g" "$ISO_NEW/preseed/$DEFAULTS"
sed -i "s%{{hostname}}%$HOSTNAME%g" "$ISO_NEW/preseed/$DEFAULTS"
sed -i "s%{{timezone}}%$TIMEZONE%g" "$ISO_NEW/preseed/$DEFAULTS"

## Calculate the checksum for the defaults file
CHECKSUM=$(md5sum $ISO_NEW/preseed/$DEFAULTS)

## Add the autoinstall option to the menu
cd "$ISO_NEW"
sed -i "/label install/ilabel autoinstall\n\
  menu label ^Autoinstall CarryBag Ubuntu Server\n\
  kernel /install/vmlinuz\n\
  append file=/cdrom/preseed/ubuntu-server.seed initrd=/install/initrd.gz auto=true priority=high preseed/file=/cdrom/preseed/ubuntu.seed preseed/file/checksum=$CHECKSUM --" "$ISO_NEW/isolinux/txt.cfg"

## Automate the selection of prompt 0 in the menu
sed -i 's/^timeout 0$/timeout 1/' "$ISO_NEW/isolinux/isolinux.cfg"
sed -i '/set menu_color_highlight/ a set default=0' "$ISO_NEW/boot/grub/grub.cfg"
sed -i '/set menu_color_highlight/ a set timeout=10' "$ISO_NEW/boot/grub/grub.cfg"

## Create the remastered ISO
(mkisofs -D -r -V "CARRYBAG_UBUNTU" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 5 -boot-info-table -o $TMP/$ISO . > /dev/null 2>&1) &
spinner $!

## Make ISO bootable (for dd'ing to  USB stick)
[[ $BOOTABLE == "Y" ]] && isohybrid "$TMP/$ISO"

# ============================================================================
# Clean up

umount "$ISO_SRC"
rm -rf "$ISO_NEW" "$ISO_SRC"

echo
echo "Remastered Ubuntu Server ISO complete and available at"
echo "$TMP/$ISO"
echo
echo "The ISO is preconfigured with the following values:"
echo "  Hostname:     $HOSTNAME"
echo "  User name:    $USER"
echo "  Password:     $PASSWD"
echo
echo "Note that the post installation script is configured to run."
