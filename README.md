# AI Tutor for Guided Network Traffic Analysis

A generative AI assistant (based on [pi-coding-agent](https://pi.dev)) that acts as a support tutor in hands-on lab sessions for **IP-based Networks** and **Telephony Systems**, capable of inspecting and explaining real network traffic —live or from `.pcap` captures— always connecting what is observed to the corresponding theoretical concept (OSI/TCP-IP model, encapsulation, addressing, flow control, etc.).

> Project developed under the **2nd Edition of Innovative Projects with AI (GenIA Programme)** — 2026 Call, University of Jaén.

## Academic Context

In the courses *IP-based Networks* (Master's in Telecommunications Engineering) and *Telephony Systems* (Bachelor's in Telematic Engineering), one of the main pedagogical challenges is the gap between layered theory and reading a real traffic capture, which is dense and unintuitive for students. This project introduces an AI agent with real network analysis capabilities (via MCP + Wireshark/tshark) into lab sessions, guided by its own pedagogical methodology:

- Always starts with a general summary before diving into packet-level detail.
- Links each header to its corresponding layer.
- Encourages students to predict what they will observe before capturing.
- Corrects conceptual errors by explaining the reason, not just the result.
- Applies explicit ethical constraints: captures only on lab networks or with express authorisation, and automatically redacts any sensitive data appearing in plaintext.

The agent is provider-agnostic; LiteLLM supports two configuration modes to reach the AI model (see [Architecture](#architecture)):

- **Via OpenRouter** — use an OpenRouter API key; OpenRouter routes the request to Gemini (or any other supported model).
- **Via Gemini directly** — use a Google Gemini API key and point LiteLLM straight at the Gemini endpoint.

Switching between modes is a matter of configuration (`config.yaml`), not redesign.

## Architecture

```mermaid
flowchart LR
    subgraph Student["Lab Session"]
        A["👤 Students"]
    end

    subgraph Agent["pi-coding-agent (AI tutor)"]
        B["Agent + Skill\nwireshark-analysis"]
    end

    subgraph Proxy["LiteLLM (local proxy)"]
        L["localhost:4000\nOpenAI-compatible API"]
    end

    subgraph Routing["AI Provider (configurable)"]
        direction TB
        OR["OpenRouter\n(gateway)"]
        GD["Gemini API\n(direct)"]
    end

    subgraph Model["AI Model"]
        C["Gemini\n(or other)"]
    end

    subgraph MCP["Wireshark MCP Server"]
        D["wireshark-mcp\n(Python venv)"]
        E["tshark"]
    end

    F[("Live traffic /\n.pcap captures")]

    A -- "question / hypothesis" --> B
    B -- "pedagogical explanation" --> A
    B <-- "reasoning" --> L
    L -- "option A: OpenRouter API key" --> OR
    L -- "option B: Gemini API key" --> GD
    OR --> C
    GD --> C
    B -- "analysis request" --> D
    D --> E
    E -- "inspects" --> F
    D -- "packets / summary\n(sensitive data redacted)" --> B
```

The agent converses with students and, for reasoning, delegates model calls to **LiteLLM**, a local proxy (default at `http://localhost:4000`) that exposes an OpenAI-compatible API. LiteLLM can forward requests to the AI model in two ways:

- **Option A — via OpenRouter:** set an OpenRouter API key in `auth.json` and configure the OpenRouter endpoint in `config.yaml`. OpenRouter acts as a gateway and routes the call to Gemini (or any other model it supports).
- **Option B — via Gemini directly:** set a Google Gemini API key in `auth.json` and point LiteLLM at the Gemini endpoint in `config.yaml`. No intermediate gateway is involved.

In both cases, switching provider or model only requires editing `config.yaml`, without touching the agent. Actual packet inspection is delegated to the Wireshark MCP server, which wraps `tshark` to read live traffic or `.pcap` files.

## Repository Structure

```
agent/
├── install-pi-agent.bat        # Installs pi-coding-agent and deploys the full configuration
├── settings.json               # Base agent configuration (provider, model, etc.)
├── mcp.json                    # Wireshark MCP server definition
├── auth.json                   # AI provider credentials
├── litellm/                    # Local proxy that unifies LLM providers under an OpenAI-compatible API
│   └── config.yaml             # Provider selection: OpenRouter or Gemini direct
└── skills/
    └── wireshark-analysis/     # Teaching skill
```

## Requirements

- Windows with `npm`/Node.js installed.
- Python 3 with `venv` available in the PATH.
- [Wireshark](https://www.wireshark.org/) installed (for `tshark`, used by the MCP server).
- [LiteLLM](https://docs.litellm.ai) installed (`pip install "litellm[proxy]"`) and running as a local proxy.
- An API key from a compatible provider: **OpenRouter** or **Google Gemini** (see [Configuration](#configuration)).

## Installation

Run `install-pi-agent.bat` from this folder. The script:

1. Installs `@earendil-works/pi-coding-agent` and `pi-mcp-adapter` globally via npm (`--ignore-scripts`).
2. Creates `%USERPROFILE%\.pi\agent` and copies `settings.json`, `auth.json`, and `skills/` into it.
3. Generates `mcp.json` with the path to the Wireshark environment, adapted to the current user directory.
4. Deploys the Wireshark MCP server: creates a Python virtual environment at `wireshark-mcp\.venv` and installs the `wireshark-mcp` package.

## Configuration

`auth.json` is intentionally distributed with an empty key (`"sk-"`). Before running the agent, replace it with your provider key and configure `litellm/config.yaml` according to the chosen option:

**Option A — OpenRouter (routes to Gemini or other models):**

```yaml
model_list:
  - model_name: default
    litellm_params:
      model: openrouter/google/gemini-2.0-flash-001
      api_key: os.environ/OPENROUTER_API_KEY
      api_base: https://openrouter.ai/api/v1
```

**Option B — Gemini direct:**

```yaml
model_list:
  - model_name: default
    litellm_params:
      model: gemini/gemini-2.0-flash-001
      api_key: os.environ/GEMINI_API_KEY
```

Set the corresponding key either directly in `%USERPROFILE%\.pi\agent\auth.json` after installation, or locally in this file before installing.

## Included Skills

- **wireshark-analysis** — Teacher mode: captures and analyses real traffic (SIP, RIP, OSPF, ARP, DHCP, DNS, TCP, HTTP, TLS...) for exclusively educational purposes.

## Contributors

Sebastián García Galán, Francisco Javier Maldonado Carrascosa, José Enrique Muñoz Expósito — Department of Telecommunications Engineering, University of Jaén.
