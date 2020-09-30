#! /bin/bash
echo "type playerid that shallbe admin of the new session:"
read ADMIN_ID
echo "You provided $ADMIN_ID"

curl --header "Content-Type: application/json" -X POST --data '{"gameKind":"ACQUIRE","adminId":'$ADMIN_ID'}' http://127.0.0.1:4242/lobby/; echo
