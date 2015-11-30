# Ubuntu Install Tools

Scripts to help speed up the installation and configuration of an ubuntu server.

Tested for installations of:
* Ubuntu 14.04 (Trusty Tahr)
* Ubuntu 15.04 (Vivid Vervet)

## Installation
[TODO]

## Configuration
Run the `post_install.sh` script. You could run it without cloning this repository using

    $(wget -O - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh | bash)
    
You can change the defaults located at the top of this shell script or change them from teh command line. To do this with the command above use

    $(wget -O - http://gitlab.different.com/alister/ubuntu_install_tools/raw/master/post_install.sh | bash -s <hostname> <domain> <username> <password>)
    
## Contribution
If you've stumbled upon this project and wish to contribute, please 
[let me know](mailto:alister@different.com).

## Reference
* [Unattended insallation](http://askubuntu.com/questions/122505/how-do-i-create-a-completely-unattended-install-of-ubuntu)
* [Additional recommended steps](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers)
* [Post install using puppet](https://github.com/netson/ubuntu-unattended/blob/master/start.sh)
* [Carrybag](http://gitlab.different.com/alister/carrybag/)