# Bootstrap

This agent (Fly) needs to configure itself on first run. Follow these steps.

## 1. Configure openclaw.json

Write `/var/lib/openclaw/state/openclaw.json` with this config:

```json
{
    "meta": {
        "lastTouchedVersion": "2026.3.12"
    },
    "models": {
        "mode": "merge",
        "providers": {
            "litellm": {
                "baseUrl": "http://10.2.0.1:4000/v1",
                "apiKey": "dummy",
                "api": "openai-completions",
                "models": [
                    {
                        "id": "anthropic/claude-sonnet-4-6",
                        "name": "Claude Sonnet via LiteLLM",
                        "reasoning": false,
                        "input": ["text", "image"],
                        "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
                        "contextWindow": 200000,
                        "maxTokens": 8192
                    },
                    {
                        "id": "anthropic/claude-opus-4-6",
                        "name": "Claude Opus via LiteLLM",
                        "reasoning": false,
                        "input": ["text", "image"],
                        "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
                        "contextWindow": 200000,
                        "maxTokens": 8192
                    },
                    {
                        "id": "anthropic/claude-haiku-4-5",
                        "name": "Claude Haiku via LiteLLM",
                        "reasoning": false,
                        "input": ["text", "image"],
                        "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
                        "contextWindow": 200000,
                        "maxTokens": 8192
                    },
                    {
                        "id": "openrouter/free",
                        "name": "OpenRouter Free via LiteLLM",
                        "reasoning": false,
                        "input": ["text"],
                        "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
                        "contextWindow": 128000,
                        "maxTokens": 4096
                    }
                ]
            }
        }
    },
    "agents": {
        "defaults": {
            "model": {
                "primary": "litellm/anthropic/claude-sonnet-4-6",
                "fallbacks": [
                    "litellm/anthropic/claude-opus-4-6",
                    "litellm/anthropic/claude-haiku-4-5",
                    "litellm/openrouter/free"
                ]
            },
            "imageModel": "litellm/anthropic/claude-haiku-4-5",
            "workspace": "/var/lib/openclaw/.openclaw/workspace",
            "compaction": {
                "mode": "safeguard"
            }
        }
    },
    "commands": {
        "native": "auto",
        "nativeSkills": "auto",
        "restart": true,
        "ownerDisplay": "raw"
    },
    "channels": {
        "whatsapp": {
            "enabled": true,
            "dmPolicy": "allowlist",
            "selfChatMode": true,
            "allowFrom": ["+5854802030"],
            "groupPolicy": "disabled",
            "debounceMs": 0,
            "mediaMaxMb": 50
        }
    },
    "gateway": {
        "mode": "local",
        "auth": {
            "mode": "token",
            "token": "fly-agent-token-change-me"
        }
    },
    "plugins": {
        "entries": {
            "whatsapp": {
                "enabled": true
            },
            "exa-search": {
                "enabled": true
            }
        },
        "load": {
            "paths": []
        }
    }
}
```

## 2. Copy workspace files

Copy the bootstrap workspace files into place:

```bash
cp -r /var/lib/openclaw/.openclaw/workspace-bootstrap/* /var/lib/openclaw/.openclaw/workspace/ 2>/dev/null || true
```

## 3. Link WhatsApp

Link this gateway to the same WhatsApp number as a separate linked device:

```bash
openclaw channels login --channel whatsapp
```

Scan the QR code with WhatsApp → Linked Devices → Link a Device.

## 4. Restart the gateway

```bash
systemctl restart openclaw-gateway
```

## 5. Verify

Send yourself a WhatsApp message starting with "aldo" — this agent should respond.
Messages NOT starting with "aldo" should be ignored by this agent.

## Notes

- The "aldo" prefix filter is enforced by the agent's instructions (IDENTITY.md + SOUL.md).
- This agent has NO access to slot1 data or credentials.
- LiteLLM proxy is at http://10.2.0.1:4000 (hypervisor bridge for slot2).
- Exa search is available for internet searches if configured.
