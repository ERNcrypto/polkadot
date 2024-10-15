#!/bin/bash

# Settings
REPO="paritytech/polkadot-sdk"
API_URL="https://api.github.com/repos/$REPO/tags"
INSTALL_DIR="$HOME/polkadot-sdk"  
LAST_TAG_FILE="$HOME/last_tag.txt"  
CURRENT_USER=$(whoami)  

# Get the last installed tag
if [ -f "$LAST_TAG_FILE" ]; then
  LAST_TAG=$(cat "$LAST_TAG_FILE")
else
  LAST_TAG=""
fi

# Fetch the latest tag from GitHub
LATEST_TAG=$(curl -s "$API_URL" | jq -r '.[0].name')

# Check if the latest tag is different from the installed one
if [ "$LATEST_TAG" != "$LAST_TAG" ]; then
  echo "New version found: $LATEST_TAG. Installing..."

  # Navigate to the SDK directory
  cd "$INSTALL_DIR" || exit

  # Stop the Polkadot service before updating
  sudo systemctl stop polkadot.service

  # Update the repository and switch to the new version
  sudo git fetch --all
  sudo git checkout "$LATEST_TAG"

  # Build
  cargo build --release

  # Reload systemd daemon and restart the service
  sudo systemctl daemon-reload
  sudo systemctl restart polkadot.service

  # Check the logs to ensure the service is running
  sudo journalctl -u polkadot.service -f

  # Update the last installed tag file
  echo "$LATEST_TAG" > "$LAST_TAG_FILE"

  echo "Version $LATEST_TAG successfully installed."

else
  echo "No new version found. Current version: $LAST_TAG"
fi
