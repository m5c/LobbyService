#!/bin/bash

# invoke the api unit test library script
source rest-tools.sh

# set server base URLs
APIROOT='http://127.0.0.1:4242/api'
TOKENROOT='http://127.0.0.1:4242/oauth'

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

function cleanupadmin {
        TESTCOUNT="C.3"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/users/admin5?access_token=$ADMINTOKEN" "200"
}

function apiTestSequence5 {

	# Reset result stats array
	CHECKSARRAY=()
	
	# Start testing the server...
	echo "Testing the servers REST tree..."

# 1. Preparations
  # Verify bgp provides online flag
	TESTCOUNT="1.1"
	ARGS=(-X GET)
	testMethod "$APIROOT/online" "200"

  # Request admin session token (needed to register gameserver)
	TESTCOUNT="1.2"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=maex&password=abc123_ABC123" "200"
	ADMINTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	ADMINTOKEN=$(escapetoken $ADMINTOKEN)

  # Request service session token (needed to register gameserver)
	TESTCOUNT="1.2"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=xox&password=laaPhie*aiN0" "200"
	SERVICETOKEN=$(echo $PAYLOAD | cut -c 18-45)
	SERVICETOKEN=$(escapetoken $SERVICETOKEN)

  # Request player session token (needed to test access on registration)
	TESTCOUNT="1.3"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=linus&password=abc123_ABC123" "200"
	LINUSTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	LINUSTOKEN=$(escapetoken $LINUSTOKEN)

  # Register gameserver
	TESTCOUNT="1.4"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"Dummy Game 1", "location":"http://127.0.0.1:4243/FunnyDemoGameServer","minSessionPlayers":"2","maxSessionPlayers":"4", "webSupport":"true"}')
        testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "200"

  # Create a second admin account (admin5)
        TESTCOUNT="1.5"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"admin5","password":"abc_123ABC123","preferredColour":"FF0000","role":"ROLE_ADMIN"}')
        testMethod "$APIROOT/users/admin5?access_token=$ADMINTOKEN" "200"

  # Get token for admin5
        TESTCOUNT="1.6"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=admin5&password=abc_123ABC123" "200"
        ADMINTOKEN5=$(echo $PAYLOAD | cut -c 18-45)
        ADMINTOKEN5=$(escapetoken $ADMINTOKEN5)

  # Verify the total list of savegames is empty
	TESTCOUNT="1.5"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames?access_token=$ADMINTOKEN" "200"
	assertnotexists XYZ42 $PAYLOAD

  # Verify the access of a non-existing savegame is denied
	TESTCOUNT="1.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$ADMINTOKEN" "400"

# 2. Sane registration
  # Register a dummy savegame for that gameserver
	TESTCOUNT="2.1"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"players":["maex", "marianick"], "gamename":"DummyGame1", "savegameid":"XYZ42"}')
        testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$SERVICETOKEN" "200"

  # Verify the total list of savegames now contains the test savegame
	TESTCOUNT="2.2"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames?access_token=$LINUSTOKEN" "200"
	assertexists XYZ42 $PAYLOAD

  # Verify the access of a non-existing savegame is now granted
	TESTCOUNT="2.3"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$LINUSTOKEN" "200"
	assertexists XYZ42 $PAYLOAD
	
  # Manually remove the registrated savegame again (accepted, admin)
	TESTCOUNT="2.4"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$ADMINTOKEN5" "200"

  # Verify the access of a non-existing savegame is denied
	TESTCOUNT="2.5"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$ADMINTOKEN" "400"
        
  # Verify the total list of savegames is empty
	TESTCOUNT="2.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames?access_token=$ADMINTOKEN" "200"
	assertnotexists XYZ42 $PAYLOAD

# Illegal registrations (all reject)
  # Register a savegame as admin, but using an admin account [reject]
	TESTCOUNT="3.1"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"players":["maex", "marianick"], "gamename":"DummyGame1", "savegameid":"XYZ42"}')
        testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$ADMINTOKEN5" "403"

  # Register a savegame as admin, but use a non existent player
	TESTCOUNT="3.2"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"players":["maex", "brian"], "gamename":"DummyGame1", "savegameid":"XYZ42"}')
        testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$ADMINTOKEN" "403"

  # Register a savegame as admin, but use a non existent game server
	TESTCOUNT="3.3"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"players":["maex", "marianick"], "gamename":"DummyGame1", "savegameid":"XYZ42"}')
        testMethod "$APIROOT/gameservices/DummyGame2/savegames/XYZ42?access_token=$ADMINTOKEN" "403"

  # Double register a savegame, using a colliding savegame id
	TESTCOUNT="3.4"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"players":["maex", "marianick"], "gamename":"DummyGame1", "savegameid":"XYZ42"}')
        testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$SERVICETOKEN" "200"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"players":["maex", "marianick"], "gamename":"DummyGame1", "savegameid":"XYZ42"}')
        testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$SERVICETOKEN" "400"

  # Manually remove the registrated savegame again
	TESTCOUNT="3.5"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$SERVICETOKEN" "200"
  # TODO: Create second service account, verify non allowed savegame access is prevented.

  # Verify the access of a non-existing savegame is denied
	TESTCOUNT="3.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$ADMINTOKEN" "400"
        
  # Verify the total list of savegames is empty
	TESTCOUNT="3.7"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames?access_token=$ADMINTOKEN" "200"
	assertnotexists XYZ42 $PAYLOAD

