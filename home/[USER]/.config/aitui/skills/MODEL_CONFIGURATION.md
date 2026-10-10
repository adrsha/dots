# Model configuration

The model-powered scripts use an OpenAI-compatible **Chat Completions API**,
not a provider-specific SDK or CLI. Python 3.10+ is required. The API client uses
only the standard library; MCP evaluation additionally needs
`pip install -r mcp-builder/scripts/requirements.txt`. Skill validation and
packaging additionally require `pip install PyYAML`.

## Settings

| Setting | Environment variable | Fallback |
| --- | --- | --- |
| API base URL, including `/v1` when required | `BIG_THINKER_URL` | Required; no default endpoint |
| API key | `BIG_THINKER_API_KEY` | Omitted for unauthenticated local servers |
| Model identifier | `MODEL_NAME` | Set automatically by aitui to its active model; no hard-coded default |

When invoked through aitui, scripts inherit its currently selected model via
`MODEL_NAME`, including after model switches. No separate model setup is needed.
`--model` is an optional explicit override for standalone runs. The scripts read your existing
`BIG_THINKER_URL` and `BIG_THINKER_API_KEY` directly; no renamed copies are needed. Requests go to
`<base-url>/chat/completions`. The endpoint/model must support function tool calls
for skill-trigger tests and MCP evaluation. Description improvement only needs
text generation. No automatic provider fallback or model selection occurs.

```bash
# Local server (use the exact identifier your server exposes)
export BIG_THINKER_URL=http://localhost:8000/v1
# Standalone runs only (aitui supplies this automatically):
export MODEL_NAME=your-local-model
# BIG_THINKER_API_KEY is optional if your local server does not require authentication.

# Hosted endpoint
# export BIG_THINKER_URL=https://your-provider.example/v1
# export BIG_THINKER_API_KEY=your-api-key
# export MODEL_NAME=your-model-name
```

Run skill-creator modules from its directory:

```bash
cd skill-creator
python -m scripts.run_eval --eval-set /path/to/eval.json --skill-path /path/to/skill
python -m scripts.improve_description --eval-results /path/to/results.json --skill-path /path/to/skill
python -m scripts.run_loop --eval-set /path/to/eval.json --skill-path /path/to/skill --report none
```

Skill tooling reads the purpose statement from sibling `description.md` and the
name/body from `SKILL.md`. Optimization prints results; it does not overwrite the
skill. Copy the chosen description to `description.md` after review.

Trigger evaluation is a **routing simulation**: it offers an optional `read_skill`
function whose description contains the skill name and purpose, and checks whether
the model selects that function with the matching name. It does not test any host's
native discovery, instruction-file loading, or real filesystem reads. API errors
are recorded as failed evaluations, including for queries that should not trigger.
`--timeout` sets the trigger request socket timeout (default 30 seconds); description
and MCP requests use 300 seconds. These are request timeouts, not whole-run deadlines.

```bash
# From the skills directory; server arguments depend on your MCP server.
python mcp-builder/scripts/evaluation.py -t stdio -c python -a server.py eval.xml
```

MCP evaluation translates MCP schemas into function tools, executes all tool calls
in each model message, returns correlated tool results, and stops after at most 50
model rounds per question. Empty tool lists are supported.

License, copyright, and legal attribution files are intentionally unchanged.
