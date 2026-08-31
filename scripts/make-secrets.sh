#!/usr/bin/env bash
# ============================================================
# 灵犀八字 · 一键生成 GitHub Secrets（合成 .p12 + 转 base64）
# ============================================================
# 用法（在 D:\八字APP 目录下，用 Git Bash 运行）：
#   bash scripts/make-secrets.sh
#
# 前提：你已经把下面 3 个文件放进 BaziApp/certs/ 目录：
#   1. distribution.cer          （第1步：Apple 后台下载的证书）
#   2. *.mobileprovision         （第3步：下载的描述文件）
#   3. AuthKey_*.p8              （第4步：App Store Connect API Key）
#
# 脚本会：
#   1. 用 .cer + 本地私钥合成 distribution.p12（设密码）
#   2. 把 .p12 / .mobileprovision / .p8 转成 base64
#   3. 生成一份「secrets 填写表」到 certs/secrets.txt，直接复制粘贴
# ============================================================
set -euo pipefail

CERTS="BaziApp/certs"
P12_PASSWORD="${P12_PASSWORD:-Lingxi@2024}"   # .p12 密码（可改，改完记得同步填到 GitHub Secret P12_PASSWORD）

cd "$(dirname "$0")/.."   # 回到仓库根目录 D:\八字APP

# ---------- 1. 合成 .p12 ----------
CER=$(ls "$CERTS"/*.cer 2>/dev/null | head -1 || true)
KEY="$CERTS/bazi_distribution.key"
if [ -z "${CER:-}" ]; then
  echo "❌ 没找到 .cer 文件。请先把 Apple 后台下载的 distribution.cer 放进 $CERTS/ 再运行。"
  exit 1
fi
if [ ! -f "$KEY" ]; then
  echo "❌ 没找到私钥 $KEY 。"
  exit 1
fi
echo "✅ 找到证书：$(basename "$CER")"
echo "✅ 找到私钥：$(basename "$KEY")"

openssl pkcs12 -export \
  -in "$CER" \
  -inkey "$KEY" \
  -out "$CERTS/distribution.p12" \
  -name "Apple Distribution" \
  -passout "pass:$P12_PASSWORD" 2>/dev/null
echo "✅ 已合成 $CERTS/distribution.p12（密码：$P12_PASSWORD）"

# ---------- 2. 定位描述文件与 .p8 ----------
MPP=$(ls "$CERTS"/*.mobileprovision 2>/dev/null | head -1 || true)
P8=$(ls "$CERTS"/AuthKey_*.p8 2>/dev/null | head -1 || true)
if [ -z "${MPP:-}" ]; then echo "⚠️  没找到 .mobileprovision，跳过该项（记得补）。"; fi
if [ -z "${P8:-}" ]; then  echo "⚠️  没找到 AuthKey_*.p8，跳过该项（记得补）。"; fi

# ---------- 3. base64 编码并输出填写表 ----------
OUT="$CERTS/secrets.txt"
{
  echo "=================================================================="
  echo "  灵犀八字 · GitHub Secrets 填写表（复制下面 = 号后的值即可）"
  echo "  生成时间：$(date '+%Y-%m-%d %H:%M:%S')"
  echo "=================================================================="
  echo ""
  echo "[P12_BASE64]  （distribution.p12 的 base64）"
  echo "=================================================================="
  base64 -w0 "$CERTS/distribution.p12" 2>/dev/null || base64 "$CERTS/distribution.p12"
  echo ""
  echo ""
  if [ -n "${MPP:-}" ]; then
    echo "[MOBILEPROVISION_BASE64]  （$(basename "$MPP") 的 base64）"
    echo "=================================================================="
    base64 -w0 "$MPP" 2>/dev/null || base64 "$MPP"
    echo ""
    echo ""
  fi
  if [ -n "${P8:-}" ]; then
    echo "[APPSTORE_API_KEY_BASE64]  （$(basename "$P8") 的 base64）"
    echo "=================================================================="
    base64 -w0 "$P8" 2>/dev/null || base64 "$P8"
    echo ""
    echo ""
  fi
  echo "------------------- 需要你手动填的 5 个纯文本值 -------------------"
  echo "P12_PASSWORD = $P12_PASSWORD"
  echo "TEAM_ID = （developer.apple.com → Membership → Team ID）"
  echo "PROFILE_NAME = （描述文件的名字，如 LingxiAppStore）"
  echo "APPSTORE_KEY_ID = （App Store Connect → 生成的 Key ID）"
  echo "APPSTORE_ISSUER_ID = （App Store Connect → Issuer ID）"
  echo "=================================================================="
} > "$OUT"

echo ""
echo "🎉 全部完成！填写表已生成：$OUT"
echo "   打开它，把每个 [xxx] 后面的内容复制到 GitHub 对应 Secret 即可。"
