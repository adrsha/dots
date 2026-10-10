"""Small dependency-free client for OpenAI-compatible Chat Completions APIs."""

import json
import os
import urllib.error
import urllib.request


def resolve_model(model=None):
    value = model or os.environ.get("MODEL_NAME")
    if not value:
        raise ValueError("Set MODEL_NAME (provided automatically by aitui), or pass --model.")
    return value


class ModelClient:
    def __init__(self, base_url=None, api_key=None, timeout=300):
        self.base_url = (base_url or os.environ.get("BIG_THINKER_URL") or "").rstrip("/")
        if not self.base_url:
            raise ValueError("Set BIG_THINKER_URL or pass base_url.")
        self.api_key = api_key if api_key is not None else os.environ.get("BIG_THINKER_API_KEY")
        self.timeout = timeout

    def chat(self, messages, model=None, tools=None):
        payload = {"model": resolve_model(model), "messages": messages}
        if tools:
            payload.update(tools=tools, tool_choice="auto")
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = "Bearer " + self.api_key
        request = urllib.request.Request(self.base_url + "/chat/completions",
                                         data=json.dumps(payload).encode(), headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                result = json.load(response)
        except urllib.error.HTTPError as exc:
            # Do not expose credentials or response bodies in error messages.
            status = exc.code
            exc.close()
            raise RuntimeError(f"Model API returned HTTP {status}") from exc
        try:
            message = result["choices"][0]["message"]
        except (KeyError, IndexError, TypeError) as exc:
            raise RuntimeError("Model API returned no chat message") from exc
        if not isinstance(message, dict):
            raise RuntimeError("Model API returned an invalid chat message")
        return message
