# DEPLOY.md — Critical Reviews Deployment Specification

> **Audience:** This document is intended for the Claude Code agent with SSH access to the Hetzner box.  
> **Do not execute this yourself** — hand it to Claude with the instruction: *"Execute the deployment steps in DEPLOY.md for the critical-reviews repo."*

---

## Infrastructure Overview

| Property | Value |
|---|---|
| Target host | `ubuntu-8gb-nbg1-2-bastobot.tailb34a06.ts.net` (Tailscale) |
| Public IP | `46.225.164.139` |
| Web server | Caddy (already running) |
| Serve path | `/var/www/critical-reviews/` |
| GitHub repo | `https://github.com/michaelbnfree/critical-reviews` |
| Site URL (v1) | See "Domain Options" below |

---

## 1. Prerequisites (one-time setup)

### 1a. Create the serve directory

```bash
sudo mkdir -p /var/www/critical-reviews
sudo chown -R www-data:www-data /var/www/critical-reviews
# Or if Caddy runs as caddy user:
sudo chown -R caddy:caddy /var/www/critical-reviews
sudo chmod -R 755 /var/www/critical-reviews
```

### 1b. Install Node.js (if not present)

```bash
node --version 2>/dev/null || (
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
)
```

### 1c. Clone the repository

```bash
cd /opt
sudo git clone https://github.com/michaelbnfree/critical-reviews.git critical-reviews
sudo chown -R $USER:$USER /opt/critical-reviews
```

---

## 2. Build Command

```bash
cd /opt/critical-reviews
npm install
npm run build
```

**Output directory:** `/opt/critical-reviews/dist/`

The build produces a fully static site — no server-side runtime required. All files in `dist/` are served directly by Caddy.

---

## 3. Sync to Serve Directory

```bash
sudo rsync -av --delete /opt/critical-reviews/dist/ /var/www/critical-reviews/
sudo chown -R caddy:caddy /var/www/critical-reviews/
```

---

## 4. Domain Options

Choose **one** of the following. Update `astro.config.mjs` `site:` value to match before building.

### Option A — Subdomain (recommended if you have a domain)

Serve at `https://criticalreviews.io` or `https://reviews.yourdomain.com`.

Add a DNS A record pointing to `46.225.164.139`, then use the Caddy block in Section 5A.

### Option B — Subpath under existing Manobot domain

Serve at `https://manobot.yourdomain.com/critical-reviews/`.

Requires updating `astro.config.mjs` to add `base: '/critical-reviews'` before building, then use the Caddy block in Section 5B.

---

## 5. Caddy Configuration

### 5A — Standalone subdomain (Option A)

Add this block to your Caddyfile (typically `/etc/caddy/Caddyfile`):

```caddy
criticalreviews.io {
    root * /var/www/critical-reviews
    file_server

    # Compression
    encode gzip zstd

    # Cache static assets aggressively, HTML conservatively
    @static {
        path *.js *.css *.png *.jpg *.jpeg *.webp *.svg *.ico *.woff *.woff2
    }
    header @static Cache-Control "public, max-age=31536000, immutable"
    header *.html Cache-Control "public, max-age=3600, must-revalidate"

    # Security headers
    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "camera=(), microphone=(), geolocation=()"
    }

    # Clean URLs — try .html fallback
    try_files {path} {path}.html {path}/index.html

    # Custom 404
    handle_errors {
        rewrite * /404.html
        file_server
    }
}
```

### 5B — Subpath under existing domain (Option B)

```caddy
# Inside your existing site block:
handle /critical-reviews/* {
    uri strip_prefix /critical-reviews
    root * /var/www/critical-reviews
    file_server

    encode gzip zstd

    @static {
        path *.js *.css *.png *.jpg *.jpeg *.webp *.svg *.ico *.woff *.woff2
    }
    header @static Cache-Control "public, max-age=31536000, immutable"

    try_files {path} {path}.html {path}/index.html
}
```

### Reload Caddy after editing

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

---

## 6. Deploy Script

A `deploy.sh` script is included in the repo root. To run a full deploy:

```bash
cd /opt/critical-reviews
bash deploy.sh
```

See `deploy.sh` for the full script. It:
1. Pulls latest from `main`
2. Installs dependencies
3. Builds the site
4. Syncs dist to `/var/www/critical-reviews/`
5. Reloads Caddy

---

## 7. Public Accessibility

Per Sebastian's stated principle: **lock infrastructure, not product surfaces.**

The site must be publicly accessible without authentication. Caddy's configuration above serves all content openly. Do **not** add HTTP Basic Auth or IP allowlists to the Caddy block for this site.

The Tailscale address is for SSH/admin access only — the public IP `46.225.164.139` must route to Caddy on ports 80/443.

Verify:
```bash
curl -I https://criticalreviews.io/
# Expected: HTTP/2 200
```

---

## 8. Post-Deploy Verification Checklist

```
[ ] https://criticalreviews.io/ loads (home page, review card visible)
[ ] https://criticalreviews.io/reviews/ideation-to-consensus loads (full article)
[ ] https://criticalreviews.io/about loads
[ ] https://criticalreviews.io/sitemap-index.xml returns XML
[ ] https://criticalreviews.io/robots.txt returns text
[ ] OG image loads: https://criticalreviews.io/images/og-ideation-to-consensus.png
[ ] curl -I shows gzip/zstd Content-Encoding on assets
[ ] curl -I shows Cache-Control headers on .js/.css files
[ ] No 404s in Caddy access log for expected routes
[ ] Mobile viewport renders correctly (test with DevTools)
```

---

## 9. Adding New Reviews (for future reference)

1. Create `src/pages/reviews/[slug].astro` following the pattern of `ideation-to-consensus.astro`
2. Add an entry to the `reviews` array in `src/pages/index.astro`
3. Generate an OG image and place it in `public/images/og-[slug].png`
4. Run `npm run build` and deploy via `deploy.sh`

---

## 10. Environment

No environment variables are required. This is a pure static site with no server-side runtime, no database, and no API keys.

---

*Generated by Manobot-ai for the Critical Reviews brick — Sebastian Productions / Bastomatic*
