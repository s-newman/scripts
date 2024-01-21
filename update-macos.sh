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

# Maintenance
brew autoremove
brew cleanup
brew bundle dump --global --force
cargo install-update --list > "${HOME}/.config/packages/cargo.txt"
pipx list > "${HOME}/.config/packages/pipx.txt"