"""OpenAI-compatible backend for vLLM and other local API servers."""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

from .base import ALPACA_SYSTEM, ModelBackend


class OpenAICompatibleBackend(ModelBackend):
    def __init__(
        self,
        model_name: str,
        base_url: str = "http://127.0.0.1:8000/v1",
        api_key: str | None = None,
        max_new_tokens: int = 8192,
        temperature: float = 1.0,
        timeout: int = 1200,
    ):
        self.model_name = model_name
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY", "EMPTY")
        self.max_new_tokens = max_new_tokens
        self.temperature = temperature
        self.timeout = timeout
        self._check_connection()

    def _request(self, path: str, payload: dict | None = None) -> dict:
        data = None if payload is None else json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(
            f"{self.base_url}{path}",
            data=data,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.api_key}",
            },
            method="POST" if payload is not None else "GET",
        )
        with urllib.request.urlopen(request, timeout=self.timeout) as response:
            return json.loads(response.read().decode("utf-8"))

    def _check_connection(self) -> None:
        try:
            models = self._request("/models")
        except (OSError, urllib.error.URLError, json.JSONDecodeError) as exc:
            raise RuntimeError(
                f"Cannot reach OpenAI-compatible endpoint at {self.base_url}"
            ) from exc
        available = {item.get("id") for item in models.get("data", [])}
        if self.model_name not in available:
            raise RuntimeError(
                f"Model {self.model_name!r} is not advertised by {self.base_url}. "
                f"Available models: {sorted(available)}"
            )

    def generate(self, instruction: str) -> str:
        payload = {
            "model": self.model_name,
            "messages": [
                {"role": "system", "content": ALPACA_SYSTEM},
                {"role": "user", "content": instruction},
            ],
            "temperature": self.temperature,
            "max_tokens": self.max_new_tokens,
            "stream": False,
        }
        try:
            response = self._request("/chat/completions", payload)
        except (OSError, urllib.error.URLError, json.JSONDecodeError) as exc:
            raise RuntimeError("OpenAI-compatible generation request failed") from exc
        try:
            return response["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError) as exc:
            raise RuntimeError(f"Malformed chat completion response: {response!r}") from exc
