#!/bin/bash

#Sudo check:
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root/sudo"
    exit
fi

echo "Ensure VM has minimum 12 processor cores and 16GB RAM"

read -r -n 1 -p "Continue [Y/n]? " answer
case ${answer:0:1} in
    n|N )
        echo "Exiting."; exit;;
    * )
        ;;
esac

#bluff need a gui server to boot headless with features.
#add/remove as you see fit 
#simple customise env script
#dl lvm expand (WIP)

#system
/usr/bin/apt update 
/usr/bin/apt install -y htop
/usr/bin/apt install -y git
/usr/bin/apt install -y curl
/usr/bin/apt install -y net-tools
/usr/bin/apt install -y open-vm-tools-desktop
/usr/bin/apt install -y openssh-server
/usr/bin/apt install -y ca-certificates
/usr/bin/apt install -y gnupg
/usr/bin/apt install -y lsb-release
##/usr/bin/apt install -y apache2-utils  #If required for updating bcrypt password string CMD: htpasswd -nb -B admin "password-here" | cut -d ":" -f 2
#openjdk-11-jdk

### Docker ###
#remove old docker if exists
/usr/bin/apt remove docker docker-engine docker.io containerd runc
#update repository with official docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#Update with new repository then install docker and dependancies
/usr/bin/apt update -y
/usr/bin/apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Configure docker to be used without requiring sudo #test further, doesn't seem to be working properly.
groupadd docker
usermod -aG docker $SUDO_USER
echo "Docker group added, relog to update groups or run 'exec sg docker newgrp' to initialize"

#start server init 3
sudo systemctl set-default multi-user.target
#reboot for headless or
#/usr/sbin/init 3

#Update resolv.conf to point at actual file so docker pulls proper entries
#ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf 
#Resolv.conf redirected from /run/systemd/resolve/stub-resolv.conf to /run/systemd/resolve/resolv.con to fix docker containers pulling entries

echo "Configuration complete"
echo "Reboot or type init 3 for headless"
echo "To return to GUI use init 5"
