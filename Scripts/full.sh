#!/bin/bash

sudo -i << ROOT

sudo apt-get update && sudo apt-get -y upgrade

# Docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker admins
systemctl start docker && sudo systemctl enable docker

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Jenkins
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

# Prometheus
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

# Grafana
wget https://mirrors.cloud.tencent.com/grafana/apt/pool/main/g/grafana-enterprise/grafana-enterprise_10.2.3_amd64.deb
sudo apt-get install -y adduser libfontconfig1 musl
sudo apt-get --fix-broken install
dpkg -i grafana-enterprise_10.2.3_amd64.deb
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo rm -r grafana-enterprise_10.2.3_amd64.deb

# Node exporter
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
sudo systemctl enable node_exporter

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

# Kubectl
curl -LO https://dl.k8s.io/release/`curl -LS https://dl.k8s.io/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Helm-chart
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -r get_helm.sh

# Yandex cloud CLI /root
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
rm -r ~/yandex-cloud

# Hostname
echo "ubuntu" > /etc/hostname
hostname `cat /etc/hostname`

# NFS
sudo apt-get install nfs-kernel-server
sudo apt-get install nfs-common
/var/lib/jenkins/workspace/django/DevOps/Projeckt/app/ *(rw,sync,no_subtree_check)
sudo exportfs -ra
sudo systemctl enable nfs-server
sudo systemctl start nfs-server
sudo ufw allow from any to any port 2049 proto tcp

ROOT

# Yandex cloud CLI /user
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
rm -r ~/yandex-cloud

echo "При первом входе ребутни вм"