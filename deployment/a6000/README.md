# A6000 Qwen3-Coder-30B service

## Local artifacts

The A6000 host runs only the model service. Bench4HLS and its HLS toolchain
remain on the V80 host.

- The model directory is `models/Qwen3-Coder-30B-A3B-Instruct-FP8` after the
  repository is cloned, or any path supplied through `QWEN_MODEL_PATH`.
- The vLLM launcher is `deployment/a6000/start_vllm.sh`.
- Model weights and local runtime environments are ignored by Git.

## Runtime choice

Use `uv` to create the project-managed environment. Do not install the runtime
packages into the system Python:

```bash
./deployment/a6000/setup.sh
```

The setup creates `.venv-a6000/`, which is ignored by Git. The dependency
groups in the repository root `pyproject.toml` are the authoritative source.

The launcher defaults to physical GPU 3, tensor parallel size 1, and a 32K
context. Change `QWEN_VISIBLE_GPUS` only after checking active processes
with `nvidia-smi`.

## Start the service

After the model download has completed:

```bash
QWEN_VISIBLE_GPUS=3 \
QWEN_TENSOR_PARALLEL_SIZE=1 \
QWEN_MAX_MODEL_LEN=32768 \
./deployment/a6000/start_vllm.sh
```

The launcher writes a run directory under `vllm_runs/` containing GPU state,
package inventory, model metadata hashes, and the vLLM log.

