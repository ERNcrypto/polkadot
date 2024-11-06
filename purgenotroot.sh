#!/bin/bash

read -sp "Enter password for sudo: " sudo_password
echo

echo $sudo_password | sudo -S systemctl stop polkadot.service

current_user=$(whoami)

cd
echo $sudo_password | sudo -S rm -r polkadot-sdk
git clone https://github.com/paritytech/polkadot-sdk.git

cd polkadot-sdk
git checkout polkadot-v1.16.1
cargo build --release

echo $sudo_password | sudo -S chmod -R 777 /home/$current_user/.local/share/polkadot/chains/ksmcc3/db/full
echo $sudo_password | sudo -S chmod -R 777 /home/$current_user/polkadot-sdk

echo $sudo_password | sudo -S systemctl restart polkadot.service
echo $sudo_password | sudo -S journalctl -u polkadot.service -f
