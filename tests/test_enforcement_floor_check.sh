#!/usr/bin/env bash
# Re-runnable test for PROTOCOL.md section 0.1 (enforcement-floor check), Bash form.
#
# Extracts the first ```bash block under "### 0.1" from PROTOCOL.md and runs THAT block, so
# the documented command and this test cannot silently drift apart. Uses a fake HOME and
# project dir under mktemp; never touches your real ~/.claude.
#
#   bash tests/test_enforcement_floor_check.sh
#
# Exit code 0 = every scenario behaved as expected; 1 = at least one did not.
# Tested with GNU grep 3.0 (Git for Windows). Linux/macOS grep: not tested.
set -u

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# PROTOCOL.md is CRLF in a Windows autocrlf checkout; strip CR or the extracted command is corrupted.
block="$(tr -d '\r' < "$repo/PROTOCOL.md" | awk '/^### 0\.1 /{s=1} s && /^```bash/{b=1; next} s && b && /^```/{exit} s && b{print}')"
[ -n "$block" ] || { echo "FAIL: no bash block found under PROTOCOL.md section 0.1"; exit 1; }

root="$(mktemp -d)"; trap 'rm -rf "$root"' EXIT
with_hook='{"hooks":{"PreToolUse":[{"matcher":"Bash|Edit|Write","hooks":[{"type":"command","command":"python C:/example/scientific-debug/hook_gate.py"}]}]}}'
no_hook='{"permissions":{"allow":["Bash(ls)"]}}'
# UTF-16LE-with-BOM writer for the (ASCII) fixture text: iconv if present, else perl.
to_utf16() {
  if command -v iconv >/dev/null 2>&1; then iconv -f UTF-8 -t UTF-16
  else perl -e 'binmode STDOUT; print "\xFF\xFE"; local $/; my $t = <STDIN>; $t =~ s/(.)/$1\x00/gs; print $t'; fi
}
can_utf16=0; { command -v iconv >/dev/null 2>&1 || command -v perl >/dev/null 2>&1; } && can_utf16=1

# fix NAME HOOK_IN "EXISTING KEYS" [ENC] [HOMENAME] [PS_IS_DIR]
# keys: hs=home settings.json  hl=home settings.local.json  ps=project settings.json  pl=project settings.local.json
fix() {
  local name=$1 hookin=$2 exist=$3 enc=${4:-utf8} homename=${5:-home} psdir=${6:-0}
  local base="$root/$name" k path text
  H="$base/$homename"; P="$base/proj"
  mkdir -p "$H/.claude" "$P/.claude" "$P/src"
  for k in $exist; do
    case $k in
      hs) path="$H/.claude/settings.json" ;;       hl) path="$H/.claude/settings.local.json" ;;
      ps) path="$P/.claude/settings.json" ;;       pl) path="$P/.claude/settings.local.json" ;;
    esac
    if [ "$k" = ps ] && [ "$psdir" = 1 ]; then mkdir -p "$path"; continue; fi
    if [ "$k" = "$hookin" ]; then text=$with_hook; else text=$no_hook; fi
    case $enc in
      utf8)    printf '%s' "$text" > "$path" ;;
      utf8bom) printf '\357\273\277%s' "$text" > "$path" ;;
      utf16)   printf '%s' "$text" | to_utf16 > "$path" ;;
    esac
  done
}

failures=0; total=0
# check "NAME" EXPECT_FOUND(1|0) CWD_UNDER_PROJECT("" or "src")
check() {
  local name=$1 expect=$2 sub=${3:-} cwd out err found=0
  cwd="$P${sub:+/$sub}"
  out="$( cd "$cwd" && HOME="$H" PROJECT_ROOT="$P" bash -c "$block" 2>"$root/err.txt" )"
  err="$(cat "$root/err.txt")"
  [ -n "$out" ] && found=1
  total=$((total+1))
  if [ "$found" = "$expect" ] && [ -z "$err" ]; then echo "PASS  $name (found=$found, expected=$expect)"
  else failures=$((failures+1)); echo "FAIL  $name (found=$found, expected=$expect, stderr='$err')"; fi
}

all="hs hl ps pl"
fix s01 hs "$all";            check "hook in home; all four files exist" 1
fix s02 hs "hs";              check "hook in home; ONLY home settings.json exists" 1
fix s03 hs "hs ps pl";        check "hook in home; home settings.local.json absent" 1
fix s04 hs "hs hl ps";        check "hook in home; project settings.local.json absent" 1
fix s05 none "hs ps pl";      check "NO hook; home settings.local.json absent" 0
fix s06 none "$all";          check "NO hook; all four files exist" 0
fix s07 none "";              check "NO settings files exist at all" 0
fix s08 ps "hs ps";           check "hook only in PROJECT settings.json; shell in subdir" 1 src
fix s09 pl "hs pl";           check "hook only in PROJECT settings.local.json" 1
fix s10 hs "hs ps" utf8bom;   check "hook in home; UTF-8 BOM" 1
fix s11 hs "hs ps" utf8 home 1; check "hook in home; project settings.json is a DIRECTORY" 1
fix s12 hs "hs ps" utf8 "Jane [x] Doe"; check "hook in home; [ ] and spaces in the home path" 1
if [ "$can_utf16" = 1 ]; then
  # KNOWN LIMITATION (documented in section 0.1): grep -l cannot see through UTF-16. The expected
  # result is "not found"; if this ever flips to found, update the documented asymmetry.
  fix s13 hs "hs ps" utf16;   check "KNOWN LIMITATION: hook in home; UTF-16 file is NOT seen by grep -l" 0
else
  echo "SKIP  UTF-16 scenario (neither iconv nor perl available)"
fi

echo "$((total-failures)) of $total scenarios passed"
[ "$failures" -eq 0 ]
