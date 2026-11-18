#!/usr/bin/env bash
# Builds the site into a temp dir (optionally with test fixture projects)
# and checks the generated HTML. Usage: bash scripts/test_site.sh
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
export BUNDLE_GEMFILE="$REPO/Gemfile"
export PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH"
FAILS=0

pass() { echo "  ok   $1"; }
fail() { echo "  FAIL $1"; FAILS=$((FAILS + 1)); }

# build <name> <with-fixtures:yes|no> [extra-config-yaml]
# Sets SRC and OUT for the build just made.
build() {
  # pwd -P: macOS temp dirs sit behind a symlink, which Jekyll's safe mode rejects
  SRC="$(cd "$(mktemp -d)" && pwd -P)/$1"
  mkdir -p "$SRC"
  rsync -a --exclude .git --exclude _site --exclude vendor --exclude .bundle \
    --exclude .jekyll-cache --exclude .superpowers --exclude test "$REPO/" "$SRC/"
  if [ "$2" = yes ]; then
    mkdir -p "$SRC/_projects"
    cp "$REPO"/test/fixtures/_projects/*.md "$SRC/_projects/"
  fi
  local configs="$SRC/_config.yml"
  if [ -n "${3:-}" ]; then
    printf '%s\n' "$3" > "$SRC/_extra.yml"
    configs="$configs,$SRC/_extra.yml"
  fi
  OUT="$SRC/_site"
  if ! bundle exec jekyll build --quiet --source "$SRC" --destination "$OUT" \
       --config "$configs" > "$SRC.log" 2>&1; then
    echo "jekyll build failed:"; tail -20 "$SRC.log"; exit 1
  fi
}

has()    { grep -qF -- "$2" "$1" && pass "$3" || fail "$3"; }
hasnt()  { grep -qF -- "$2" "$1" && fail "$3" || pass "$3"; }
exists() { [ -e "$1" ] && pass "$2" || fail "$2"; }
absent() { [ -e "$1" ] && fail "$2" || pass "$2"; }
# before <file> <a> <b> <label>: first occurrence of a comes before b
before() {
  local a b
  a=$(grep -bo -F -- "$2" "$1" | head -1 | cut -d: -f1)
  b=$(grep -bo -F -- "$3" "$1" | head -1 | cut -d: -f1)
  [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ] && pass "$4" || fail "$4"
}

echo "== Base site (no projects, no résumé)"
build plain no
I="$OUT/index.html"
exists "$I" "home page built"
if [ ! -e "$I" ]; then echo "FAILED ($FAILS)"; exit 1; fi
has   "$I" "Anthony Casapulla" "name shown"
has   "$I" "Cybersecurity &amp; Technology Risk" "tagline shown"
has   "$I" 'href="https://www.linkedin.com/in/anthony-casapulla/"' "LinkedIn link"
has   "$I" 'href="https://github.com/acasapulla"' "GitHub link"
has   "$I" 'href="/assets/css/style.css"' "stylesheet linked"
hasnt "$I" "mailto:" "no email when unset"
hasnt "$I" "resume.pdf" "no résumé link when unset"
absent "$OUT/docs" "docs/ not published"
absent "$OUT/scripts" "scripts/ not published"
absent "$OUT/README.html" "README not published"

echo "== Résumé set"
build resume no "resume: /assets/files/resume.pdf"
has "$OUT/index.html" 'href="/assets/files/resume.pdf"' "résumé link when set"

echo "== Email set"
build email no "email: someone@example.com"
has "$OUT/index.html" 'href="mailto:someone@example.com"' "email link when set"

echo "== Projects: empty state (real _projects only, example is unpublished)"
build empty no
has    "$OUT/index.html" "Projects coming soon" "empty-state message"
hasnt  "$OUT/index.html" "Example Project" "unpublished example not listed"
absent "$OUT/projects/example-project" "unpublished example has no page"

echo "== Projects: with fixtures"
build projects yes
I="$OUT/index.html"
hasnt  "$I" "Projects coming soon" "no empty-state when projects exist"
hasnt  "$I" "Example Project" "unpublished example still not listed"
before "$I" "Featured Old" "Newer Project" "featured project listed first"
before "$I" "Newer Project" "Minimal Project" "then newest first"
has    "$I" 'href="/projects/newer/"' "card links to project page"
N="$OUT/projects/newer/index.html"
exists "$N" "project page generated"
has    "$N" 'href="/assets/files/x.pdf"' "report button"
has    "$N" "NIST CSF" "tags on project page"
has    "$N" "<h2 id=\"overview\">Overview</h2>" "markdown body rendered"
F="$OUT/projects/featured-old/index.html"
has    "$F" 'href="https://github.com/acasapulla/featured-old"' "repo button"
has    "$N" '<meta name="description" content="A newer project with a report link." />' "link-preview description = project description"
has    "$I" "A newer project with a report link." "card shows description"

echo "== CSS"
C="$OUT/assets/css/style.css"
# Light-mode focus ring must reach 3:1 against white (WCAG 1.4.11)
FOCUS=$(grep -m1 -- '--focus:' "$C" | grep -o '#[0-9a-fA-F]\{6\}')
python3 -I - "$FOCUS" <<'PY' && pass "focus ring contrast >= 3:1 ($FOCUS)" || fail "focus ring contrast >= 3:1 ($FOCUS)"
import sys
h = sys.argv[1].lstrip('#')
def lin(c):
    c = c / 255
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
r, g, b = (int(h[i:i+2], 16) for i in (0, 2, 4))
L = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
sys.exit(0 if 1.05 / (L + 0.05) >= 3 else 1)
PY
# Long unbroken strings (URLs, hashes, paths) must wrap instead of widening the page
css_rule() { # css_rule <file> <selector> <declaration-regex>: a rule for exactly <selector> contains the declaration
  python3 -I - "$@" <<'PYCSS'
import re, sys
css, sel, decl = open(sys.argv[1]).read(), sys.argv[2], sys.argv[3]
css = re.sub(r"/\*.*?\*/", "", css, flags=re.S)
rules = re.findall(r"([^{}]+)\{([^{}]*)\}", css)
sys.exit(0 if any(sel in [x.strip() for x in s.split(",")] and re.search(decl, body) for s, body in rules) else 1)
PYCSS
}
for sel in ".prose" ".card-summary" ".lead"; do
  css_rule "$C" "$sel" 'overflow-wrap:\s*anywhere' && pass "$sel wraps long strings" || fail "$sel wraps long strings"
done
css_rule "$C" ".card" 'min-width:\s*0' && pass ".card can shrink (min-width: 0)" || fail ".card can shrink (min-width: 0)"

M="$OUT/projects/minimal/index.html"
exists "$M" "minimal project page generated"
hasnt  "$M" 'class="tags"' "no empty tag list"
hasnt  "$M" 'class="btn' "no empty link buttons"

if [ "$FAILS" -eq 0 ]; then echo "ALL PASS"; else echo "FAILED ($FAILS)"; exit 1; fi
