#!/bin/bash
current_user=$(whoami)
sudo systemctl stop polkadot.service

cd 

sudo rm -r polkadot-sdk

git clone https://github.com/paritytech/polkadot-sdk.git 

cd polkadot-sdk
 
git checkout polkadot-v1.16.0

cargo build --release

sudo chmod -R 777 /home/$current_user/.local/share/polkadot/chains/ksmcc3/db/full

sudo chmod -R 777 /home/$current_user/polkadot-sdk

sudo systemctl start polkadot.service

sleep 450

sudo systemctl stop polkadot.service

sudo chmod -R 777 /home/$current_user/.local/share/polkadot/chains/ksmcc3/db/full

sudo systemctl daemon-reload

sudo systemctl restart polkadot.service && sudo journalctl -u polkadot.service -f
