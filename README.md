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

Clone the repository, prepare a Python environment containing PyTorch,
Transformers, and vLLM, then download the model with:

```bash
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

Install the benchmark dependencies and copy the local configuration:

```bash
python3 -m venv .venv-bench4hls
. .venv-bench4hls/bin/activate
python -m pip install -r vendor/Bench4HLS/requirements.txt
cp vendor/Bench4HLS/bench4hls_config.example.json \
   vendor/Bench4HLS/bench4hls_config.json
```

Source the Vitis HLS environment, establish the SSH local forward, set the
local API URL in `bench4hls_config.json`, and run the first single-sample
baseline:

```bash
BENCH4HLS_PYTHON="$PWD/.venv-bench4hls/bin/python" \
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
