#!/usr/bin/env bash
set -euo pipefail

# main을 제외한 모든 워크트리, 로컬 브랜치, stale 원격 참조 삭제

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "=== 워크트리 정리 ==="
git worktree list --porcelain \
  | awk '/^worktree / { path=$2 } /^branch refs\/heads\// { branch=substr($2,12) } /^$/ { if (path != ENVIRON["REPO_ROOT"] && branch != "main") print path }' \
  REPO_ROOT="$REPO_ROOT" \
  | while read -r wt; do
      echo "  removing worktree: $wt"
      git worktree remove --force "$wt"
    done

echo "=== 로컬 브랜치 정리 ==="
git branch --format='%(refname:short)' \
  | grep -v '^main$' \
  | while read -r branch; do
      echo "  deleting branch: $branch"
      git branch -D "$branch"
    done

echo "=== stale 원격 참조 정리 ==="
git remote prune origin

echo ""
echo "=== 완료 ==="
git worktree list
echo "---"
git branch -a
