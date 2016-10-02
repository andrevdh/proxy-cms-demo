
### Setting up local docker development environment

## Pre-requisites
- http://brew.sh/ Homebrew
- `brew install docker docker-machine docker-compose`
- Install Virtualbox https://www.virtualbox.org/

1. Create a new docker host (called proxy-cms-demo with 2 cores and 2 gigs of RAM) like this:
```docker-machine create -d virtualbox proxy-cms-demo --virtualbox-memory 2048 --virtualbox-cpu-count 2```

2. stop the new machine
```docker-machine stop proxy-cms-demo```

3. create the shared folder mount points
```VBoxManage sharedfolder add "proxy-cms-demo" --name "backend" --hostpath "$HOME/Source/proxy-cms-demo"```

4. start it up again
```docker-machine start proxy-cms-demo```

5. set up the ENV
```eval $(docker-machine env proxy-cms-demo)```

6. map the directory
```docker-machine ssh proxy-cms-demo "sudo sh -c 'mkdir /backend && mount -t vboxsf -o uid=33,gid=33 backend /backend'"```

7. cd to the source folder for the backend (in my case $HOME/Source/proxy-cms-demo)

8. run
    ```docker-compose -f docker-compose-local.yml up```

9. then to get the IP of your docker host machine run
    ```docker-machine ip proxy-cms-demo```

    E.g. comes up as 192.168.99.100
    so the proxy should be available on http://192.168.99.100
    and the backend on http://192.168.99.100:8080
