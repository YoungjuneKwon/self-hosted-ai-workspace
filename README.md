# self-hosted-ai-workspace

A script that sets up a persistent, isolated container for working with AI
coding agents every day.

Korean / 한국어: [docs/ko/README.md](docs/ko/README.md)

---

I have run a setup like this daily for about a year. People kept asking how it
was put together, so here it is, minus the parts that only work on my machine.

The short version of why: a cloud workspace opens instantly and is clean every
time, which is the right trade for occasional use. It is the wrong trade once
you are in there every day and keep rebuilding the same tools, files and
permissions. Hotel, or house. Most people should stay in the hotel.

## What the difference actually is

My read as of October 2026. Vendor features move, so check the current state
before trusting a row.

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

The bold row is the one the cloud wins. A hosted agent keeps running when my
power, router or laptop does not. I use an always-on machine, cron and a
restart policy, and it still is not the same thing. Scheduled work I cannot
afford to miss goes in the cloud. I use both.

Reasoning for each row: [docs/why-this-exists.md](docs/why-this-exists.md).

## What you get

A Debian container whose home directory survives restarts, with:

- Node 22, Python 3.11, git, gh, ripgrep, jq
- Claude Code. Optionally opencode and Codex CLI.
- [ValetFS](https://github.com/WinM2M/valet-fs), which gives a secret to one
  command without storing it in the container. The installer checks the
  published SHA-256 before installing. See the note below about what that
  check does and does not prove.
- `workspace/`, bind-mounted from your disk, so your code is not in the
  container and the container can be thrown away

## Quick start

Needs Docker. On Windows, Docker Desktop with the WSL2 backend.

```sh
git clone https://github.com/YoungjuneKwon/self-hosted-ai-workspace
cd self-hosted-ai-workspace
./bootstrap.sh
```

The script checks for the tools it needs, then creates a Docker image, a named
volume for the home directory, and a container. Outside Docker it only creates
`workspace/` in the directory you ran it from.

```sh
./bootstrap.sh --help            # every flag
./bootstrap.sh --no-valetfs      # skip the vault
./bootstrap.sh --grant-vault     # answer the permission question up front
./bootstrap.sh --shell           # shell into a workspace you already built
```

Inside, run `claude` once to sign in. The session is kept in the volume.

## The question the bootstrap asks

Before starting the container, the script asks whether the agent may call
`valetfs exec` without a permission prompt every time, and lists what the grant
covers: `exec`, `ls`, `status`, and not `cat`.

It asks because this is a permission decision and those should be yours. It
does not make you go type the command afterwards, because the decision is the
part that has to be yours, not the keystrokes. Answer with `--grant-vault` or
`--no-grant-vault` when scripting. Non-interactive runs decline by default.

To change your mind later, run `valetfs setup-claude` in the container or edit
`~/.claude/settings.json` there.

[docs/secrets.md](docs/secrets.md) covers how a secret reaches a command
without the agent reading it, and what that does not protect you from.

## About that checksum

The installer downloads the SHA-256 from the same GitHub release as the binary.
That catches a truncated or corrupted download. It does not prove provenance,
because an attacker who can replace one file can replace the other.

ValetFS releases are also signed with cosign (keyless), and that signature is a
real trust path. I did not put cosign in the image, to keep it small. If you
want the stronger check, run it yourself before building:

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
- **Not a GPU rig.** It is a workspace for agents that call hosted models. It
  does not set up local inference.
- **Not my whole machine.** My daily setup also has a browser the agent drives,
  a tunnel, and host-specific configuration. None of it is portable, so none of
  it is here.
- **Not audited by anyone but me.** There has been no third-party security
  review. Read `docker/Dockerfile` and `bootstrap.sh` before running them.

## License

MIT. See [LICENSE](LICENSE).
