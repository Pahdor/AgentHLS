# V80 Bench4HLS baseline

The V80 server owns benchmark generation and evaluation. It does not download
or load the Qwen model. The model endpoint is the OpenAI-compatible vLLM API
provided by the A6000 server through the SSH tunnel described in
`handoff_llm_hls_servers.md`.

## Prepare the local configuration

```bash
cd vendor/Bench4HLS
cp bench4hls_config.example.json bench4hls_config.json
```

Keep `bench4hls_config.json` local if the endpoint or tool paths differ. It is
ignored by the repository. Set `openai_compatible.base_url` to the V80-local
tunnel endpoint, normally `http://127.0.0.1:8000/v1`.

Install the benchmark dependencies on V80:

```bash
python3 -m venv .venv-bench4hls
. .venv-bench4hls/bin/activate
python -m pip install -r vendor/Bench4HLS/requirements.txt
```

Source the Vitis HLS environment before running the benchmark. The first
baseline should use `BENCH4HLS_PASS_AT_K=1`. Increase it only after the
single-trajectory path has been validated.

```bash
BENCH4HLS_PYTHON="$PWD/.venv-bench4hls/bin/python" \
  ./evaluation/v80/run_baseline.sh
```

The vendored runner includes an `openai_compatible` backend that calls
`/v1/models` before generation and `/v1/chat/completions` for each task.
Results are written under `results/`, which is ignored by Git.
