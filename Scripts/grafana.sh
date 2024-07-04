#!/bin/bash

wget https://mirrors.cloud.tencent.com/grafana/apt/pool/main/g/grafana-enterprise/grafana-enterprise_10.2.3_amd64.deb
sudo apt-get install -y adduser libfontconfig1 musl
sudo apt-get --fix-broken install
dpkg -i grafana-enterprise_10.2.3_amd64.deb
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo rm -r grafana-enterprise_10.2.3_amd64.deb