# Ubuntu Install Tools
Scripts to help speed up the installation and configuration of an ubuntu server.

Tested for installations of:
* Ubuntu 14.04 (Trusty Tahr)
* Ubuntu 15.04 (Vivid Vervet)
* Ubuntu 15.10 (Wily Werewolf)

## Unattended installation ISO creation
**The [create_iso](create_iso) script will download a Ubuntu Server ISO and reconfigure it
to perform an unattended installation.**

This script is written to run on an existing Ubuntu system and has been tested
on Ubuntu 14.04 LTS Desktop. 

Download the script and run it

    wget http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/create_iso && chmod 755 create_iso
    sudo ./create_iso

The script will ask what version of Ubuntu ISO to remaster and then prompt for
your preferred initial account credentials. The [ubuntu.seed](ubuntu.seed)
file contains all the defaults used for the unattended installation.

The [post_install](post_install) script is included in the ISO bundle so that it may be
executed after installation to patch and configure the installation.

The resulting ISO can be burnt to CDROM, USB drive or mounted directly for
other installation methods, such as creating a virtual machine.

## Virtual machine creation
These are suggestions based on how I've used these scripts in my own process.

### ESXi v5.x & v6.x
This assumes you have [enabled SSH and ESXi Shell](http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2004746)
on the ESXi host.

Push any unattended installation ISOs you created, and want to use, to your ESXi
datastore, say a directory you created called ISOs under the default datastore

    scp /tmp/*unattended.iso root@esxi-001.foo.com:/vmfs/volumes/datastore1/ISOs/

Log into the ESXi host and download the [create_esxi_vm](http://gitlab.different.com/alister/vmware_scripts/blob/master/ESXi/create_esxi_vm)
script like this

    wget -Oq http://gitlab.different.com/alister/vmware_scripts/raw/master/ESXi/create_esxi_vm && chmod 755 create_esxi_vm

Create a virtual machine using the vCPU, memory and storage defaults and one of
the installation ISOs you just uploaded

    ./create_esxi_vm -n server_01 -i /vmfs/volumes/datastore1/ISOs/ubuntu-14.04.3-server-amd64-unattended.iso

Once complete, the virtual machine will automically power on and install Ubuntu
Server. After a few minutes it will reboot and end on a login prompt.

To perform post installation configuration, open a console on the virtual
machine, login using the credentials defined.

## Post installation
The [post_install](post_install) script will patch the Ubuntu OS, configure some basic
security settings and install the [CarryBag environment](http://gitlab.different.com/alister/carrybag).

If you created a Ubuntu Server using the unattended installation ISO described
above, then log into the server using the preferred credentials defined and run

    sudo ./post_install

The scirpt will prompt for your preferred hostname and domian before performing
any configuration. Once configuration is completed successfully, the script
will delete itself and reboot the system.

For systems created without the unattended installation ISO, you could download
the script in various way. Here are some suggestions

    wget -Oq http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh && chmod 755 post_install

    wget -Oq - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install | bash

    wget -Oq - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install | bash -s <hostname> <domain>

## Contribution
If you've stumbled upon this project and wish to contribute, please
[let me know](mailto:alister@different.com).

## Credits
* [Netson's Unattended Ubuntu ISO Maker](https://github.com/netson/ubuntu-unattended)
* [Justin Ellingwood's Digital Ocean tutorials](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers)