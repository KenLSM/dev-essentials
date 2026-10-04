#!/usr/bin/env bash
#
# Install the dev essentials toolkit on macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/KenLSM/dev-essentials/master/install.sh | bash
#
# Set DEV_ESSENTIALS_SKIP_ZSHRC=1 to leave ~/.zshrc untouched.

set -euo pipefail

REPO_URL="https://github.com/KenLSM/dev-essentials"
RAW_URL="https://raw.githubusercontent.com/KenLSM/dev-essentials/master"
FZF_LINE='source <(fzf --zsh)'

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || fail "This installer only supports macOS."

# Install Homebrew if it is missing.
if ! command -v brew >/dev/null 2>&1; then
  info "Homebrew not found; installing it"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      break
    fi
  done
  command -v brew >/dev/null 2>&1 || fail "Homebrew installation did not put brew on PATH."
fi

# Use the Brewfile next to this script when run from a clone; otherwise
# download it. Either way, the Brewfile is the single list of tools.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"
if [[ -f "$script_dir/Brewfile" && -f "$script_dir/install.sh" ]]; then
  brewfile="$script_dir/Brewfile"
else
  brewfile="$(mktemp -t dev-essentials-brewfile)"
  trap 'rm -f "$brewfile"' EXIT
  curl -fsSL "$RAW_URL/Brewfile" -o "$brewfile" || fail "Could not download the Brewfile."
fi

tools=()
while IFS= read -r tool; do
  tools+=("$tool")
done < <(brew bundle list --file="$brewfile" --formula)

info "Installing: ${tools[*]}"
brew bundle install --file="$brewfile"

# Enable fzf key bindings and completion in Zsh.
if [[ "${DEV_ESSENTIALS_SKIP_ZSHRC:-}" != "1" ]]; then
  zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  if [[ -f "$zshrc" ]] && grep -qF "$FZF_LINE" "$zshrc"; then
    info "fzf already enabled in $zshrc"
  else
    info "Enabling fzf key bindings in $zshrc"
    printf '\n# fzf key bindings and completion\n%s\n' "$FZF_LINE" >> "$zshrc"
  fi
fi

# Summarise what was installed, using Homebrew's own metadata.
printf '\n'
info "Installed tools:"
printf '\n'
brew info --json=v2 --formula "${tools[@]}" | jq -r '
  .formulae[]
  | "  \u001b[1m\(.name)\u001b[0m \(.installed[0].version // "?")\n"
  + "    \(.desc)\n"
  + "    \(.homepage)\n"'

info "Examples and tips for every tool: $REPO_URL#the-toolkit"
info "Done. Restart your shell or run: source ~/.zshrc"
