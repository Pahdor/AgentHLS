#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BENCH="${ROOT}/vendor/Bench4HLS"
PYTHON="${BENCH4HLS_PYTHON:-python3}"
CONFIG="${BENCH4HLS_CONFIG:-${BENCH}/bench4hls_config.json}"

[[ -f "${CONFIG}" ]] || {
  echo "Missing ${CONFIG}. Copy bench4hls_config.example.json to bench4hls_config.json and edit it." >&2
  exit 1
}
command -v "${PYTHON}" >/dev/null 2>&1 || {
  echo "Python interpreter not found: ${PYTHON}" >&2
  exit 1
}
command -v vitis_hls >/dev/null 2>&1 || {
  echo "vitis_hls is not on PATH. Source the Xilinx setup script first." >&2
  exit 1
}

export BENCH4HLS_CONFIG="${CONFIG}"
export PYTHONPATH="${BENCH}:${PYTHONPATH:-}"
cd "${BENCH}"
exec "${PYTHON}" bench4hls_runner.py \
  --backend openai_compatible \
  --pass@k "${BENCH4HLS_PASS_AT_K:-1}" \
  --ppa-evaluation \
  --verbose
