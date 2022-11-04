#!/bin/bash

# invoke the api unit test library script
source rest-tools.sh

# set server base URLs
APIROOT='http://127.0.0.1:4242/api'
TOKENROOT='http://127.0.0.1:4242/oauth'

function apiTestSequence2 {

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
	echo "[DEBUG] Admin-token: $ADMINTOKEN"

  # 2.2 request linus session token
	TESTCOUNT="2.2"
	ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
	testMethod "$TOKENROOT/token?grant_type=password&username=linus&password=abc123_ABC123" "200"
	LINUSTOKEN=$(echo $PAYLOAD | cut -c 18-45)
	echo "[DEBUG] Joerg-token: $LINUSTOKEN"

  # 3.1 try to resolve linus token
	TESTCOUNT="3.1"
	ARGS=(-X GET  -H "Authorization:Bearer $LINUSTOKEN") # Note: Requires the UNESCAPED token as param.
	testMethod "$TOKENROOT/username" "200"
	assertexists "linus" $PAYLOAD
	
  # 3.2 try to resolve admin token
	TESTCOUNT="3.2"
	ARGS=(-X GET  -H "Authorization:Bearer $ADMINTOKEN") # Note: Requires the UNESCAPED token as param.
	testMethod "$TOKENROOT/username" "200"
	assertexists "maex" $PAYLOAD

	# from here one we need the escaped tokens, for we use tham as URL parameters.
	ADMINTOKEN=$(escapetoken $ADMINTOKEN)
	LINUSTOKEN=$(escapetoken $LINUSTOKEN)

  # 4.1a create a new user "foo", who is a "player", using admin token, reject, URL mismatch
	TESTCOUNT="4.1a"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Foo","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
	testMethod "$APIROOT/users/Fbo?access_token=$ADMINTOKEN" "400"

  # 4.1b create a new user "foo", who is a "player", using admin token
	TESTCOUNT="4.1b"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Foo","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
	testMethod "$APIROOT/users/Foo?access_token=$ADMINTOKEN" "200"

  # 4.1c update colour for user foo
	TESTCOUNT="4.1c"
	ARGS=(-X POST --header 'Content-Type: application/json' --data '{"colour":"DECAFF"}')
	testMethod "$APIROOT/users/Foo/colour?access_token=$ADMINTOKEN" "200"

  # 4.1d query colour for user foo
	TESTCOUNT="4.1d"
	ARGS=(-X GET)
	testMethod "$APIROOT/users/Foo/colour?access_token=$ADMINTOKEN" "200"
	assertexists "DECAFF" $PAYLOAD
  
  # 4.1e update password for user foo
	TESTCOUNT="4.1e"
	ARGS=(-X POST --header 'Content-Type: application/json' --data '{"oldPassword":"abc_123ABC123","nextPassword":"abc123_ABC123"}')
	testMethod "$APIROOT/users/Foo/password?access_token=$ADMINTOKEN" "200"

  # 4.1f try to retrieve token with new password
        TESTCOUNT="4.1f"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=Foo&password=abc123_ABC123" "200"

  # 4.2 create a the same user again, must be rejected due to name collision
	TESTCOUNT="4.2"
	ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Foo","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
	testMethod "$APIROOT/users/Foo?access_token=$ADMINTOKEN" "400"

  # 4.3 verify user appears in list (admin)
	TESTCOUNT="4.3"
	ARGS=(-X GET)
	testMethod "$APIROOT/users?access_token=$ADMINTOKEN" "200"
	assertexists "Foo" $PAYLOAD

  # 4.4 delete the user again
	TESTCOUNT="4.4"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/users/Foo?access_token=$ADMINTOKEN" "200"

  # 4.5 verify user does no longer appear in list (admin)
	TESTCOUNT="4.5"
	ARGS=(-X GET)
	testMethod "$APIROOT/users?access_token=$ADMINTOKEN" "200"
	assertnotexists "Foo" $PAYLOAD
	
  # 5.1 delete a non-existing user (reject)
	TESTCOUNT="5.1"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/users/Baz?access_token=$ADMINTOKEN" "400"

  # 6.1 add another admin (admin2)
	TESTCOUNT="6.1"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"admin2","password":"abc_123ABC123","preferredColour":"FF0000","role":"ROLE_ADMIN"}')
        testMethod "$APIROOT/users/admin2?access_token=$ADMINTOKEN" "200"	
	echo $PAYLOAD
	
  # 6.2 get token for admin2
	TESTCOUNT="6.2"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=admin2&password=abc_123ABC123" "200"
        ADMINTOKEN2=$(echo $PAYLOAD | cut -c 18-45)
        ADMINTOKENESC2=$(escapetoken $ADMINTOKEN2)
        echo "[DEBUG] Admin-token: $ADMINTOKENESC2"

  # 6.3 use token of admin2 to create another user
	TESTCOUNT="6.3"
        ARGS=(-X PUT --header 'Content-Type: application/json' --data '{"name":"Bar","password":"abc_123ABC123","preferredColour":"01FFFF","role":"ROLE_PLAYER"}')
        testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKENESC2" "200"

  # 6.4 test token retrieval for other user (bar)
	TESTCOUNT="6.4"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=Bar&password=abc_123ABC123" "200"
        BARTOKEN=$(echo $PAYLOAD | cut -c 18-45)
        echo "[DEBUG] Bar-token (Unescaped): $BARTOKEN"

  # 6.5 verify group affiliation of bar
	TESTCOUNT="6.5"
	ARGS=(-X GET  -H "Authorization:Bearer $BARTOKEN") # Note: Requires the UNESCAPED token as param.
	testMethod "$TOKENROOT/role" "200"
	assertexists "ROLE_PLAYER" $PAYLOAD

  # 6.6 verify group affiliation of admin2
	TESTCOUNT="6.6"
	ARGS=(-X GET  -H "Authorization:Bearer $ADMINTOKEN2") # Note: Requires the UNESCAPED token as param.
	testMethod "$TOKENROOT/role" "200"
	assertexists "ROLE_ADMIN" $PAYLOAD
	
  # 6.7 use token of admin2 to delete other user (bar)
	TESTCOUNT="6.7"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/users/Bar?access_token=$ADMINTOKENESC2" "200"

  # 6.8 use token of admin2 to remove admin2 (reject, self removal not allowed for admins)
	TESTCOUNT="6.8"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/users/admin2?access_token=$ADMINTOKENESC2" "400"
	echo $PAYLOAD

  # 6.9 use token of admin to remove admin2
	TESTCOUNT="6.9"
	ARGS=(-X DELETE)
	testMethod "$APIROOT/users/admin2?access_token=$ADMINTOKEN" "200"

  # 7.1 reject token retrieval for Bar
	TESTCOUNT="7.1"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=Bar&password=abc_123ABC123" "400"

  # 7.2 reject token retrieval for admin2
	TESTCOUNT="7.2"
        ARGS=(-X POST --user bgp-client-name:bgp-client-pw)
        testMethod "$TOKENROOT/token?grant_type=password&username=admin2&password=abc_123ABC123" "400"

# requires revoking session and renew token on user delete.

   # 7.3 reject token to name resolving for Bar
        ARGS=(-X GET  -H "Authorization:Bearer $BARTOKEN") # Note: Requires the UNESCAPED token as param.
        testMethod "$TOKENROOT/username" "401"
        assertnotexists "Bar" $PAYLOAD

   # 7.4 reject token to name resolving for admin2
        ARGS=(-X GET  -H "Authorization:Bearer $ADMINTOKEN2") # Note: Requires the UNESCAPED token as param.
        testMethod "$TOKENROOT/username" "401"
        assertnotexists "admin2" $PAYLOAD

   # 7.5 reject token to group resolving for Bar
        ARGS=(-X GET  -H "Authorization:Bearer $BARTOKEN") # Note: Requires the UNESCAPED token as param.
        testMethod "$TOKENROOT/role" "401"
        assertnotexists "Bar" $PAYLOAD

   # 7.6 reject token to group resolving for admin2
        ARGS=(-X GET  -H "Authorization:Bearer $ADMINTOKEN2") # Note: Requires the UNESCAPED token as param.
        testMethod "$TOKENROOT/role" "401"
        assertnotexists "admin2" $PAYLOAD

}

apiTestSequence2
printstats 2

