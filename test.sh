#!/bin/bash

set -o nounset

print_project_dir() {
  (
    cd "$(dirname "$0")"
    pwd
  )
}

readonly PROJECT_DIR="$(print_project_dir)"
readonly TEST_DIR="${PROJECT_DIR}/test"
readonly TEMP_DIR="${PROJECT_DIR}/z_tmp"
readonly EXE_FILE=${PROJECT_DIR}/bin/app

readonly MAX_ID_JSON=6
readonly MAX_ID_LEX=3
readonly MAX_ID_PARSE=2
readonly MAX_ID_COMPILE=29

ERRS=""

run_test_json() {
  local infile="$1"; shift

  cat $infile | bin/json_tester
}

run_lex() {
  local infile="$1"; shift

  cat $infile | bin/lexer
}

run_parse() {
  local infile="$1"; shift

  cat $infile | bin/parser
}

run_codegen() {
  local infile="$1"; shift

  cat $infile | bin/codegen
}

# --------------------------------

setup() {
  mkdir -p ./z_tmp
  mkdir -p ./bin
}

build() {
  set -o errexit

  local opts="--error-trace"

  ./build_container.sh

  set +o errexit
}

postproc() {
  local stage="$1"; shift

  if [ "$ERRS" = "" ]; then
    echo "${stage}: ok"
  else
    echo "----"
    echo "FAILED: ${ERRS}" | sed -e 's/,/\n  /g'
    exit 1
  fi
}

get_ids() {
  local max_id="$1"; shift

  if [ $# -eq 1 ]; then
    echo "$1"
  else
    seq 1 $max_id
  fi
}

# --------------------------------

test_json_nn() {
  local nn="$1"; shift

  echo "case ${nn}"

  local input_file="${TEST_DIR}/json/${nn}.json"
  local temp_json_file="${TEMP_DIR}/test.json"
  local exp_file="${TEST_DIR}/json/${nn}.json"

  run_test_json $input_file > $temp_json_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},${nn}_json"
    return
  fi

  ruby test/diff.rb json $exp_file $temp_json_file
  if [ $? -ne 0 ]; then
    # meld $exp_file $temp_json_file &

    ERRS="${ERRS},json_${nn}_diff"
    return
  fi
}

test_json() {
  local ids="$(get_ids $MAX_ID_JSON "$@")"

  for id in $ids; do
    test_json_nn $(printf "%02d" $id)
  done
}

# --------------------------------

test_lex_nn() {
  local nn="$1"; shift

  echo "case ${nn}"

  local input_file="${TEST_DIR}/lex/${nn}.vg.txt"
  local temp_tokens_file="${TEMP_DIR}/test.tokens.txt"
  local exp_file="${TEST_DIR}/lex/exp_${nn}.txt"

  run_lex $input_file > $temp_tokens_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},lex_${nn}_lex"
    return
  fi

  ruby test/diff.rb text $exp_file $temp_tokens_file
  if [ $? -ne 0 ]; then
    # meld $exp_file $temp_tokens_file &

    ERRS="${ERRS},lex_${nn}_diff"
    return
  fi
}

test_lex() {
  local ids="$(get_ids $MAX_ID_LEX "$@")"

  for id in $ids; do
    test_lex_nn $(printf "%02d" $id)
  done
}

# --------------------------------

test_parse_nn() {
  local nn="$1"; shift

  echo "case ${nn}"

  local input_file="${TEST_DIR}/parse/${nn}.vg.txt"
  local temp_tokens_file="${TEMP_DIR}/test.tokens.txt"
  local temp_vgt_file="${TEMP_DIR}/test.vgt.json"
  local exp_file="${TEST_DIR}/parse/exp_${nn}.vgt.json"

  echo "  lex" >&2
  run_lex $input_file > $temp_tokens_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},parse_${nn}_lex"
    return
  fi

  echo "  parse" >&2
  run_parse $temp_tokens_file \
    > $temp_vgt_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},parse_${nn}_parse"
    return
  fi

  ruby test/diff.rb json $exp_file $temp_vgt_file
  if [ $? -ne 0 ]; then
    # meld $exp_file $temp_vga_file &

    ERRS="${ERRS},parse_${nn}_diff"
    return
  fi
}

