#!/bin/bash
set -eo pipefail

ROOT=$(readlink -f "$1")

gen_sed() {
  for K in "$@"
  do
    printf %s "s\\%$K%\\${!K}\\g; "
  done
}

unique_vars() {
  GREP_EXPR="%\S+?%"
  SED_EXPR="s\\%\\\\g"

  VARS_IN_PATHS=$(
    find "$ROOT" -type f | grep -ohP "$GREP_EXPR" | sed "$SED_EXPR")
  VARS_IN_CONTENT=$(
    grep -orhP "$GREP_EXPR" "$ROOT" | sed "$SED_EXPR")

  echo "$VARS_IN_PATHS $VARS_IN_CONTENT" \
    | tr ' ' '\n' \
    | sort -u
}

validate_all_set() {
  VAR_NOT_SET=0
  for K in "$@"
  do
    V="${!K}"
    if [ -z "$V" ]; then
      VAR_NOT_SET=1
    fi
    echo >&2 "  $K=$V"
  done
  if [ $VAR_NOT_SET -eq "1" ]; then
    echo >&2 "All variables not set, aborting"
    exit 1
  fi
}

echo >&2 "Source template:"
echo >&2 "  $ROOT"
echo >&2 "Target:"
echo >&2 "  $PWD"
echo >&2 "Variables:"

mapfile -t UNIQUE_VARS < <(unique_vars)
validate_all_set "${UNIQUE_VARS[@]}"
SED_EXPR=$(gen_sed "${UNIQUE_VARS[@]}")

echo >&2 "SED expression:"
echo >&2 "  $SED_EXPR"
echo >&2
echo >&2 "Pipe to \`sh\` to execute:"
echo >&2

echo "set -xe"
echo "SED_EXPR='$SED_EXPR'"
find "$ROOT" -type f | while read -r FILE
do
  [ "$FILE" == "$ROOT" ] && continue
  REL_FILE="${FILE#$ROOT/}"
  NEW_FILE="$PWD/$(sed "$SED_EXPR" <<<"${REL_FILE}")"
  echo "mkdir -p        '${NEW_FILE%/*}'"
  echo "sed \"\$SED_EXPR\" '$FILE' > '$NEW_FILE'"
done
