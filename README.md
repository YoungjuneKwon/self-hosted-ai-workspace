# self-hosted-ai-workspace

A script for setting up a persistent, isolated container for AI coding agents.

Korean / 한국어: [docs/ko/README.md](docs/ko/README.md)

---

A cloud workspace is ready immediately and starts fresh each time. That works
well for occasional use. With daily use, you have to set up the same tools,
files and permissions for each session. The provider also manages your
credentials, context and limits.

It is closer to the difference between a hotel and a house. A cloud workspace
is suitable for most users. This repository is for users who need to manage
their own workspace.

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
| **Keeps working while you sleep** | **O** | **O** | **X** |
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
- `workspace/`, bind-mounted from the host. Your code remains on the host if
  you delete the container.

## Quick start

Docker is required. On Windows, use Docker Desktop with the WSL2 backend.

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
./bootstrap.sh --shell           # shell into a workspace already built
```

Run `claude` inside the container to sign in. The login session is stored in
the volume.

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

ValetFS is published by the same author as this repository.

## License

MIT. See [LICENSE](LICENSE).
