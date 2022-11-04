#!/bin/bash

# invoke the api unit test library script
source rest-tools.sh

# set server base URLs
APIROOT='http://127.0.0.1:4242/api'
TOKENROOT='http://127.0.0.1:4242/oauth'

# Helper method to speed up the process of getting a launchable game on server side.
# Can only be called if TOKENS are already set.
# Overwrites the SESSIONID variable
function launchPreparation {

	# Create new player "Foo", who will create the session
	TESTCOUNT="LP.1"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Foo","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
        testMethod "$APIROOT/users/Foo?access_token=$ADMINTOKEN" "200"

	# Register game server
        TESTCOUNT="LP.2"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"Dummy Game 1","location":"http://127.0.0.1:4243/FunnyDemoGameServer","minSessionPlayers":"2","maxSessionPlayers":"2", "webSupport":"true"}')
        testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "200"

	# Get Foo's token
        TESTCOUNT="LP.3"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=Foo&password=abc_123ABC123" "200"
        FOOTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	FOOTOKEN=$(escapetoken $FOOTOKEN)

	# Create a session
        TESTCOUNT="LP.4"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"game":"DummyGame1", "creator":"Foo", "savegame":""}')
        testMethod "$APIROOT/sessions?access_token=$FOOTOKEN" "200"
        ARGS=(-X GET)
        testMethod "$APIROOT/sessions" "200"
	SESSIONID=$(echo $PAYLOAD | cut -d\" -f 4)

	# Join the session as marianick
        TESTCOUNT="LP.5"
        ARGS=(-X PUT)
        testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN2" "200"
}

function cleanup {

  # C.1 unregister dummy game server
	TESTCOUNT="C.1"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$ADMINTOKEN" "200"

  # C.2 Verify dummy game shows no longer up in list of available games
        TESTCOUNT="C.2"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices" "200"	
	assertnotexists "DummyGame1" $PAYLOAD

}

function usercleanup {

  # C.3 Delete dummy user "Foo"
        TESTCOUNT="C.3"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/users/Foo?access_token=$ADMINTOKEN" "200"
}

function mainpath {

	# Reset result stats array
	CHECKSARRAY=()
	
	# Start testing the server...
	echo "Testing the servers REST tree..."

  # 1. verify bgp provides online flag
	TESTCOUNT="1"
	ARGS=(-X GET)
	testMethod "$APIROOT/online" "200"


## PREPARATIONS

  # 2.1 request admin session token
	TESTCOUNT="2.1"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=maex&password=abc123_ABC123" "200"
	ADMINTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	ADMINTOKEN=$(escapetoken $ADMINTOKEN)
	echo "[DEBUG] Admin-token: $ADMINTOKEN"

  # 2.2 request a user token
	TESTCOUNT="2.3"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=khabiir&password=abc123_ABC123" "200"
	USERTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	USERTOKEN=$(escapetoken $USERTOKEN)
	echo "[DEBUG] User-token: $USERTOKEN"

  # 2.2 request a second user token
	TESTCOUNT="2.4"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=marianick&password=abc123_ABC123" "200"
	USERTOKEN2=$(echo $PAYLOAD | cut -c 18-45)
	USERTOKEN2=$(escapetoken $USERTOKEN2)
	echo "[DEBUG] User-token 2: $USERTOKEN2"

  # 2.2 request a third user token
	TESTCOUNT="2.5"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=linus&password=abc123_ABC123" "200"
	USERTOKEN3=$(echo $PAYLOAD | cut -c 18-45)
	USERTOKEN3=$(escapetoken $USERTOKEN3)
	echo "[DEBUG] User-token 2: $USERTOKEN3"

  # 3.1 try to create a session for a non-existing game-service (reject)
        TESTCOUNT="3.1"
	ARGS=(-X POST --header 'Content-Type: application/json' --data '{"game":"DummyGame1", "creator":"maex", "savegame":""}')
	testMethod "$APIROOT/sessions?access_token=$USERTOKEN" "400"	

  # 3.2a get service token
          # 2.1 request service session token
        TESTCOUNT="3.2a"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=xox&password=laaPhie*aiN0" "200"
        assertexists "access_token" $PAYLOAD
        SERVICETOKEN=$(echo $PAYLOAD | cut -c 18-45)
        SERVICETOKEN=$(escapetoken $SERVICETOKEN)
        #echo $PAYLOAD
        echo "[DEBUG] Service-token: $SERVICETOKEN"

  # 3.2b register a new dummy gameserver
	TESTCOUNT="3.2b"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"Dummy Game 1","location":"http://127.0.0.1:4243/FunnyDemoGameServer","minSessionPlayers":"2","maxSessionPlayers":"2", "webSupport":"true"}')
	testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "200"

  # 3.3 Verify the registered gameserver is listed
	TESTCOUNT="3.3"
        ARGS=(-X GET)
        testMethod "$APIROOT/gameservices" "200"	
	assertexists "DummyGame1" $PAYLOAD

  # 3.4 try to create a session in the name of someone else (reject)
        TESTCOUNT="3.4"
	ARGS=(-X POST --header 'Content-Type: application/json' --data '{"game":"DummyGame1", "creator":"marianick", "savegame":""}')
	testMethod "$APIROOT/sessions?access_token=$USERTOKEN" "400"	

  # 3.5 Verify dummy game does not yet show up in list of open sessions
        TESTCOUNT="3.5"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertnotexists "DummyGame1" $PAYLOAD

