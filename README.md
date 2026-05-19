# codegraph — Claude / Cursor / Codex / opencode plugin

Local-first semantic code intelligence + MCP server. Indexes 21
languages with tree-sitter and exposes a knowledge graph to your
AI coding agent.

**This repo is a thin distribution layer for the
[codegraph](https://github.com/peterctwang/codegraph-rust) Rust
implementation.** Every release here mirrors the source repo's
releases — same binaries, same version numbers — so you can install
without a GitHub token or `cargo`.

---

## Install (one line)

### Windows (PowerShell)

```powershell
iwr https://github.com/peterctwang/codegraph-rust-public/raw/main/scripts/install.ps1 | iex
```

### macOS / Linux

```bash
curl -fsSL https://github.com/peterctwang/codegraph-rust-public/raw/main/scripts/install.sh | bash
```

The bootstrap will:

1. Pick the binary that matches your CPU (5 platform targets).
2. Drop it at `~/.codegraph/bin/codegraph` and add that to your `PATH`.
3. Run `codegraph install --location global` — writes MCP config for every
   detected agent (Claude Code, Cursor, Codex CLI, opencode), preserving
   any sibling MCP servers you already have.

Restart your IDE. Claude / Cursor / Codex now see a `codegraph` MCP
server with **10 tools**:

| Tool | Use |
|------|------|
| `codegraph_search` | FTS5 search with `kind:function`, `lang:python` filters |
| `codegraph_get_node` | Full metadata for one node by id |
| `codegraph_callers` / `_callees` | Who calls X / what does X call |
| `codegraph_impact` | Transitive caller BFS within depth |
| `codegraph_context` | Markdown context block for a task |
| `codegraph_status` | files / nodes / edges counts |
| `codegraph_files` | List indexed file paths |
| `codegraph_resolve` | Run import + framework resolution |
| `codegraph_languages` | Breakdown of indexed files by extension |

Index your project once:

```bash
cd your-project
codegraph index            # full
codegraph sync --watch     # live, debounced (Ctrl-C to stop)
```

## What you actually get

Inside the binary:
- **21 indexable languages** (TS, JS, TSX, JSX, Python, Rust, Go, Java,
  C, C++, C#, PHP, Ruby, Swift, Kotlin, Dart, Scala, Pascal, Svelte,
  Vue, Liquid).
- **13 framework resolvers** that detect routes in Express, Django, Rails,
  FastAPI, Flask, Laravel, Spring, Gin, Actix, Axum, ASP.NET, SvelteKit,
  Vapor.
- **Incremental sync** — file-hash based, only re-extracts changed files.
- **Embedded SQLite + FTS5** — no external DB to manage.

The binary is ~34 MB, statically linked. No Node, no Python, no Rust
toolchain needed at runtime.

## Platforms supported

| Platform | Triple |
|:---------|:-------|
| macOS Intel | `x86_64-apple-darwin` |
| macOS Apple Silicon | `aarch64-apple-darwin` |
| Linux x86_64 | `x86_64-unknown-linux-gnu` |
| Linux arm64 | `aarch64-unknown-linux-gnu` |
| Windows x86_64 | `x86_64-pc-windows-msvc` |

## Uninstall

```bash
codegraph uninstall --location global   # strip MCP entries from all agents
rm -rf ~/.codegraph                     # remove the binary + PATH entry
# also remove the codegraph export line from .bashrc / .zshrc
```

## Manual install (no script)

```bash
# 1. Download the matching binary from the latest release
gh release download --repo peterctwang/codegraph-rust-public \
    --pattern "codegraph-<your-triple>*"

# 2. Place + chmod
mkdir -p ~/.codegraph/bin
mv codegraph-* ~/.codegraph/bin/codegraph
chmod +x ~/.codegraph/bin/codegraph
export PATH=$HOME/.codegraph/bin:$PATH

# 3. Wire MCP config into your agents
codegraph install --location global
```

## Want to hack on it?

Source code, tests, benchmarks, CI matrix:
**https://github.com/peterctwang/codegraph-rust** (private until v1).
Releases there mirror here every time a new tag is cut.

## License

[MIT](LICENSE)