# --------------------------------

test_parse() {
  local ids="$(get_ids $MAX_ID_PARSE "$@")"

  for id in $ids; do
    test_parse_nn $(printf "%02d" $id)
  done
}

# --------------------------------

test_compile_do_skip() {
  local nn="$1"; shift

  for skip_nn in 25 26 27 28; do
    if [ "$nn" = "$skip_nn" ]; then
      return 0
    fi
  done

  return 1
}

test_compile_nn() {
  local nn="$1"; shift

  echo "case ${nn}"

  if (test_compile_do_skip "$nn"); then
    echo "  ... skip" >&2
    return
  fi

  local temp_tokens_file="${TEMP_DIR}/test.tokens.txt"
  local temp_vgt_file="${TEMP_DIR}/test.vgt.json"
  local temp_vga_file="${TEMP_DIR}/test.vga.txt"
  local local_errs=""
  local exp_file="${TEST_DIR}/compile/exp_${nn}.vga.txt"

  echo "  lex" >&2
  run_lex ${TEST_DIR}/compile/${nn}.vg.txt \
    > $temp_tokens_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},compile_${nn}_lex"
    local_errs="${local_errs},${nn}_lex"
    return
  fi

  echo "  parse" >&2
  run_parse $temp_tokens_file \
    > $temp_vgt_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},compile_${nn}_parse"
    local_errs="${local_errs},${nn}_parse"
    return
  fi

  echo "  codegen" >&2
  run_codegen $temp_vgt_file \
    > $temp_vga_file
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},compile_${nn}_codegen"
    local_errs="${local_errs},${nn}_codegen"
    return
  fi

  if [ "$local_errs" = "" ]; then
    ruby test/diff.rb asm $exp_file $temp_vga_file
    if [ $? -ne 0 ]; then
      # meld $exp_file $temp_vga_file &

      ERRS="${ERRS},compile_${nn}_diff"
      return
    fi
  fi
}

# --------------------------------

test_compile() {
  local ids="$(get_ids $MAX_ID_COMPILE "$@")"

  for id in $ids; do
    test_compile_nn $(printf "%02d" $id)
  done
}

# --------------------------------

test_all() {
  echo "==== json ===="
  test_json
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},all_json"
    return
  fi

  echo "==== lex ===="
  test_lex
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},all_lex"
    return
  fi

  echo "==== parse ===="
  test_parse
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},all_parse"
    return
  fi

  echo "==== compile ===="
  test_compile
  if [ $? -ne 0 ]; then
    ERRS="${ERRS},all_compile"
    return
  fi
}

# --------------------------------

container_main() {
  local cmd=
  if [ $# -ge 1 ]; then
    cmd="$1"; shift
  else
    cmd="show_tasks"
  fi

  setup
  build

  case $cmd in
    json | j* )      #task: Run json tests
      test_json "$@"
      postproc "json"

  ;; lex | l* )      #task: Run lex tests
      test_lex "$@"
      postproc "lex"

  ;; parse | p* )    #task: Run parse tests
      test_parse "$@"
      postproc "parse"

  ;; compile | c* )  #task: Run compile tests
      test_compile "$@"
      postproc "compile"

  ;; all | a* )      #task: Run all tests
      test_all
      postproc "all"

  ;; * )
      echo "Tasks:"
      grep '#task: ' $0 | grep -v grep
      ;;
  esac
}

# --------------------------------

in_container() {
  env | grep --quiet IN_CONTAINER
}

if (in_container); then
  container_main "$@"
else
  # Run in container
  ./docker.sh run bash test.sh "$@"
fi
