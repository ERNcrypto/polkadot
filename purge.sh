#!/bin/bash
sudo systemctl stop polkadot.service

cd polkadot-sdk

./target/release/polkadot purge-chain --chain=kusama --database=RocksDb -y

cd

sudo rm -r polkadot-sdk

git clone https://github.com/paritytech/polkadot-sdk.git 

cd polkadot-sdk
 
git checkout polkadot-v1.14.1

cargo build --release

sudo curl -o - -L https://snapshots.polkachu.com/snapshots/kusama/kusama_23934069.tar.lz4 | lz4 -c -d - | sudo tar -x -C /root/.local/share/polkadot/chains/ksmcc3/

sudo systemctl daemon-reload

sudo systemctl restart polkadot.service && sudo journalctl -u polkadot.service -f
