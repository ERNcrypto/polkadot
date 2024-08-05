#!/bin/bash

# Prompt the user for the node name
read -p "Enter NODE name: " name
echo "export NODE=$name"

# Get the current username
current_user=$(whoami)

# Create the service file using the node name variable and current username
sudo tee /etc/systemd/system/polkadot.service > /dev/null <<EOF
[Unit]
Description=Polkadot Validator Service
After=network.target

[Service]
Type=simple
User=$current_user
ExecStart=$HOME/polkadot-sdk/target/release/polkadot --validator --name "$name" --chain=polkadot --database RocksDb --telemetry-url 'wss://telemetry-backend.w3f.community/submit 1' --state-pruning 1000 --prometheus-external --prometheus-port=9615 --insecure-validator-i-know-what-i-do
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment=START

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon and start the service
sudo systemctl daemon-reload
sudo systemctl enable polkadot.service
sudo systemctl restart polkadot.service

# View the service logs
sudo journalctl -u polkadot.service -f
