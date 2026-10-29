# A workspace for AI coding agents. Read it before you run it; it is short.
FROM debian:12-slim

ARG AGENTS=claude
ARG WITH_VALETFS=1
ARG VALETFS_VERSION=v0.3.0
ARG NODE_MAJOR=22

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    NPM_CONFIG_UPDATE_NOTIFIER=false

# The floor every agent assumes is already there.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg git jq less ripgrep tini sudo unzip \
      python3 python3-venv python3-pip \
 && rm -rf /var/lib/apt/lists/*

# Node, from NodeSource rather than Debian's older package.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# GitHub CLI.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

# Agents. Only the ones asked for.
RUN set -eux; \
    for a in $(echo "$AGENTS" | tr ',' ' '); do \
      case "$a" in \
        claude)   npm install -g @anthropic-ai/claude-code ;; \
        opencode) npm install -g opencode-ai ;; \
        codex)    npm install -g @openai/codex ;; \
        *) echo "unknown agent: $a" >&2; exit 1 ;; \
      esac; \
    done; \
    npm cache clean --force

# ValetFS. Downloaded from its public release and checked against the
# published SHA256SUMS before it is allowed to become executable.
RUN set -eux; \
    if [ "$WITH_VALETFS" = "1" ]; then \
      case "$(dpkg --print-architecture)" in \
        amd64) asset=valetfs-linux-amd64 ;; \
        arm64) asset=valetfs-linux-arm64 ;; \
        *) echo "no ValetFS build for $(dpkg --print-architecture)" >&2; exit 1 ;; \
      esac; \
      base="https://github.com/WinM2M/valet-fs/releases/download/${VALETFS_VERSION}"; \
      curl -fsSL "$base/$asset"     -o /tmp/valetfs; \
      curl -fsSL "$base/SHA256SUMS" -o /tmp/SHA256SUMS; \
      want="$(awk -v a="$asset" '$2 == a { print $1 }' /tmp/SHA256SUMS)"; \
      [ -n "$want" ] || { echo "no checksum published for $asset" >&2; exit 1; }; \
      echo "$want  /tmp/valetfs" | sha256sum -c -; \
      install -m 0755 /tmp/valetfs /usr/local/bin/valetfs; \
      rm -f /tmp/valetfs /tmp/SHA256SUMS; \
      valetfs --version; \
    fi

# Not root. The agent runs as a user that can sudo when it is told to.
RUN useradd -m -s /bin/bash -u 1000 agent \
 && echo 'agent ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/agent \
 && chmod 0440 /etc/sudoers.d/agent \
 && mkdir -p /workspace && chown agent:agent /workspace

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

USER agent
WORKDIR /workspace
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["bash", "-l"]
