#!/bin/bash

sudo apt update
gpg --recv-keys --keyserver hkps://keys.mailvelope.com 9D4B2B6EB8F97156D19669A9FF0812D491B96798
gpg --export 9D4B2B6EB8F97156D19669A9FF0812D491B96798 > /usr/share/keyrings/parity.gpg
echo 'deb [signed-by=/usr/share/keyrings/parity.gpg] https://releases.parity.io/deb release main' > /etc/apt/sources.list.d/parity.list
sudo apt update
sudo apt install parity-keyring
sudo apt install polkadot


sudo tee /usr/lib/systemd/system/polkadot.service > /dev/null << EOF
[Unit]
Description=kusama
After=network.target
Documentation=https://github.com/paritytech/polkadot
OnFailure=unit-status-mail@%n.service
StartLimitIntervalSec=200
StartLimitBurst=2

[Service]
ExecStart=/usr/bin/polkadot --chain kusama --name test0001 --validator --state-pruning 1000 --port 30333 --rpc-port 9901 --ws-port 9801 --prometheus-port 9601 --prometheus-external --base-path /home/polkadot/ --database paritydb --sync warp --telemetry-url 'wss://telemetry.polkadot.io/submit/ 1' 
User=polkadot
Group=polkadot
Restart=always
RestartSec=30
CapabilityBoundingSet=
LockPersonality=true
NoNewPrivileges=true
PrivateDevices=true
PrivateMounts=true
PrivateTmp=true
PrivateUsers=true
ProtectClock=true
ProtectControlGroups=true
ProtectHostname=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectSystem=strict
RemoveIPC=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_NETLINK AF_UNIX
RestrictNamespaces=true
RestrictSUIDSGID=true
SystemCallArchitectures=native
SystemCallFilter=@system-service
SystemCallFilter=~@clock @module @mount @reboot @swap @privileged
UMask=0027

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start polkadot.service
sudo systemctl enable polkadot.service
sudo journalctl -u polkadot.service -f
