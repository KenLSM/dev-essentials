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

# Split the tools into those already present and those this run installs.
installed_formulae="$(brew list --formula -1)"
new_tools=()
existing_tools=()
for tool in "${tools[@]}"; do
  if grep -qxF "$tool" <<<"$installed_formulae"; then
    existing_tools+=("$tool")
  else
    new_tools+=("$tool")
  fi
done

if ((${#new_tools[@]})); then
  info "Installing: ${new_tools[*]}"
else
  info "All tools are already installed; checking for updates"
fi
brew bundle install --file="$brewfile"

# Add shell integration to ~/.zshrc inside a marked block. The block is
# rewritten on every run, and any setting the user already configures outside
# it is left alone.
configure_zsh() {
  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  local start="# >>> dev-essentials >>>"
  local end="# <<< dev-essentials <<<"
  local rest block tmp

  touch "$zshrc"
  rest="$(awk -v s="$start" -v e="$end" '$0 == s {skip=1} !skip {print} $0 == e {skip=0}' "$zshrc")"

  # True if an uncommented line outside our block matches the pattern.
  user_sets() { grep -qE "^[^#]*($1)" <<<"$rest"; }

  block="$start"$'\n'"# Managed by $REPO_URL — rerun the installer to update."

  if ! user_sets 'FZF_DEFAULT_COMMAND'; then
    block+=$'\n\n# fzf: list files with fd so .gitignore is respected\n'
    block+=$(cat <<'EOF'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
EOF
)
  fi

  if ! user_sets 'FZF_CTRL_T_OPTS|FZF_ALT_C_OPTS'; then
    block+=$'\n\n# fzf: preview files with bat and directories with eza\n'
    block+=$(cat <<'EOF'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
EOF
)
  fi

  if ! user_sets 'fzf --zsh|\.fzf\.zsh|fzf/shell'; then
    block+=$'\n\n# fzf: key bindings (Ctrl-T, Ctrl-R, Alt-C) and completion\n'
    block+="$FZF_LINE"
  fi

  if ! user_sets 'MANPAGER'; then
    block+=$'\n\n# Colourise man pages with bat\n'
    block+=$(cat <<'EOF'
export MANPAGER="sh -c 'col -bx | bat --language=man --plain'"
EOF
)
  fi

  if ! user_sets 'zoxide init'; then
    block+=$'\n\n# zoxide: jump to directories with z and zi\n'
    block+='eval "$(zoxide init zsh)"'
  fi

  block+=$'\n'"$end"

  if [[ -s "$zshrc" ]]; then
    cp "$zshrc" "$zshrc.dev-essentials.bak"
    info "Backed up $zshrc to $zshrc.dev-essentials.bak"
  fi

  # Write through the file rather than replacing it, so symlinked dotfiles
  # stay symlinked.
  tmp="$(mktemp -t dev-essentials-zshrc)"
  { [[ -n "$rest" ]] && printf '%s\n\n' "$rest"; printf '%s\n' "$block"; } >"$tmp"
  cat "$tmp" >"$zshrc"
  rm -f "$tmp"
  info "Updated shell integration in $zshrc"
}

if [[ "${DEV_ESSENTIALS_SKIP_ZSHRC:-}" != "1" ]]; then
  configure_zsh
fi

# Summarise the run, using Homebrew's own metadata.
if ((${#new_tools[@]})); then
  printf '\n'
  info "Newly installed:"
  printf '\n'
  brew info --json=v2 --formula "${new_tools[@]}" | jq -r '
    .formulae[]
    | "  \u001b[1m\(.name)\u001b[0m \(.installed[0].version // "?")\n"
    + "    \(.desc)\n"
    + "    \(.homepage)\n"'
fi

if ((${#existing_tools[@]})); then
  # The newly installed list already ends with a blank line.
  ((${#new_tools[@]})) || printf '\n'
  info "Already installed (updated if a newer version was available):"
  printf '\n'
  brew info --json=v2 --formula "${existing_tools[@]}" | jq -r '
    .formulae[]
    | "  \u001b[1m\(.name)\u001b[0m \(.installed[0].version // "?") — \(.homepage)"'
  printf '\n'
fi

info "Examples and tips for every tool: $REPO_URL#the-toolkit"
info "Done. Restart your shell or run: source ~/.zshrc"
