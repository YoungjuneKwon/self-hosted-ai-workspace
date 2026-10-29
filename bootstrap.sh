#!/usr/bin/env bash
# Build and start a persistent workspace for AI coding agents.
# Touches nothing outside Docker and this directory.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="ai-workspace"
WORKSPACE="$HERE/workspace"
AGENTS="claude"
WITH_VALETFS=1
SHELL_ONLY=0
REBUILD=0

usage() {
  cat <<'EOF'
usage: ./bootstrap.sh [options]

  --name <n>        container and volume name        (default: ai-workspace)
  --workspace <d>   directory to mount at /workspace (default: ./workspace)
  --agents <list>   claude,opencode,codex            (default: claude)
  --no-valetfs      do not install the ValetFS client
  --rebuild         rebuild the image even if it exists
  --shell           open a shell in a workspace already built
  -h, --help        this text

examples:
  ./bootstrap.sh --agents claude,opencode
  ./bootstrap.sh --workspace ~/code --name work
  ./bootstrap.sh --shell
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --name)       NAME="$2"; shift 2 ;;
    --workspace)  WORKSPACE="$2"; shift 2 ;;
    --agents)     AGENTS="$2"; shift 2 ;;
    --no-valetfs) WITH_VALETFS=0; shift ;;
    --rebuild)    REBUILD=1; shift ;;
    --shell)      SHELL_ONLY=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

say()  { printf '\n==> %s\n' "$*"; }
warn() { printf '    warning: %s\n' "$*" >&2; }
die()  { printf '\nerror: %s\n' "$*" >&2; exit 1; }

IMAGE="$NAME:latest"
VOLUME="$NAME-home"

# ---------------------------------------------------------------- preflight

if [ "$SHELL_ONLY" -eq 0 ]; then
  say "Checking this machine"

  command -v docker >/dev/null 2>&1 || die \
    "Docker is not installed. On Windows install Docker Desktop and turn on the
       WSL2 backend; on Linux install docker.io or Docker Engine."

  docker info >/dev/null 2>&1 || die \
    "Docker is installed but not responding. Start Docker Desktop, or run
       'sudo systemctl start docker', and try again."

  if grep -qi microsoft /proc/version 2>/dev/null; then
    if [ "${WSL_INTEROP:-}" = "" ] && [ ! -e /run/WSL ]; then
      warn "This looks like WSL1. WSL2 is strongly recommended; file I/O under
             WSL1 is slow enough to be painful."
    fi
    case "$(pwd)" in
      /mnt/[a-z]/*) warn "You are on a Windows drive (/mnt/...). Builds and git
             operations are much slower here than under the Linux filesystem." ;;
    esac
  fi

  case "$(uname -m)" in
    x86_64|amd64|aarch64|arm64) ;;
    *) die "Unsupported architecture: $(uname -m). amd64 and arm64 only." ;;
  esac

  printf '    docker    %s\n' "$(docker --version | sed 's/,.*//')"
  printf '    arch      %s\n' "$(uname -m)"
  printf '    agents    %s\n' "$AGENTS"
  printf '    valetfs   %s\n' "$([ "$WITH_VALETFS" -eq 1 ] && echo yes || echo no)"
fi

mkdir -p "$WORKSPACE"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

# ------------------------------------------------------------------- build

if [ "$SHELL_ONLY" -eq 0 ]; then
  if [ "$REBUILD" -eq 1 ] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    say "Building $IMAGE (first run takes a few minutes)"
    docker build \
      --build-arg "AGENTS=$AGENTS" \
      --build-arg "WITH_VALETFS=$WITH_VALETFS" \
      -t "$IMAGE" \
      -f "$HERE/docker/Dockerfile" \
      "$HERE/docker"
  else
    say "Image $IMAGE already exists (use --rebuild to rebuild)"
  fi

  docker volume inspect "$VOLUME" >/dev/null 2>&1 || {
    say "Creating volume $VOLUME for the home directory"
    docker volume create "$VOLUME" >/dev/null
  }
fi

# -------------------------------------------------------------------- run

if [ "$SHELL_ONLY" -eq 1 ]; then
  docker image inspect "$IMAGE" >/dev/null 2>&1 || die \
    "No image named $IMAGE. Run ./bootstrap.sh without --shell first."
fi

say "Entering the workspace"
printf '    home       %s  (persists)\n' "$VOLUME"
printf '    workspace  %s  (your disk)\n' "$WORKSPACE"

if [ "$SHELL_ONLY" -eq 0 ]; then
  cat <<EOF

    Inside, start with:

      claude                 sign in once; the session is kept in the volume
      valetfs setup-claude   let the agent use the vault without a prompt
                             each time. Do this one yourself; see README.

EOF
fi

exec docker run --rm -it \
  --name "$NAME" \
  --hostname "$NAME" \
  -v "$VOLUME:/home/agent" \
  -v "$WORKSPACE:/workspace" \
  -w /workspace \
  --env-file "$([ -f "$HERE/.env" ] && echo "$HERE/.env" || echo /dev/null)" \
  "$IMAGE" "$@"
