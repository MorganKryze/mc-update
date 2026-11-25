#!/usr/bin/env bash
# End-to-end check of mc-update: a full run, the repository fallback, the pin checks,
# and the archive path with intact and altered archives. Needs docker, git, jq and
# network access.
set -euo pipefail

M=$(cd "$(dirname "$0")/.." && pwd)/bin/mc-update
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
cd "$W"

pass() { echo "ok    $*"; }
fail() {
	echo "FAIL  $*" >&2
	exit 1
}
# refuses DESCRIPTION PATTERN COMMAND... expects COMMAND to fail with PATTERN in its output.
refuses() {
	local desc=$1 pattern=$2 out
	shift 2
	if out=$("$@" 2>&1); then fail "$desc: accepted"; fi
	grep -q "$pattern" <<<"$out" || fail "$desc: unexpected message: $out"
	pass "$desc"
}
# altered NAME CHANGE builds an archive from the packed one, with CHANGE run inside it.
altered() {
	rm -rf unpack && mkdir unpack && tar -xzf "$archive" -C unpack
	(cd unpack/mc-src && eval "$2")
	tar -czf "$1" -C unpack mc-src
}

"$M" all -o dist >all.log 2>&1 || {
	cat all.log
	fail "all"
}
grep -q "Source matches sources.lock" all.log || fail "all: no pin check"
pass "all fetches, checks the pin, raises and packs"
archive=$(ls dist/*.tar.gz)

out=$(MC_UPDATE_REPOS="https://invalid.invalid/mc https://github.com/MorganKryze/mc" "$M" fetch -d fallback 2>&1)
grep -q "from https://github.com/MorganKryze/mc" <<<"$out" || fail "fallback: $out"
pass "fetch falls back to the next repository"

refuses "fetch refuses a commit missing from sources.lock" "is not in" \
	"$M" fetch -c 68f1d43f056a6015ab153d3b35f4df1e06787d7e -d unpinned
[ ! -e unpinned ] || fail "the refused source stayed on disk"
pass "a refused source leaves nothing on disk"

"$M" fetch -a "$archive" -d from-archive >/dev/null 2>&1 || fail "fetch -a on a packed archive"
cmp -s from-archive/go.mod from-archive/.mc-update/go.mod.orig || fail "fetch -a kept the raised go.mod"
[ ! -e from-archive/vendor ] || fail "fetch -a kept vendor/"
pass "fetch -a brings a packed archive back to the pinned source"

"$M" pack -d from-archive -o dist2 >/dev/null 2>&1 || fail "pack after fetch -a"
pass "pack works on a source fetched from an archive"

altered altered-code.tar.gz 'echo "// changed" >> main.go'
refuses "fetch -a refuses an archive with a changed source file" "differs from its pin" \
	"$M" fetch -a altered-code.tar.gz -d altered-code

altered altered-orig.tar.gz 'echo "// changed" >> .mc-update/go.mod.orig'
refuses "fetch -a refuses an archive with a changed original go.mod" "differs from its pin" \
	"$M" fetch -a altered-orig.tar.gz -d altered-orig

altered added-file.tar.gz 'echo "package main" > extra.go'
refuses "fetch -a refuses an archive with an added file" "differs from its pin" \
	"$M" fetch -a added-file.tar.gz -d added-file

cp "$archive" bad-sum.tar.gz
echo "0000000000000000000000000000000000000000000000000000000000000000  bad-sum.tar.gz" >bad-sum.tar.gz.sha256
refuses "fetch -a refuses an archive that differs from its .sha256" "does not match" \
	"$M" fetch -a bad-sum.tar.gz -d bad-sum

echo "// changed" >>fallback/main.go
refuses "pack refuses a source edited after fetch" "changed since fetch" \
	"$M" pack -d fallback -o dist3

echo "all checks passed"
