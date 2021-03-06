#!/bin/bash
set -u

GIT_REPO="dalijolijo"
GIT_PROJECT="bitsee"
DOCKER_REPO="dalijolijo"
IMAGE_NAME="btx-bitsee"
IMAGE_TAG="0.15.2.0.0" #BTX Version 0.15.2.0.0
CONFIG_PATH="/root/.bitcore"
CONFIG=${CONFIG_PATH}/bitcore.conf
CONTAINER_NAME="btx-bitsee"
DEFAULT_PORT="8555"
RPC_PORT="8556"
TOR_PORT="9051"
BITSEE_PORT="3000"
WEB="bitcore.cc" # without "https://" and without the last "/" (only HTTPS accepted)
BOOTSTRAP="bootstrap.tar.gz"
BITSEE_DATA="/root/bitsee_data/"

#
# Color definitions
#
RED='\033[0;31m'
GREEN='\033[0;32m'
NO_COL='\033[0m'
BTX_COL='\033[1;35m'

#
# Check if bitcore.conf already exist.
#
clear
printf "\nDOCKER SETUP FOR ${BTX_COL}BTX BITSEE (v.${IMAGE_TAG})${NO_COL}\n"
printf "\nSetup Config file"
printf "\n-----------------\n"

#
# Docker Installation
#
if ! type "docker" > /dev/null; then
    curl -fsSL https://get.docker.com | sh
fi


#
# Firewall Setup
#
printf "\nDownload needed Helper-Scripts"
printf "\n------------------------------\n"
wget https://raw.githubusercontent.com/${GIT_REPO}/${GIT_PROJECT}/master/docker/check_os.sh -O check_os.sh
chmod +x ./check_os.sh
source ./check_os.sh
#rm ./check_os.sh
wget https://raw.githubusercontent.com/${GIT_REPO}/${GIT_PROJECT}/master/docker/firewall_config.sh -O firewall_config.sh
chmod +x ./firewall_config.sh
source ./firewall_config.sh ${DEFAULT_PORT} ${RPC_PORT} ${TOR_PORT} ${BITSEE_PORT}
#rm ./firewall_config.sh

# 
# Create directory to mount inside the docker container
#
mkdir -p BITSEE_DATA

#
# Pull docker images and run the docker container
#
printf "\nStart Docker container"
printf "\n----------------------\n"
sudo docker ps | grep ${CONTAINER_NAME} >/dev/null
if [ $? -eq 0 ];then
    printf "${RED}Conflict! The container name \'${CONTAINER_NAME}\' is already in use.${NO_COL}\n"
    printf "\nDo you want to stop the running container to start the new one?\n"
    printf "Enter [Y]es or [N]o and Hit [ENTER]: "
    read STOP

    if [[ $STOP =~ "Y" ]] || [[ $STOP =~ "y" ]]; then
        docker stop ${CONTAINER_NAME}
    else
	printf "\nDocker Setup Result"
        printf "\n----------------------\n"
        printf "${RED}Canceled the Docker Setup without starting BTX Bitsee Docker Container.${NO_COL}\n\n"
	exit 1
    fi
fi

docker rm ${CONTAINER_NAME} >/dev/null
docker pull ${DOCKER_REPO}/${IMAGE_NAME}:${IMAGE_TAG}
docker run --rm \
 -p ${DEFAULT_PORT}:${DEFAULT_PORT} \
 -p ${RPC_PORT}:${RPC_PORT} \
 -p ${TOR_PORT}:${TOR_PORT} \
 -p ${BITSEE_PORT}:${BITSEE_PORT} \
 --name ${CONTAINER_NAME} \
 -e WEB="${WEB}" \
 -e BOOTSTRAP="${BOOTSTRAP}" \
 -e CONFIG_PATH=${CONFIG_PATH} \
 -v ${BITSEE_DATA}:/root/bitsee/public/files:rw \
 -d ${DOCKER_REPO}/${IMAGE_NAME}:${IMAGE_TAG}


#
# Show result and give user instructions
#
sleep 3
clear
printf "\nDocker Setup Result"
printf "\n----------------------\n"
sudo docker ps | grep ${CONTAINER_NAME} >/dev/null
if [ $? -ne 0 ];then
    printf "${RED}Sorry! Something went wrong. :(${NO_COL}\n"
else
    printf "${GREEN}GREAT! Your ${BTX_COL}BTX${GREEN} Bitsee Docker Container is running now! :)${NO_COL}\n"
    printf "\nShow your running docker container \'${CONTAINER_NAME}\' with ${GREEN}'docker ps'${NO_COL}\n"
    sudo docker ps | grep ${CONTAINER_NAME}
    printf "\nJump inside the ${BTX_COL}BTX${NO_COL} Bitsee Docker Container with ${GREEN}'docker exec -it ${CONTAINER_NAME} bash'${NO_COL}\n"
    printf "\nCheck Log Output of ${BTX_COL}BTX${NO_COL} Bitsee with ${GREEN}'docker logs ${CONTAINER_NAME}'${NO_COL}\n"
    printf "${GREEN}HAVE FUN!${NO_COL}\n\n"
fi
