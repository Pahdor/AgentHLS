# Cross-server deployment template

The public repository intentionally contains no private hostnames, usernames,
jump-host addresses, or credentials. Keep those values in a local SSH config
and in the private handoff document.

The supported topology is:

```text
V80 HLS evaluator
  └─ localhost:8000/v1
       └─ SSH local forward
            └─ A6000 vLLM on 127.0.0.1:8000
```

The V80 side owns the SSH tunnel and runs
`evaluation/v80/run_baseline.sh`. The A6000 side runs
`deployment/a6000/start_vllm.sh` and never needs to expose the vLLM port on a
public interface.

Before the model run, validate the route with a temporary HTTP server, then
check `/v1/models`, and only then run Bench4HLS. Keep the private SSH
configuration outside this repository.
