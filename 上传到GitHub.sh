#!/bin/bash
# 一键上传脚本：把当前目录的 HTML 同步到 GitHub Pages 线上（git 不可用时用 Contents API）
# 用法：双击运行，或终端执行 `bash 上传到GitHub.sh`
# 前置：已安装 gh 并登录（gh auth login），仓库已在 GitHub 建好

export PATH="$HOME/.local/bin:$PATH"

cd "$(dirname "$0")" || exit 1

REPO="Pomegranaate/guanghe-store"
SITE="https://pomegranaate.github.io/guanghe-store/"

# 登录检查
if ! gh auth status >/dev/null 2>&1; then
  echo "❌ 未登录 GitHub，请先运行： gh auth login"
  exit 1
fi

# 仅上传 .html 文件（忽略截图 png、脚本 rb 等）
FILES=($(ls *.html 2>/dev/null))
if [ -z "${FILES:-}" ]; then
  echo "⚠️  当前目录没有 HTML 文件。"
  exit 1
fi

echo "开始同步 ${#FILES[@]} 个 HTML 文件到仓库 $REPO ..."
echo "-----------------------------------------------------"

ok=0; fail=0
for f in "${FILES[@]}"; do
  # 取已存在文件的 blob sha（更新必需），不存在则为空
  sha=$(gh api "repos/$REPO/contents/$f" -q .sha 2>/dev/null || echo "")

  args=(-f "message=update $f" -f "content=$(base64 < "$f" | tr -d '\n')" -f "path=$f")
  if [ -n "$sha" ]; then
    args+=(-f "sha=$sha")
  fi

  if gh api -X PUT "repos/$REPO/contents/$f" "${args[@]}" -q .content.path >/tmp/pushlog 2>&1; then
    echo "  ✓  $f"
    ok=$((ok+1))
  else
    echo "  ✗  $f  ($(tail -1 /tmp/pushlog))"
    fail=$((fail+1))
  fi
done

echo "-----------------------------------------------------"
if [ "$fail" -eq 0 ]; then
  echo "✅ 同步完成：成功 $ok 个，失败 $fail 个。"
else
  echo "⚠️  同步完成但有失败：成功 $ok 个，失败 $fail 个。"
fi
echo "线上地址： $SITE"
echo "（GitHub Pages 更新后会重新构建，稍等 1-2 分钟生效）"