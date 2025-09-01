# Fushigi

Assistant for aiding conversational fluency for Japanese language, with a focus out output.

Monorepo for a Go managed Pocketbase backend-as-a-service, SwiftUI Apple multiplatform native application, SvelteKit frontend webapp,
and potentially even a TUI via Rust's Ratatui. We are interested in trying to make version of this app across various other native
frameworks as a learning experiment.

## Development

Users should utilize `devenv` to get involved with this project.

This assumes you have a working NixOS or Nix Home-Manager install with the devenv and direnv packages included.

Then, you simply need to `direnv allow` the root folder and all projects can be spun up with `devenv up`.

## Data Sync Model for Apple Devices

Decided to use this tiered system to save on costs from calling a hosted database too often.
This also lets us take advantage of iCloud to sync across apple devices without needing to
rely on the Pocketbase API for that.

```text
  ┌───────────────┐
  │  Remote DB    │  ← Pocketbase (canonical source of truth)
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
