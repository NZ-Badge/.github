#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <github-org> [workspace-dir]" >&2
  exit 1
fi

ORG_NAME="$1"
WORKSPACE_DIR="${2:-$(pwd)}"
BASE_URL="${GIT_BASE_URL:-git@github.com:${ORG_NAME}}"

clone_if_missing() {
  local repo_name="$1"
  local target_dir="$2"
  local repo_url="${BASE_URL}/${repo_name}.git"

  mkdir -p "$(dirname "${target_dir}")"

  if [[ -d "${target_dir}/.git" ]]; then
    echo "skip  ${target_dir} (already a git repository)"
    return 0
  fi

  if [[ -e "${target_dir}" ]]; then
    echo "error ${target_dir} exists but is not a git repository" >&2
    return 1
  fi

  echo "clone ${repo_url} -> ${target_dir}"
  git clone "${repo_url}" "${target_dir}"
}

cd "${WORKSPACE_DIR}"

clone_if_missing "nz-badge-webapp" "app"
clone_if_missing "nz-badge-hardware" "hardware"
clone_if_missing "nz-badge-reader-station" "firmware/reader-station"
clone_if_missing "nz-badge-writer-station" "firmware/writer-station"

echo
echo "Workspace ready in ${WORKSPACE_DIR}"
