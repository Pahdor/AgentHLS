#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UV_BIN="${UV_BIN:-$(command -v uv || true)}"
ENV_DIR="${QWEN_ENV_DIR:-${ROOT}/.venv-a6000}"

# Use the domestic PyPI mirror by default. Override UV_INDEX_URL when needed.
export UV_INDEX_URL="${UV_INDEX_URL:-https://mirrors.aliyun.com/pypi/simple/}"
export UV_HTTP_TIMEOUT="${UV_HTTP_TIMEOUT:-120}"
export UV_HTTP_RETRIES="${UV_HTTP_RETRIES:-5}"

[[ -x "${UV_BIN}" ]] || {
  echo "uv is required. Install it from https://docs.astral.sh/uv/" >&2
  exit 1
}

cd "${ROOT}"
if [[ -L "${ENV_DIR}" ]]; then
  rm "${ENV_DIR}"
fi
UV_PROJECT_ENVIRONMENT="${ENV_DIR}" "${UV_BIN}" sync --group a6000
UV_PROJECT_ENVIRONMENT="${ENV_DIR}" "${UV_BIN}" run --group a6000 python - <<'PY'
import torch
import transformers
import vllm

print("torch", torch.__version__, "cuda", torch.version.cuda)
print("transformers", transformers.__version__)
print("vllm", vllm.__version__)
print("cuda_available", torch.cuda.is_available())
PY
