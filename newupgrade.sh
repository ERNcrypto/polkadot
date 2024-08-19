#!/bin/bash
cd

cd polkadot-sdk

sudo systemctl stop polkadot.service

sudo git fetch

git checkout polkadot-v1.15.1

cargo build --release

sudo systemctl restart polkadot.service
sudo journalctl -u polkadot.service -f
