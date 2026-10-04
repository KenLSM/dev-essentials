# Dev Essentials for macOS

A small, opinionated set of command-line tools that make searching, filtering,
and exploring code faster. This guide assumes you are using macOS. The installer
sets up [Homebrew](https://brew.sh/) for you if it is missing.

## Install everything

Run the installer with one command:

```sh
curl -fsSL https://raw.githubusercontent.com/KenLSM/dev-essentials/master/install.sh | bash
```

It installs Homebrew if needed, installs every tool in the `Brewfile`, adds
[shell integration](#shell-integration) to `~/.zshrc`, and finishes with a
summary of each installed tool, its version, and a link to its documentation.
Rerunning it is safe: it upgrades outdated tools and rewrites its
own `~/.zshrc` block in place.

To install the tools without touching `~/.zshrc`:

```sh
curl -fsSL https://raw.githubusercontent.com/KenLSM/dev-essentials/master/install.sh | DEV_ESSENTIALS_SKIP_ZSHRC=1 bash
```

Or clone this repository and let Homebrew install the `Brewfile` directly:

```sh
brew bundle
```

## Shell integration

The installer adds one block to `~/.zshrc`, between
`# >>> dev-essentials >>>` and `# <<< dev-essentials <<<`. It backs up the
previous file to `~/.zshrc.dev-essentials.bak` first. The block:

- **Lists files with `fd` in fzf**, so `Ctrl-T` and `Alt-C` respect
  `.gitignore` and skip `node_modules`, build output, and `.git`.
- **Adds previews to fzf**: `Ctrl-T` shows the file with `bat`, and `Alt-C`
  shows the directory as an `eza` tree.
- **Enables fzf key bindings**: `Ctrl-T` inserts a file path, `Ctrl-R` searches
  history, and `Alt-C` changes into a directory.
- **Colourises man pages with `bat`** by setting `MANPAGER`.
- **Enables zoxide**, which provides the `z` and `zi` commands.

Any of these you already configure yourself (for example, an existing
`MANPAGER` or `zoxide init` line) is left out of the block. To remove the
integration, delete the block and restart your shell.

## The toolkit

### `rg` — search text quickly

[ripgrep](https://github.com/BurntSushi/ripgrep) recursively searches files,
respects `.gitignore`, and is a fast replacement for many `grep` workflows.

```sh
# Find a string and include line numbers
rg --line-number "TODO"

# Search only TypeScript files, ignoring case
rg --ignore-case --type ts "deprecated"

# List files that contain a match
rg --files-with-matches "API_KEY"
```

### `fzf` — interactively filter anything

[fzf](https://github.com/junegunn/fzf) turns a list from standard input into an
interactive fuzzy-search menu.

```sh
# Pick a file from the current directory
fd --type f | fzf

# Search file contents, then choose a result
rg --line-number "TODO" | fzf

# Preview files while selecting them
fzf --preview 'bat --color=always --style=numbers --line-range=:200 {}'
```

The installer enables fzf's key bindings and shell completion for you. To set
them up by hand instead, add this to `~/.zshrc`:

```sh
source <(fzf --zsh)
```

Restart the shell or run `source ~/.zshrc` after making the change.

### `jq` — query and transform JSON

[jq](https://jqlang.org/) is a command-line JSON processor. It is especially
handy for inspecting API responses and composing shell scripts.

```sh
# Pretty-print JSON
jq . package.json

# Read one field
jq -r '.version' package.json

# Select objects from an array
jq '.users[] | select(.active) | {id, name}' response.json
```

### `ast-grep` — search code by syntax

[ast-grep](https://ast-grep.github.io/) searches syntax trees instead of raw
text, so formatting differences do not affect structural searches.

```sh
# Find console.log calls in JavaScript
ast-grep --lang js --pattern 'console.log($$$ARGS)'

# Find calls to a named JavaScript function
ast-grep --lang js --pattern 'fetch($URL)'

# Rewrite var declarations interactively
ast-grep --lang js --pattern 'var $A = $B' --rewrite 'let $A = $B' --interactive
```

Review rewrites before accepting them, and commit or stash existing work first.

### `fd` — find files with friendlier defaults

[fd](https://github.com/sharkdp/fd) is a convenient alternative to `find`. It
uses regular expressions, searches recursively, and respects `.gitignore`.

```sh
# Find Markdown files
fd --extension md

# Find directories named src
fd --type directory '^src$'

# Include hidden and ignored files when needed
fd --hidden --no-ignore '.env'
```

### `bat` — view files with syntax highlighting

[bat](https://github.com/sharkdp/bat) is a `cat` alternative with syntax
highlighting, line numbers, and Git-aware changes.

```sh
# Read a source file
bat src/main.ts

# Show a line range
bat --line-range 40:80 src/main.ts

# Produce plain output that is safe to pipe
bat --plain --color=never README.md | head
```

### `zoxide` — jump to directories you use

[zoxide](https://github.com/ajeetdsouza/zoxide) remembers the directories you
visit and ranks them by frequency and recency, so a few letters are enough to
get back to one.

```sh
# Jump to the best match for "dev"
z dev

# Match several words in order, such as ~/Projects/dev-essentials
z proj ess

# Choose from matching directories interactively with fzf
zi
```

### `eza` — list files with more context

[eza](https://eza.rocks) is an `ls` replacement with colours, Git status, and a
built-in tree view.

```sh
# Long listing with Git status for each file
eza --long --git

# Tree view, two levels deep, ignoring files Git ignores
eza --tree --level=2 --git-ignore

# Sort by modification time, newest last
eza --long --sort=modified
```

### `tldr` — read short, practical help pages

[tldr](https://tldr.sh/) shows the most common ways to use a command, with
examples, instead of the full manual. It is installed through
[tlrc](https://tldr.sh/tlrc/), the official client.

```sh
tldr tar
tldr git rebase

# Refresh the page cache
tldr --update
```

### `yq` — query and edit YAML

[yq](https://github.com/mikefarah/yq) uses jq-like syntax for YAML, and also
reads JSON, XML, CSV, and TOML. It is handy for Kubernetes manifests, GitHub
Actions workflows, and Compose files.

```sh
# Read one value
yq '.services.web.image' compose.yaml

# List the keys of a map
yq '.services | keys' compose.yaml

# Edit a file in place
yq --inplace '.image.tag = "v2"' values.yaml

# Convert YAML to JSON
yq --output-format=json . config.yaml
```

### `hyperfine` — benchmark commands

[hyperfine](https://github.com/sharkdp/hyperfine) runs commands repeatedly and
reports the mean, spread, and relative speed.

```sh
# Compare two commands
hyperfine 'rg TODO' 'grep -r TODO .'

# Warm the file cache first and export the results
hyperfine --warmup 3 --export-markdown results.md 'npm run build'
```

### `gh` — work with GitHub from the terminal

[GitHub CLI](https://cli.github.com/) brings pull requests, issues, Actions
runs, and repositories to the command line. Sign in once with `gh auth login`.

```sh
# Create a pull request for the current branch
gh pr create --fill

# Check out a pull request locally to review it
gh pr checkout 123

# Watch the CI run for the current branch
gh run watch

# Open the current repository in the browser
gh browse
```

## Useful combinations

The tools become more useful when composed:

```sh
# Select a file and open it in your configured editor
${EDITOR:-vim} "$(fd --type f | fzf)"

# Select a JSON file and pretty-print it
fd --extension json | fzf | xargs jq .

# Pick one of your open pull requests and check it out
gh pr list --author @me | fzf | awk '{print $1}' | xargs gh pr checkout

# Preview search results in context
rg --line-number --no-heading "TODO" | fzf --delimiter : \
  --preview 'bat --color=always --highlight-line {2} {1}'
```

## Keep the tools current

```sh
brew update
brew upgrade
brew bundle check
```
