# self-hosted-ai-workspace

A script that sets up a persistent, isolated container for working with AI
coding agents every day.

Korean / 한국어: [docs/ko/README.md](docs/ko/README.md)

---

A cloud workspace opens instantly and is clean every time. For occasional use
that is the right trade. For daily use it means rebuilding the same tools,
files and permissions on every session, and accepting that credentials, context
and limits are managed by someone else.

Hotel, or house. Most people should stay in the hotel. This is for the case
where that stops being true.

## What the difference actually is

Assessment as of October 2026. Vendor features move, so check any row that
matters before relying on it.

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

The bold row goes to the cloud. A hosted agent keeps running when a home
machine's power, network or lid does not. An always-on host with cron and a
restart policy narrows the gap; it does not close it. Scheduled work that
cannot be missed belongs in the cloud. The two are not exclusive.

Reasoning for each row: [docs/why-this-exists.md](docs/why-this-exists.md).

## What you get

A Debian container whose home directory survives restarts, with:

- Node 22, Python 3.11, git, gh, ripgrep, jq
- Claude Code. Optionally opencode and Codex CLI.
- [ValetFS](https://github.com/WinM2M/valet-fs), which gives a secret to one
  command without storing it in the container. The installer checks the
  published SHA-256 before installing. See the note below on what that check
  does and does not prove.
- `workspace/`, bind-mounted from the host, so code lives outside the container
  and the container stays disposable

## Quick start

Needs Docker. On Windows, Docker Desktop with the WSL2 backend.

```sh
git clone https://github.com/YoungjuneKwon/self-hosted-ai-workspace
cd self-hosted-ai-workspace
./bootstrap.sh
```

The script checks for the tools it needs, then creates a Docker image, a named
volume for the home directory, and a container. Outside Docker it creates only
`workspace/` in the directory it was run from.

```sh
./bootstrap.sh --help            # every flag
./bootstrap.sh --no-valetfs      # skip the vault
./bootstrap.sh --grant-vault     # answer the permission question up front
./bootstrap.sh --shell           # shell into a workspace already built
```

Inside, run `claude` once to sign in. The session is kept in the volume.

## The question the bootstrap asks

Before starting the container, the script asks whether the agent may call
`valetfs exec` without a permission prompt every time, and lists what the grant
covers: `exec`, `ls`, `status`, and not `cat`.

It asks rather than deciding, because granting an agent standing access to a
vault is a security decision and those belong to the operator. It applies the
answer rather than printing a command to run later, because what has to be the
operator's is the decision, not the keystrokes.

Use `--grant-vault` or `--no-grant-vault` when scripting. Non-interactive runs
decline by default. To change the answer afterwards, run `valetfs setup-claude`
in the container or edit `~/.claude/settings.json` there.

[docs/secrets.md](docs/secrets.md) covers how a secret reaches a command
without the agent reading it, and what that does not protect against.

## About that checksum

The installer downloads the SHA-256 from the same GitHub release as the binary.
That catches a truncated or corrupted download. It does not establish
provenance, because whoever can replace one file can replace the other.

ValetFS releases are also signed with cosign (keyless), which is a real trust
path. cosign is not in the image, to keep it small. For the stronger check, run
it before building:

```sh
cosign verify-blob \
  --certificate SHA256SUMS.pem \
  --signature   SHA256SUMS.sig \
  --certificate-identity-regexp 'https://github.com/WinM2M/valet-fs/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  SHA256SUMS
```

## What this is not

- **Not a cloud replacement.** See the bold row above.
- **Not a GPU rig.** This is a workspace for agents that call hosted models. It
  does not set up local inference.
- **Not a full environment.** A browser the agent drives, a tunnel, and
  host-specific configuration are all out of scope, because none of it ports.
- **Not independently audited.** There has been no third-party security review.
  Read `docker/Dockerfile` and `bootstrap.sh` before running them.

ValetFS is published by the same author as this repository.

## License

MIT. See [LICENSE](LICENSE).
