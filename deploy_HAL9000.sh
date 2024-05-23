#!/bin/bash

#HAL9000 - Happy Application Land, it's over 9000!
#taken from the Capesstack, modded for use with CPT
#MSD145

#Sudo check:
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

# Set your IP address as a variable. This is for instructions below. Prompts for IP, sets to 10.4.50.105 if empty response.
#Prompt for IP but no validation of correct IP
read -r -e -p "Enter IP for host system (blank for default 10.3.10.105)? " IP
IP="${IP:-10.3.10.105}"

#Automated script
#ip route get 1 | awk '{print $NF;exit}'

# Update your Host file
echo "$IP HAL9000" | tee -a /etc/hosts

# Create SSL certificates
#mkdir -p $(pwd)/nginx/ssl
#mkdir -p $(pwd)/config/onlyoffice/ssl
#openssl req -newkey rsa:2048 -nodes -keyout $(pwd)/nginx/ssl/hal9000.key -x509 -sha256 -days 365 -out $(pwd)/nginx/ssl/hal9000.crt -subj "/C=US/ST=hal9000/L=hal9000/O=hal9000/OU=hal9000/CN=hal9000"
#openssl req -newkey rsa:2048 -nodes -keyout $(pwd)/config/onlyoffice/ssl/hal9000.key -x509 -sha256 -days 365 -out $(pwd)/config/onlyoffice/ssl/hal9000.crt -subj "/C=US/ST=hal9000/L=hal9000/O=hal9000/OU=hal9000/CN=hal9000"

################################
########### Docker #############
################################

# Create the hal9000 network and data volume
docker network create hal9000

# Create & update container volumes where subdirectories are required
install -g 1000 -o 1000 -d /var/lib/docker/volumes/thehive/{db,index,data}
install -g 1000 -o 1000 -d "$(pwd)"/obsidian_vault

######################
## HAL9000 Services ##
######################

#Port References:
# 222       - Gitea
# 3000      - Gitea
# 8000-8001 - Velociraptor
# 9000      - Homer Homepage
# 9001      - Cyberchef ##change due to elastic agent having the same port
# 9002      - Draw.IO
# 9003      - Owncloud
# 9004      - Unused
# 9005      - TheHive
# 9100      - ONLYOFFICE
# 9443      - Portainer

# MySQL DB - Version latest #OwnCloud + Gitea
docker volume create mysql_data
docker run -d --network hal9000 --restart unless-stopped --name hal-mysql -v mysql_data:/var/lib/mysql -v "$(pwd)"/config/mysql/init.sql:/docker-entrypoint-initdb.d/init.sql -e MYSQL_ROOT_PASSWORD=Cyber'!'23 -e MYSQL_DATABASE=owncloud -e MYSQL_USER=cptmysql -e MYSQL_PASSWORD=cptmysql mysql:latest

# Portainer Service - Version 2.18
docker volume create portainer_data
docker run --privileged -d --network hal9000 --restart unless-stopped --name hal-portainer -v portainer_data:/data -v /var/run/docker.sock:/var/run/docker.sock -p 0.0.0.0:9443:9443 portainer/portainer-ce:2.18.3 --admin-password='$2y$05$75NDe3rVNMXwi4EPONivoenIIBiK6M3E4IQZe1z6bIRZ4NnACoiwe' --base-url=/portainer

# ONLYOFFICE DocumentServer - Version latest
docker run -d --network hal9000 --restart unless-stopped --name hal-onlyoffice -p 0.0.0.0:9100:80 -e JWT_SECRET=secret -v document_data:/var/www/onlyoffice/Data -v document_log:/var/log/onlyoffice onlyoffice/documentserver:latest

# Owncloud Service - Version 10.12.x
docker volume create owncloud_data
docker run -d --network hal9000 --restart unless-stopped --name hal-owncloud -p 0.0.0.0:9003:8080 -e JWT_SECRET=secret -e OWNCLOUD_DOMAIN=$IP:9003 -e OWNCLOUD_TRUSTED_DOMAINS=localhost,$IP,hal-onlyoffice -e OWNCLOUD_DB_TYPE=mysql -e OWNCLOUD_DB_NAME=owncloud -e OWNCLOUD_DB_USERNAME=cptmysql -e OWNCLOUD_DB_PASSWORD=cptmysql -e OWNCLOUD_DB_HOST=hal-mysql -e OWNCLOUD_ADMIN_USERNAME=cpt -e 'OWNCLOUD_ADMIN_PASSWORD=Cyber!23' -v owncloud_data:/mnt/data owncloud/server:10.12

