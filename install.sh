#!/bin/bash

scripts=$(find . -maxdepth 1 -type f -name "*.sh" | sed -e 's/^\.\///' -e '/^_/d' -e '/^install.sh$/d')
cwd=$(pwd)

mkdir -p "${HOME}/bin"

for script in ${scripts}; do
  if [ -f "${HOME}/bin/${script}" ]; then
    echo "${script} already exists, skipping..."
  else
    echo "Installing ${script}"
    ln -fs "${cwd}/${script}" "${HOME}/bin/${script}"
  fi
done