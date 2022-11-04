#!/bin/bash

# invoke the api unit test library script
source rest-tools.sh

# set server base URLs
APIROOT='http://127.0.0.1:4242/api'
TOKENROOT='http://127.0.0.1:4242/oauth'

# Main functionality, common to all p2p sequences (iterations)
function p2pmain {

  # Create a p2p admin account (p2pa)
        TESTCOUNT="M.1"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"p2pa","password":"abc_123ABC123","preferredColour":"FF0000","role":"ROLE_ADMIN"}')
        testMethod "$APIROOT/users/p2pa?access_token=$ADMINTOKEN" "200"

  # Create p2p user acount (p2pu)
        TESTCOUNT="M.2a"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"p2pu","password":"abc_123ABC123","preferredColour":"FF0000","role":"ROLE_PLAYER"}')
        testMethod "$APIROOT/users/p2pu?access_token=$ADMINTOKEN" "200"

  # Create service user acount (service)
        TESTCOUNT="M.2b"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"service","password":"abc_123ABC123","preferredColour":"FFFFFF","role":"ROLE_SERVICE"}')
        testMethod "$APIROOT/users/service?access_token=$ADMINTOKEN" "200"

  # Get service token
        TESTCOUNT="M.2c"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=service&password=abc_123ABC123" "200"
        assertexists "access_token" $PAYLOAD
        SERVICETOKEN=$(echo $PAYLOAD | cut -c 18-45)
        SERVICETOKEN=$(escapetoken $SERVICETOKEN)
        echo "[DEBUG] Service-token: $SERVICETOKEN"

  # Get p2pa token
	TESTCOUNT="M.3"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=p2pa&password=abc_123ABC123" "200"
	P2PATOKEN=$(echo $PAYLOAD | cut -c 18-45)
	P2PATOKEN=$(escapetoken $P2PATOKEN)
	
  # Get p2pu token
	TESTCOUNT="M.4"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=p2pu&password=abc_123ABC123" "200"
	P2PUTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	P2PUTOKEN=$(escapetoken $P2PUTOKEN)

	  # Get p2pu token
	TESTCOUNT="M.5"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=linus&password=abc123_ABC123" "200"
	LINUSTOKEN=$(echo $PAYLOAD | cut -c 18-45)
        LINUSTOKEN=$(escapetoken $LINUSTOKEN)

	# Optional test cases for game-server registration with nonsense location
	if [ -z $OPTIONAL ]; then
		echomagenta "[Optional checks activated]"

		# Register p2p stub gameserver with "foobar" as IP [reject]
		TESTCOUNT="O.1"
       		ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"p2p-phantom","displayName":"P2P Phantom","location":"foobar","minSessionPlayers":"2","maxSessionPlayers":"4", "webSupport":"false"}')
        	testMethod "$APIROOT/gameservices/p2p-phantom?access_token=$P2PATOKEN" "403"		

		# Register p2p stub gameserver with whitespace " " [reject]
		TESTCOUNT="O.2"
        	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"p2p-phantom","displayName":"P2P Phantom","location":" ","minSessionPlayers":"2","maxSessionPlayers":"4", "webSupport":"false"}')
        	testMethod "$APIROOT/gameservices/p2p-phantom?access_token=$P2PATOKEN" "403"		
	fi

	# Register p2p stub gameserver without an IP [accept - considered a P2P phantom server]
	TESTCOUNT="M.6"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"p2p-phantom","displayName":"P2P Phantom","location":"","minSessionPlayers":"2","maxSessionPlayers":"4", "webSupport":"false"}')
        testMethod "$APIROOT/gameservices/p2p-phantom?access_token=$SERVICETOKEN" "200"		

	# Optional test cases for p2p-session creation with nonsense client location
	if [ -z $OPTIONAL ]; then
		echomagenta "[Optional checks activated]"

  		    # Create a session for the registered phantom server, without providing a client IP [reject]
		      TESTCOUNT="O.3"
        	ARGS=(-X POST --header 'Content-Type: application/json' --data '{"game":"p2p-phantom", "creator":"p2pu", "savegame":""}')
        	testMethod "$APIROOT/sessions?access_token=$P2PUTOKEN" "400"

		      # Create a session for the registered phantom server, with nonsense IP [reject]
		      TESTCOUNT="O.4"
        	ARGS=(-X POST --header 'Content-Type: application/json' --data '{"game":"p2p-phantom", "creator":"p2pu", "savegame":""}')
        	testMethod "$APIROOT/sessions?location=foobar&access_token=$P2PUTOKEN" "400"
	fi

	# Create a session for the registered phantom server, providing a valid client IP [reject]
	TESTCOUNT="M.7"
  ARGS=(-X POST --header 'Content-Type: application/json' --data '{"game":"p2p-phantom", "creator":"p2pu", "savegame":""}')
  testMethod "$APIROOT/sessions?location=127.0.0.1&access_token=$P2PUTOKEN" "200"
	SESSIONID=$(echo $PAYLOAD | cut -d\" -f 4)

	# Optional test cases for p2p session joining with nonsense location
	if [ -z $OPTIONAL ]; then
	    echomagenta "[Optional checks activated]"

	    # Join a session for the registered phantom server, without providing a client IP [reject]
            TESTCOUNT="O.5"
  	    ARGS=(-X PUT)
            testMethod "$APIROOT/sessions/$SESSIONID/players/maex?access_token=$LINUSTOKEN" "400"

            # Join a session for the registered phantom server, with nonsense IP [reject]
            TESTCOUNT="0.6"
  	    ARGS=(-X PUT)
            testMethod "$APIROOT/sessions/$SESSIONID/players/maex?access_token=$LINUSTOKEN&location=foobar" "400"
	fi

        # join session with valid client IP
        TESTCOUNT="M.8"
        ARGS=(-X PUT)
        testMethod "$APIROOT/sessions/$SESSIONID/players/linus?access_token=$LINUSTOKEN&location=127.0.0.2" "200"

	# Verify both client IPs appear in session details
        TESTCOUNT="M.9"
        ARGS=(-X GET)
        testMethod "$APIROOT/sessions" "200"
        TESTCOUNT="M.10"
        assertexists "127.0.0.1" $PAYLOAD	
        assertexists "127.0.0.2" $PAYLOAD	

        # Launch session (must not fire an exception - unireset calls deactivated if game server in phantom mode.)
        TESTCOUNT="M.10"
        ARGS=(-X POST)
        testMethod "$APIROOT/sessions/$SESSIONID?access_token=$P2PUTOKEN" "200"	

	if [ ! -z "$INTERLEAVED" ]; then
		echoblue "Hit enter when done with verification of BGP log. (Must not contain a unirest exception.)"
		read awaitgo
	fi	

        # Verify the session is marked as launched
	TESTCOUNT="M.12"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"
	assertexists "launched\":true" $PAYLOAD

}

