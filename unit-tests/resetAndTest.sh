#! /bin/bash
if [ ! "$1" = "RESETANDTEST" ] ;then
	echo "You have to explicitly tell me that you read the docs."
        exit -1
fi

./dockerResetDb.sh PRUNE
./serviceReset.sh KILLJAVA
sleep 10

./ls-units-1.sh
./ls-units-2.sh
./ls-units-3.sh
./ls-units-4.sh
./ls-units-5.sh
./ls-units-6.sh

pkill -9 java