## Session creation

  # 3.6 create a session
        TESTCOUNT="3.6"
	ARGS=(-X POST --header 'Content-Type: application/json' --data '{"game":"DummyGame1", "creator":"khabiir", "savegame":""}')
	testMethod "$APIROOT/sessions?access_token=$USERTOKEN" "200"	

  # 3.7 Verify dummy game shows up in list of open sessions
        TESTCOUNT="3.7"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertexists "DummyGame1" $PAYLOAD

## Launch preparations
## Launching a game (reject)
## Extract sessionid of game from PAYLOAD
	SESSIONID=$(echo $PAYLOAD | cut -d\" -f 4)

  # 4.1. Verify updates for only this specific game can be obtained
        TESTCOUNT="4.1"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions/$SESSIONID" "200"	
	echo $PAYLOAD
	assertexists "DummyGame1" $PAYLOAD

  # 4.2 Launch the game on behalf of someone who is not the game creator (reject)
        TESTCOUNT="4.2"
	ARGS=(-X POST)
	testMethod "$APIROOT/sessions/$SESSIONID?access_token=$USERTOKEN2" "400"	

  # 4.3 Launch the game while there are not yet enough players in the session (reject)
        TESTCOUNT="4.3"
	ARGS=(-X POST)
	testMethod "$APIROOT/sessions/$SESSIONID?access_token=$USERTOKEN" "400"	

# Joining and leaving sessions

  # 5.1 join the game so there are enough players (reject, on behalf of so else)
        TESTCOUNT="5.1"
	ARGS=(-X PUT)
	testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN" "400"	

  # 5.2 join the game so there are enough players
        TESTCOUNT="5.2"
	ARGS=(-X PUT)
	testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN2" "200"	

  # 5.3 verify the players registered to the game
        TESTCOUNT="5.3"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions/$SESSIONID" "200"	
	assertexists "khabiir" $PAYLOAD
	assertexists "marianick" $PAYLOAD

  # 5.4 join the game so there are enough players (reject, game full)
        TESTCOUNT="5.4"
	ARGS=(-X PUT)
	testMethod "$APIROOT/sessions/$SESSIONID/players/linus?access_token=$USERTOKEN3" "400"	

  # 5.5 leave the game again (reject, on behalf of so else)
        TESTCOUNT="5.5"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN3" "400"	

  # 5.6 leave the game again (success)
        TESTCOUNT="5.6"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN2" "200"	

  # 5.7 leave the game as creator (reject)
        TESTCOUNT="5.7"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/sessions/$SESSIONID/players/khabiir?access_token=$USERTOKEN" "400"	

  # 5.8 join the game again, with the other player, so there are enough players for the game to be launched.
        TESTCOUNT="5.8"
	ARGS=(-X PUT)
	testMethod "$APIROOT/sessions/$SESSIONID/players/linus?access_token=$USERTOKEN3" "200"	
	
  # 5.9 verify the players registered to the game
        TESTCOUNT="5.9"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions/$SESSIONID" "200"	
	assertexists "khabiir" $PAYLOAD
	assertexists "linus" $PAYLOAD

## Launch and terminate

  # 6.0 Unauthenticated launch (reject)
        TESTCOUNT="6.0"
	ARGS=(-X POST)
	testMethod "$APIROOT/sessions/$SESSIONID" "401"	

  # 6.1 Phony launch (reject)
        TESTCOUNT="6.1"
	ARGS=(-X POST)
	testMethod "$APIROOT/sessions/$SESSIONID?access_token=$USERTOKEN2" "400"	

  # 6.2 Launch the game on behalf of the creator
        TESTCOUNT="6.2"
	ARGS=(-X POST)
	testMethod "$APIROOT/sessions/$SESSIONID?access_token=$USERTOKEN" "200"	

if [ ! -z "$INTERLEAVED" ]; then
	echoblue "Hit enter when done with verification of dummy game-server log."
	read awaitgo
fi

  # 6.3 Verfify the game is marked as launched.
        TESTCOUNT="6.3"
        ARGS=(-X GET)
        testMethod "$APIROOT/sessions/$SESSIONID" "200"
        assertexists "launched" $PAYLOAD	

  # 6.4 remove launched dummygame session (reject)
        TESTCOUNT="6.4"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/sessions/$SESSIONID?access_token=$USERTOKEN" "400"	

  # 6.5 add another admin (admin3)
        TESTCOUNT="6.5"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"admin3","password":"abc_123ABC123","preferredColour":"FF0000","role":"ROLE_ADMIN"}')
        testMethod "$APIROOT/users/admin3?access_token=$ADMINTOKEN" "200"

  # 6.6 get token for admin3
        TESTCOUNT="6.6"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=admin3&password=abc_123ABC123" "200"
        ADMINTOKEN3=$(echo $PAYLOAD | cut -c 18-45)
        ADMINTOKENESC3=$(escapetoken $ADMINTOKEN3)

  # 6.7 terminate the launched session (game), phony as other admin (reject)
        TESTCOUNT="6.7"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/sessions/$SESSIONID?access_token=$ADMINTOKENESC3" "400"	

  # 6.8 terminate the launched session (game)
        TESTCOUNT="6.8"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/sessions/$SESSIONID?access_token=$SERVICETOKEN" "200"	

  # 6.9 verify session no longer indexed
        TESTCOUNT="6.9"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	assertnotexists DummyGame1 $PAYLOAD
	
  # 6.10 remove admin3
	TESTCOUNT="6.10"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/users/admin3?access_token=$ADMINTOKEN" "200"
	
