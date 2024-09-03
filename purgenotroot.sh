#!/bin/bash
current_user=$(whoami)
sudo systemctl stop polkadot.service

cd polkadot-sdk

./target/release/polkadot purge-chain --chain=kusama --database=RocksDb -y

cd

sudo rm -r polkadot-sdk

git clone https://github.com/paritytech/polkadot-sdk.git 

cd polkadot-sdk
 
git checkout polkadot-v1.15.2

cargo build --release

sudo chmod -R 777 /home/$current_user/.local/share/polkadot/chains/ksmcc3/db/full

sudo chmod -R 777 /home/$current_user/polkadot-sdk

sudo systemctl start polkadot.service

sleep 450

sudo systemctl stop polkadot.service

./target/release/polkadot purge-chain --chain=kusama --database=RocksDb -y


sudo curl -o - -L https://kusama.services-ernventures.com/kusama/snap_kusama.tar.lz4 | lz4 -c -d - | sudo tar -x -C /home/$current_user/.local/share/polkadot/chains/ksmcc3/

sudo chmod -R 777 /home/$current_user/.local/share/polkadot/chains/ksmcc3/db/full

sudo systemctl daemon-reload

sudo systemctl restart polkadot.service && sudo journalctl -u polkadot.service -f