# First p2p sequence. Enables optionals in p2pmain function. Verifies no invalid IPs can be used for server / player registrations. Verifies absence of a serverIP enforces presence of a player IP (p2p mode) upon creation / join of a new session.
function p2pseq1 {

  # Reset result stats array
	CHECKSARRAY=()
	
  # Start testing the server...
	echo "Testing the servers REST tree..."

  # Verify bgp provides online flag
	TESTCOUNT="1.0"
	ARGS=(-X GET)
	testMethod "$APIROOT/online" "200"

  # Request admin session token (needed to create p2pa / p2pu / registrations)
	TESTCOUNT="1.1"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=maex&password=abc123_ABC123" "200"
	ADMINTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	ADMINTOKEN=$(escapetoken $ADMINTOKEN)

   # Run main test scenario with all optionals
	OPTIONALS='true'
        p2pmain
	unset OPTIONALS

   # Leave BGP in same state as before seq1	
   # Delete p2pa
	TESTCOUNT="1.2"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/users/p2pa?access_token=$ADMINTOKEN" "200"

   # Delete p2pu
	TESTCOUNT="1.3a"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/users/p2pu?access_token=$ADMINTOKEN" "200"

   # Delete service account
	TESTCOUNT="1.3b"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/users/service?access_token=$ADMINTOKEN" "200"

  # Verify the phantom server is gone (cascade triggered by deletion of account used for service registration)
	## get list of registered gameservers
	TESTCOUNT="1.4"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices" "200"
  ## verify the response body does not contain the string of the registered game
	TESTCOUNT="1.5"
	assertnotexists "p2p-phantom" $PAYLOAD

  # Verify no more sessions are around
  TESTCOUNT="1.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"
	echo $PAYLOAD
	assertnotexists "p2p-phantom" $PAYLOAD
}