# TheHive Service - Version 4.1.x 
docker run -d --network hal9000 --restart unless-stopped --name hal-thehive -p 0.0.0.0:9005:9000 -v "$(pwd)"/config/thehive/application.conf:/etc/thehive/application.conf -v /var/lib/docker/volumes/thehive/db:/opt/thp/thehive/db -v /var/lib/docker/volumes/thehive/index:/opt/thp/thehive/index -v /var/lib/docker/volumes/thehive/data:/opt/thp/thehive/data -e "MAX_HEAP_SIZE=1G" -e "HEAP_NEWSIZE=1G" thehiveproject/thehive4:4.1 --no-config --no-config-secret
## Default user: admin@thehive.local pass: secret ##

# Cyberchef Service - Version latest
docker run -d --network hal9000 --restart unless-stopped --name hal-cyberchef -p 0.0.0.0:9001:8000 mpepping/cyberchef:latest

# Draw.io Service - Version latest
docker run -d --network hal9000 --restart unless-stopped --name hal-draw.io -p 0.0.0.0:9002:8080 jgraph/drawio:latest

# regex101
docker run -d --network hal9000 --restart unless-stopped --name hal-regex -p 0.0.0.0:13007:9090 loopsun/regex101:latest  regex101:
  
#MSB Build not required 
# Gitea Service - Version latest
#docker volume create gitea_data
#docker run -d --network hal9000 --restart unless-stopped --name hal-gitea -p 0.0.0.0:3000:3000 -p 0.0.0.0:222:22 -v gitea_data:/data -v /etc/timezone:/etc/timezone:ro -v /etc/localtime:/etc/localtime:ro -e GITEA__database__DB_TYPE=gitea -e GITEA__database__HOST=hal-mysql:3306 -e GITEA__database__NAME=gitea -e GITEA__database__USER=cptmysql -e GITEA__database__PASSWD=cptmysql gitea/gitea:latest

#MSB build - not required 
# Syncthing Service - Version latest
# Verify against line on IR HAL
#docker run -d --network hal9000 --restart unless-stopped --name hal-syncthing -p 0.0.0.0:8384:8384 -p 0.0.0.0:22000:22000/tcp -p 0.0.0.0:22000:22000/udp -p 0.0.0.0:21027:21027/udp -v "$(pwd)"/obsidian_vault:/var/syncthing syncthing/syncthing:latest

#############
## Testing ##
#############

docker run -d --network hal9000 --restart unless-stopped --name hal-homer -p 0.0.0.0:80:8080 -v "$(pwd)"/homer/assets:/www/assets b4bz/homer:latest

# Quake Server - Version latest
# docker run -d --network hal9000 --restart unless-stopped --name hal-quake -e "HTTP_PORT=666" -e "SERVER=$IP" -p 0.0.0.0:27960:27960 -p 0.0.0.0:666:80 treyyoder/quakejs

########################
## hal9000 Monitoring ##
########################

# Velociraptor - Version latest #Disabled on HAL, moved to independant VM
#docker volume create velociraptor_data
#docker run -d --network hal9000 --restart unless-stopped --name hal-velociraptor -v velociraptor_data:/velociraptor/:rw -p 0.0.0.0:8000-8001:8000-8001 -p 0.0.0.0:8889:8889 -e "VELOX_USER=cptadmin" -e "VELOX_PASSWORD=Cyber!23" -e "VELOX_ROLE=administrator" -e "VELOX_SERVER_URL=https://hal-velociraptor:8000/" -e "VELOX_FRONTEND_HOSTNAME=hal-velociraptor" wlambert/velociraptor:latest

################################
######### Success Page #########
################################
#clear
echo "Great Success"
echo "HAL has been successfully deployed. Browse to https://${IP} for homepage."
echo "Recommend post-install script to be run before accessing any tools."
echo ""
echo "Answer 'No' if install did not download images"
read -n 1 -p "Run post-install configuration script [y/N]? " answer
case "$answer" in
    y|Y )
        echo "Running"; sleep 1; ./postinstall_config.sh "$IP";;
    * )
        echo "Exiting"; sleep 1; exit;;
esac
