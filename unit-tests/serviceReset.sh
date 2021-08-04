#! /bin/bash
if [ ! "$1" = "KILLJAVA" ] ;then
	echo "You have to explicitly tell me to kill ALL YOUR RUNNING JAVA processes."
        exit -1
fi

pkill -9 java
cd ..
mvn clean spring-boot:run -Pdev &
sleep 5
cd -
cd GameServerStub
mvn clean spring-boot:run &
sleep 5
