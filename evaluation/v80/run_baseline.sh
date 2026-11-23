#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BENCH="${ROOT}/vendor/Bench4HLS"
PYTHON="${BENCH4HLS_PYTHON:-${ROOT}/.venv-v80/bin/python}"
CONFIG="${BENCH4HLS_CONFIG:-${BENCH}/bench4hls_config.json}"
BASE_URL="${BENCH4HLS_BASE_URL:-http://127.0.0.1:8100/v1}"
MODEL="${BENCH4HLS_MODEL:-Qwen3-Coder-30B-A3B-Instruct-FP8}"
RUN_ID="${BENCH4HLS_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RESULT_DIR="${BENCH4HLS_OUTPUT_DIR:-${ROOT}/results/bench4hls/${RUN_ID}}"

[[ -f "${CONFIG}" ]] || CONFIG="${BENCH}/bench4hls_config.example.json"
command -v "${PYTHON}" >/dev/null 2>&1 || {
  echo "Python interpreter not found: ${PYTHON}" >&2
  exit 1
}
command -v vitis_hls >/dev/null 2>&1 || {
  echo "vitis_hls is not on PATH. Source the Xilinx setup script first." >&2
  exit 1
}

BENCH4HLS_BASE_URL="${BASE_URL}" \
BENCH4HLS_MODEL="${MODEL}" \
BENCH4HLS_PYTHON="${PYTHON}" \
"${ROOT}/evaluation/v80/check_env.sh"

export BENCH4HLS_CONFIG="${CONFIG}"
export BENCH4HLS_BASE_URL="${BASE_URL}"
export BENCH4HLS_MODEL="${MODEL}"
export BENCH4HLS_OUTPUT_DIR="${RESULT_DIR}"
export BENCH4HLS_OUTPUT_JSON="${RESULT_DIR}/output.json"
export PYTHONPATH="${BENCH}:${PYTHONPATH:-}"
cd "${BENCH}"
exec "${PYTHON}" bench4hls_runner.py \
  --backend openai_compatible \
  --pass@k "${BENCH4HLS_PASS_AT_K:-1}" \
  --ppa-evaluation \
  --verbose
