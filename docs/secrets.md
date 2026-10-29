# Secrets

Korean / 한국어: [ko/secrets.md](ko/secrets.md)

## The problem

To let an agent use a service you normally put a key where the agent can read
it: an environment variable, a `.env` file, a token in a git remote URL.

The trouble is the reading. When an agent reads a key in order to use it, a
copy of that key is in its transcript. Deleting the original does not delete
the copy, and you cannot revoke it. This is the most common way a working
credential ends up somewhere it was never meant to be, and it is how I lost
one (see [why-this-exists.md](why-this-exists.md)).

## What this workspace does instead

[ValetFS](https://github.com/WinM2M/valet-fs) keeps keys on your phone. A
daemon in the container receives them in memory, not on disk, and only while
the phone allows it. The grant expires.

```sh
valetfs serve --join <CONNECTION KEY>   # pair this machine with the phone
valetfs status                          # what is served, and for how long
valetfs ls fs:/keys                     # names only, never values
```

Do not read a secret in order to use it. Hand it to the command:

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
valetfs exec --as API_KEY fs:/keys/openai.txt -- node script.mjs
valetfs exec --as-file KEYFILE fs:/keys/apple.p8 -- ./sign.sh
```

The value goes into the child process's environment, so it does not appear in
your shell history or the agent's context.

`valetfs cat` prints a secret to stdout. Do not call it from an agent. That is
the leak this is here to avoid.

## The grant, and who makes it

Claude Code stops an agent from editing its own settings, and from reading
credentials by default. Both are right. An agent that can open the vault on its
own initiative is not much better than a key on disk.

`valetfs setup-claude` is the sanctioned way through. It merges three rules
into your settings:

```json
{"permissions":{"allow":["Bash(valetfs exec *)","Bash(valetfs ls *)","Bash(valetfs status)"]}}
```

`valetfs cat` is not in that list and will not be, unless you pass
`--allow-cat` and accept what that means.

`./bootstrap.sh` asks about this before starting the container and applies your
answer. That is not an agent granting itself anything. It is you running a
script on your own machine, told what you are agreeing to first. Non-interactive
runs decline unless you pass `--grant-vault`.

```sh
valetfs setup-claude --print     # show the JSON, change nothing
valetfs setup-claude             # grant it later, inside the container
./bootstrap.sh --no-grant-vault  # decline up front, no prompt
```

## What this does not protect you from

- While the grant is open, anything running in the container can ask the daemon
  for a secret, including a compromised process. The length of the grant window
  is the control.
- `valetfs exec` protects the value up to the point the process gets it. If the
  program then writes it to a log, that is the program's problem.
- "In memory, not on disk" describes what ValetFS does. It is not a claim about
  swap or core dumps.
- Screen recordings and screenshots respect none of this. Mask before you
  publish.

## Not using ValetFS

`./bootstrap.sh --no-valetfs` leaves it out and the rest works. If you go that
way, at least keep keys out of git remote URLs and out of `workspace/`, which
is mounted from your disk.
