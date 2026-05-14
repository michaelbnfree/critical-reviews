# Polymarket Strategy — System Record (Claude, May 2026)

> **Purpose:** Baseline record of the current strategy and implementation before comparison with Grok's paper trading output.

---

## Strategy Overview

**Signal source:** BTC Markov Chain regime detector  
**Target markets:** Polymarket "Bitcoin Up or Down" 5-minute binary markets  
**Edge model:** Map current BTC macro regime (BULL/BEAR/CRAB) to a Yes probability; trade when that probability diverges from market price by >4 cents

---

## Signal: BTC Markov Chain Regime Detector

### How it works
1. Fetch 730 days of BTC/USDT daily OHLCV from Binance
2. Classify each day into one of three regimes using a 20-day rolling window:
   - **BULL** — 20-day return > +5%
   - **BEAR** — 20-day return < -5%
   - **CRAB** — everything else, or low-vol consolidation (20d return std < 1.5%)
3. Build a 3×3 transition matrix from historical state sequences
4. Current state → probability of next state → Yes signal

### Trained transition matrix (as of May 14 2026, 730d training)
```
           → BULL    → BEAR    → CRAB
BULL       0.8667    0.0000    0.1333
BEAR       0.0055    0.8197    0.1749
CRAB       0.0963    0.1096    0.7940
```

### Stationary distribution
- BULL: 31.7%
- BEAR: 25.8%
- CRAB: 42.5%

### Signal generation
```python
signal = clip(0.5 + (P[state][BULL] - P[state][BEAR]) * 0.4, 0.01, 0.99)
```
- BULL state → signal ~0.847 (strong Yes edge)
- BEAR state → signal ~0.498 (near neutral)
- CRAB state → signal ~0.516 (slight Yes lean)

### Current live state (May 14 2026)
- BTC 20-day return: +5.24%
- 20-day vol: 1.39% (below 1.5% CRAB threshold)
- **Active state: CRAB**

---

## Risk Engine

| Parameter | Value |
|---|---|
| Bankroll | $100 (paper) / configurable |
| Risk per trade | 1% of bankroll |
| Max exposure per outcome | 20% of bankroll |
| Daily loss kill switch | -5% unrealized |
| Stop loss per position | -8% from entry |
| Min edge to enter | 4 cents (0.04) |
| Max open orders | 3 |

---

## Market Targeting

- **MarketPoller** polls `gamma-api.polymarket.com` every 30 seconds
- Detects new "Bitcoin Up or Down" 5-minute markets as they go live
- Fires async callback → bot resets position and switches token targets
- Falls back to `YES_TOKEN`/`NO_TOKEN` in `.env` if no live 5-min markets

---

## Infrastructure

- **Language:** Python 3.12
- **CLOB SDK:** `py_clob_client_v2`
- **Auth:** CLOB L2 (derived API key from wallet private key, chain_id=137)
- **Price feed:** Polymarket WebSocket (`wss://ws-subscriptions-clob.polymarket.com/ws/market`)
- **Order book:** REST polling every 10s (`https://clob.polymarket.com/book`)
- **BTC data:** Binance via `ccxt` (daily OHLCV, refreshed hourly)
- **Wallet:** `0xa801E9dF4f5Edc94069dF690AeE9754Fc15c0611` (Polygon mainnet)

---

## Paper Trading Mode

File: `paper_trader.py`

- Runs full stack: WS feed + order book + Markov + strategy
- Signs orders with real wallet (proves mechanism) but **never posts**
- Tracks simulated P&L against live market prices
- Prints ledger status every 30s, full summary every 60s
- Auto-switches markets when poller finds new BTC Up/Down markets

Run: `python paper_trader.py` or `python paper_trader.py --market <slug>`

---

## Known Limitations

1. **No live 5-min markets available outside US trading hours** — poller will idle until they appear
2. **CRAB signal is weak** — only +1.6 cents edge in current state; bot will not trade unless market price is below ~0.496
3. **Markov trained on daily data** — 5-minute markets resolve on 5-minute BTC moves; regime signal is macro context, not short-term direction
4. **No volume/liquidity filter** — bot may target low-liquidity markets with wide spreads

---

## Files

```
/root/polymarket_bot/
  polymarket_full_bot.py   — production bot (6-layer WS + orders + risk)
  paper_trader.py          — paper trading simulation
  market_poller.py         — live market discovery
  markov_core.py           — BTC regime detector + training
  btc_transition_matrix.json — trained Markov matrix
  .env                     — secrets (gitignored)
  .env.example             — template
  requirements.txt
```

---

## Open Questions (for Grok comparison)

1. Is the Markov signal actually predictive for 5-minute BTC binary outcomes?
2. Should the signal use intraday data (1h or 15m) instead of daily?
3. Is 4-cent edge threshold appropriate given typical 5-min market spreads?
4. What does Grok's paper trading output show for win rate and edge?
