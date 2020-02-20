#!/bin/bash

source IPs.conf

HOME_DIR=$(pwd)

scp -i "$HOME_DIR"/default.pem ./run*.sh ./IPs.conf ./default.pem root@"$PUBLIC_IP_INFRA":/root/
echo -e 'INFRA: ssh -i '$HOME_DIR'/default.pem root@'$PUBLIC_IP_INFRA
scp -i "$HOME_DIR"/default.pem ./run*.sh ./IPs.conf ./default.pem root@"$PUBLIC_IP_COMPUTE00":/root/
echo -e 'COMPUTE00: ssh -i '$HOME_DIR'/default.pem root@'$PUBLIC_IP_COMPUTE00
scp -i "$HOME_DIR"/default.pem ./run*.sh ./IPs.conf ./default.pem root@"$PUBLIC_IP_COMPUTE01":/root/
echo -e 'COMPUTE01: ssh -i '$HOME_DIR'/default.pem root@'$PUBLIC_IP_COMPUTE01
