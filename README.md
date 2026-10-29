# self-hosted-ai-workspace

One script that gives you a persistent, isolated machine where AI coding agents
actually live — instead of a chat tab that forgets you when you close it.

Korean / 한국어: [docs/ko/README.md](docs/ko/README.md)

---

## A hotel room, or a home

A hotel is a good deal. It opens the moment you arrive, someone cleans it every
day, and you never think about the plumbing. For a trip, a hotel is the right
answer and buying a house would be a silly one.

But you cannot leave anything of your own in a hotel room. You check out and the
room is wiped. You cannot drill the wall. Your valuables go in a safe whose
combination the front desk knows.

Cloud AI workspaces are hotels, and they are good ones. This repository is for
the people who stopped travelling and started living there — who work with an
agent every day, and have begun to notice that every morning starts from an
empty room.

## What the difference actually is

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

Read the row in bold again. **The cloud wins that one and it is not close.** A
hotel has a generator; your house does not. If your machine is off, your agent
is off. Everything else on this list is a reason to own a house, and that row is
the reason to keep using hotels too. Most people should.

Longer version, with the reasoning behind each row:
[docs/why-this-exists.md](docs/why-this-exists.md).

## What you get

A Debian container with a home directory that persists across restarts, holding:

- **Node 22, Python 3.11, git, gh, ripgrep, jq** — the floor every agent assumes
- **Claude Code**, and optionally **opencode** and **Codex CLI**
- **[ValetFS](https://github.com/WinM2M/valet-fs)** — your API keys stay on your
  phone and are lent to the container in memory, for one command, while you
  allow it. Installed with its checksum and signature verified.
- A bind-mounted `workspace/` directory, so your code lives on your disk and the
  container is disposable

## Quick start

Requires Docker. On Windows, Docker Desktop with the WSL2 backend.

```sh
git clone https://github.com/YoungjuneKwon/self-hosted-ai-workspace
cd self-hosted-ai-workspace
./bootstrap.sh
```

The script checks your environment, builds the image, and starts the container.
It changes nothing outside Docker and the directory you run it in.

```sh
./bootstrap.sh --help        # every flag
./bootstrap.sh --no-valetfs  # skip the vault
./bootstrap.sh --shell       # get a shell in a workspace you already built
```

Then, inside the container:

```sh
claude            # sign in once; the session persists in the named volume
valetfs --help    # pair your phone when you are ready to use real keys
```

## The part worth doing by hand

```sh
valetfs setup-claude
```

This is the only step the bootstrap will not do for you, and that is deliberate.
It grants the agent permission to call `valetfs exec` without asking you each
time. An agent that can open the vault on its own initiative defeats the point
of having one, so the grant is a person's decision, made once, at the keyboard.

Everything else about this repository is convenience. This part is the argument.

See [docs/secrets.md](docs/secrets.md) for how a secret reaches a command
without ever passing through the agent's transcript.

## What this is not

- **Not a cloud replacement.** See the bold row above.
- **Not a GPU rig.** This is a workspace for agents that call hosted models. It
  does not set up local inference.
- **Not my exact machine.** The environment this was extracted from also has a
  browser the agent drives, a tunnel, and a few host-specific things that are
  not portable. Those are deliberately out of scope here.
- **Not audited by anyone but me.** Read `docker/Dockerfile` before you run it.
  It is 60 lines and that is on purpose.

## License

MIT. See [LICENSE](LICENSE).
