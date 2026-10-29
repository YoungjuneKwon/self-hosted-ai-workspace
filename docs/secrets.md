# Secrets

Korean / 한국어: [ko/secrets.md](ko/secrets.md)

## The problem

To let an agent use a service, a key normally goes where the agent can read it:
an environment variable, a `.env` file, a token in a git remote URL.

The problem is the reading. Once an agent reads a key in order to use it, a
copy of that key exists in the transcript. Deleting the original does not
delete that copy, and the copy cannot be revoked. A token embedded in a git
remote URL is written to the transcript the first time an agent runs
`git remote -v`.

## What this workspace does instead

[ValetFS](https://github.com/WinM2M/valet-fs) keeps keys on a phone. A daemon
in the container receives them in memory rather than on disk, and only while
the phone allows it. The grant expires.

```sh
valetfs serve --join <CONNECTION KEY>   # pair this machine with the phone
valetfs status                          # what is served, and for how long
valetfs ls fs:/keys                     # names only, never values
```

Do not read a secret in order to use it. Pass it to the command:

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
valetfs exec --as API_KEY fs:/keys/openai.txt -- node script.mjs
valetfs exec --as-file KEYFILE fs:/keys/apple.p8 -- ./sign.sh
```

The value goes into the child process's environment, so it does not appear in
shell history or in the agent's context.

`valetfs cat` prints a secret to stdout. Do not call it from an agent. That is
the disclosure this setup exists to prevent.

## The grant, and who makes it

Claude Code prevents an agent from editing its own settings, and from reading
credentials by default. Both restrictions are correct. An agent that can open
the vault on its own provides little more protection than a key on disk.

`valetfs setup-claude` is the supported way to allow it. The command merges
three rules into the settings file:

```json
{"permissions":{"allow":["Bash(valetfs exec *)","Bash(valetfs ls *)","Bash(valetfs status)"]}}
```

`valetfs cat` is not included, and is only added if you pass `--allow-cat`.

`./bootstrap.sh` asks about this before starting the container and applies your
answer. The agent is not granting itself permission: the operator runs the
script and is shown what the permission covers first. Non-interactive runs deny
access unless `--grant-vault` is passed.

```sh
valetfs setup-claude --print     # show the JSON, change nothing
valetfs setup-claude             # grant it later, inside the container
./bootstrap.sh --no-grant-vault  # decline up front, no prompt
```

## What this does not protect against

- While the grant is open, any process in the container can request a secret
  from the daemon, including a compromised one. The length of the grant window
  is what limits this.
- `valetfs exec` protects the value until the process receives it. If that
  program writes the value to a log, the program is the problem.
- "In memory rather than on disk" describes ValetFS's own behaviour. It is not
  a claim about swap or core dumps.
- Screen recordings and screenshots are unaffected by any of this. Mask them
  before publishing.

## Not using ValetFS

`./bootstrap.sh --no-valetfs` leaves it out and everything else still works. In
that case, keep keys out of git remote URLs and out of `workspace/`, which is
mounted from the host.
