#!/bin/bash
yum -y install docker
yum -y install git
curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash - 
yum install -y nodejs 
npm install -g artillery@latest
wget  -O Dynatrace-OneAgent-Linux-1.243.166.sh "https://zhy38306.live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest?arch=x86&flavor=default" --header="Authorization: Api-Token dt0c01.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
/bin/sh Dynatrace-OneAgent-Linux-1.243.166.sh --set-infra-only=false --set-app-log-content-access=true
service docker start
docker run -p 8888:8080/tcp --memory=500m igoroschsimoes/simplegreeting:v0.3-with-oa &

git clone https://github.com/aborigene/simple-java-rest.git
cd simple-java-rest
chmod 755 run_test.sh

./run_test.sh > /root/artillery.log &
sleep 120
./run_test.sh > /root/artillery.log &
sleep 120
./run_test.sh > /root/artillery.log &
sleep 120
./run_test.sh > /root/artillery.log &