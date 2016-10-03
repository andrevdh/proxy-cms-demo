CircleCI Build Status [![CircleCI](https://circleci.com/gh/andrevdh/proxy-cms-demo.svg?style=svg)](https://circleci.com/gh/andrevdh/proxy-cms-demo)

This is a quick demonstration project which was set up to show a DevOps workflow for a CMS based on a Laravel PHP web site with an Nginx Reverse Proxy in front of it.

The project runs off 2 docker containers:
- a Nginx reverse proxy based on Ubuntu 16.04
- a LAMP server based on Ubuntu 16.04 running PHP 7 and the Laravel Framework

The local dev environment also features mapped and shared folders for quick editing and testing on the fly while running the docker containers in the background

### A little background on Laravel Framework for PHP

The CMS demo is a simple quick start project generated with composer using the following command in the main project folder (the root of the Laravel application is all contained in the "dist" directory)<br />

```composer create-project laravel/laravel dist 4.2.*```

See https://laravel.com/docs/4.2/quick for more info about this framework

Please note that the basic Laravel app is already included in the source code for this demo so there is no need to install it separately.  

# Setting up local docker development environment

## Pre-requisites
- MacOS
- http://brew.sh/ Homebrew
- Docker and associated utilities<br />`brew install docker docker-machine docker-compose`
- Install Virtualbox https://www.virtualbox.org/

## Set up instructions

1. Create a new docker host (called proxy-cms-demo with 2 cores and 2 GBs of RAM) that runs in VirtualBox like this:<br />
```docker-machine create -d virtualbox --virtualbox-memory 2048 --virtualbox-cpu-count 2 proxy-cms-demo```

2. stop the new machine<br />
```docker-machine stop proxy-cms-demo```

3. create the shared folder mount points<br />
```VBoxManage sharedfolder add "proxy-cms-demo" --name "backend" --hostpath "$HOME/Source/proxy-cms-demo"```

4. start it up again<br />
```docker-machine start proxy-cms-demo```

5. set up the ENV<br />
```eval $(docker-machine env proxy-cms-demo)```

6. map the directory<br />
```docker-machine ssh proxy-cms-demo "sudo sh -c 'mkdir /backend && mount -t vboxsf -o uid=33,gid=33 backend /backend'"```

7. cd to the source folder for the project (in my case ~/Source/proxy-cms-demo)

8. run (in the background with the -d flag)<br />
    ```docker-compose -f docker-compose-local.yml up -d```

9. then to get the IP of your docker host machine run<br />
    ```docker-machine ip proxy-cms-demo```

    the results for example come up as 192.168.99.100<br /><br />
    so the proxy should be available on http://192.168.99.100<br />
    and the backend on http://192.168.99.100:8080

# Deployment workflow and set up

Using the following extra files and scripts we can integrate with some nice tools for a full end to end workflow

- circle.yml (for controlling the build/test/deploy process)
- envsetup.sh (for injecting environment variables into the flow using CircleCI project settings)
- deploy.sh (does the actual docker builds, tagging, pushing into dockerhub and AWS deployments)
- Dockerrun.aws.json.template (used for Elastic Beanstalk deployments via DockerHub and S3)

## CircleCI - Continuous Integration and Deployment
The project comes with a circle.yml file and additional build scripts to do full unit testing and deployment into AWS Elastic Beanstalk applications and environments

## Docker Hub
For Docker image storage and distribution into AWS a DockerHub account is also required (docker build, tagging and pushing all done in circle.yml)
Docker images are tagged with the CircleCI Build Numbers for quickly rolling back in case of emergency.

## Slack Chat Channel
For CircleCI and AWS deployment feedback - Slack integration via a webhook into a chat channel is provided (see the SEND_COMMS function in deploy.sh)

## AWS deployment into Elastic Beanstalk
This requires some further setup in AWS with the following additional configurations

Elastic Beanstalk Applications and Environments will need to be created for each deployment group. For now the demo has staging and production configured as examples in the build scripts (See the BUILD_ENV variable in circle.yml for instance) - but no set up has been done in AWS yet!!

Each environment will also need a proxy and backend tier - apply autoscaling and load balancer settings accordingly - I would recommend have a publicly facing load balancer for the proxy and an internal load balancer between the proxy and backend tier. The URLs for the load balancer endpoints can be injected into the proxy and/or backend environment variables by using the envsetup.sh script.  

All builds are tagged and versioned in AWS as well ... so manual redeployment and rolling back to previous builds can be done quickly and easily using the AWS admin console.
