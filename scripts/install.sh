#!/usr/bin/env bash
# codegraph quick-install for macOS / Linux.
#
# Usage:
#   curl -fsSL https://github.com/peterctwang/codegraph-rust-public/raw/main/scripts/install.sh | bash
#
# No GitHub token needed — this repo and its releases are public.

set -euo pipefail

OWNER="peterctwang"
REPO="codegraph-rust-public"
VERSION="${CODEGRAPH_VERSION:-latest}"

err() { echo "error: $*" >&2; exit 1; }

resolve_target() {
    local os arch
    case "$(uname -s)" in
        Darwin) os="apple-darwin" ;;
        Linux)  os="unknown-linux-gnu" ;;
        *)      err "Unsupported OS: $(uname -s). Use install.ps1 on Windows." ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64)  arch="x86_64" ;;
        arm64|aarch64) arch="aarch64" ;;
        *)             err "Unsupported arch: $(uname -m)" ;;
    esac
    echo "${arch}-${os}"
}

api_url() {
    if [ "$VERSION" = "latest" ]; then
        echo "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest"
    else
        echo "https://api.github.com/repos/${OWNER}/${REPO}/releases/tags/${VERSION}"
    fi
}

resolve_asset() {
    local target="$1"
    local rel
    if ! rel="$(curl -fsSL -H "Accept: application/vnd.github+json" "$(api_url)")"; then
        err "Failed to fetch release metadata from GitHub."
    fi
    local asset_name="codegraph-rust-${target}"
    local url
    url="$(echo "$rel" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in data.get('assets', []):
    if a['name'] == '$asset_name':
        print(a['browser_download_url'])
        break
")"
    [ -z "$url" ] && err "No asset $asset_name in release"
    tag="$(echo "$rel" | python3 -c "import json, sys; print(json.load(sys.stdin)['tag_name'])")"
    echo "$tag"
    echo "$url"
}

ensure_path_entry() {
    local dir="$1"
    case ":$PATH:" in
        *":$dir:"*) return 0 ;;
    esac
    local profile
    if [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL:-}" = "/bin/zsh" ] || [ "${SHELL:-}" = "/usr/bin/zsh" ]; then
        profile="${HOME}/.zshrc"
    else
        profile="${HOME}/.bashrc"
    fi
    if ! grep -q ".codegraph/bin" "$profile" 2>/dev/null; then
        echo '' >> "$profile"
        echo '# Added by codegraph installer' >> "$profile"
        echo 'export PATH="$HOME/.codegraph/bin:$PATH"' >> "$profile"
        echo "Appended PATH update to $profile — open a new shell or 'source $profile'."
    fi
    export PATH="$dir:$PATH"
}

main() {
    local target tag url
    target="$(resolve_target)"
    echo "Resolved target: $target"

    {
        read -r tag
        read -r url
    } < <(resolve_asset "$target")
    echo "Downloading codegraph ${tag}…"

    local bin_dir="$HOME/.codegraph/bin"
    mkdir -p "$bin_dir"
    local bin_path="$bin_dir/codegraph-rust"
    curl -fsSL -o "$bin_path" "$url"
    chmod +x "$bin_path"
    # macOS Gatekeeper: clear the quarantine attribute so the binary runs.
    if command -v xattr >/dev/null 2>&1; then
        xattr -d com.apple.quarantine "$bin_path" 2>/dev/null || true
    fi
    echo "Wrote $bin_path"

    ensure_path_entry "$bin_dir"

    echo "Wiring MCP config into installed agents…"
    "$bin_path" install --location global

    echo ""
    echo "codegraph ${tag} is ready. Restart Claude Code / Cursor to pick up the MCP server."
    echo "Then in any project:  codegraph init  &&  codegraph index"
}

main "$@"
