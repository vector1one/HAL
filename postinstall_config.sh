#!/bin/bash

#Set $IP from previous script or prompt if no arg and use default if blank
IP=${1:-$(read -p "Enter IP for host system (blank for default 10.3.10.105)? " x && echo "$x")}; IP="${IP:-10.3.10.105}"
#IP=Variable{default to read value, store in x then echo value so it sets as you can't use read value directly for a default}
#As a seperate command if IP is blank then default the value to 10.3.10.105


###############
## Functions ##
###############

#Function to easily enable/disable modules if pre-added to homepage config.yml file, example module below:
      # - name: "Carbon Black"
      #   logo: "assets/icons/carbonblack.png"
      #   subtitle: "Analysis"
      #   tag: "CB"
      #   url: "https://cb-ip"
      #   target: "_blank"
      #   #cb-bgbackground: black
# cb-ip tag for IP (replace with modules tag-ip)
# #cb-bg tag for disabled background (replace with modules tag-bg)
# add/remove tags based on what you want to show up when hovering over


######
#ask_install function to enable/disable homepage modules
#[name, tag-IP, app IP] example: ask_install "Security Onion 2" so2 10.3.10.106
ask_install ()
{
  read -e -n 1 -p "$1 Enable/Disable module? [y/N] " answer
  case "$answer" in
    y|Y )
        read -e -p "IP? (blank for default $3)? " module_IP #Get IP if different from default (default given in function call)
        echo "Setting $1 Homepage IP to $module_IP"
        sed -i "s/$2-ip/$module_IP/" homer/assets/config.yml #Replace module-ip tag with proper IP to enable the modules properly
        ;;
    * )
        echo "Disabling $1 module on Homepage"
        sed -i "s/$2-ip/0.0.0.0/" homer/assets/config.yml #Replace module-ip tag with 0.0.0.0
        sed -Ei "s/$1\"/$1 (Disabled)\"/" homer/assets/config.yml #Append (Disabled) to module name
        sed -i "s/#$2-bg//" homer/assets/config.yml #Remove #module-bg tag to enable background: black line
        ;;
  esac
}

###################
## Configuration ##
###################

# Owncloud ONLYOFFICE Connector
# Adds folder to archive with group and owner data, sends to STDOUT (-f - ), docker cp can read STDIN (cp - ) and auto extract
tar --owner www-data --group www-data -cf - -C "$(pwd)"/config/onlyoffice/ . | docker cp - hal-owncloud:/var/www/owncloud/custom/ 
sleep 2 #Wait for copy before running commands below
#Set config parameters inside the owncloud container via its 'occ' CLI using user www-data (Internal user for owncloud in container).
docker exec --user www-data hal-owncloud occ --no-warnings app:enable onlyoffice
docker exec --user www-data hal-owncloud occ --no-warnings config:system:set onlyoffice DocumentServerUrl --value="http://$IP:9100/"
docker exec --user www-data hal-owncloud occ --no-warnings config:system:set onlyoffice DocumentServerInternalUrl --value="http://hal-onlyoffice/"
docker exec --user www-data hal-owncloud occ --no-warnings config:system:set onlyoffice StorageUrl --value="http://$IP:9003/"
docker exec --user www-data hal-owncloud occ --no-warnings config:system:set onlyoffice jwt_secret --value="secret"
docker exec --user www-data hal-owncloud occ --no-warnings config:system:set onlyoffice verify_peer_off --value="true"

########################
## Configure Homepage ##
########################

#Add set IP for homepage to access most apps
sed -i "s/host-ip/$IP/" homer/assets/config.yml

#Prompt for IP of the following servers, or disable on homepage (Arguments [name, tag-IP, IP] (name, tag-IP, #tag-bg added to homepage ahead of time)
#ask_install "Security Onion 2" so2 10.3.10.106
#ask_install "Assembly Line" assem 10.3.10.107
#ask_install "Velociraptor" velo 10.3.10.108
#ask_install "Carbon Black" cb 10.3.10.109
