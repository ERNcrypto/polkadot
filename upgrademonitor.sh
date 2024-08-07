#!/bin/bash

# Убедитесь, что yq установлен
if ! command -v yq &> /dev/null
then
    echo "yq could not be found, installing..."
    sudo apt-get update
    sudo apt-get install -y yq
fi

# Извлечение токена из файла alertmanager.yml
TOKEN=$(sudo yq e '.receivers[] | select(.name == "telepush") | .webhook_configs[0].url' /etc/alertmanager/alertmanager.yml | awk -F '/' '{print $NF}')
echo "Token extracted: $TOKEN"
echo 'export TOKEN='$TOKEN

read -p "Enter NODE name:" NODE
echo 'export NODE='$NODE
read -p "Enter IP server:" IP
echo 'export IP='$IP

# Установка node_exporter
sudo wget $(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "tag_name" | awk '{print "https://github.com/prometheus/node_exporter/releases/download/" substr($2, 2, length($2)-3) "/node_exporter-" substr($2, 3, length($2)-4) ".linux-amd64.tar.gz"}')
sudo tar xvf node_exporter-*.tar.gz
sudo cp ./node_exporter-*.linux-amd64/node_exporter /usr/local/bin/
sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter
sudo rm -rf ./node_exporter*

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
  Description=Node Exporter
  Wants=network-online.target
  After=network-online.target
[Service] 
  User=node_exporter
  Group=node_exporter
  Type=simple
  ExecStart=/usr/local/bin/node_exporter
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start node_exporter.service
sudo systemctl enable node_exporter.service

# Установка prometheus
sudo wget $(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "tag_name" | awk '{print "https://github.com/prometheus/prometheus/releases/download/" substr($2, 2, length($2)-3) "/prometheus-" substr($2, 3, length($2)-4) ".linux-amd64.tar.gz"}')
sudo tar xvf prometheus-*.tar.gz
sudo cp ./prometheus-*.linux-amd64/prometheus /usr/local/bin/
sudo cp ./prometheus-*.linux-amd64/promtool /usr/local/bin/
sudo cp -r ./prometheus-*.linux-amd64/consoles /etc/prometheus
sudo cp -r ./prometheus-*.linux-amd64/console_libraries /etc/prometheus
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus
sudo mkdir /var/lib/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus
sudo rm -rf ./prometheus*

sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s
rule_files:
  - 'rules.yml'
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - $IP:9093
scrape_configs:
  - job_name: "node_exporter"
    scrape_interval: 5s
    static_configs:
      - targets: ["$IP:9100"]
  - job_name: "kusama_node"
    scrape_interval: 5s
    static_configs:
      - targets: ["$IP:9615"]
EOF

sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
  Description=Prometheus Monitoring
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
  --web.console.libraries=/etc/prometheus/console_libraries \
  --storage.tsdb.retention.time 30d \
  --web.enable-admin-api
  ExecReload=/bin/kill -HUP $MAINPID
[Install]
  WantedBy=multi-user.target
EOF

cd /etc/prometheus
sudo tee rules.yml > /dev/null <<EOF
groups:
  - name: alert_rules
    rules:
      - alert: KusamaNodeSyncLag
        expr: (max(substrate_block_height{status="best"}) by (instance) - max(substrate_block_height{status="finalized"}) by (instance)) > 20
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Node $NODE lagging behind"
          description: "Node $NODE is lagging more than 20 blocks behind the network."
      - alert: NodeDown
        expr: up{job="kusama_node"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Node $NODE down"
          description: "Node $NODE has been down for more than 1 minute."
      - alert: HighDiskUsage
        expr: (node_filesystem_avail_bytes{job="node_exporter", fstype!="tmpfs", fstype!="sysfs", fstype!="proc"} / node_filesystem_size_bytes{job="node_exporter", fstype!="tmpfs", fstype!="sysfs", fstype!="proc"}) * 100 < 5
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High disk usage on $NODE"
          description: "Disk usage is above 95% on $NODE."
      - alert: KusamaNodeNotSyncing
        expr: substrate_sub_libp2p_sync_is_major_syncing{job="kusama_node"} == 1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Node $NODE not syncing"
          description: "Node $NODE is not syncing blocks for more than 5 minutes."
      - alert: KusamaNodeHighCPUUsage
        expr: rate(process_cpu_seconds_total{job="kusama_node"}[5m]) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on $NODE"
          description: "CPU usage is above 80% on $NODE for more than 5 minutes."
EOF

sudo chown prometheus:prometheus rules.yml

sudo systemctl daemon-reload
sudo systemctl start prometheus.service
sudo systemctl enable prometheus.service

# Установка alertmanager
cd ~
sudo wget https://github.com/prometheus/alertmanager/releases/download/v0.24.0/alertmanager-0.24.0.linux-amd64.tar.gz
sudo tar xvf alertmanager-0.24.0.linux-amd64.tar.gz
sudo rm alertmanager-0.24.0.linux-amd64.tar.gz
sudo mkdir /etc/alertmanager /var/lib/prometheus/alertmanager
cd alertmanager-0.24.0.linux-amd64
sudo cp alertmanager amtool /usr/local/bin/
sudo cp alertmanager.yml /etc/alertmanager

sudo useradd --no-create-home --shell /bin/false alertmanager
sudo chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/prometheus/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/{alertmanager,amtool}

sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF
[Unit]
Description=AlertManager Server Service
Wants=network-online.target
After=network-online.target
[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/alertmanager --config.file /etc/alertmanager/alertmanager.yml --web.external-url=http://$IP:9093 --cluster.advertise-address='0.0.0.0:9093'
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/alertmanager/alertmanager.yml > /dev/null <<EOF
route:
  group_by: ['alertname', 'instance', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'telepush'
receivers:
  - name: 'telepush'
    webhook_configs:
      - url: 'https://telepush.dev/api/inlets/alertmanager/$TOKEN'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF

sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

sudo systemctl restart prometheus.service
sudo systemctl restart alertmanager.service