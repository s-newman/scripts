#!/bin/bash

scripts=$(find . -maxdepth 1 -type f -name "*.sh" | sed -e 's/^\.\///' -e '/^_/d' -e '/^install.sh$/d')
cwd=$(pwd)

mkdir -p "${HOME}/bin"

for script in ${scripts}; do
  target="${HOME}/bin/${script//.sh/}"
  if [ -f "${target}" ]; then
    echo "${script} already installed, skipping..."
  else
    echo "Installing ${script}"
    ln -fs "${cwd}/${script}" "${target}"
  fi
done