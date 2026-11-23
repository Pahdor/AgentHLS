# V80 Bench4HLS baseline

The V80 server owns benchmark generation and evaluation. It does not install
vLLM or download the Qwen model. The model endpoint is the OpenAI-compatible
vLLM API provided by the A6000 server through the SSH tunnel.

## Prepare the V80 environment

The V80 host needs Python evaluation dependencies and the Xilinx HLS
toolchain. From the repository root, run:

```bash
./evaluation/v80/setup.sh
```

Source the Vitis HLS environment and check the tunnel before running:

```bash
./evaluation/v80/check_env.sh
```

The check validates the 170-task Bench4HLS inventory, `vitis_hls`, the SSH
tunnel, and the model advertised by the A6000 API.

The runner defaults to the V80-local tunnel endpoint
`http://127.0.0.1:8100/v1`. Override it with `BENCH4HLS_BASE_URL`.

## Optional local configuration

```bash
cd vendor/Bench4HLS
cp bench4hls_config.example.json bench4hls_config.json
```

The local configuration is ignored by Git. Environment variables supplied to
`run_baseline.sh` override its model, API URL, result directory, and output
file.

## Run the first baseline

Use `BENCH4HLS_PASS_AT_K=1` for the first complete path. Increase it only after
the single-trajectory path has been validated.

```bash
BENCH4HLS_PYTHON="$PWD/.venv-v80/bin/python" \
BENCH4HLS_BASE_URL="http://127.0.0.1:8100/v1" \
BENCH4HLS_PASS_AT_K=1 \
  ./evaluation/v80/run_baseline.sh
```

The vendored runner calls `/v1/models` before generation and
`/v1/chat/completions` for each task, then runs extraction, compilation,
simulation, synthesis, and the reference PPA comparison. Results are written
under `results/`, which is ignored by Git.
