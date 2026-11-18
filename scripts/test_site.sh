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

if [ "$FAILS" -eq 0 ]; then echo "ALL PASS"; else echo "FAILED ($FAILS)"; exit 1; fi
