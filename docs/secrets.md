# Secrets, and why none of them live in this container

Korean / 한국어: [ko/secrets.md](ko/secrets.md)

## The problem with the normal way

To let an agent use a service, you normally put a key somewhere the agent can
read: an environment variable, a `.env` file, a token in a git remote URL.

That key is now readable by every process in the container, present in every
backup of the volume, and one command away from any log or transcript. And
agents read things. The moment an agent reads a key in order to use it, a copy
of that key exists in its transcript — a second location, in a form you do not
control and cannot revoke.

This is not hypothetical. It is the most common way a working credential ends
up somewhere it was never meant to be.

## What this workspace does instead

[ValetFS](https://github.com/WinM2M/valet-fs) keeps your keys on your phone.
A daemon in the container serves them in memory only, never writing to disk,
and only while your phone allows it. The grant expires.

```sh
valetfs serve --join <CONNECTION KEY>   # pair this machine with the phone
valetfs status                          # what is being served, and for how long
valetfs ls fs:/keys                     # names only, never values
```

To use a secret, do not read it. Hand it to the command that needs it:

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
valetfs exec --as API_KEY fs:/keys/openai.txt -- node script.mjs
valetfs exec --as-file KEYFILE fs:/keys/apple.p8 -- ./sign.sh
```

The value goes into the child process's environment. It does not pass through
the shell history, the agent's context, or the transcript.

`valetfs cat` exists and prints a secret to stdout. Do not use it from an
agent. That is exactly the leak this is here to prevent.

## The grant, and who makes it

Claude Code blocks an agent from editing its own settings, and blocks it from
reading credentials by default. Both are correct. An agent that can open the
vault on its own initiative is not meaningfully different from a key on disk.

`valetfs setup-claude` is the sanctioned way through. It merges three rules into
your settings:

```json
{"permissions":{"allow":["Bash(valetfs exec *)","Bash(valetfs ls *)","Bash(valetfs status)"]}}
```

`valetfs cat` is not in that list, and will not be unless you pass `--allow-cat`
and accept what it means.

`./bootstrap.sh` asks you about this before it starts the container, and applies
your answer. That is not the agent granting itself anything — it is you, running
a script on your own machine, being told what you are agreeing to first. The
prompt is the consent; the typing was never the point.

```sh
valetfs setup-claude --print   # see the JSON, change nothing
valetfs setup-claude           # grant it later, from inside the container
./bootstrap.sh --no-grant-vault  # decline up front, no prompt
```

## What is still on you

- A compromised container can still ask the daemon for a secret while the grant
  is open. The grant window is the control; keep it short.
- `valetfs exec` protects the value in transit to the process. If the program
  you run then writes it to a log, that is your program's problem.
- Screen recordings and screenshots do not respect any of this. Mask before you
  publish.

## Not using ValetFS

`./bootstrap.sh --no-valetfs` leaves it out and everything else works. If you
go that way, at minimum keep keys out of git remotes and out of any file inside
`workspace/`, which is bind-mounted from your disk.
