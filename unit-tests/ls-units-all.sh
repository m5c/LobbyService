#! /bin/bash
cd GameServerStub
mvn clean spring-boot:run &
cd ..
sleep 5

echo "Hit enter when ready for the unit-tests."
read ready

# if set, the unit test will pause after expected dummy gameserver logs, to allow for the tester to verify the log data.

export INTERLEAVED=true

./ls-units-1.sh
./ls-units-2.sh
./ls-units-3.sh
./ls-units-4.sh
./ls-units-5.sh
./ls-units-6.sh

unset INTERLEAVED

# kill the server again
kill $(ps -a | grep Stub | head -n 1 | awk '{print $1;}') &


