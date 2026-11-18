# Portfolio Site — Design

Date: 2026-11-17

## Intent

A personal portfolio site, hosted on GitHub Pages, showcasing cybersecurity and
technology-risk projects. The owner has few/no projects published yet and plans
to add many over time, so **adding a project must be trivial** (one Markdown file
+ `git push`).

## Audience

- **Recruiters** — need to grasp in ~30 seconds: who this is, the focus
  (cybersecurity / tech risk), the strongest projects, and how to get the résumé /
  LinkedIn / contact.
- **Students** — should be able to open a project and follow the reasoning and
  steps, i.e. project pages are real write-ups, not just links.

## Goals

- Professional, fast, readable on phone and desktop.
- One Markdown file per project; home page lists projects automatically.
- Zero local tooling required to publish (GitHub builds it).

## Non-goals (for now)

- Blog, comments, analytics, contact form, CMS.
- Custom domain (can be added later via `CNAME`).

## Anti-goals

- Neon styling that hurts readability: body text stays plain, high-contrast and
  non-animated (see Look). *(Originally "no hacker aesthetic"; owner chose a
  cyberpunk / neon-city theme on 2026-11-17.)*
- Anything that makes adding a project require editing more than one file.
- Publishing placeholder/fake projects as if real.

## Approaches considered

1. **Jekyll on GitHub Pages (chosen)** — native to Pages, Markdown projects in a
   collection, no build pipeline to maintain. Trade-off: dated tooling; local
   preview needs a newer Ruby (optional).
2. Hugo/Astro + GitHub Actions — more modern/flexible, but extra install and a
   deploy workflow to maintain. Rejected: adds friction against the core goal.
3. Plain HTML/CSS — no build, fully transparent, but each project means
   hand-editing two HTML files. Rejected: doesn't scale as projects grow.

Chosen by the owner: Jekyll.

## Design

### Repo & hosting
- Repo named `<github-username>.github.io` (public) → site at
  `https://<github-username>.github.io`.
- Built by GitHub Pages' default Jekyll build ("Deploy from branch: main / root").
  Only plugins on the GitHub Pages allowlist (e.g. `jekyll-seo-tag`,
  `jekyll-sitemap`).
- `docs/` excluded from the build in `_config.yml`.

### Structure
```
_config.yml          site title, name, tagline, links, collections
_layouts/            default.html, project.html
_includes/           header, footer, project-card
_projects/           one .md per project
assets/css/style.css hand-written CSS (no framework)
assets/img/          project images
assets/files/        resume.pdf, report PDFs
index.html           home page
README.md            how to add a project
```

### Home page (single scroll)
```
[Name]                                   Projects · Résumé · LinkedIn · GitHub
Cybersecurity & Technology Risk
1–2 line intro

Projects
┌────────────┐ ┌────────────┐ ┌────────────┐
│ Title      │ │ Title      │ │ Title      │
│ summary    │ │ summary    │ │ summary    │
│ [tag][tag] │ │ [tag][tag] │ │ [tag]      │
└────────────┘ └────────────┘ └────────────┘

About — short bio, focus areas, certifications (optional)
Footer — email / LinkedIn / GitHub
```
- Projects sorted: `featured: true` first, then newest `date` first.
- Résumé link points to `assets/files/resume.pdf`; hidden if not set in config.

### Project file format (`_projects/<slug>.md`)
```yaml
---
title: "Risk Assessment of a Small Business Network"
date: 2026-11-01
summary: "2–3 sentences: problem and what I found/built."
tags: [Risk Assessment, NIST CSF]
featured: false
repo: https://github.com/...     # optional
report: /assets/files/x.pdf      # optional
---
## Overview
## What I Did
## Results & Takeaways
```
Project page renders title, tags, date, link buttons (only those present), then
the body.

### Look
- Cyberpunk / neon-city theme, dark only: night-sky gradient, neon cyan +
  magenta accents, SVG city skyline with lit windows in the hero, faint scanlines.
- Fonts (Google Fonts): Orbitron for headings, Share Tech Mono for labels/tags,
  Inter for body text. Readable line length (~70ch).
- Animations (title flicker, cursor blink, antenna beacons) are disabled under
  `prefers-reduced-motion`. Text colors ≥ 4.5:1 and focus ring ≥ 3:1 on the
  background (checked by the test script).
- Responsive card grid (1 column on phone, 2–3 on desktop).
- Accessible: semantic HTML, sufficient contrast, visible focus states.

### Starter content
- One clearly-marked **example** project file (`_projects/example-project.md`,
  with `published: false`) showing the format, so it never appears on the live
  site.
- `README.md` with the "add a project" steps.

## Setup steps the owner will do
- Set git identity (`git config --global user.name/email`).
- Create the GitHub repo and push (via web UI + git, or install `gh`).
- Enable Pages (Settings → Pages → main / root).

## Left to the builder
- Exact accent color and spacing scale.
- Placeholder copy for name/tagline/bio in `_config.yml`, clearly marked TODO.

## Owner details (provided)
- GitHub username: `acasapulla` → repo `acasapulla.github.io`,
  site `https://acasapulla.github.io`
- Display name: Anthony Casapulla
- LinkedIn: https://www.linkedin.com/in/anthony-casapulla/
- Résumé: owner has a PDF; copy to `assets/files/resume.pdf` (location to confirm
  at build time).

## Still open
- Tagline: defaults to "Cybersecurity & Technology Risk" (builder's call).
- Public email: not provided — omit email link unless owner supplies one (do not
  publish an address the owner hasn't approved for the site).
