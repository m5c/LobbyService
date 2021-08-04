#! /bin/bash
if [ ! "$1" = "PRUNE" ] ;then
	echo "You have to explicitly tell me to prune ALL YOUR SYSTEM DOCKER config."
        exit -1
fi

cd ..
docker kill $(docker ps -q)
docker rm -f $(docker ps -a -q)
docker rmi -f $(docker images -q)
docker build -t "ls-db:Dockerfile" . -f Dockerfile-ls-db
docker run --name=ls-db -p 3453:3306 -d ls-db:Dockerfile
cd -
echo "DB reset complete. Waiting for DB to signal healthy state."

for i in {1..100}; do
    HEALTHY=$(docker ps -a | grep healthy)
    if [[ ! -z "$HEALTHY" ]]; then
      echo OK
      docker ps -a
      exit 1
    else
      echo -n .
    fi
    sleep 1
done
exit -1
