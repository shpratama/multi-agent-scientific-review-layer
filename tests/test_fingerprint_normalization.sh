#!/usr/bin/env bash
# Re-runnable test for PROTOCOL.md section 10.1 (fingerprints), Bash recipe.
#
# Extracts the first ```bash block under "### 10.1" (the fingerprint function) from PROTOCOL.md and
# tests THAT. Fixtures are generated in-script from exact bytes under mktemp. The expected digests
# are the SAME literals used by tests/test_fingerprint_normalization.ps1, so a pass in both shells
# means the two recipes agree with each other, not just with themselves.
#
#   bash tests/test_fingerprint_normalization.sh
#
# Exit code 0 = all assertions held; 1 = at least one did not.
# Tested with perl 5.38 and GNU coreutils 8.32 (Git for Windows). Linux/macOS: not tested.
set -u

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# PROTOCOL.md is CRLF in a Windows autocrlf checkout; strip CR or the extracted function is corrupted.
block="$(tr -d '\r' < "$repo/PROTOCOL.md" | awk '/^### 10\.1 /{s=1} s && /^```bash/{b=1; next} s && b && /^```/{exit} s && b{print}')"
[ -n "$block" ] || { echo "FAIL: no bash block found under PROTOCOL.md section 10.1"; exit 1; }
eval "$block"
command -v fingerprint >/dev/null 2>&1 || type fingerprint >/dev/null 2>&1 || { echo "FAIL: the 10.1 block did not define fingerprint()"; exit 1; }

D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT
printf 'alpha\nbeta\ngamma\n'          > "$D/lf.txt"
printf 'alpha\r\nbeta\r\ngamma\r\n'    > "$D/crlf.txt"
printf 'alpha\r\nbeta\ngamma\r\n'      > "$D/mixed.txt"
printf 'alpha\rbeta\r\n'               > "$D/lonecr.txt"
printf 'alpha\r\nbeta'                 > "$D/noeol.txt"
printf 'alpha\r\nbeta\r'               > "$D/trailcr.txt"
printf '\357\273\277alpha\r\nbeta\r\n' > "$D/bom_crlf.txt"
printf '\000\015\012\377\015\012\177\015' > "$D/binary.bin"

failures=0; total=0
check() {  # NAME ACTUAL EXPECTED
  total=$((total+1))
  if [ "$2" = "$3" ]; then echo "PASS  $1"
  else failures=$((failures+1)); echo "FAIL  $1"; echo "        got      $2"; echo "        expected $3"; fi
}

echo "--- 8 fixtures x 2 modes, against digests shared with the PowerShell test ---"
while read -r name lfhex rawhex; do
  [ -z "$name" ] && continue
  check "$name lf"  "$(fingerprint "$D/$name" lf)"  "sha256-lf:$lfhex"
  check "$name raw" "$(fingerprint "$D/$name" raw)" "sha256-raw:$rawhex"
done <<'TABLE'
lf.txt       4fdbc441ea7b546100e086ac1e4fc5ae6749b7314311c99db05be450eca12996 4fdbc441ea7b546100e086ac1e4fc5ae6749b7314311c99db05be450eca12996
crlf.txt     4fdbc441ea7b546100e086ac1e4fc5ae6749b7314311c99db05be450eca12996 c8dba68945249de9b4faed72b89e041e3df77ffff885122599e6c2f7c65a68b2
mixed.txt    4fdbc441ea7b546100e086ac1e4fc5ae6749b7314311c99db05be450eca12996 10ed6683680f49e00196f995b0e87f9a48fe44e16119f338fdd63d4ac4aed2e3
lonecr.txt   558bbba819eb2c82a290db0729b065f60c1934745f4b5ed0be0a05a4f8c4f281 32a71235b900461a387ce14c151e761c06330bf8efc5370c70b5f117c1d901f9
noeol.txt    bbfb79e82216bd2db1ad2c507d44ddf80aeb12f64f9562056afe93aad43154d9 4854aaef74503959fd26363306e2ef967a9d50bdda90d033a3a4acacbbd57547
trailcr.txt  aafd61de9a3a1d5bddc8f2c70795cce8e095a3acf056f3ac9cdd5e6121e86530 9f582519fb21e19307c20b3c7734a71fc7631d4ae779b8c219e361eb8c40271c
bom_crlf.txt bf7a11618542a830d64e5aeb970f1c6cc67cfce607ced9603efb2a696b9b2160 c3660080e3eee0ef1c03dd97ef4bb91bb952cf45f1ac2d52b2360e05fb201968
binary.bin   d80d66c7ab3f740bc73e2642caa67712cfb0add253425da2bd2efec06b3feff5 eb5f875e5217953e083261e490e017d22abd45308947539cc52509c182530e3e
TABLE