# Sessions from savegames (ok)
  # Create a savegame that can be turned into a session
	TESTCOUNT="4.1"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"players":["maex", "marianick", "khabiir"], "gamename":"DummyGame1", "savegameid":"XYZ42"}')
        testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$SERVICETOKEN" "200"

  # Create a session from a previously created savegame
	TESTCOUNT="4.2"
	ARGS=(-X POST --header 'Content-Type: application/json' --data '{"game":"DummyGame1", "creator":"linus", "savegame":"XYZ42"}')
	testMethod "$APIROOT/sessions?access_token=$LINUSTOKEN" "200"

  # Verify the session is listed, verify ID is stored, verify playeramount is fixed to 3
	TESTCOUNT="4.3"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"
	echo $PAYLOAD
	assertexists "DummyGame1" $PAYLOAD
	assertexists "XYZ42" $PAYLOAD
	assertexists "maxSessionPlayers\":3" $PAYLOAD
	assertexists "minSessionPlayers\":3" $PAYLOAD
	# extract the sessionid
	SESSIONID=$(echo $PAYLOAD | cut -d\" -f 4)

  # Get session tokens for marianick, linus, khabiir, so the session can be joined
	TESTCOUNT="4.4"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=marianick&password=abc123_ABC123" "200"
	USERTOKEN2=$(echo $PAYLOAD | cut -c 18-45)
	USERTOKEN2=$(escapetoken $USERTOKEN2)
	TESTCOUNT="4.5"
        testMethod "$TOKENROOT/token?grant_type=password&username=khabiir&password=abc123_ABC123" "200"
	USERTOKEN3=$(echo $PAYLOAD | cut -c 18-45)
	USERTOKEN3=$(escapetoken $USERTOKEN3)

  # Join the session (3rd join must be rejected)
	TESTCOUNT="4.7"
        ARGS=(-X PUT)
        testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN2" "200"
	TESTCOUNT="4.8"
        testMethod "$APIROOT/sessions/$SESSIONID/players/khabiir?access_token=$USERTOKEN3" "200"
# TODO: add a third join, must lead to 400
	
# Remove registration of game-server "DummyGame1"
	cleanup
	cleanupadmin

# Verify savegames are no longer registered (implicit)
	TESTCOUNT="C.4"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices/DummyGame1/savegames?access_token=$ADMINTOKEN" "400"
	assertnotexists XYZ42 $PAYLOAD
	

# Verify all sessions have been implicitly removed
	TESTCOUNT="C.5"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"
	echo $PAYLOAD
	assertnotexists "DummyGame1" $PAYLOAD
	assertnotexists "SESSIONID" $PAYLOAD

# Launching a loaded session
        # register a gameserver
	TESTCOUNT="5.1"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"DummyGame1","displayName":"Dummy Game 1","location":"http://127.0.0.1:4243/FunnyDemoGameServer","minSessionPlayers":"2","maxSessionPlayers":"4", "webSupport":"true"}')
        testMethod "$APIROOT/gameservices/DummyGame1?access_token=$SERVICETOKEN" "200"
	
	# register a savegame for the gameserver
	TESTCOUNT="5.2"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"players":["maex", "marianick", "khabiir"], "gamename":"DummyGame1", "savegameid":"XYZ42"}')
        testMethod "$APIROOT/gameservices/DummyGame1/savegames/XYZ42?access_token=$SERVICETOKEN" "200"

        # Create a session from the savegame
	TESTCOUNT="5.3"
	ARGS=(-X POST --header 'Content-Type: application/json' --data '{"game":"DummyGame1", "creator":"linus", "savegame":"XYZ42"}')
	testMethod "$APIROOT/sessions?access_token=$LINUSTOKEN" "200"

	# Extract the sessionid
	TESTCOUNT="5.3"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"
	SESSIONID=$(echo $PAYLOAD | cut -d\" -f 4)

	# Join the session, so it can be launched
	TESTCOUNT="5.4"
        ARGS=(-X PUT)
        testMethod "$APIROOT/sessions/$SESSIONID/players/marianick?access_token=$USERTOKEN2" "200"

	# Launch the session when there are not enough players (reject)
        TESTCOUNT="5.5"
        ARGS=(-X POST)
        testMethod "$APIROOT/sessions/$SESSIONID?access_token=$LINUSTOKEN" "400"	

	TESTCOUNT="5.6"
        ARGS=(-X PUT)
        testMethod "$APIROOT/sessions/$SESSIONID/players/khabiir?access_token=$USERTOKEN3" "200"

	# Launch the sessions (success)
        TESTCOUNT="5.7"
        ARGS=(-X POST)
        testMethod "$APIROOT/sessions/$SESSIONID?access_token=$LINUSTOKEN" "200"	


if [ ! -z "$INTERLEAVED" ]; then
        echoblue "Hit enter when done with verification of dummy game-server log."
        read awaitgo
fi

	# Verify the session is launched
	TESTCOUNT="5.8"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"
	assertexists "launched\":true" $PAYLOAD
	
	# Remove the registration (must implicitly stall the launched session)
	cleanup

if [ ! -z "$INTERLEAVED" ]; then
        echoblue "Hit enter when done with verification of dummy game-server log."
        read awaitgo
fi

	# Verify the session no longer exists
	TESTCOUNT="E.1"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"
	assertnotexists "launched" $PAYLOAD

}

apiTestSequence5
printstats 5

