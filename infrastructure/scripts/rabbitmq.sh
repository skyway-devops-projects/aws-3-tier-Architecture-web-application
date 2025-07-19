#!/bin/bash
sudo apt update -y
sudo apt install rabbitmq-server -y 
sudo apt-get install firewalld -y
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo systemctl status firewalld
sudo systemctl enable --now rabbitmq-server
sudo firewall-cmd --add-port=5672/tcp
sudo firewall-cmd --runtime-to-permanent
sudo systemctl start rabbitmq-server
sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
sudo rabbitmqctl add_user test test
sudo rabbitmqctl set_user_tags test administrator
sudo systemctl restart rabbitmq-server
