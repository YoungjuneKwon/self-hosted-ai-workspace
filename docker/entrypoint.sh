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

  # The vault grant. bootstrap.sh asked; this applies the answer.
  if command -v valetfs >/dev/null 2>&1; then
    case "${VALETFS_GRANT:-no}" in
      yes)
        if valetfs setup-claude --yes >/dev/null 2>&1; then
          echo "  Vault access granted: the agent may call valetfs exec without"
          echo "  asking each time. valetfs cat is still blocked."
        else
          echo "  Could not apply the vault grant. Run 'valetfs setup-claude'"
          echo "  yourself when you need it." >&2
        fi
        ;;
      *)
        echo "  Vault access not granted. Claude Code will ask before each"
        echo "  valetfs call. To change that: valetfs setup-claude"
        ;;
    esac
  fi

  touch "$HOME/.workspace-initialised"

  cat <<'HELLO'

  This home directory is new. Sign in once and it is kept in the volume:

    claude

HELLO
fi

exec "$@"
