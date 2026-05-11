# AeroFloat — Base44 API Access Brief

> **Purpose:** Enable Manus to access and analyze the AeroFloat app built on Base44.

---

## App Overview

- **Name:** AeroFloat
- **Description:** An interactive physics simulation playground for experimenting with wind strength, buoyancy, and fluid dynamics.
- **Live URL:** https://aero-float-copy-be581d83.base44.app
- **Main page:** AirflowSim (`src/pages/AirflowSim.jsx`)
- **Platform:** Base44 v4 (AI-powered app builder, React/Vite frontend)

---

## API Access

**Base URL:** `https://app.base44.com`  
**Auth:** query param `?api_key=<key>` (not a header)  
**App ID:** `6a00764b964a855e999897f5`

### Confirmed working endpoints

```bash
# Full app metadata (pages, entities, agents, config, conversation history)
GET https://app.base44.com/api/apps/6a00764b964a855e999897f5?api_key=<key>

# List all apps on the account
GET https://app.base44.com/api/apps?api_key=<key>
```

### What the metadata contains

The app object is large (~110KB) and includes:
- `page_names` — list of page names
- `discovered_routes` — file paths per page (e.g. `src/pages/AirflowSim.jsx`)
- `entities` — data models
- `agents` — any AI agents configured in the app
- `functions` / `function_names` — backend serverless functions
- `conversation` — the full AI build conversation (how the app was constructed)
- `design_guidelines`, `custom_instructions`
- `auth_config`, `public_settings`
- `last_git_commit_hash: 43450bcdf1ca7a8f5eb13c7dbf04828044ebd6aa`
- `git_remote_source: s3` — source code stored on S3, not directly downloadable via API

### Source code access

The source files are on S3 (not exposed via a download API endpoint). To read the actual component code, options are:
1. Browse the live app at the URL above
2. Log into the Base44 dashboard at https://app.base44.com with account `bastobot.xbt@gmail.com`
3. Explore the `conversation` field in the metadata — it contains the full AI build history which describes what was built and why

---

## What to analyze

1. **App structure** — what does AirflowSim do? What physics model is it simulating?
2. **Code quality** — is the simulation logic sound? Any issues with the approach?
3. **Reusability** — what parts could be extracted as bricks for the critical-reviews library?
4. **Improvement opportunities** — what would you add or change?

---

## Notes

- `is_managed_source_code: true` — Base44 owns the source lifecycle
- `public_settings: public_without_login` — app is publicly accessible
- `using_sandbox: true` — running in Base44's sandbox environment
- `has_unchained_ai: true` — AI agent is enabled inside the app
