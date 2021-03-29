# LS Build & Deploy Instructions

How to run the LS on your system.

## About

This section explains how to set up the Lobby Service on your system, using *Docker*. At the end you will find instructions for advanced users on how to integrate a gameserver into a prepared *docker-compose* configuration. 

 * [Standard setup, using Docker](#standard-setup)
 * [Full Microservice setup, using Docker-Compose](#advanced-setup)

### Preliminary steps

Clone this repository with either ```https```, ```ssh``` or the direct download as ```zip```.

 * First option: ```git clone https://github.com/kartoffelquadrat/LobbyService.git```
 * Or click on the download button, then extract the zip file.

Install the following software on your machine:

 * [JDK-8 or higher](https://www.oracle.com/java/technologies/javase-jdk14-downloads.html).  
 *Verify system JDK version: ```java -version```*
   * [Mac](https://brew.sh/) ```brew cask install adoptopenjdk12```
   * [Linux](https://linux.die.net/man/8/apt-get) ```sudo apt install openjdk-12-jdk```
   * [Windows](https://www.oracle.com/java/technologies/javase-jdk14-downloads.html)
 * [Maven](https://maven.apache.org/)
   * [Mac](https://brew.sh/) ```brew install maven```
   * [Linux](https://linux.die.net/man/8/apt-get) ```sudo apt install maven```
   * [Windows](https://maven.apache.org/download.cgi)
 * [Docker](https://docs.docker.com/get-docker)

## Standard Setup

### Deploy Database

 * Create a docker container from the provided ```Dockerfile```. 
 ```bash
  docker build -t "ls-db:Dockerfile" . -f Dockerfile-ls-db
  docker run --name=ls-db -p 3453:3306 -d ls-db:Dockerfile
 ```
 
 > Note: Creation and deployment by Dockerfile is only required the first time!  
 Use ```docker start ls-db``` from here on.
 
### Compile / Deploy API backend

 * Power up the LS REST-API backend:
```
cd LobbyService
mvn clean spring-boot:run
```

### Verify setup

 * Verify the LS is reachable
   * Open a browser
   * Visit [http://127.0.0.1:4242/api/online](http://127.0.0.1:4242/api/online)  
You should see ```Lobby-Service platform is happily serving 5 users.```
   
 * Verify DB access:  
```bash
mysql -h 127.0.0.1 -P 3453 --protocol=tcp -u ls -pphaibooth3sha6Hi
 > USE ls;
 > SELECT * FROM player;
```  
*(Make sure the five default users are listed)*


## Advanced Setup

The advanced setup builds and deploys the entire LS and provided GameServers as a Microservice.

 > Disclaimer: You will have to create a corresponding entry in ```docker-compose.yml``` and an extra ```Dockerfile``` for each integrated Game-Server.  
   **This setup is intended for deployment on production servers, not for game developers.**


### Preparations

 * Write a ```Dockerfile``` for (each) of your game service.
 * Remove the comment lines from [```docker-compose.yml```](../docker-compose.yml).
 * Edit the stub service entry for (each of) your Game-Service in [```docker-compose.yml```](../docker-compose.yml).  
Update:
   * Port information
   * Service name
   * Service launch command
   * Serivce dependencies
   * Path to your ```Dockerfile```
 
### Deployment

 * Power up the microservice:
```bash
cd LobbyService
docker-compose up
```

 * Make sure the API backend is reachable:  
```curl -X GET http://127.0.0.1:4242/api/online```

 * [Test API access](http://127.0.0.1:4242/api/online) -> Must display: ```Lobby-Service platform is happily serving 5 users.```
