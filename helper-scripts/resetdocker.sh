cd ..
docker rm -f $(docker ps -aq)
docker build -t "ls-db:Dockerfile" . -f Dockerfile-ls-db
docker run --name=ls-db -p 3453:3306 -d ls-db:Dockerfile
cd -
