#!/bin/bash
sudo curl -o - -L https://snapshots.polkachu.com/snapshots/kusama/kusama_23934069.tar.lz4 | lz4 -c -d - | sudo tar -x -C /home/admuser/.local/share/polkadot/chains/ksmcc3/

sudo chmod -R 777 /home/admuser/.local/share/polkadot/chains/ksmcc3/db/full

sudo systemctl restart polkadot.service && sudo journalctl -u polkadot.service -f
