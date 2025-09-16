#!/bin/bash
#set -x
set -euo pipefail

# Optional args:
#   $1 = test name (without .s). If provided, run only this test.
#   $2 = ISS name (e.g., spike|whisper). If provided, run only this ISS.
#   $3 = config filename (with or without .json). If provided, run only this config.
test_arg="${1-}"         # may be empty
iss_arg="${2-}"          # may be empty
config_arg="${3-}"       # may be empty

# -----------------------
# Define full test matrix
# -----------------------
tests=(
  "test"
  "app_test"
  "bfs"
  "bf16"
  "litmus_example"
  "interrupt_enabled_test"
  "init_csr_test"
  "floyd_warshall"
  "fib"
  "fail_test"
  "fact"
  "exceptions"
  "dijkstras"
  "dfs"
  "check_excp"
  "test_equates"
  "test_alt_htif"
  "svinval"
  "skip_instr"
  "riescued_ld_test"
  "prim_tree"
  "test_wysiwyg"
  "test_vs_gstage_svadu"
  "test_vs_gstage"
  "test_vs"
  "test_template"
  "test_stee"
  "test_m_paging"
  "test_long"
  "test_interrupts"
  "test_excp"
  "user_interrupt_table"
  "union_find"
  # MP tests (included as you listed them)
  "mp_stack_test"
  "mp_par_5p_mode_default_test"
  "mp_par_5p"
  "mp_configjson"
  "mp_5p_semaphore"
  "mp_5p_lr_sc"
  "mp_5p"
  "mp_2p_petersons"
  "mp_2p"
)

iss_list=("spike" "whisper")

configs=(
  "basic_config.json"
  "config.json"
  "config_secure_0.json"
  "config_secure_1.json"
  "twogb_dram_config.json"
  "whisper_basic_config.json"
  "whisper_config.json"
  "whisper_secure_config.json"
)

# -----------------------
# Helper: membership test
# -----------------------
in_array() {
  local needle="$1"; shift
  local x
  for x in "$@"; do
    [[ "$x" == "$needle" ]] && return 0
  done
  return 1
}

# -----------------------
# Narrow matrices by args
# -----------------------
if [[ -n "$test_arg" ]]; then
  if ! in_array "$test_arg" "${tests[@]}"; then
    echo "ERROR: test '$test_arg' not in test list."
    echo "Hint: add it to 'tests' or correct the name."
    exit 1
  fi
  tests=("$test_arg")
fi

if [[ -n "$iss_arg" ]]; then
  if ! in_array "$iss_arg" "${iss_list[@]}"; then
    echo "ERROR: ISS '$iss_arg' not in iss_list (allowed: ${iss_list[*]})."
    exit 1
  fi
  iss_list=("$iss_arg")
fi

if [[ -n "$config_arg" ]]; then
  # normalize to *.json
  [[ "$config_arg" != *.json ]] && config_arg="${config_arg}.json"
  if ! in_array "$config_arg" "${configs[@]}"; then
    echo "ERROR: config '$config_arg' not in configs list."
    echo "Hint: add it to 'configs' or correct the name."
    exit 1
  fi
  configs=("$config_arg")
fi

# -----------------------
# Run all combinations
# -----------------------
mkdir -p workdir

for t in "${tests[@]}"; do
  test_src="riescue/dtest_framework/tests/${t}.s"
  if [[ ! -f "$test_src" ]]; then
    echo "SKIP: missing test source '$test_src'"
    continue
  fi

  for iss in "${iss_list[@]}"; do
    for cfg in "${configs[@]}"; do
      cfg_path="riescue/dtest_framework/lib/$cfg"
      if [[ ! -f "$cfg_path" ]]; then
        echo "SKIP: missing config '$cfg_path'"
        continue
      fi

      # Cleaner run dir: avoid slashes and long suffixes
      cfg_tag="${cfg%.json}"
      run_dir="workdir/${t}_${iss}_${cfg_tag}"

      rm -rf "$run_dir"
      mkdir -p "$run_dir"

      # Run quietly, log to per-run file
      log="$run_dir/${t}_run.log"
      if ! riescued -t "$test_src" \
            --run_iss \
            --iss "$iss" \
            --force_alignment \
            --run_dir "$run_dir" \
            --cpuconfig "$cfg_path" >"$log" 2>&1; then
        echo " test_template: $t | ISS: $iss | CONFIG: $cfg | FAILED (see $log)"
      else
        echo " test_template: $t | ISS: $iss | CONFIG: $cfg | PASSED"
      fi
    done
  done
done

