#!/usr/bin/env bash
#
# Install the dev essentials toolkit on macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/KenLSM/dev-essentials/master/install.sh | bash
#
# Set DEV_ESSENTIALS_SKIP_ZSHRC=1 to leave ~/.zshrc untouched.

set -euo pipefail

TOOLS=(ripgrep fzf jq ast-grep fd bat)
FZF_LINE='source <(fzf --zsh)'

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWarning:\033[0m %s\n' "$*" >&2; }
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

info "Installing: ${TOOLS[*]}"
brew install "${TOOLS[@]}"

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

info "Installed versions:"
rg --version | head -n 1
fzf --version
jq --version
ast-grep --version
fd --version
bat --version

info "Done. Restart your shell or run: source ~/.zshrc"
