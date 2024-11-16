#!/bin/bash

# Step 1: Prerequisites
echo "Setting up prerequisites..."

# Replace with your own values
CHAIN_NAME="inco"
CHAIN_ID="21097"
RPC_URL="https://validator.rivest.inco.org"
PRIVATE_KEY="%PRIVATE_KEY%"

# Install Hyperlane CLI if not already installed
if ! command -v hyperlane &> /dev/null
then
    echo "Hyperlane CLI not found, installing..."
    npm install -g @hyperlane-xyz/cli
else
    echo "Hyperlane CLI is already installed"
fi

# Step 2: Initialize Registry
echo "Initializing registry for the custom chain..."
hyperlane registry init

echo "Follow the prompts to configure your chain metadata."

# Confirm metadata file creation
METADATA_FILE="$HOME/.hyperlane/chains/$CHAIN_NAME/metadata.yaml"
if [ -f "$METADATA_FILE" ]; then
    echo "Metadata created successfully at $METADATA_FILE"
else
    echo "Failed to create metadata file."
    exit 1
fi

# Step 3: Configure and Deploy Core Contracts
echo "Setting up core contracts..."

# Export private key for deployment
export HYP_KEY="$PRIVATE_KEY"

# Initialize core configuration
echo "Initializing core configuration..."
hyperlane core init

# Deploy core contracts
echo "Deploying core contracts..."
hyperlane core deploy

echo "Select your custom chain from the list during the prompt."

ADDRESSES_FILE="$HOME/.hyperlane/chains/$CHAIN_NAME/addresses.yaml"
if [ -f "$ADDRESSES_FILE" ]; then
    echo "Core contracts deployed successfully. Addresses saved in $ADDRESSES_FILE"
else
    echo "Failed to deploy core contracts."
    exit 1
fi

# Step 4: Send Test Message
echo "Sending test message..."
hyperlane send message --relay

echo "Optionally, run a relayer in the background:"
echo "hyperlane relayer --chains $CHAIN_NAME,sepolia"

# Step 5: Set Up Warp Route
echo "Setting up warp route for token bridging..."
echo "Refer to the Deploy a Warp Route docs for detailed steps."

# Step 6: Submit to Registry
echo "Submitting to registry..."

# Add logo and metadata
REGISTRY_PATH="$HOME/.hyperlane"
LOGO_PATH="$REGISTRY_PATH/chains/$CHAIN_NAME/logo.svg"
if [ ! -f "$LOGO_PATH" ]; then
    echo "Please add a logo.svg to $LOGO_PATH"
    exit 1
fi

echo "Linting YAML files..."
yamllint "$REGISTRY_PATH"

echo "Committing changes..."
cd "$REGISTRY_PATH" || exit
git init
git add .
git commit -m "Add $CHAIN_NAME to Hyperlane registry"

echo "Syncing with canonical registry..."
git remote add canonical git@github.com:hyperlane-xyz/hyperlane-registry.git
git pull canonical main --rebase

echo "Pushing changes to fork..."
git remote add origin "your-fork-url"
git push origin main

echo "Submitting PR. Include a changeset in your PR description."

echo "🎉 Hyperlane successfully deployed and submitted to the registry."
