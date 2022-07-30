#Default compose args
COMPOSE_ARGS=" -f jenkins.yml -p jenkins "

#Make sure old containers are gone
sudo docker compose $COMPOSE_ARGS stop
sudo docker compose $COMPOSE_ARGS rm --force -v

#build the system
sudo docker compose $COMPOSE_ARGS build --no-cache
sudo docker compose $COMPOSE_ARGS up -d

#Run unit tests
sudo docker compose $COMPOSE_ARGS run --no-deps --rm -e ENV=UNIT identidock
ERR=$?

#Run system test if unit tests passed
if [ $ERR -eq 0 ]; then
  # Connect jenkins-identidock-1 container to the same network as jenkins container.
  sudo docker network connect bridge jenkins-identidock-1

  IP=$(sudo docker inspect -f {{.NetworkSettings.Networks.bridge.IPAddress}} jenkins-identidock-1)
  CODE=$(curl -sL -w "%{http_code}" $IP:9090/monster/bla -o /dev/null)
  if [ $CODE -eq 200 ]; then
    echo "Test passed -- Tagging."
    HASH=$(git rev-parse --short HEAD)
    sudo docker tag -f jenkins_identidock vogolubenets/identidock:$HASH
    sudo docker tag -f jenkins_identidock vogolubenets/identidock:newest
    echo "Pushing..."
    sudo docker login -e golubenets2010@yandex.ru -u vogolubenets -p "A</4Pxy^;N[fGqh@F(oV"
    sudo docker push vogolubenets/identidock:$HASH
    sudo docker push vogolubenets/identidock:newest
  else
    echo "Site returned" $CODE
    ERR=1
  fi

  sudo docker network disconnect bridge jenkins-identidock-1
fi

#Pull down the system
sudo docker compose $COMPOSE_ARGS stop
sudo docker compose $COMPOSE_ARGS rm --force -v

return $ERR