## CLEAN
	cleanup
}

## Sidepath I - removing a session without launching it
function sidepath1
{
	# Prepare the session again
	launchPreparation
		
  # 7.1 remove unlaunched dummygame session
        TESTCOUNT="7.1"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/sessions/$SESSIONID?access_token=$FOOTOKEN" "200"	

  # 7.2 verify no more updates can be retreived uniquely for removed session
        TESTCOUNT="7.2"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions/$SESSIONID" "400"	
	cleanup
	usercleanup
}

## Sidepath II - removing a session implicitly, by deleting the creator
function sidepath2
{
  # Prepare the session again
	launchPreparation
		
  # 7.1 remove creator
	usercleanup

  # 7.2 verify no more updates can be retreived uniquely for implicitly removed session
        TESTCOUNT="7.2"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions/$SESSIONID" "400"	
	cleanup
}

## Sidepath III - removing a player implicitly from an unlaunched session, by deleting a non-creator
function sidepath3
{
  # Prepare the session again
	launchPreparation

  # 8.1 remove Ryan from the session (do not want to delete a built in user)
        TESTCOUNT="8.1"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN2" "200"	
	
  # 8.2 create a new dummy player (Bar), get her token
	TESTCOUNT="8.2"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Bar","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
        testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKEN" "200"

  # 8.3 Get Bar's token
        TESTCOUNT="8.3"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=Bar&password=abc_123ABC123" "200"
        BARTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	BARTOKEN=$(escapetoken $BARTOKEN)

  # 8.4 Make Bar join Foo's session
        TESTCOUNT="8.4"
	ARGS=(-X PUT)
	testMethod "$APIROOT/sessions/$SESSIONID/players/Bar?access_token=$BARTOKEN" "200"	

  # 8.5 Verify Bar and Foo are in the session
        TESTCOUNT="8.5"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions/$SESSIONID" "200"	
	assertexists "Foo" $PAYLOAD
	assertexists "Bar" $PAYLOAD

  # 8.6 Verify the session exists
        TESTCOUNT="8.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertexists "DummyGame1" $PAYLOAD

  # Remove non-creator from the session, by deleting her account
	usercleanup

  # 8.7 Verify the session no longer exists
        TESTCOUNT="8.7"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertnotexists "DummyGame1" $PAYLOAD
	
  # 8.8 Remove temporary player BAR, clean
        TESTCOUNT="8.8"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKEN" "200"
	cleanup
}

