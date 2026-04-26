#!/usr/bin/env bash

# main을 제외한 모든 워크트리, 로컬 브랜치, stale 원격 참조 삭제

REPO_ROOT="$(git rev-parse --show-toplevel)"
CALLER_PWD="$(pwd)"

# ── 안전 체크: 터미널 CWD가 삭제될 워크트리 안에 있는지 확인 ──────────────────
UNSAFE_WT=""
while IFS= read -r line; do
  if [[ "$line" == worktree* ]]; then
    WT_PATH="${line#worktree }"
    # main 워크트리(REPO_ROOT)는 건너뜀
    if [[ "$WT_PATH" == "$REPO_ROOT" ]]; then
      WT_PATH=""
      continue
    fi
  fi
  if [[ "$line" == "branch refs/heads/main" ]]; then
    WT_PATH=""  # main 브랜치 워크트리는 건너뜀
  fi
  if [[ -z "$line" && -n "$WT_PATH" ]]; then
    # 현재 터미널 위치가 이 워크트리 안에 있으면 위험
    if [[ "$CALLER_PWD" == "$WT_PATH"* ]]; then
      UNSAFE_WT="$WT_PATH"
    fi
    WT_PATH=""
  fi
done < <(git worktree list --porcelain; echo "")

if [[ -n "$UNSAFE_WT" ]]; then
  echo "❌ 오류: 현재 터미널 위치가 삭제 대상 워크트리 안에 있습니다."
  echo "   위치: $CALLER_PWD"
  echo "   워크트리: $UNSAFE_WT"
  echo ""
  echo "   아래 명령어로 메인 디렉토리로 이동 후 다시 실행하세요:"
  echo "   cd $REPO_ROOT && ./cleanup-branches.sh"
  exit 1
fi

cd "$REPO_ROOT"

# ── 워크트리 정리 ──────────────────────────────────────────────────────────────
echo "=== 워크트리 정리 ==="
REMOVED_WT=0
while IFS= read -r line; do
  if [[ "$line" == worktree* ]]; then
    WT_PATH="${line#worktree }"
    WT_BRANCH=""
  fi
  if [[ "$line" == "branch refs/heads/"* ]]; then
    WT_BRANCH="${line#branch refs/heads/}"
  fi
  if [[ -z "$line" && -n "$WT_PATH" && "$WT_PATH" != "$REPO_ROOT" && "$WT_BRANCH" != "main" ]]; then
    echo "  removing worktree: $WT_PATH"
    git worktree remove --force "$WT_PATH" && REMOVED_WT=$((REMOVED_WT + 1))
    WT_PATH=""
  fi
done < <(git worktree list --porcelain; echo "")
echo "  → ${REMOVED_WT}개 제거됨"

# ── 로컬 브랜치 정리 ──────────────────────────────────────────────────────────
echo "=== 로컬 브랜치 정리 ==="
REMOVED_BR=0
while IFS= read -r branch; do
  [[ -z "$branch" ]] && continue
  echo "  deleting branch: $branch"
  if git branch -D "$branch" 2>/dev/null; then
    REMOVED_BR=$((REMOVED_BR + 1))
  else
    echo "  ⚠️  건너뜀 (현재 체크아웃된 브랜치이거나 삭제 실패): $branch"
  fi
done < <(git branch --format='%(refname:short)' | grep -v '^main$')
echo "  → ${REMOVED_BR}개 제거됨"

# ── stale 원격 참조 정리 ──────────────────────────────────────────────────────
echo "=== stale 원격 참조 정리 ==="
git remote prune origin

echo ""
echo "=== 완료 ==="
git worktree list
echo "---"
git branch -a
