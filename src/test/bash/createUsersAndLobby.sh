#!/bin/bash

#create three users
curl --header "Content-Type: application/json"       -X POST       --data '{"uniqueName":"maex","displayName":"toto","password":"abc123"}'       http://127.0.0.1:4242/accounts/
curl --header "Content-Type: application/json"       -X POST       --data '{"uniqueName":"resa","displayName":"toto","password":"abc123"}'       http://127.0.0.1:4242/accounts/
curl --header "Content-Type: application/json"       -X POST       --data '{"uniqueName":"schiedi","displayName":"toto","password":"abc123"}'       http://127.0.0.1:4242/accounts/

# query users
curl -X GET http://127.0.0.1:4242/accounts/;echo

# search for open games
# curl -X GET http://127.0.0.1:4242/lobby/?hash=;echo




