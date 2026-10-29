# Connecting to the outside

Korean / 한국어: [ko/connect.md](ko/connect.md)

A container with no way out is a nicer sandbox, not a workspace. This page
covers the connections that make the environment useful, and where each one
stores its state.

Everything here persists in the home volume, so you do it once per workspace,
not once per session.

## What is already installed

| | |
|---|---|
| `git`, `gh` | GitHub, over HTTPS |
| `ssh`, `rsync` | remote machines, file sync |
| `curl`, `wget`, `openssl` | HTTP, certificates |
| `tmux` | keeping a process alive after you close the shell |
| `claude` | Claude Code, including Remote Control |
| `valetfs` | secrets, see [secrets.md](secrets.md) |
| `cloudflared` | only with `./bootstrap.sh --with-cloudflared` |

Outbound HTTPS works through Docker's default bridge. No ports are published
inbound unless you pass `--port`.

## GitHub

```sh
gh auth login
```

Credentials land in `~/.config/gh`, which is on the home volume. `git push`
over HTTPS then works without a token in the remote URL, which matters: a
token in a remote URL reaches the agent's transcript the first time anything
runs `git remote -v`.

For SSH remotes, put the key in the vault rather than on disk:

```sh
valetfs exec --as-file KEY fs:/keys/id_ed25519 -- \
  sh -c 'GIT_SSH_COMMAND="ssh -i $KEY" git push'
```

## Claude Code

```sh
claude
```

Sign in once. The session is stored in `~/.claude` on the volume, so it
survives `docker rm` and rebuilding the image.

## Claude Remote Control

Remote Control lets you drive a session in this container from claude.ai/code
or the mobile app. One process serves one directory.

```sh
claude remote-control
```

That process must stay alive, and it dies with the shell that started it.
Use tmux:

```sh
tmux new -d -s rc 'cd /workspace && claude remote-control --name my-workspace'
tmux ls                 # confirm it is running
tmux attach -t rc       # look at it; Ctrl-b d to leave it running
```

The container itself has to keep running too. `bootstrap.sh` uses
`docker run --rm`, which stops when you exit the shell. For a workspace you
want to reach while you are away, start it detached with the listener as the
container's main process:

```sh
docker run -d --restart unless-stopped \
  --name ai-workspace \
  -v ai-workspace-home:/home/agent \
  -v "$PWD/workspace:/workspace" \
  -w /workspace \
  ai-workspace:latest \
  claude remote-control --name my-workspace
```

Do not wrap that in `tmux new -d`. A detached tmux returns immediately, PID 1
exits, and with `--restart unless-stopped` the container goes into a restart
loop instead of staying up. tmux is for keeping something alive inside a shell
you are already in; for a detached container, the thing you want running is
the thing you pass to `docker run`.

Verified: `claude remote-control` is present in the installed CLI, and a
detached container with `--restart unless-stopped` stays up and survives
`docker restart` when its main process runs in the foreground. Starting an
actual listener needs your Claude account, so test that part yourself before
relying on it.

## MCP connectors

Google Drive, Slack, a database, your own server: these reach Claude Code
through MCP, not by installing a tool in the container.

```sh
claude mcp add --help
claude mcp list
```

Configuration is written under `~/.claude`, so it persists with everything
else. Connectors that need a key should read it through `valetfs exec` rather
than from an environment variable baked into the container.

## A public URL

With `--with-cloudflared`, a quick tunnel takes one command and needs no
Cloudflare account:

```sh
cloudflared tunnel --url http://localhost:5173
```

It prints a `trycloudflare.com` URL that forwards to the container. The URL is
random, temporary, and public to anyone who has it. Do not put an unprotected
admin page behind one.

For a stable hostname on a domain you own, use a named tunnel with
`cloudflared tunnel login`. The credentials it writes belong in the vault, not
in the image.

## Reaching a dev server without a tunnel

```sh
./bootstrap.sh --port 5173
```

Then `http://localhost:5173` on the host. Nothing is published unless you ask,
and `--port` can be repeated.

## What does not pass through

- **The host's SSH agent.** Not forwarded. Use a key from the vault.
- **The host's browser session.** Nothing in the container shares cookies with
  a browser on your machine.
- **GUI applications.** No X or Wayland socket is mounted.