echo "--- properties ---"
check "default mode is lf" "$(fingerprint "$D/crlf.txt")" "$(fingerprint "$D/crlf.txt" lf)"
check "LF, CRLF and mixed files share one lf fingerprint" "$(for f in lf crlf mixed; do fingerprint "$D/$f.txt" lf; done | sort -u | wc -l | tr -d ' ')" "1"
check "LF and CRLF files have DIFFERENT raw fingerprints" "$([ "$(fingerprint "$D/lf.txt" raw)" = "$(fingerprint "$D/crlf.txt" raw)" ] && echo same || echo different)" "different"
check "a lone CR is NOT normalized away" "$([ "$(fingerprint "$D/lonecr.txt" lf)" = "$(fingerprint "$D/lf.txt" lf)" ] && echo same || echo different)" "different"
check "output is lowercase hex only" "$(fingerprint "$D/bom_crlf.txt" lf | grep -cE '^sha256-(lf|raw):[0-9a-f]{64}$')" "1"

echo "--- error path: a missing file must fail loudly, never yield a plausible hash ---"
out="$(fingerprint "$D/does-not-exist.txt" lf 2>/dev/null)"; rc=$?
check "missing file: non-zero exit" "$([ "$rc" -ne 0 ] && echo nonzero || echo zero)" "nonzero"
check "missing file: nothing printed on stdout" "$out" ""

out="$(fingerprint "$D/lf.txt" typo 2>/dev/null)"; rc=$?
check "invalid mode: non-zero exit" "$([ "$rc" -ne 0 ] && echo nonzero || echo zero)" "nonzero"
check "invalid mode: nothing printed on stdout (no 'sha256-typo:' record)" "$out" ""

# An upstream failure must not turn into a plausible hash of EMPTY input (e3b0c442...).
mkdir -p "$D/stubbin"; printf '#!/bin/sh\nexit 3\n' > "$D/stubbin/perl"; chmod +x "$D/stubbin/perl"
out="$(PATH="$D/stubbin:$PATH" fingerprint "$D/crlf.txt" lf 2>/dev/null)"; rc=$?
check "failing perl: non-zero exit" "$([ "$rc" -ne 0 ] && echo nonzero || echo zero)" "nonzero"
check "failing perl: nothing printed on stdout (no hash of empty input)" "$out" ""

cp "$D/lf.txt" "$D/unreadable.txt"; chmod 000 "$D/unreadable.txt" 2>/dev/null
if [ ! -r "$D/unreadable.txt" ]; then
  out="$(fingerprint "$D/unreadable.txt" lf 2>/dev/null)"; rc=$?
  check "unreadable file: non-zero exit" "$([ "$rc" -ne 0 ] && echo nonzero || echo zero)" "nonzero"
  check "unreadable file: nothing printed on stdout" "$out" ""
else
  echo "SKIP  unreadable-file case (chmod 000 had no effect here: running as root, or a filesystem without POSIX modes)"
fi
chmod 644 "$D/unreadable.txt" 2>/dev/null

echo "--- git multi-device scenario (scratch repos) ---"
if command -v git >/dev/null 2>&1; then
  G="$D/git"; mkdir -p "$G"
  git init -q "$G/origin" >/dev/null 2>&1
  git -C "$G/origin" config core.autocrlf false; git -C "$G/origin" config user.email test@example.invalid; git -C "$G/origin" config user.name test
  printf 'a = 1;\nb = 2;\n' > "$G/origin/dep.m"
  git -C "$G/origin" add dep.m >/dev/null 2>&1; git -C "$G/origin" commit -q -m x >/dev/null 2>&1
  git -c core.autocrlf=true  clone -q "$G/origin" "$G/winlike"  >/dev/null 2>&1
  git -c core.autocrlf=input clone -q "$G/origin" "$G/unixlike" >/dev/null 2>&1
  check "the autocrlf=true checkout really has CRLF on disk" "$(tr -cd '\r' < "$G/winlike/dep.m" | wc -c | tr -d ' ' | awk '{print ($1>0)?"yes":"no"}')" "yes"
  check "raw fingerprints DIFFER between the two checkouts (the false-STALE problem)" "$([ "$(fingerprint "$G/winlike/dep.m" raw)" = "$(fingerprint "$G/unixlike/dep.m" raw)" ] && echo same || echo different)" "different"
  check "lf fingerprints are IDENTICAL across both checkouts and the origin" "$(for f in winlike unixlike origin; do fingerprint "$G/$f/dep.m" lf; done | sort -u | wc -l | tr -d ' ')" "1"
else
  echo "SKIP  git not found; multi-device scenario not exercised"
fi

echo "$((total-failures)) of $total assertions passed"
[ "$failures" -eq 0 ]
