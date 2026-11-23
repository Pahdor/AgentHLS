#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UV_BIN="${UV_BIN:-$(command -v uv || true)}"
ENV_DIR="${BENCH4HLS_ENV_DIR:-${ROOT}/.venv-v80}"

[[ -x "${UV_BIN}" ]] || { echo "uv is required" >&2; exit 1; }
export UV_INDEX_URL="${UV_INDEX_URL:-https://mirrors.aliyun.com/pypi/simple/}"
export UV_HTTP_TIMEOUT="${UV_HTTP_TIMEOUT:-120}"
export UV_HTTP_RETRIES="${UV_HTTP_RETRIES:-5}"

cd "${ROOT}"
if [[ -L "${ENV_DIR}" ]]; then rm "${ENV_DIR}"; fi
UV_PROJECT_ENVIRONMENT="${ENV_DIR}" "${UV_BIN}" sync --group v80
"${ENV_DIR}/bin/python" - <<'PY'
import numpy
import pandas
print("numpy", numpy.__version__)
print("pandas", pandas.__version__)
print("v80 environment: ok")
PY
