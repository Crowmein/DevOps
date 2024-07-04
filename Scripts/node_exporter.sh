#!/bin/bash

wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
sudo tar -xvf node_exporter*amd64.tar.gz
cp node_exporter-*amd64/node_exporter /usr/local/bin
sudo rm -r node_exporter-1.8.1.linux-amd64.tar.gz && sudo rm -r node_exporter-1.8.1.linux-amd64

cat << 'EOF' | sudo tee /etc/systemd/system/node_exporter.service > /dev/null
[Unit]
Description=Service of Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start node_exporter

sudo cat << 'EOF' > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
scrape_configs:
    - job_name: 'prometheus'
      scrape_interval: 5s
      static_configs:
        - targets: ['localhost:9090']
    - job_name: 'prometheus_node'
      scrape_interval: 5s
      static_configs:
        - targets: ['localhost:9100']
EOF

systemctl restart prometheus