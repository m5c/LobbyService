#!/bin/bash

# invoke the api unit test library script
source rest-tools.sh

# set server base URLs
APIROOT='http://127.0.0.1:4242/api'
TOKENROOT='http://127.0.0.1:4242/oauth'

function apiTestSequence4 {

	# Reset result stats array
	CHECKSARRAY=()
	
	# Start testing the server...
	echo "Testing the servers REST tree..."

  # 1. verify bgp provides online flag
	TESTCOUNT="1"
	ARGS=(-X GET)
	testMethod "$APIROOT/online" "200"

  # 2.1 request admin session token
	TESTCOUNT="2.1"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=maex&password=abc123_ABC123" "200"
	ADMINTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	ADMINTOKEN=$(escapetoken $ADMINTOKEN)

  # 2.2 Create new player "Foo", who we can then modify
        TESTCOUNT="2.2"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Foo","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
        testMethod "$APIROOT/users/Foo?access_token=$ADMINTOKEN" "200"

  # 2.3 Get Foo's token
        TESTCOUNT="2.3"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=Foo&password=abc_123ABC123" "200"
        FOOTOKEN=$(echo $PAYLOAD | cut -c 18-45)
        FOOTOKEN=$(escapetoken $FOOTOKEN)

  # 2.4 Get linuss'token
        TESTCOUNT="2.4"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=linus&password=abc123_ABC123" "200"
        USERTOKEN=$(echo $PAYLOAD | cut -c 18-45)
        USERTOKEN=$(escapetoken $USERTOKEN)

# Details and colour
  # 3.1 try to query foo details as linus (reject)
        TESTCOUNT="3.1"
        ARGS=(-X GET)
        testMethod "$APIROOT/users/Foo?access_token=$USERTOKEN" "400"
	
  # 3.2 try to query foo details as admin
        TESTCOUNT="3.2"
        ARGS=(-X GET)
        testMethod "$APIROOT/users/Foo?access_token=$ADMINTOKEN" "200"
	assertexists Foo $PAYLOAD

  # 3.3 try to query foo details as foo
        TESTCOUNT="3.3"
        ARGS=(-X GET)
        testMethod "$APIROOT/users/Foo?access_token=$FOOTOKEN" "200"
	assertexists 01FFFF $PAYLOAD

  # 3.4 Manipulate colour of Foo (as maex, reject)
        TESTCOUNT="3.4"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"colour":"0000FF"}')
        testMethod "$APIROOT/users/Foo/colour?access_token=$USERTOKEN" "400"

  # 3.5 Manipulate colour of Foo (as admin, ok)
        TESTCOUNT="3.5"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"colour":"0000FF"}')
        testMethod "$APIROOT/users/Foo/colour?access_token=$ADMINTOKEN" "200"

  # 3.6 Manipulate colour of Foo
        TESTCOUNT="3.6"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"colour":"0000FF"}')
        testMethod "$APIROOT/users/Foo/colour?access_token=$FOOTOKEN" "200"

  # 3.7 Verify colour change
        TESTCOUNT="3.7"
        ARGS=(-X GET)
        testMethod "$APIROOT/users/Foo/colour?access_token=$FOOTOKEN" "200"
	assertexists 0000FF $PAYLOAD

# Password 
  # 4.1 try to modify foos password as linus
        TESTCOUNT="4.1"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"oldPassword":"abc_123ABC123", "nextPassword":"abc_123ABC123"}')
        testMethod "$APIROOT/users/Foo/password?access_token=$USERTOKEN" "400"

  # try to modify foos password as admin, but use identical password as new password (reject)
        TESTCOUNT="4.2"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"oldPassword":"abc_123ABC123", "nextPassword":"abc_123ABC123"}')
        testMethod "$APIROOT/users/Foo/password?access_token=$ADMINTOKEN" "400"

  # modify foos password as admin
        TESTCOUNT="4.3"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"oldPassword":"abc_123ABC123", "nextPassword":"abc123_ABC123"}')
        testMethod "$APIROOT/users/Foo/password?access_token=$ADMINTOKEN" "200"

  # modify foos password as foo, but use wrong old password (reject)
        TESTCOUNT="4.4"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"oldPassword":"abc_123ABC123", "nextPassword":"abc123ABC_123"}')
        testMethod "$APIROOT/users/Foo/password?access_token=$FOOTOKEN" "400"

  # modify foos password as foo
        TESTCOUNT="4.5"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"oldPassword":"abc123_ABC123", "nextPassword":"abc123ABC_123"}')
        testMethod "$APIROOT/users/Foo/password?access_token=$FOOTOKEN" "200"

  # try to get session token with old password (reject)
	TESTCOUNT="4.6"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=Foo&password=abc_123ABC123" "400"

  # get session token with new password
	TESTCOUNT="4.7"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=Foo&password=abc123ABC_123" "200"

# Clean up

  # 5.1 Delete user foo as admin
        TESTCOUNT="5.1"
        ARGS=(-X DELETE)
        testMethod "$APIROOT/users/Foo?access_token=$ADMINTOKEN" "200"

  # 5.2 try to query foo details as foo
        TESTCOUNT="5.2"
        ARGS=(-X GET)
        testMethod "$APIROOT/users/Foo?access_token=$FOOTOKEN" "401"

  # 5.3 try to query foo colour details as foo
        TESTCOUNT="5.3"
        ARGS=(-X GET)
        testMethod "$APIROOT/users/Foo/colour?access_token=$FOOTOKEN" "401"
  
  # 5.4 try to query foo colour details as admin
        TESTCOUNT="5.4"
        ARGS=(-X GET)
        testMethod "$APIROOT/users/Foo/colour?access_token=$ADMINTOKEN" "400"

  # 5.5 try to manipulate colour of foo as admin
        TESTCOUNT="5.5"
        ARGS=(-X POST --header 'Content-Type: application/json' --data '{"colour":"00FFFF"}')
        testMethod "$APIROOT/users/Foo/colour?access_token=$ADMINTOKEN" "400"

	
}

apiTestSequence4
printstats 4

