#!/bin/bash
PKGS=$(find ~/arch/pkg -mindepth 1 -maxdepth 1 -type d)
CDIR=$(pwd)
echo "Checking for orphaned packages..."
aurphan -a
echo "Checking for AUR updates..."
for PKG in $PKGS
do
  PKG_NAME=$(echo $PKG | sed 's/\// /g' | awk '{print $NF}')
  printf "\001\e[34m\002↻\001\e[\0m $PKG_NAME"
  cd ${PKG}
  git fetch > /dev/null 2>&1
  BEHIND=$(git rev-list --count ..@{u} 2>/dev/null)
  if [ "${BEHIND}" -gt "0" ]
  then
    printf "\r\001\e[33m\002!\001\e[\0m ${PKG_NAME}\n"
  else
    printf "\r\001\e[32m\002✓\001\e[\0m ${PKG_NAME}\n"
  fi
  cd ${CDIR}
done
