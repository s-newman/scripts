#!/bin/bash

scripts=$(find . -maxdepth 1 -type f -name "*.sh" | grep -v "\./_" | grep -v "install.sh")
cwd=$(pwd)

for script in ${scripts}; do
  if [ -f "${HOME}/bin/${script}" ]; then
    echo "${script} already exists, skipping..."
  else
    ln -fs "${cwd}/${script}" "${HOME}/bin/${script}"
  fi
done