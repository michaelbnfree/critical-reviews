> **Note: This is a proposed plan of action. Review and confirm before implementing.**

# Brief: Polygon.io Integration for ContrarianAlpha

## What you're building
A new data source module (`polygon.py`) for the ContrarianAlpha trading dashboard, plus wiring it into the existing snapshot orchestrator. This adds BTC ETF institutional flow signals and macro equity context to the existing crypto snapshot.

---

## Server & stack
- **Server:** Ubuntu 24.04, aarch64, accessed via SSH on port 2222
- **Project root:** `/opt/manobot/`
- **Data layer package:** `/opt/manobot/data-layer/src/manobot_data/`
- **Snapshot service:** `/opt/manobot/snapshot-svc/` — FastAPI app wrapping the data layer
- **System env file:** `/etc/manobot.env` — all secrets live here, loaded by systemd
- **Service to restart after changes:** `manobot-snapshot.service`
- **Python venv:** `/opt/manobot/venv/` (run installs with `/opt/manobot/venv/bin/pip`)

---

## Architecture: how a new data source plugs in

The pattern is identical for every source. Study these two files before writing anything:

**`/opt/manobot/data-layer/src/manobot_data/sources/binance.py`** — shows the cache pattern:
```python
def some_fn(symbol: str, *, cache: Cache | None = None) -> dict:
    if cache:
        cached = cache.get("source_name.fn_name", symbol)
        if cached is not None:
            return cached
    payload = get_json(URL, params={...})
    if cache:
        cache.set("source_name.fn_name", symbol, payload, ttl_seconds=30)
    return payload
```

**`/opt/manobot/data-layer/src/manobot_data/sources/coinglass.py`** — shows how to load an API key from the environment and use a custom header, plus how to return `{}` gracefully on failure (no exceptions propagated to caller).

**`/opt/manobot/data-layer/src/manobot_data/sources/_http.py`** — the shared HTTP helper. Use `get_json(url, params=...)` for simple GETs. It handles retries and timeouts. Import with `from ._http import get_json`.

**`/opt/manobot/data-layer/src/manobot_data/cache.py`** — `Cache.get(source, key)` / `Cache.set(source, key, payload, ttl_seconds)`.

**`/opt/manobot/data-layer/src/manobot_data/snapshot.py`** — the orchestrator. It calls all sources, wraps them in `_safe()` to suppress errors, and builds a single JSON dict. You'll add a new `"macro"` key to the returned dict.

---

## Step 1: Add the API key to the system env

Append to `/etc/manobot.env`:
```
POLYGON_API_KEY=wab61mc0P09cAJUO4exg5Rpz4Xumg5LJ
```

---

## Step 2: Create `/opt/manobot/data-layer/src/manobot_data/sources/polygon.py`

**What to fetch (all via Polygon's `/v2/aggs/ticker/{ticker}/prev` endpoint — free plan confirmed working):**

| Function | Tickers | Purpose |
|---|---|---|
| `btc_etf_flows()` | IBIT, FBTC, GBTC | Institutional BTC flow proxy — prev day price + volume |
| `macro_equities()` | SPY, QQQ, GLD, UUP | Risk-on/off context — prev day price + % change |
| `ticker_news(ticker)` | BTC, ETH | Recent headlines for sentiment |

**API details:**
- Base URL: `https://api.polygon.io`
- Auth: query param `apiKey` (not a header)
- Previous day endpoint: `GET /v2/aggs/ticker/{ticker}/prev?adjusted=true&apiKey={key}`
- News endpoint: `GET /v2/reference/news?ticker={ticker}&limit=5&apiKey={key}`
- Free plan rate limit: 5 requests/minute — cache aggressively (TTL 3600s for prev-day, 900s for news)
- Load key with: `os.environ.get("POLYGON_API_KEY", "")`
- If key missing or request fails, return `{}` / `[]` silently (same pattern as coinglass)

**Shape of `/v2/aggs/ticker/{ticker}/prev` response:**
```json
{
  "results": [{"T": "IBIT", "o": 55.1, "h": 56.2, "l": 54.8, "c": 55.9, "v": 38200000, "vw": 55.6, "t": 1778184000000}],
  "status": "OK"
}
```
Extract `results[0]` — fields: `c` (close), `o` (open), `v` (volume), `vw` (volume-weighted avg price), `t` (timestamp ms).

**Return shapes to aim for:**

`btc_etf_flows()` → dict:
```python
{
  "IBIT": {"close": 55.9, "volume": 38200000, "vwap": 55.6, "open": 55.1, "timestamp_ms": 1778184000000},
  "FBTC": {...},
  "GBTC": {...},
}
```

`macro_equities()` → dict:
```python
{
  "SPY":  {"close": 521.4, "volume": 61000000, "vwap": 520.1, "open": 519.0, "timestamp_ms": ...},
  "QQQ":  {...},
  "GLD":  {...},
  "UUP":  {...},
}
```

`ticker_news(ticker: str)` → list:
```python
[
  {"title": "...", "published_utc": "2026-05-07T...", "url": "..."},
  ...
]
```

Cache keys: use `"polygon.btc_etf_flows"` / `"polygon.macro_equities"` / `f"polygon.news.{ticker}"` as the source string with `"all"` or the ticker as the key.

---

## Step 3: Wire into `/opt/manobot/data-layer/src/manobot_data/snapshot.py`

At the top, add the import:
```python
from .sources import binance, coingecko, coinglass, fear_greed, polygon
```

Inside `build_snapshot()`, add calls after the existing source fetches:
```python
etf_flows = _safe(polygon.btc_etf_flows, cache=cache) or {}
macro_eq  = _safe(polygon.macro_equities, cache=cache) or {}
btc_news  = _safe(polygon.ticker_news, "BTC", cache=cache) or []
```

Add a new top-level key to the returned dict:
```python
"macro": {
    "btc_etfs": etf_flows,
    "equities": macro_eq,
    "news_btc": btc_news,
},
```

---

## Step 4: Register the new source in `__init__.py`

Check `/opt/manobot/data-layer/src/manobot_data/sources/__init__.py` — if it explicitly imports modules, add `polygon` to the list. If it's empty or uses `__all__`, it may need no change.

---

## Step 5: Restart and verify

```bash
systemctl restart manobot-snapshot.service
systemctl status manobot-snapshot.service   # confirm active

# Test the snapshot endpoint — look for "macro" key in response
curl -s http://127.0.0.1:8000/snapshot/BTCUSDT | python3 -m json.tool | grep -A 30 '"macro"'
```

Expected: `"macro"` block with `btc_etfs`, `equities`, `news_btc` populated. If Polygon key is missing or rate-limited, those sub-keys should be `{}` / `[]` — not a 500 error.

---

## What NOT to touch
- `/opt/manobot/backend/` — the Node layer already proxies `/snapshot` transparently, no changes needed there
- `/opt/manobot/snapshot-svc/app/main.py` — the FastAPI wrapper calls `build_snapshot()` generically, no changes needed
- Any frontend files

---

## Done signal

```bash
curl -s http://127.0.0.1:8000/snapshot/BTCUSDT | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(list(d['macro']['btc_etfs'].keys()))"
```

Should print: `['IBIT', 'FBTC', 'GBTC']`