## Sidepath IV - Stalling a running game implicitly by deleting one of the registered players
function sidepath4
{
  # Prepare the session again
	launchPreparation

  # 9.1 remove Ryan from the session (do not want to delete a built in user)
        TESTCOUNT="9.1"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN2" "200"	
	
  # 9.2 create a new dummy player (Bar), get her token
	TESTCOUNT="9.2"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Bar","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
        testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKEN" "200"

  # 9.3 Get Bar's token
        TESTCOUNT="9.3"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=Bar&password=abc_123ABC123" "200"
        BARTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	BARTOKEN=$(escapetoken $BARTOKEN)

  # 9.4 Make Bar join Foo's session
        TESTCOUNT="9.4"
	ARGS=(-X PUT)
	testMethod "$APIROOT/sessions/$SESSIONID/players/Bar?access_token=$BARTOKEN" "200"	

  # 9.5 Verify Bar and Foo are in the session
        TESTCOUNT="9.5"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions/$SESSIONID" "200"	
	assertexists "Foo" $PAYLOAD
	assertexists "Bar" $PAYLOAD

  # 9.6 Verify the session exists
        TESTCOUNT="9.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertexists "DummyGame1" $PAYLOAD

  # 9.7 Launch the session
        TESTCOUNT="9.7"
	ARGS=(-X POST)
	testMethod "$APIROOT/sessions/$SESSIONID?access_token=$FOOTOKEN" "200"	

if [ ! -z "$INTERLEAVED" ]; then
	echoblue "Hit enter when done with verification of dummy game-server log."
	read awaitgo
fi

  # Remove non-creator from the session, by deleting her account - implicitly deleted launched game
	usercleanup

if [ ! -z "$INTERLEAVED" ]; then
	echoblue "Hit enter when done with verification of dummy game-server log."
	read awaitgo
fi

  # 9.8 Verify the session no longer exists
        TESTCOUNT="9.8"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertnotexists "DummyGame1" $PAYLOAD
	
  # 9.9 Remove temporary player BAR, clean
        TESTCOUNT="9.9"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKEN" "200"
	cleanup
}

