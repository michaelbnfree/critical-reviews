# Critical Reviews

**Rigorous analysis of emerging concepts in crypto, governance, and decentralized systems.**

A Sebastian Productions brick — composable, standalone, and freely accessible.

---

## What This Is

Critical Reviews is a long-form editorial publication that stress-tests crypto, Web3, and governance concepts across five standard dimensions:

| # | Dimension | Accent |
|---|---|---|
| 01 | Legal & Regulatory Compliance | Navy |
| 02 | Governance & Security | Teal |
| 03 | Economic & Game Theory Mechanics | Amber |
| 04 | Technical & Operational Feasibility | Slate |
| 05 | Product & User Experience | Rose |

Each review uses three card types for instant visual scanning:

| Glyph | Card Type | Meaning |
|---|---|---|
| ○ | What is Missing | Gaps in the concept that need to be filled |
| △ | What Needs to be Challenged | Assumptions that need to be questioned |
| ◆ | Improvements | Concrete, actionable recommendations |

---

## Tech Stack

- **Framework:** [Astro](https://astro.build) (static site generator)
- **Styling:** Tailwind CSS v4 + CSS custom properties
- **Fonts:** Lora (headings, serif) + Inter (body, sans-serif)
- **SEO:** Sitemap via `@astrojs/sitemap`, Open Graph meta, Schema.org Article structured data
- **Deployment:** Static files served by Caddy on Hetzner

---

## Project Structure

```
critical-reviews/
├── src/
│   ├── layouts/
│   │   └── BaseLayout.astro        # Site shell: nav, footer, SEO meta
│   ├── components/
│   │   ├── ReviewHero.astro         # Deep-navy hero banner
│   │   ├── TableOfContents.astro    # Sticky sidebar TOC + mobile drawer
│   │   ├── ReviewSection.astro      # Color-coded section wrapper + copy-link
│   │   ├── CardGroup.astro          # Glyph card group heading (○ △ ◆)
│   │   ├── ReviewCard.astro         # Individual glyph card
│   │   ├── RiskTable.astro          # Executive Summary risk matrix
│   │   ├── ActionMatrix.astro       # Conclusion prioritized action table
│   │   └── ReviewListCard.astro     # Home page review listing card
│   ├── pages/
│   │   ├── index.astro              # Home — review listing
│   │   ├── about.astro              # About page
│   │   ├── 404.astro                # 404 page
│   │   └── reviews/
│   │       └── ideation-to-consensus.astro   # Inaugural article
│   └── styles/
│       └── global.css               # Brand tokens, base styles
├── public/
│   ├── images/
│   │   ├── og-ideation-to-consensus.png
│   │   └── og-default.png
│   ├── favicon.svg
│   └── robots.txt
├── DEPLOY.md                        # Hetzner deployment specification
├── deploy.sh                        # Deploy script (for Claude/CI)
└── astro.config.mjs
```

---

## Development

```bash
npm install
npm run dev        # Start dev server at http://localhost:4321
npm run build      # Build to dist/
npm run preview    # Preview built site
```

---

## Adding a New Review

1. **Create the article page** — copy `src/pages/reviews/ideation-to-consensus.astro` to `src/pages/reviews/your-review-slug.astro` and update title, content, section data, risk rows, action rows, and schema.

2. **Add to the home page listing** — in `src/pages/index.astro`, add an entry to the `reviews` array.

3. **Generate an OG image** — place a 1200x630px image at `public/images/og-your-review-slug.png`.

4. **Build and deploy** — `npm run build` then `bash deploy.sh` on the Hetzner box.

---

## Deployment

See [`DEPLOY.md`](./DEPLOY.md) for the full Hetzner deployment specification, Caddy configuration, and post-deploy verification checklist.

**Quick summary:**
- Build output: `dist/`
- Serve path on box: `/var/www/critical-reviews/`
- Deploy: `bash deploy.sh` on the Hetzner box
- Web server: Caddy (already running)

---

## Composability

The components in `src/components/` are designed to be extracted into a shared component library for other Sebastian Productions bricks. The visual system (color tokens, glyph cards, TOC, section wrappers) is self-contained and can be dropped into any Astro + Tailwind project.

---

## Brand

- **Brand name:** Critical Reviews
- **Tagline:** Rigorous analysis of emerging concepts in crypto, governance, and decentralized systems.
- **Parent:** Sebastian Productions / Bastomatic
- **Related:** [Contrarian Alpha](https://contrarianalpha.io) (trading & macro analysis)
- **Palette:** Deep navy (`#04050C`), off-white (`#F5F3EE`), gold (`#C9A84C`)

---

## License

Content © Sebastian Productions. Code is MIT-licensed — reuse the component patterns freely.
