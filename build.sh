#!/usr/bin/env bash
# exit on error
set -o errexit

# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

cd apps/pulk_web
mix assets.setup
mix assets.deploy
cd ../..

# Build the release and overwrite the existing release directory
MIX_ENV=prod mix release --overwrite
