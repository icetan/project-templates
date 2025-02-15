#!/bin/bash
set -e

ROOT=$(readlink -f $1)
ROOT_LEN=$(expr length "$ROOT" + 2)

gen_sed() {
  EXPR=""
  for K in "$@"
  do
    V="${!K}"
    EXPR="$EXPR -e 's\\%$K%\\$V\\g'"
  done
  echo "$EXPR"
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
  VARS=$1

  VAR_NOT_SET=0
  for K in $VARS
  do
    V="${!K}"
    if [ -z "$V" ]; then
      VAR_NOT_SET=1
    fi
    echo "  $K=$V"
  done
  if [ $VAR_NOT_SET -eq "1" ]; then
    echo "All variables not set, aborting"
    exit
  fi
}

echo "Source template:"
echo "  $ROOT"
echo "Target:"
echo "  $(pwd)"
echo "Variables:"

UNIQUE_VARS=$(unique_vars)
validate_all_set "$UNIQUE_VARS"
SED_EXPR=$(gen_sed $UNIQUE_VARS)

echo "Using sed:"
echo "  $SED_EXPR"
echo "Copying:"
for FILE in $(find $ROOT -type f)
do
  REL_FILE=$(echo "$FILE" \
               | cut "-c$ROOT_LEN-")

  NEW_FILE=$(echo "$FILE" \
               | eval sed "$SED_EXPR" \
               | cut "-c$ROOT_LEN-")
  echo "  $REL_FILE -> $NEW_FILE"
  mkdir -p "$(dirname "$NEW_FILE")"
  eval "sed $SED_EXPR $FILE > $NEW_FILE"
done
