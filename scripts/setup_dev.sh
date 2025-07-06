#!/usr/bin/env bash
# Setup development dependencies for minecraft_for_all
# This installs tools used by the repository's lint and test
# workflows: Terraform, Node.js tooling and Python packages.
set -euo pipefail

# Update apt and install base packages
sudo apt-get update
sudo apt-get install -y curl gnupg unzip python3-pip nodejs npm

# Install Terraform from HashiCorp apt repository if not already installed
if ! command -v terraform >/dev/null 2>&1; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update
  sudo apt-get install -y terraform
fi

# Install global Node tools used for formatting and linting
sudo npm install -g prettier eslint

# Install Python packages used in tests and validation
python3 -m pip install --upgrade pip
python3 -m pip install html5validator playwright

# Install Playwright browsers
playwright install --with-deps

cat <<MSG
Development tools installed:
  - terraform $(terraform version | head -n1)
  - node $(node --version)
  - npm $(npm --version)
  - prettier $(prettier --version)
  - eslint $(eslint --version)
  - html5validator $(python3 -m pip show html5validator | grep Version | awk '{print $2}')
MSG
