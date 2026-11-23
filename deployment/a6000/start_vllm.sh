#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHON="${QWEN_PYTHON:-python3}"
MODEL_PATH="${QWEN_MODEL_PATH:-${ROOT}/models/Qwen3-Coder-30B-A3B-Instruct-FP8}"
SERVED_MODEL="${QWEN_SERVED_MODEL:-Qwen3-Coder-30B-A3B-Instruct-FP8}"
VISIBLE_GPUS="${QWEN_VISIBLE_GPUS:-3}"
TP_SIZE="${QWEN_TENSOR_PARALLEL_SIZE:-1}"
PORT="${QWEN_VLLM_PORT:-8000}"
HOST="${QWEN_VLLM_HOST:-0.0.0.0}"
MAX_MODEL_LEN="${QWEN_MAX_MODEL_LEN:-32768}"
GPU_MEMORY_UTILIZATION="${QWEN_GPU_MEMORY_UTILIZATION:-0.90}"
RUN_ROOT="${QWEN_VLLM_RUN_ROOT:-${ROOT}/vllm_runs}"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="${RUN_ROOT}/${RUN_ID}"

[[ -x "${PYTHON}" ]] || { echo "Python entry point not found: ${PYTHON}" >&2; exit 1; }
[[ -d "${MODEL_PATH}" ]] || { echo "Model directory not found: ${MODEL_PATH}" >&2; exit 1; }
[[ -f "${MODEL_PATH}/config.json" ]] || { echo "Missing config.json in ${MODEL_PATH}" >&2; exit 1; }
[[ -f "${MODEL_PATH}/model.safetensors.index.json" ]] || {
  echo "Missing model.safetensors.index.json in ${MODEL_PATH}" >&2
  exit 1
}

mkdir -p "${RUN_DIR}"
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES="${VISIBLE_GPUS}"
export HF_HOME="${QWEN_HF_HOME:-${ROOT}/cache/huggingface}"
export VLLM_CACHE_ROOT="${QWEN_VLLM_CACHE:-${ROOT}/cache/vllm}"
mkdir -p "${HF_HOME}" "${VLLM_CACHE_ROOT}"

nvidia-smi --query-gpu=index,name,uuid,memory.total,memory.used,memory.free \
  --format=csv,noheader > "${RUN_DIR}/gpu_inventory_before.csv"
printf '%s\n' "${MODEL_PATH}" > "${RUN_DIR}/model_path.txt"
printf '%s\n' "${SERVED_MODEL}" > "${RUN_DIR}/served_model.txt"
printf '%s\n' "${VISIBLE_GPUS}" > "${RUN_DIR}/visible_gpus.txt"
printf '%s\n' "${TP_SIZE}" > "${RUN_DIR}/tensor_parallel_size.txt"
printf '%s\n' "${MAX_MODEL_LEN}" > "${RUN_DIR}/max_model_len.txt"
"${PYTHON}" -m pip freeze > "${RUN_DIR}/environment_pip_freeze.txt" || true
sha256sum "${MODEL_PATH}/config.json" \
  "${MODEL_PATH}/model.safetensors.index.json" \
  "${MODEL_PATH}/generation_config.json" 2>/dev/null \
  > "${RUN_DIR}/model_metadata_sha256.txt" || true

exec "${PYTHON}" -m vllm.entrypoints.openai.api_server \
  --model "${MODEL_PATH}" \
  --served-model-name "${SERVED_MODEL}" \
  --tensor-parallel-size "${TP_SIZE}" \
  --max-model-len "${MAX_MODEL_LEN}" \
  --max-num-seqs "${QWEN_MAX_NUM_SEQS:-4}" \
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}" \
  --generation-config vllm \
  --host "${HOST}" \
  --port "${PORT}" \
  2>&1 | tee "${RUN_DIR}/vllm.log"
