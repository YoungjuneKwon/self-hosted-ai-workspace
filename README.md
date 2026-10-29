# self-hosted-ai-workspace

[![CI](https://github.com/YoungjuneKwon/self-hosted-ai-workspace/actions/workflows/ci.yml/badge.svg)](https://github.com/YoungjuneKwon/self-hosted-ai-workspace/actions/workflows/ci.yml)
[![license](https://img.shields.io/github/license/YoungjuneKwon/self-hosted-ai-workspace.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Engine-2496ED.svg?logo=docker&logoColor=white)](https://docs.docker.com/engine/)
[![Debian](https://img.shields.io/badge/Debian-12-A81D33.svg?logo=debian&logoColor=white)](https://www.debian.org/)
[![Node](https://img.shields.io/badge/Node-22-5FA04E.svg?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-included-D97757.svg)](https://docs.claude.com/en/docs/claude-code)
[![ValetFS](https://img.shields.io/badge/ValetFS-v0.3.0-0A7E8C.svg)](https://github.com/WinM2M/valet-fs)
[![docs](https://img.shields.io/badge/docs-%ED%95%9C%EA%B5%AD%EC%96%B4-blue.svg)](docs/ko/README.md)

**A script for setting up a persistent, isolated container for AI coding agents.
Your keys stay on your phone; your context stays on your disk.**

Korean / 한국어: [docs/ko/README.md](docs/ko/README.md)

## Why you might need this

A cloud workspace is ready immediately and starts fresh each time. That works
well for occasional use. With daily use, you have to set up the same tools,
files and permissions for each session. The provider also manages your
credentials, context and limits.

It is closer to the difference between a hotel and a house. A cloud workspace
is suitable for most users. This repository is for users who need to manage
their own workspace.

**Who this assumes you are:** someone who already uses a coding agent such as
Claude Code and has run into its limits. This is not an introduction to AI
coding agents, and it will not be worth the setup if you are still deciding
whether to use one.

## What the difference actually is

This comparison reflects the features available in October 2026. Features can
change, so verify current support for anything you need.

| | OpenAI cloud | Anthropic cloud | This workspace |
|---|:---:|:---:|:---:|
| Runs on hardware you control | X | X | O |
| Context survives the session | △ | △ | O |
| Desktop and browser control | △ | △ | O |
| Credentials and permissions | X | △ | O |
| Generates UI inside the loop | X | △ | O |
| **Runs 24/7 without interruption** | **O** | **O** | **X** |
| Data stays where you put it | X | X | O |
| Cost you can predict | △ | △ | O |

`O` directly supported · `△` partial or constrained · `X` not available

Cloud workspaces have the advantage in the bold row. A hosted agent keeps
running even if your home computer loses power or its network connection, or
you close your laptop lid. Keeping the host on and configuring cron and a
restart policy can reduce this difference, but cannot eliminate it. Use the
cloud for scheduled jobs that must run. You can use it alongside this
workspace.

Reasoning for each row: [docs/why-this-exists.md](docs/why-this-exists.md).

## What you get

A Debian container whose home directory survives restarts, with:

- Node 22, Python 3.11, git, gh, ripgrep, jq
- Claude Code. Optionally opencode and Codex CLI.
- [ValetFS](https://github.com/WinM2M/valet-fs), which passes a secret to a
  single command without storing it in the container. The installer checks the
  published SHA-256 before installing. The checksum section below explains the
  limits of this check.
- `ssh`, `rsync`, `tmux`, `wget`, `openssl`, because most real work reaches
  something outside the container and a listener has to outlive the shell that
  started it. `cloudflared` with `--with-cloudflared`.
- `workspace/`, bind-mounted from the host. Your code remains on the host if
  you delete the container.

## Quick start

**Recommended path: Docker Engine.** On Linux, install Docker Engine. On
Windows, install Docker Engine inside a WSL2 distribution and run the script
from there. This is the configuration everything here was tested on — Debian 12,
Docker Engine 29.5, x86_64.

**Docker Desktop is untested.** It should work, and nothing here depends on
Engine specifically. But it has not been run, so treat it as unverified. It also
puts its own proxy between the container and the Windows host, so published
ports behave differently from a direct Engine bind. If that has cost you time
before, installing Engine inside WSL2 avoids the layer entirely.

```sh
git clone https://github.com/YoungjuneKwon/self-hosted-ai-workspace
cd self-hosted-ai-workspace
./bootstrap.sh
```

The script checks for the tools it needs, then creates a Docker image, a named
volume for the home directory, and a container. The only thing it creates
outside Docker is `workspace/`, in the directory it was run from.

```sh
./bootstrap.sh --help            # every flag
./bootstrap.sh --no-valetfs      # skip the vault
./bootstrap.sh --grant-vault     # answer the permission question up front
./bootstrap.sh --port 5173       # publish a port, repeatable
./bootstrap.sh --shell           # shell into a workspace already built
./bootstrap.sh -- claude --version   # run one command instead of a shell
```

No ports are published unless you ask for them. To reach a dev server running
in the container, pass `--port` once per port.

Run `claude` inside the container to sign in. The login session is stored in
the volume.

## What ValetFS is

[ValetFS](https://github.com/WinM2M/valet-fs) is referenced throughout this
repository, so it is worth one paragraph before it shows up again.

It is a small open-source tool that keeps API keys on your phone instead of on
the machine the agent runs on. A daemon in the container receives a key in
memory, only while the phone allows it, and `valetfs exec` hands the value to a
child process so the agent never reads it. The name is the point: like valet
parking, someone else drives, and the key comes back to you.

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
```

It is here because of the row above: an agent that reads a key has put a copy
of it in its transcript, where you cannot revoke it. It is optional — pass
`--no-valetfs` and everything else still works. It is MIT-licensed and free,
and I wrote it, which is also why it is the tool this workspace reaches for.

Repository: <https://github.com/WinM2M/valet-fs> ·
Docs: <https://winm2m.github.io/valet-fs/> ·
Details in [docs/secrets.md](docs/secrets.md)

## The question the bootstrap asks

Before starting the container, the script asks whether to allow the agent to
run `valetfs exec` without prompting for permission each time. It also lists
the commands covered by this permission: `exec`, `ls` and `status`. `cat` is
excluded.

The script asks because the operator must decide whether to give an agent
standing access to the vault. The script applies your answer immediately, so
you do not need to run a separate command later.

For scripted use, pass `--grant-vault` or `--no-grant-vault`. Non-interactive
runs deny access by default. To change the answer afterwards, run
`valetfs setup-claude` in the container or edit `~/.claude/settings.json`
there.

[docs/secrets.md](docs/secrets.md) explains how secrets are passed to commands
without being read by the agent, along with the security limits of this
approach.

## Connecting to the outside

GitHub, Claude Code sign-in, Claude Remote Control, MCP connectors and public
URLs each need one step, and each stores its state in the home volume so you
do it once. [docs/connect.md](docs/connect.md) covers them, including what
does not pass through into the container.

## About that checksum

The installer downloads the SHA-256 from the same GitHub release as the binary.
This check detects incomplete or corrupted downloads. It cannot verify the
file's source: anyone who can replace the binary can also replace the checksum
file.

ValetFS releases also have cosign (keyless) signatures that can be verified to
check their source. cosign is omitted to keep the image small. To verify the
signature, run the following command before building:

```sh
cosign verify-blob \
  --certificate SHA256SUMS.pem \
  --signature   SHA256SUMS.sig \
  --certificate-identity-regexp 'https://github.com/WinM2M/valet-fs/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  SHA256SUMS
```

## What this is not

- **Not a cloud replacement.** See the bold row above for the comparison on
  keeping scheduled jobs running.
- **Not a GPU rig.** This is a workspace for agents that call hosted models. It
  does not set up local inference.
- **Not a complete environment setup.** Agent-controlled browsers, tunnels and
  host-specific configuration are excluded because they cannot be transferred
  directly to another environment.
- **Not independently audited.** There has been no third-party security review.
  Read `docker/Dockerfile` and `bootstrap.sh` before running them.
- **Not tested on Docker Desktop.** Everything here was run on Docker Engine.
  Docker Desktop is expected to work and is not recommended against, but it is
  unverified. If you try it, an issue reporting what happened is welcome.

ValetFS is published by the same author as this repository.

## License

MIT. See [LICENSE](LICENSE).
