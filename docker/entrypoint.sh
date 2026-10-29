#!/usr/bin/env bash
# Runs once per container start, as the agent user.
set -euo pipefail

# The home directory is a named volume, so it starts empty the first time.
if [ ! -f "$HOME/.workspace-initialised" ]; then
  mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.claude"

  if [ ! -f "$HOME/.bashrc" ] || ! grep -q 'self-hosted-ai-workspace' "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" <<'RC'

# self-hosted-ai-workspace
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="${EDITOR:-vi}"
RC
  fi

  git config --global --get init.defaultBranch >/dev/null 2>&1 \
    || git config --global init.defaultBranch main
  git config --global --get safe.directory >/dev/null 2>&1 \
    || git config --global --add safe.directory '*'

  touch "$HOME/.workspace-initialised"

  cat <<'HELLO'

  This home directory is new. Two things worth doing now:

    claude                 sign in; the session is kept in the volume
    valetfs setup-claude   let the agent use the vault without a prompt
                           each time. Run this one yourself, on purpose.

HELLO
fi

exec "$@"
