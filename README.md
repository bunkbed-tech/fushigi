# Fushigi

Assistant for aiding conversational fluency for Japanese language, with a focus out output.

Monorepo for a Python FastAPI backend, SwiftUI multiplatform native application, SvelteKit frontend webapp,
and potentially even a TUI via Rust's Ratatui.

## Development

Users have two main ways to get involved with this project.

### Option 1: Use Docker

If you have docker installed on your computer, each project can be run as a container via `docker compose up --build`.

### Option 2: Use devenv and direnv

This assumes you have a working NixOS or Nix Home-Manager install with the devenv and direnv packages included.

Then, you simply need to `direnv allow` the root folder and all projects can be spun up with `devenv up`.

### Setting up a local dev environment

If you aren't using devenv, then you must install the following:

1. `uv` to manage python.
2. `cargo` to manage rust.
3. `bun` to manage typescript.

```shell On sourcing the python virtual environment for IDE
uv venv
source .venv/bin/activate
uv sync --dev
```

For devenv users, the location is included in `.envrc` and auto-sourced for you.

## Data Sync Model for Apple Devices

Decided to use this tiered system to save on costs from calling a hosted database too often.
This also lets us take advantage of iCloud to sync across apple devices without needing to
rely on the PostgreSQL API for that.

```text
  ┌───────────────┐
  │  Remote DB    │  ← PostgreSQL (canonical source of truth)
  └───────┬───────┘
          │ fetch / push
          ▼
  ┌───────────────┐
  │ Local DB      │  ← SwiftData / ModelContainer (persistent on device)
  └───────┬───────┘
          │ read / write
          ▼
  ┌───────────────┐
  │ Store         │  ← ObservableObject / GrammarStore (session cache)
  └───────┬───────┘
          │ bind / observe
          ▼
  ┌───────────────┐
  │ Views         │  ← SwiftUI UI, reads/writes via the store
  └───────────────┘
```

I am assuming something similar exists for browser persistent storage in the SvelteKit
webapp version of Fushigi. Currently this is a major work in progress where I'm heavily
relying on AI for assistance so there might be issues with the implementation.
