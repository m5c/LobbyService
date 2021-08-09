#!/bin/bash

# invoke the api unit test library script
source rest-tools.sh

# set server base URLs
APIROOT='http://127.0.0.1:4242/api'
TOKENROOT='http://127.0.0.1:4242/oauth'

function apiTestSequence1 {

	# Reset result stats array
	CHECKSARRAY=()
	
	# Start testing the server...
	echo "Testing the servers REST tree..."

  # 1. verify bgp provides online flag
	TESTCOUNT="1"
	ARGS=(-X GET)
	testMethod "$APIROOT/online" "200"

  # 2.1 request service session token
	TESTCOUNT="2.1"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=xox&password=laaPhie*aiN0" "200"

  #2.2 verify the response body contains an access token.
	TESTCOUNT="2.2"
	assertexists "access_token" $PAYLOAD
	SERVICETOKEN=$(echo $PAYLOAD | cut -c 18-45)
	SERVICETOKEN=$(escapetoken $SERVICETOKEN)
	#echo $PAYLOAD
	echo "[DEBUG] Service-token: $SERVICETOKEN"

  # 3.1 register test game server without token (reject)
	TESTCOUNT="3.1"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","location":"myFunnyLocation", "maxSessionPlayers":2, "minSessionPlayers":2, "webSupport":"false"}')
	testMethod "$APIROOT/gameservices/DummyGame1" "401"

  # 3.2 get list of registered game servers, so we can validate the registration failed
	TESTCOUNT="3.2"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices" "200"

  # 3.3 verify the response body does not contain the string of the registered game
	TESTCOUNT="3.3"
	assertnotexists "DummyGame1" $PAYLOAD

  # 3.4 retireve specific information (reject)
	TESTCOUNT="3.4"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1" "400"

  # 5.1 register test game server with admin token (reject, bad bounds)
	TESTCOUNT="5.1"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"Dummy Game 1","location":"http://127.0.0.1:8080/sessions/123","minSessionPlayers":"-2","maxSessionPlayers":"8", "webSupport":"true"}')
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "400"

  # 5.2 register test game server with admin token (reject, bad adress)
	TESTCOUNT="5.2"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"Dummy Game 1","location":"http://127.0.0.1::8080/sessions/123","minSessionPlayers":"3","maxSessionPlayers":"5", "webSupport":"true"}')
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "400"

  # 5.3a register test game server with admin token (reject, bad server name)
	TESTCOUNT="5.3a"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"   ","displayName":"Dummy Game 1", "location":"http://127.0.0.1:8080/sessions/123","minSessionPlayers":"3","maxSessionPlayers":"5", "webSupport":"true"}')
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "400"

  # 5.3b register test game server with admin token (reject, bad display name)
	TESTCOUNT="5.3b"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"     ", "location":"http://127.0.0.1:8080/sessions/123","minSessionPlayers":"3","maxSessionPlayers":"5", "webSupport":"true"}')
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "400"

  # 5.4 register test game server with admin token (reject, bad server name in websupport field)
	TESTCOUNT="5.4"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"Dummy Game 1","location":"http://127.0.0.1:8080/sessions/123","minSessionPlayers":"3","maxSessionPlayers":"5", "webSupport":"xyz"}')
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "400"

  # 5.5a register test game server with admin token (reject, blank display name)
	TESTCOUNT="5.5a"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"     ","location":"http://127.0.0.1:8080/sessions/123","minSessionPlayers":"3","maxSessionPlayers":"5", "webSupport":"true"}')
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "400"

  # 5.5b register test game server with admin token (success)
	TESTCOUNT="5.5b"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"Dummy Game 1","location":"http://127.0.0.1:8080/sessions/123","minSessionPlayers":"3","maxSessionPlayers":"5", "webSupport":"true"}')
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "200"

  # 5.6 Verify parameter retrieval for this specific gameservice
	TESTCOUNT="5.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1" "200"
	assertexists "DummyGame1" $PAYLOAD

  # 6.1 verify if the registered game shows up
	TESTCOUNT="6.1"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices" "200"

  # 6.2 verify the response body contains the string of the registered game
	TESTCOUNT="6.2"
	assertexists "DummyGame1" $PAYLOAD

  # 6.3 verify the same game name (same name identifier, different displayName) can not be registered twice
	TESTCOUNT="6.3"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"Dummy Game 3","location":"127.0.0.1:8080","minSessionPlayers":"3","maxSessionPlayers":"5", "webSupport":"true"}')
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "400"

  # 6.4 verify the same game name (different identifier, same displayName) can not be registered twice
	TESTCOUNT="6.4"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame3","displayName":"Dummy Game 1","location":"127.0.0.1:8080","minSessionPlayers":"3","maxSessionPlayers":"5", "webSupport":"true"}')
	testMethod "$APIROOT/gameservices/DummyGame3?access_token=$SERVICETOKEN" "400"

  # 7. unregister the registered game
	TESTCOUNT="7"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "200"

  # 8.1 verify the unregistered game does no longer show up, get list of registered games
	TESTCOUNT="8.1"
        ARGS=(-X GET)
        testMethod "$APIROOT/gameservices" "200"	

  # 8.2 verify DummyGame1 no longer shows up
	TESTCOUNT="8.2"
        assertnotexists "DummyGame1" $PAYLOAD
}

apiTestSequence1
printstats 1

