#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BENCH="${ROOT}/vendor/Bench4HLS"
PYTHON="${BENCH4HLS_PYTHON:-${ROOT}/.venv-v80/bin/python}"
BASE_URL="${BENCH4HLS_BASE_URL:-http://127.0.0.1:8100/v1}"
EXPECTED_MODEL="${BENCH4HLS_MODEL:-Qwen3-Coder-30B-A3B-Instruct-FP8}"

[[ -x "${PYTHON}" ]] || { echo "Missing V80 Python: ${PYTHON}" >&2; exit 1; }
command -v vitis_hls >/dev/null 2>&1 || { echo "vitis_hls is not on PATH" >&2; exit 1; }

prompts=$(find "${BENCH}/benchmark/prompts" -type f -name '*_prompt.txt' | wc -l)
references=$(find "${BENCH}/benchmark/reference_design" -type f -name '*_ref.cpp' | wc -l)
testbenches=$(find "${BENCH}/benchmark/testbenches" -type f -name '*_tb.cpp' | wc -l)
[[ "${prompts}" -eq 170 && "${references}" -eq 170 && "${testbenches}" -eq 170 ]] || {
  echo "Bench4HLS inventory mismatch: prompts=${prompts}, references=${references}, testbenches=${testbenches}" >&2
  exit 1
}

models_json="$(curl --fail --silent --show-error --max-time 20 "${BASE_URL}/models")" || {
  echo "Cannot reach A6000 API: ${BASE_URL}" >&2
  exit 1
}
MODEL_JSON="${models_json}" EXPECTED_MODEL="${EXPECTED_MODEL}" "${PYTHON}" - <<'PY'
import json
import os
payload = json.loads(os.environ["MODEL_JSON"])
expected = os.environ["EXPECTED_MODEL"]
available = [item.get("id") for item in payload.get("data", [])]
if expected not in available:
    raise SystemExit(f"Expected model {expected!r} is unavailable: {available}")
print("A6000 model available:", expected)
PY

echo "Vitis HLS: $(command -v vitis_hls)"
echo "Bench4HLS cases: 170"
echo "A6000 API: ${BASE_URL}"
echo "V80 environment: ok"
