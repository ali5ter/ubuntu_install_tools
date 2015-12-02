# Ubuntu Install Tools
Scripts to help speed up the installation and configuration of an ubuntu server.

Tested for installations of:
* Ubuntu 14.04 (Trusty Tahr)
* Ubuntu 15.04 (Vivid Vervet)
* Ubuntu 15.10 (Wily Werewolf)

## Unattended installation ISO creation
The `create_iso.sh` script will download a Ubuntu Server ISO and reconfigure it
to perform an unattended installation.

This script is written to run on an existing Ubuntu system and has been tested
on Ubuntu 14.04 LTS Desktop systems. You can download and run the script like
this

    wget http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/create_iso.sh && chmod 755 create_iso.sh
    sudo ./create_iso.sh

The script will ask what version of Ubuntu ISO to remaster and then prompt for
your preferred initial account credentials. The `ubuntu.seed` file contains all
the defaults used for the unattended installation.

The `post_install.sh` script is included in the ISO bundle so that it may be
run after installation to patch and configure the installation.

The resulting ISO can be burnt to CDROM, USB drive or mounted directly for
other installation methods, such as creating a virtual machine.

## Virtual machine creation
These are suggested based on how I've used these scripts in my own process.

### ESXi v5.5 & v6
The `create_esxi_vm.sh` script generates the files needed to create a virtual
machine and registers it with the ESXi system. The the `defaults.vmx` file
provides the template of required metadata.

If you're using the unattended isntallation ISOs described above, assuming SSH
and ESXi Shell is enabled, upload them to your ESXi datastore

    scp /tmp/*unattended.iso root@esxi-001.foo.com:/vmfs/volumes/datastore1/ISOs/

Log into the ESXi server and download the script and metadata template

    wget http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/create_esxi_vm.sh && cmod 755 create_esxi_vm.sh
    wget http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/defaults.vmx

Create a VM using the vCPU, memory and storage defaults using one of the
installation ISOs

    ./create_esxi_vm.sh -n server_01 -i /vmfs/volumes/datastore1/ISOs/ubuntu-14.04.3-server-amd64-unattended.iso

For help about changing the defaults run

    ./create_esxi_vm.sh -h

## VMware Fusion 7 & 8
[Process description to come]

## Post installation
The `post_install.sh` script will patch the Ubuntu OS, configure some basic
security settings and install the [CarryBag environment](http://gitlab.different.com/alister/carrybag).

If you create a Ubuntu Server using the unattended installation ISO described
above, then log into the server using the preferred credentials defined and run

    sudo ./post_install.sh

The scirpt will prompt for your preferred hostname and domian before performing
any configuration. Once configuration is completed successfully, the script
will delete itself and reboot the system.

For systems created without the unattended installation ISO, you could download
the script in various way. Here are some suggestions

    wget http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh && chmod 755 post_install.sh

    wget -O - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh | bash

    wget -O - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh | bash -s <hostname> <domain>

## Contribution
If you've stumbled upon this project and wish to contribute, please
[let me know](mailto:alister@different.com).

## Credits
* [Netson's Unattended Ubuntu ISO Maker](https://github.com/netson/ubuntu-unattended)
* [Justin Ellingwood's Digital Ocean tutorials](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers)
