#! /bin/bash
# Docker deployment script for local dev environment - Andre van den Heever

docker-machine create -d virtualbox proxy-cms-demo

docker-machine stop proxy-cms-demo

echo "Creating shared folder in: $HOME$1"

VBoxManage sharedfolder add "proxy-cms-demo" --name "backend" --hostpath "$HOME$1"

docker-machine start proxy-cms-demo

eval $(docker-machine env proxy-cms-demo)

docker-machine ssh proxy-cms-demo "sudo sh -c 'mkdir /backend && mount -t vboxsf -o uid=33,gid=33 backend /backend'"

docker-compose -f docker-compose-local.yml up

docker-machine ip proxy-cms-demo
