# Portfolio Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Jekyll portfolio for Anthony Casapulla on GitHub Pages where adding a project = one Markdown file + `git push`.

**Architecture:** Plain Jekyll site (no theme) built by GitHub Pages' default branch build. Projects are a Jekyll collection (`_projects/`) rendered as cards on the home page and as individual pages via a `project` layout. A shell test script builds the site into a temp dir with fixture projects and asserts on the generated HTML.

**Tech Stack:** Jekyll via the `github-pages` gem (matches Pages' versions), Liquid, hand-written CSS, Bash + grep for tests.

**Spec:** `docs/superpowers/specs/2026-11-17-portfolio-site-design.md`

## Global Constraints

- Repo: `acasapulla.github.io`, public, branch `main`, Pages source "Deploy from a branch / main / (root)".
- Site URL `https://acasapulla.github.io`, `baseurl: ""`; every internal link uses `| relative_url`.
- Display name "Anthony Casapulla"; tagline "Cybersecurity & Technology Risk"; LinkedIn `https://www.linkedin.com/in/anthony-casapulla/`; GitHub `https://github.com/acasapulla`.
- No email anywhere on the site unless `email` is set in `_config.yml` (default: unset).
- Plugins only from the Pages allowlist: `jekyll-seo-tag`, `jekyll-sitemap`.
- No CSS/JS frameworks, no external scripts. System font stack. Light default + `prefers-color-scheme: dark`.
- No "hacker" styling (green-on-black, glitch, monospace body text).
- `docs/`, `scripts/`, `test/`, `README.md`, `Gemfile*` excluded from the build.

## Review Focus

1. Project without `repo`/`report`/`tags` → page and card render with no empty buttons/tag rows. (Task 2 fixture `minimal.md`)
2. `published: false` example project → absent from home page and no page generated. (Task 2)
3. `resume` unset in config → no résumé link anywhere; set → link to `/assets/files/resume.pdf`. (Task 1)
4. Featured + dated ordering → featured first, then newest first. (Task 2)
5. Long project title / narrow phone viewport → no horizontal scroll (card grid single column under 600px, `overflow-wrap: anywhere` on titles). Checked manually in Task 3.

---

### Task 0: Local build tooling

**Files:**
- Create: `Gemfile` (`gem "github-pages", group: :jekyll_plugins`; `gem "webrick"`)
- Create: `.gitignore` (`_site/`, `.jekyll-cache/`, `vendor/`, `.bundle/`, `Gemfile.lock` is committed)

- [ ] **Step 1:** If `ruby -v` < 3.0, `brew install ruby` and add `$(brew --prefix ruby)/bin` to PATH in `~/.zshrc`. If Homebrew is missing, stop and ask the owner (fallback: skip local builds, verify on GitHub after push).
- [ ] **Step 2:** `bundle config set --local path vendor/bundle && bundle install` → completes without error.
- [ ] **Step 3:** `git init -b main`; set identity if unset: `git config --global user.name "Anthony Casapulla"` (ask owner for the email to use for commits). Commit spec, plan, Gemfile, .gitignore.

### Task 1: Base site — config, layout, header/footer, about, résumé

**Files:**
- Create: `_config.yml`, `_layouts/default.html`, `_includes/header.html`, `_includes/footer.html`, `index.html`, `assets/css/style.css`, `scripts/test_site.sh`

**Interfaces:**
- Produces: `_config.yml` keys `title`, `author`, `tagline`, `description`, `linkedin`, `github`, `resume` (path or unset), `email` (unset); collection `projects` with `output: true`, `permalink: /projects/:name/`. `default` layout wraps `{{ content }}` with header/footer and loads `/assets/css/style.css`. `index.html` has sections `#projects` (left empty with a `<!-- project-grid -->` marker for Task 2) and `#about`.
- `scripts/test_site.sh`: copies repo (minus `.git`, `_site`, `vendor`) to `mktemp -d`, copies `test/fixtures/_projects/*` into its `_projects/` if present, runs `bundle exec jekyll build --source <tmp> --destination <tmp>/_site` (with `BUNDLE_GEMFILE` pointing at the repo Gemfile), then runs assertions; exits non-zero on first failure, printing which.

- [ ] **Step 1: Write failing assertions in `scripts/test_site.sh`**
  - `_site/index.html` contains `Anthony Casapulla` and `Cybersecurity &amp; Technology Risk`
  - contains `href="https://www.linkedin.com/in/anthony-casapulla/"` and `href="https://github.com/acasapulla"`
  - contains `href="/assets/css/style.css"`
  - does not contain `mailto:`
  - with `resume` unset: does not contain `resume.pdf`; then rebuild with an extra config `resume: /assets/files/resume.pdf` (`--config _config.yml,<tmp>/resume.yml`) and assert it contains `href="/assets/files/resume.pdf"`
  - `_site/docs/` and `_site/scripts/` do not exist
- [ ] **Step 2:** `bash scripts/test_site.sh` → FAIL (no `_config.yml`).
- [ ] **Step 3:** Implement the files. About section: short placeholder bio wrapped in `<!-- TODO: Anthony to write -->`. Header nav: Projects (`#projects`), About (`#about`), Résumé (if set), LinkedIn, GitHub. Include `{% seo %}` in `<head>`.
- [ ] **Step 4:** `bash scripts/test_site.sh` → `ALL PASS`.
- [ ] **Step 5:** Commit `feat: base site layout and config`.

### Task 2: Projects collection — cards, project pages, ordering

**Files:**
- Create: `_layouts/project.html`, `_includes/project-card.html`, `_projects/example-project.md`, `test/fixtures/_projects/{featured-old,newer,minimal}.md`
- Modify: `index.html` (replace `<!-- project-grid -->`), `scripts/test_site.sh`

**Interfaces:**
- Consumes: `projects` collection, `default` layout.
- Produces: project front matter `title` (req), `date` (req), `summary` (req), `tags` (list, opt), `featured` (bool, opt), `repo` (url, opt), `report` (path, opt). `project-card.html` takes `include.project`.
- Ordering: `{% assign sorted = site.projects | sort: "date" | reverse %}` rendered featured-first (two loops: `featured == true`, then the rest).
- Empty-state: if no published projects, show "Projects coming soon."

- [ ] **Step 1: Fixtures + failing assertions**
  - `featured-old.md`: title "Featured Old", date 2025-01-01, featured: true, tags [GRC], repo set
  - `newer.md`: title "Newer Project", date 2026-06-01, tags [NIST CSF], report `/assets/files/x.pdf`
  - `minimal.md`: title "Minimal Project", date 2026-01-01, summary only
  - Assert on `index.html`: order of first occurrence is `Featured Old` < `Newer Project` < `Minimal Project`; does not contain `Example Project`.
  - Assert `_site/projects/newer/index.html` exists and contains `href="/assets/files/x.pdf"` and `NIST CSF`; `_site/projects/example-project/` does not exist.
  - Assert `_site/projects/minimal/index.html` contains no `class="tags"` and no `class="btn"`.
  - Without fixtures (plain build): `index.html` contains `Projects coming soon`.
- [ ] **Step 2:** `bash scripts/test_site.sh` → FAIL on ordering assertion.
- [ ] **Step 3:** Implement. `example-project.md` has `published: false`, title "Example Project", and the Overview / What I Did / Results & Takeaways body as a template with guidance comments.
- [ ] **Step 4:** `bash scripts/test_site.sh` → `ALL PASS`.
- [ ] **Step 5:** Commit `feat: projects collection with cards and pages`.

### Task 3: Styling, README, visual check

**Files:**
- Modify: `assets/css/style.css`
- Create: `README.md`

- [ ] **Step 1:** CSS: CSS custom properties on `:root` with dark overrides under `@media (prefers-color-scheme: dark)`; one accent color; body max-width ~70ch for prose; card grid `repeat(auto-fill, minmax(260px, 1fr))`, single column < 600px; `overflow-wrap: anywhere` on card titles; visible `:focus-visible` outline; text contrast ≥ 4.5:1 in both modes.
- [ ] **Step 2:** `bundle exec jekyll serve` with fixtures temporarily copied in; check at 375px and 1280px, light and dark: no horizontal scroll, long title wraps, cards readable. Remove fixtures from `_projects/` afterwards (`git status` shows none).
- [ ] **Step 3:** README: "Add a project" (copy `example-project.md`, rename, remove `published: false`, fill fields, `git add/commit/push`), "Preview locally" (`bundle exec jekyll serve`), "Run tests" (`bash scripts/test_site.sh`), "Update résumé" (replace `assets/files/resume.pdf`).
- [ ] **Step 4:** `bash scripts/test_site.sh` → `ALL PASS`. Commit `style: site styles and README`.

### Task 4: Résumé and publish

- [ ] **Step 1:** Ask owner for résumé file path; copy to `assets/files/resume.pdf`; set `resume: /assets/files/resume.pdf` in `_config.yml`. Test passes. Commit.
- [ ] **Step 2:** Owner creates empty public repo `acasapulla.github.io` on github.com (no README). `git remote add origin https://github.com/acasapulla/acasapulla.github.io.git && git push -u origin main` (owner authenticates).
- [ ] **Step 3:** Owner enables Settings → Pages → Deploy from branch → `main` / root.
- [ ] **Step 4:** After the Pages build, `curl -s https://acasapulla.github.io | grep "Anthony Casapulla"` → match; `curl -sI https://acasapulla.github.io/assets/files/resume.pdf` → `200`.
