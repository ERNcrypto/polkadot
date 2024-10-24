#!/bin/bash

cd

cd polkadot-sdk

sudo systemctl stop polkadot.service

sudo git fetch

git checkout polkadot-v1.16.1

cargo update -p time

cargo build --release

sudo systemctl restart polkadot.service
sudo journalctl -u polkadot.service -f
