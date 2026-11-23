#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODEL_ID="${QWEN_MODEL_ID:-Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8}"
MODEL_DIR="${QWEN_MODEL_DIR:-${ROOT}/models/Qwen3-Coder-30B-A3B-Instruct-FP8}"
MAX_WORKERS="${QWEN_DOWNLOAD_WORKERS:-8}"

MODELSCOPE_BIN="${MODELSCOPE_BIN:-}"
if [[ -z "${MODELSCOPE_BIN}" ]]; then
  for candidate in "$(command -v modelscope 2>/dev/null || true)"; do
    if [[ -x "${candidate}" ]]; then
      MODELSCOPE_BIN="${candidate}"
      break
    fi
  done
fi
[[ -x "${MODELSCOPE_BIN}" ]] || {
  echo "modelscope CLI is not available" >&2
  exit 1
}

mkdir -p "${MODEL_DIR}"
exec "${MODELSCOPE_BIN}" download \
  --model "${MODEL_ID}" \
  --local_dir "${MODEL_DIR}" \
  --max-workers "${MAX_WORKERS}"
