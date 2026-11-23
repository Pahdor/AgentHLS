# LLM-HLS two-server baseline

This repository contains the first reproducible baseline for HLS code
generation with Qwen3-Coder-30B-A3B-Instruct-FP8 and Bench4HLS.

The two servers have separate responsibilities:

```text
A6000                                V80
Qwen3-Coder-30B-A3B-Instruct-FP8    Bench4HLS + Vitis HLS
vLLM /v1 API  <── SSH tunnel ─────   OpenAI-compatible benchmark backend
```

The model weights and generated results are local artifacts. They are ignored
by Git. Keep the host-specific SSH handoff document outside the public
repository.

## Repository layout

```text
deployment/a6000/       Model download and vLLM service launcher
evaluation/v80/          Bench4HLS baseline runner
vendor/Bench4HLS/        170 HLS tasks, testbenches, reference designs, runner
docs/                    Public server handoff template
```

## A6000 server

Clone the repository and create the A6000 environment with `uv`:

```bash
./deployment/a6000/setup.sh
./deployment/a6000/download_model.sh
```

The launcher defaults to a single GPU and a 32K context:

```bash
QWEN_VISIBLE_GPUS=3 \
QWEN_TENSOR_PARALLEL_SIZE=1 \
QWEN_MAX_MODEL_LEN=32768 \
./deployment/a6000/start_vllm.sh
```

Set `QWEN_MODEL_PATH` when storing weights outside the repository. Keep the
vLLM service bound to loopback when using the SSH tunnel.

## V80 server

Create the V80 environment and copy the optional local configuration:

```bash
./evaluation/v80/setup.sh
cp vendor/Bench4HLS/bench4hls_config.example.json \
   vendor/Bench4HLS/bench4hls_config.json
```

Source the Vitis HLS environment, establish the SSH local forward, set the
local API URL in `bench4hls_config.json`, and run the first single-sample
baseline:

```bash
BENCH4HLS_PYTHON="$PWD/.venv-v80/bin/python" \
BENCH4HLS_BASE_URL="http://127.0.0.1:8100/v1" \
BENCH4HLS_PASS_AT_K=1 \
./evaluation/v80/run_baseline.sh
```

The vendored runner validates `/v1/models`, calls
`/v1/chat/completions`, extracts generated HLS code, and runs compilation,
simulation, synthesis, and reference PPA comparison.

## Private handoff

Use [docs/server-handoff-template.md](docs/server-handoff-template.md) for the
public workflow. Do not commit private IP addresses, usernames, SSH proxy
settings, tokens, or generated results.
