# Ubuntu Install Tools
Scripts to help speed up the installation and configuration of an ubuntu server.

Tested for installations of:
* Ubuntu 14.04 (Trusty Tahr)
* Ubuntu 15.04 (Vivid Vervet)
* Ubuntu 15.10 (Wily Werewolf)

## Installation
Run the `create_iso.sh` script to build a customized version of an Ubuntu Server ISO that will perform an unattended installation.

You could run it without cloning this repository using

    $(wget -qO - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/create_iso.sh | bash)

The script will ask what version of Ubuntu to use and the account credentials the installation should create.

[Some utility to create an ESX or Fusion VM using this ISO]

## Configuration
Run the `post_install.sh` script. You could run it without cloning this repository using

    $(wget -qO - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh | bash)

You can change the defaults located at the top of this shell script or change them from teh command line. To do this with the command above use

    $(wget -qO - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh | bash -s <hostname> <domain> <username> <password>)

## Contribution
If you've stumbled upon this project and wish to contribute, please [let me know](mailto:alister@different.com).

## Reference
* [Unattended installation](http://askubuntu.com/questions/122505/how-do-i-create-a-completely-unattended-install-of-ubuntu)
* [Additional recommended steps](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers)
* [Post install using puppet](https://github.com/netson/ubuntu-unattended/blob/master/start.sh)
* [Carrybag](http://gitlab.different.com/alister/carrybag/)