## Sidepath V - Removing a session implicitly (unlaunched), beacuse the game-server has been unregistered
function sidepath5
{
  # Prepare the session again
	launchPreparation

  # 10.1 remove Ryan from the session (do not want to delete a built in user)
        TESTCOUNT="10.1"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN2" "200"	
	
  # 10.2 create a new dummy player (Bar), get her token
	TESTCOUNT="10.2"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Bar","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
        testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKEN" "200"

  # 10.3 Get Bar's token
        TESTCOUNT="10.3"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=Bar&password=abc_123ABC123" "200"
        BARTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	BARTOKEN=$(escapetoken $BARTOKEN)

  # 10.4 Make Bar join Foo's session
        TESTCOUNT="10.4"
	ARGS=(-X PUT)
	testMethod "$APIROOT/sessions/$SESSIONID/players/Bar?access_token=$BARTOKEN" "200"	

  # 10.5 Verify Bar and Foo are in the session
        TESTCOUNT="10.5"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions/$SESSIONID" "200"	
	assertexists "Foo" $PAYLOAD
	assertexists "Bar" $PAYLOAD

  # 10.6 Verify the session exists
        TESTCOUNT="10.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertexists "DummyGame1" $PAYLOAD

  # Remove session implicitly, by unregistering the associated gameserver
	cleanup

  # 10.7 Verify the session no longer exists
        TESTCOUNT="10.7"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertnotexists "DummyGame1" $PAYLOAD

  # 10.8 Remove temporary player BAR, clean
        TESTCOUNT="10.8"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKEN" "200"
	usercleanup
}

## Sidepath VI - Stalling a launched session implicitly, because the game server has been unregistered.
function sidepath6
{
  # Prepare the session again
	launchPreparation

  # 11.1 remove Ryan from the session (do not want to delete a built in user)
        TESTCOUNT="11.1"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN2" "200"	
	
  # 11.2 create a new dummy player (Bar), get her token
	TESTCOUNT="11.2"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Bar","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
        testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKEN" "200"

  # 11.3 Get Bar's token
        TESTCOUNT="11.3"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=Bar&password=abc_123ABC123" "200"
        BARTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	BARTOKEN=$(escapetoken $BARTOKEN)

  # 11.4 Make Bar join Foo's session
        TESTCOUNT="11.4"
	ARGS=(-X PUT)
	testMethod "$APIROOT/sessions/$SESSIONID/players/Bar?access_token=$BARTOKEN" "200"	

  # 11.5 Verify Bar and Foo are in the session
        TESTCOUNT="11.5"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions/$SESSIONID" "200"	
	assertexists "Foo" $PAYLOAD
	assertexists "Bar" $PAYLOAD

  # 11.6 Verify the session exists
        TESTCOUNT="11.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertexists "DummyGame1" $PAYLOAD

  # 11.7 launch the session
        TESTCOUNT="11.7"
	ARGS=(-X POST)
	testMethod "$APIROOT/sessions/$SESSIONID?access_token=$FOOTOKEN" "200"	

if [ ! -z "$INTERLEAVED" ]; then
	echoblue "Hit enter when done with verification of dummy game-server log."
	read awaitgo
fi

  # Remove session implicitly, by unregistering the associated gameserver
	cleanup

if [ ! -z "$INTERLEAVED" ]; then
	echoblue "Hit enter when done with verification of dummy game-server log."
	read awaitgo
fi

  # 10.8 Verify the session no longer exists
        TESTCOUNT="10.8"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"	
	echo $PAYLOAD
	assertnotexists "DummyGame1" $PAYLOAD
	
  # 10.9 Remove temporary player BAR, clean
        TESTCOUNT="10.9"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKEN" "200"
	usercleanup
}



mainpath
sidepath1
sidepath2
sidepath3
sidepath4
sidepath5
sidepath6
printstats 3