# Second p2p sequence. Skips optionals in p2pmain function. Verifies no invalid IPs can be used for server / player registrations. Verifies absence of a serverIP enforces presence of a player IP (p2p mode) upon creation / join of a new session.
function p2pseq2 {

   # Run main test scenario without optionals
	unset OPTIONALS
        p2pmain

   # Leave BGP in same state as before seq1
   # Unregister phantom server
  TESTCOUNT="2.1"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/gameservices/p2p-phantom?access_token=$P2PATOKEN" "200"

  # Verify the phantom server is gone
	## get list of registered gameservers
	TESTCOUNT="2.2"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices" "200"
  ## verify the response body does not contain the string of the registered game
	TESTCOUNT="2.3"
	assertnotexists "p2p-phantom" $PAYLOAD

  # Verify no more sessions are around
  TESTCOUNT="2.4"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"
	echo $PAYLOAD
	assertnotexists "p2p-phantom" $PAYLOAD

   # Delete p2pa
	TESTCOUNT="2.5"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/users/p2pa?access_token=$ADMINTOKEN" "200"

   # Delete p2pu
	TESTCOUNT="2.6"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/users/p2pu?access_token=$ADMINTOKEN" "200"

   # Delete service account
	TESTCOUNT="2.7"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/users/service?access_token=$ADMINTOKEN" "200"


}

# Third p2p sequence. Skips optionals in p2pmain function. Verifies no invalid IPs can be used for server / player registrations. Verifies absence of a serverIP enforces presence of a player IP (p2p mode) upon creation / join of a new session.
function p2pseq3 {

   # Run main test scenario without optionals
	unset OPTIONALS
        p2pmain

  # Leave BGP in same state as before seq1
  # Delete p2pu (must implicitly remove session where p2pu participates)
	TESTCOUNT="3.1"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/users/p2pu?access_token=$ADMINTOKEN" "200"

  # Verify no more sessions are around
  TESTCOUNT="3.2"
	ARGS=(-X GET)
	testMethod "$APIROOT/sessions" "200"
	echo $PAYLOAD
	assertnotexists "p2p-phantom" $PAYLOAD

  # Verify the phantom server is still there
	## get list of registered gameservers
	TESTCOUNT="3.3"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices" "200"
  ## verify the response body does not contain the string of the registered game
	TESTCOUNT="3.4"
	assertexists "p2p-phantom" $PAYLOAD

   # Unregister phantom server
  TESTCOUNT="3.5"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/gameservices/p2p-phantom?access_token=$P2PATOKEN" "200"

  # Verify the phantom server is gone
	## get list of registered gameservers
	TESTCOUNT="3.6"
	ARGS=(-X GET)
	testMethod "$APIROOT/gameservices" "200"
  ## verify the response body does not contain the string of the registered game
	TESTCOUNT="3.7"
	assertnotexists "p2p-phantom" $PAYLOAD

   # Delete p2pa
	TESTCOUNT="3.8"
  ARGS=(-X DELETE)
  testMethod "$APIROOT/users/p2pa?access_token=$ADMINTOKEN" "200"
}




p2pseq1
p2pseq2
p2pseq3
printstats 6

