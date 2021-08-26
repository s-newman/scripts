#!/bin/bash
#
# Check all git repos under a given path for changes.

repos=$(find "${1}" -type d -name ".git" | sed 's/\.git$//')
cwd=$(pwd)

print_list() {
  for line in ${1}; do
    echo "     - ${line}"
  done
}

for repo in ${repos}; do
  cd "${repo}" || exit

  # https://unix.stackexchange.com/a/155077
  output=$(git status --porcelain)
  if [ -n "${output}" ]; then
    echo "[*] ${repo} unclean"
  fi

  output=$(git cherry 2>/dev/null)
  if [ -n "${output}" ]; then
    echo "[*] ${repo} unpushed branches:"
    branches=$(echo "${output}" | cut -d' ' -f 2 | xargs -I {} git name-rev --name-only {} | sort -u)
    print_list "${branches}"
  fi

  output=$(git fetch --all --prune 2>&1)
  # Check for errors
  if echo "${output}" | grep --quiet "ERROR" >/dev/null; then
    echo "[*] ${repo} can't fetch"
  fi

  branches=$(echo "${output}" | grep '\[deleted\]' | awk '{ print $NF }')
  if [ -n "${branches}" ]; then
    echo "[*] ${repo} pruned remote tracking branches:"
    print_list "${branches}"
  fi

  # https://www.erikschierboom.com/2020/02/17/cleaning-up-local-git-branches-deleted-on-a-remote/
  output=$(git for-each-ref --format '%(refname:short) %(upstream:track)' 2>/dev/null | awk '$2 == "[gone]" {print $1}')
  if [ -n "${output}" ]; then
    echo "[*] ${repo} local branches to delete:"
    print_list "${output}"
  fi

  output=$(git branch -v | sed 's/^* //' | awk '$3 == "[behind" {print $1}')
  if [ -n "${output}" ]; then
    echo "[*] ${repo} local branches behind upstream:"
    print_list "${output}"
  fi

  cd "${cwd}" || exit
done