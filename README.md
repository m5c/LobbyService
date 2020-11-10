# Lobby Service

Generic board game functionality, coded for reuse.

![version](https://img.shields.io/badge/version-1.0.0-brightgreen)
![coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)
![building](https://img.shields.io/badge/build-passing-brightgreen)
![spring](https://img.shields.io/badge/Spring%20Boot-2.3.0-blue)
![gson](https://img.shields.io/badge/Gson-2.8.6-blue)
![arl](https://img.shields.io/badge/AsyncRestLib-1.5.1-blue)
![unirest](https://img.shields.io/badge/Unirest-3.7.02-blue)
![sql](https://img.shields.io/badge/SQL-8.0.21-blue)
![docker](https://img.shields.io/badge/Docker-19.03.8-blue)
![docker-compose](https://img.shields.io/badge/DockerCompose-1.25.5-blue)

## About

This repository hosts the sources of the *Lobby Service* (LS)

 * The LS provides generic game-functionality, that can be easily integrated to speed up the implementation of new board games. Those are:
   * User management and authentication.
   * Game session management.
 * The LS exposes all functionality through a REST interface. The LS can be invoked from any programming language that supports the [Hypertext Transfer Protocol (HTTP)](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol).

## Further Reading

Please consult the following documents for further instructions:

 * [Build & Deploy Instructions](markdown/build-deploy.md) How to get the LS running on your system.
 * [Game Dev Essentials](markdown/game-dev.md) What game-developers should know about the LS.
 * [API Specification](markdown/api.md) Complete API documentation of LS-provided methods.

## For Contributors

This repository is structured as follows

 * Dockerfiles / Docker-compose files: ```/```
 * LS-backend sources: ```/src```
 * [Unit tests](unit-tests/about.md) are located at ```/unit-tests/ls-units-*```  
There is a total of 344 tests/assertions that fully covers the [services REST API](markdown/api.md#user-content-rif-overview).
 * Sample Game-Server for callbacks: ```/units/GameServerStub```
 * Documentation: ```/markdown```

## Contact / Pull Requests

Contact information for bug reports and pull requests:

 * Author: Maximilian Schiedermeier ![email](markdown/email.png)
 * Github: [Kartoffelquadrat](https://github.com/kartoffelquadrat)
 * Webpage: [McGill University, School of Computer Science](https://www.cs.mcgill.ca/~mschie3)
 * License: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
