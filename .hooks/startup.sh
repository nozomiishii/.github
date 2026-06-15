#!/usr/bin/env bash
set -euo pipefail
# Codex は CODEX_PROJECT_DIR 相当を持たず session cwd で hook を回すため、worktree の
# サブディレクトリで起動された場合 pnpm install が package.json を見失う。両ツールから
# 同じ起点で動かすために repo root へ移動する。
cd "$(git rev-parse --show-toplevel)"

# Claude Code の worktree 作成(EnterWorktree)が共有 .git/config に core.hooksPath を書き込む。
# 値はデフォルト(.git/hooks)と同じで冗長だが、lefthook が「独自パス」とみなし commit ごとの
# self-sync で "Skipping hook sync" 警告を毎回出す。後段の merge --ff-only が走らせる
# post-merge hook より前に unset して打ち消す（--unset-all は未設定だと exit 5 なので保険を付ける）。
# 上流バグ: https://github.com/anthropics/claude-code/issues/27474
git config --unset-all --local core.hooksPath 2>/dev/null || true

git fetch origin --quiet

# HEAD が origin/main の祖先のときだけ進める（diverged branch や未コミット作業を壊さない）。
# --ff-only で linear history を維持。lock 更新があれば post-merge hook が pnpm install を実行する。
if git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
  git merge --ff-only origin/main --quiet
fi

if [ ! -d node_modules ]; then
  pnpm install
fi
