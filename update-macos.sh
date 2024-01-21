#!/bin/bash
set -eoux pipefail

# General packages
brew upgrade

# Python tools
pipx upgrade-all

# Rust tools
rustup update
cargo install-update --all

# LaTeX packages
sudo tlmgr update --self
sudo tlmgr update --all