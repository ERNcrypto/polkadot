#!/bin/bash
sudo systemctl stop polkadot.service

cd polkadot-sdk

./target/release/polkadot purge-chain --chain=polkadot --database=RocksDb -y

cd

sudo rm -r polkadot-sdk

git clone https://github.com/paritytech/polkadot-sdk.git 

cd polkadot-sdk
 
git checkout polkadot-v1.16.0

cargo update -p time

cargo build --release

sudo curl -o - -L https://snapshots.radiumblock.com/polkadot_6240179_2024-10-15.tar.lz4 | lz4 -c -d - | sudo tar -x -C /root/.local/share/polkadot/chains/polkadot/

sudo systemctl daemon-reload

sudo systemctl restart polkadot.service && sudo journalctl -u polkadot.service -f
