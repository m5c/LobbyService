#! /bin/bash

TESTPREAMBLE='----------------------------'

# Change terminal colours to green
function echogreen {
	echo -e "\033[00;32m$1\033[00;39m"
}

# Change terminal colours to red
function echored {
	echo -e "\033[00;31m$1\033[00;39m"
}

# Change terminal colours to blue
function echoblue {
	echo -e "\033[00;36m$1\033[00;39m"
}

# Change terminal colours to blue
function echomagenta {
	echo -e "\033[00;35m$1\033[00;39m"
}

# First param: target URL (including URL-params)
# Second param: expected return code (number) or "HTML" if an error page is expected.
# Third param (Optional): Expected return body payload string
# Other arguments: global ARGS variable (is an array, resolve it with ${ARGS[@]})
function testMethod {

	# continue on errors
	set +e

	# print log information
	echo $TESTPREAMBLE
	echo "[$TESTCOUNT] Testing: $1"
	ESCAPED_URL=""
	echo "Effective query:    curl -s -D /dev/stdout "${ARGS[@]}" \"$1\"; echo"
	echo "Expected:  $2"

	# actually test the backend
	RETURN_BUNDLE=$(curl -s -D /dev/stdout "${ARGS[@]}" $1 | tr '\r' '#')
#DEBUG
#			echo "Bundle = $RETURN_BUNDLE"

	# if no reply, server did not reply / is down
	if [ -z "$RETURN_BUNDLE" ]; then
	    echored "[FAILED] No reply from API."
	    CHECKSARRAY+=('[FAILED]')
	    return -1
	fi

	# if bundle is formated like an html page, this means tomcat created an error page for us
	if [[ $RETURN_BUNDLE == *"doctype html"* ]]; then
	    if test "$2" != "HTML"; then
	        echored "ERROR! Server returned HTML fallback page."
                exit -1
            else
		echogreen "[PASSED]"
		CHECKSARRAY+=('[PASSED]')
		return 1
	    fi
	fi

	# get last word in first line (is the status code)
	HTTP_CODE=$(cut -d "#" -f 1 <<< $RETURN_BUNDLE | awk '{ print $NF }')
	# get only word in 6th line.
	RETURN_VALUE=$(cut -d "#" -f 8 <<< $RETURN_BUNDLE | cut -c 2-)
#DEBUG
			echo "Received:  $HTTP_CODE"
#			echo "Value = $RETURN_VALUE"

	# if returned http code is not the expected, abort.
	if test "$HTTP_CODE" != "$2"; then
	   echored "[FAILED] Server returned: $HTTP_CODE"
	   CHECKSARRAY+=('[FAILED]') 
	   return -1
	fi

	# if returned payload is not the expected content, abort.
	if [ ! -z $3 ]; then
		if test "$RETURN_VALUE" != "$4"; then
	   	echored "[FAILED] Server returned: \"$RETURN_VALUE\" but I expected: \"$4\""
	        CHECKSARRAY+=('[FAILED]') 
	   	return -1
		fi
	fi

	# return actual payload, just in case it is required for further dynamic sequences
	# payload is in lone 11 or 12 or 13  depending on query. However the mutually other line is always empty so we can just concatenate the two lines.
	PAYLOAD=$(cut -d "#" -f 11 <<< $RETURN_BUNDLE)
	PAYLOAD=$PAYLOAD$(cut -d "#" -f 12 <<< $RETURN_BUNDLE)
	PAYLOAD=$PAYLOAD$(cut -d "#" -f 13 <<< $RETURN_BUNDLE)
	echo " >> $PAYLOAD"
	export PAYLOAD

	echogreen "[PASSED]"
	CHECKSARRAY+=('[PASSED]')

	# disable ignore errors
	set -e
}

function foo
{
	echo foo;
}

# prints the stats, based on the individual api test results
function printstats {
        echo "============================"

	# considered failed if there is at least one api method that did not reply as expected.
	for i in "${CHECKSARRAY[@]}"
	do
		if [ ! "$i" = "[PASSED]" ]; then
			echored "Some tests failed!"
			return -1
		fi
	done

        # consider success otherwise
        echogreen "All tests of unit $1 successful!"
}

# replaces special characters in oath2 tokens by their httpo substitute
function escapetoken
{
	echo $1 | sed s/\+/%2B/g
}

# verifies if a certain string is present in a response body. Print result in coherent colors and appends corresponding entry to CHECKSARRAY.
# $1 is the search string
# $2 is a response body
# $3 are additional search instructions, e.g. "-v" to invert the search
function assertexists
{
	SEARCH_PATTERN=$1
	CONTEXT="${@:2}"

## DEBUG
#	echo "Searching for $SEARCH_PATTERN in ${CONTEXT[@]}"

	#continue on errors
	set +e

	echo $TESTPREAMBLE
	MATCHSTRING=$(echo "$CONTEXT[@]" | grep "$SEARCH_PATTERN")

	if [ -z "$INVERT" ]; then
	  # if we expect the string to be there, post an error if the string is no match
	  echo "Assert: $1 substring of response body."
  	  if [ -z "$MATCHSTRING" ]; then
		#error
		echored "[FAILED]"
		CHECKSARRAY+=('[FAILED]')
		return -1
	  fi
	else
	  # if we don't expect the string to be there, post an error if there was a match
	  echo "Assert: $1 not substring of response body."
  	  if [ ! -z "$MATCHSTRING" ]; then
		#error
		echored "[FAILED]"
		CHECKSARRAY+=('[FAILED]')
		return -1
          fi
        fi

	echogreen "[PASSED]"

	# disable continue on errors
	set -e
}

function assertnotexists
{
	INVERT=true
	assertexists "$@"
	unset INVERT
}


