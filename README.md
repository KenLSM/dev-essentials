# Dev Essentials for macOS

A small, opinionated set of command-line tools that make searching, filtering,
and exploring code faster. This guide assumes you are using macOS and already
have [Homebrew](https://brew.sh/) installed.

## Install everything

Run the installer with one command. It installs Homebrew if needed, installs
every tool below, and enables fzf's key bindings in `~/.zshrc`:

```sh
curl -fsSL https://raw.githubusercontent.com/KenLSM/dev-essentials/master/install.sh | bash
```

To leave `~/.zshrc` untouched, pass `DEV_ESSENTIALS_SKIP_ZSHRC=1`:

```sh
curl -fsSL https://raw.githubusercontent.com/KenLSM/dev-essentials/master/install.sh | DEV_ESSENTIALS_SKIP_ZSHRC=1 bash
```

Or clone this repository, change into it, and let Homebrew install the tools in
the included `Brewfile`:

```sh
brew bundle
```

Alternatively, install them directly:

```sh
brew install ripgrep fzf jq ast-grep fd bat
```

Verify the installation:

```sh
rg --version
fzf --version
jq --version
ast-grep --version
fd --version
bat --version
```

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

Enable fzf's key bindings and shell completion in Zsh by adding this to
`~/.zshrc`:

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

## Useful combinations

The tools become more useful when composed:

```sh
# Select a file and open it in your configured editor
${EDITOR:-vim} "$(fd --type f | fzf)"

# Select a JSON file and pretty-print it
fd --extension json | fzf | xargs jq .

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
