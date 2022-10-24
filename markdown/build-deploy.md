# LS Build & Deploy Instructions

How to run the LS on your system.

## About

This section explains how to set up the Lobby Service on your system, using *Maven* and *Docker*.

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

## Setup

The LS requires preconfigured database before it can be powered up. This is required for lookup / persistence of user data.

### Database

The recommended setup is a dockerized mySQL db setup. Scripts for a [native mySQL DB](../ls-db-setup.sql) or [native Derby DB](ls-derby-setup.sql) are provided as fallbacks, but require careful selection of the [appropriate LS build profile](#lobby-service).

Dockerized DB setup:

 * Create a docker container from the provided ```Dockerfile```. 
 ```bash
  docker build -t "ls-db:Dockerfile" . -f Dockerfile-ls-db
  docker run --platform linux/x86_64 --name=ls-db -p 3453:3306 -d ls-db:Dockerfile 
 ```
 
 > Note: Creation and deployment by Dockerfile is only required the first time!  
 Use ```docker start ls-db``` from here on.

 > **Linux Compatibility**: Docker MySQL container on Fedora is [suspect to saturate RAM](https://github.com/docker-library/mysql/issues/579#issuecomment-519495808). To set boundary, use ```--ulimit``` flag:  ```docker run --ulimit nofile=262144:262144 --platform linux/x86_64 --name=ls-db -p 3453:3306 -d ls-db:Dockerfile```

### Lobby Service

Select one of the provided build profiles, depending on your deployment context:

| Profile | Maven Command | Context |
|---|---|---|
| **dev** | ```mvn clean package spring-boot:run``` | Default profile for development environments. Starts the LS as a native java application, TLS disabled. Accesses the DB as a dockerized mySQL instance.|
| **derby** | ```mvn clean package spring-boot:run -Pderby``` | Same as *dev* except the default mySQL DB connection configuration is replaced by a DERBY configuration. Fallback for developers whose system does not support docker / are having troubles with a manual mySQL installation. |
| **prod** | *Use BGP docker configuration* | Convenient deployment on production servers. LS is compiled and hosted in a docker container. No JDK required on host. DB connection also uses container identifier. Is used by BGP's *docker-compose* configuration. |
| **war** | ```mvn clean package -Pwar``` | Advanced build option that compiles the LS sources into a war file, for native deployment on an existing application container. DB access is replaced by a native mySQL access. This profile has the best resources/performance ratio and is compatible to container provided TLS (https). |

### Verify setup

 * Verify DB access (mySQL, docker):  
```bash
mysql -h 127.0.0.1 -P 3453 --protocol=tcp -u ls -pphaibooth3sha6Hi
 > USE ls;
 > SELECT * FROM player;
```  
*(Make sure default users are listed)*

 > Note: Above command verifies if the DB is reachable from your host system. Therefore you want to run the command on your regular command-line, *not* on a container-internal shell.

 * Verify the LS is running and reflects DB state:
   * Open a browser
   * Visit [http://127.0.0.1:4242/api/online](http://127.0.0.1:4242/api/online)  
You should see ```Lobby-Service platform is happily serving X users.```
   

