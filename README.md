# Ubuntu Install Tools
Scripts to help speed up the installation and configuration of an ubuntu server.

Tested for installations of:
* Ubuntu 14.04 (Trusty Tahr)
* Ubuntu 15.04 (Vivid Vervet)
* Ubuntu 15.10 (Wily Werewolf)

## Installation
Download the `create_iso.sh` script and run it. This will build a customized
version of an Ubuntu Server ISO that will perform an unattended installation.

    wget http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/create_iso.sh && chmod 755 create_iso.sh
    sudo ./create_iso.sh

The script will ask what version of Ubuntu to use and the account credentials
the installation should create.

The resulting ISO can be burnt to CDROM or USB drive or used to create a
virtual machine.

## Configuration
If you created a server using the unattended installation ISO (described above)
, then log into the server using the credentials defined by it and in the home
directory will be the `post_install.sh` script. Run this script for an
interactive configuration:

    sudo ./post_install.sh

For systems created without the unattended installation ISO, download and run
the script like this

    wget -O - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh | bash

You can change the defaults located at the top of this shell script or provide
them from the command line like this

    wget -O - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh | bash -s <hostname> <domain>

## Contribution
If you've stumbled upon this project and wish to contribute, please
[let me know](mailto:alister@different.com).

## Credits
* [Netson's Unattended Ubuntu ISO Maker](https://github.com/netson/ubuntu-unattended)
* [Justin Ellingwood's Digital Ocean tutorials](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers)
