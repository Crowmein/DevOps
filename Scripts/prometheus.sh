#!/bin/bash

sudo apt-get update
sudo wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
sudo tar -xvf prometheus*.tar.gz


sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

sudo mv ./prometheus-2.53.0.linux-amd64/prometheus /usr/local/bin
sudo mv ./prometheus-2.53.0.linux-amd64/promtool /usr/local/bin

sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

sudo mkdir /etc/prometheus && sudo mkdir /var/lib/prometheus
sudo mv ./prometheus-2.53.0.linux-amd64/consoles /etc/prometheus
sudo mv ./prometheus-2.53.0.linux-amd64/console_libraries /etc/prometheus
sudo mv ./prometheus-2.53.0.linux-amd64/prometheus.yml /etc/prometheus

sudo chown prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus

sudo cat << 'EOF' > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
EOF

promtool check config /etc/prometheus/prometheus.yml

sudo cat << 'EOF' > /etc/systemd/system/prometheus.service
[Unit]
Description=Background service of Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
	--config.file /etc/prometheus/prometheus.yml \
	--storage.tsdb.path /var/lib/prometheus/ \
	--web.console.templates=/etc/prometheus/consoles \
	--web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

sudo rm -r prometheus-2.53.0.linux-amd64
sudo rm -r prometheus-2.53.0.linux-amd64.tar.gz