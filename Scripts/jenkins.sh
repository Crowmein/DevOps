#!/bin/bash

sudo apt-get update
timedatectl set-timezone Europe/Moscow
sudo apt-get install -y chrony
systemctl enable chrony
iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
sudo apt-get install -y default-jdk
update-alternatives --config java

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
sudo apt-get install -y jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword