#!/usr/bin/env bash
# deploy.sh — Critical Reviews deployment script
# Run on the Hetzner box as a user with sudo access.
# Usage: bash deploy.sh [--branch main]
#
# See DEPLOY.md for full deployment specification.

set -euo pipefail

REPO_DIR="/opt/critical-reviews"
SERVE_DIR="/var/www/critical-reviews"
BRANCH="${1:-main}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Critical Reviews — Deploy Script"
echo "  Branch: ${BRANCH}"
echo "  $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Pull latest ────────────────────────────────────────────────────────────
echo ""
echo "▶ Pulling latest from ${BRANCH}..."
cd "${REPO_DIR}"
git fetch origin
git checkout "${BRANCH}"
git pull origin "${BRANCH}"
echo "  ✓ Git pull complete. Commit: $(git rev-parse --short HEAD)"

# ── 2. Install dependencies ───────────────────────────────────────────────────
echo ""
echo "▶ Installing dependencies..."
npm ci --prefer-offline 2>&1 | tail -3
echo "  ✓ Dependencies installed."

# ── 3. Build ──────────────────────────────────────────────────────────────────
echo ""
echo "▶ Building site..."
npm run build
echo "  ✓ Build complete. Output: dist/"

# ── 4. Sync to serve directory ────────────────────────────────────────────────
echo ""
echo "▶ Syncing dist/ → ${SERVE_DIR}..."
sudo rsync -av --delete "${REPO_DIR}/dist/" "${SERVE_DIR}/"
sudo chown -R caddy:caddy "${SERVE_DIR}/" 2>/dev/null || sudo chown -R www-data:www-data "${SERVE_DIR}/"
echo "  ✓ Sync complete."

# ── 5. Reload Caddy ───────────────────────────────────────────────────────────
echo ""
echo "▶ Validating and reloading Caddy..."
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
echo "  ✓ Caddy reloaded."

# ── 6. Smoke test ─────────────────────────────────────────────────────────────
echo ""
echo "▶ Running smoke test..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "${HTTP_STATUS}" = "200" ] || [ "${HTTP_STATUS}" = "301" ] || [ "${HTTP_STATUS}" = "302" ]; then
  echo "  ✓ Smoke test passed (HTTP ${HTTP_STATUS})"
else
  echo "  ⚠ Smoke test returned HTTP ${HTTP_STATUS} — check Caddy logs"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Deploy complete!"
echo "  Commit: $(git rev-parse --short HEAD)"
echo "  Time:   $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
