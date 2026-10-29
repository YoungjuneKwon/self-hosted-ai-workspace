# Why this exists

Korean / 한국어: [ko/why-this-exists.md](ko/why-this-exists.md)

The reasoning behind each row of the table in the README.

## Runs on hardware you control

A cloud workspace starts in seconds because it runs on the provider's hardware.
The provider therefore also decides what the workspace can reach, and can
change those limits without notice. On your own machine you set them.

## Context survives the session

Hosted memory selects what to retain, and what it retains is usually a summary.
A directory of files keeps what was written until someone deletes it.

This is easy to rank below more visible concerns such as permissions, but in
daily use it changes the most. An agent that starts from the repository alone
behaves differently from one that also has the notes and decisions from earlier
sessions.

## Desktop and browser control

Hosted agents restrict browser and desktop access, for defensible reasons. On
your own machine you configure those permissions, including incorrectly. That
is the cost of the control, not a feature of it.

## Credentials and permissions

The rest of the design follows from this row.

The usual way to give an agent access to a service is to put a key where the
agent can read it: an environment variable, a `.env` file, a token in a git
remote URL. The problem is the reading. Once an agent reads a key in order to
use it, a copy of that key exists in the transcript. Deleting the original does
not delete that copy, and the copy cannot be revoked.

This does not require carelessness. A token embedded in a git remote URL is
written to the transcript the first time an agent runs `git remote -v`, which
is a routine command that nobody treats as disclosing a credential.

[ValetFS](https://github.com/WinM2M/valet-fs) keeps keys on a phone and serves
them to the machine in memory, only while the phone allows it. `valetfs exec`
passes the value to a child process, so the agent writes the command without
receiving the key:

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
```

The installer checks the published SHA-256 before installing. That checksum
ships from the same release as the binary, so it detects a corrupted download
but cannot verify the source. The README gives the cosign command for that.

The bootstrap asks before allowing the agent to run `valetfs exec` without a
prompt. A script can apply the setting, but the operator decides whether an
agent gets standing access to the vault.

ValetFS is published by the same author as this repository and has not had a
third-party security audit.

## Generates UI inside the loop

An agent that can only write interface code needs a person to look at the
result and describe what is wrong on every iteration. An agent that can mount
what it built and inspect it does not need that relay.

## Keeps working while you sleep

Cloud workspaces have the advantage here. A hosted agent keeps running even if
your home computer loses power or its network connection, or you close your
laptop lid. Keeping the host on with cron and a container restart policy covers
most cases, which is not the same as the availability a datacentre provides.

Use the cloud for scheduled jobs that must run. Nothing here argues otherwise.

## Data stays where you put it

For an individual this matters less than it sounds. It becomes relevant when a
contract or local law restricts where someone else's data may be processed.

## Cost you can predict

Owning the machine makes the workspace cost easier to estimate, although
hardware fails and electricity is not free. Model API usage is metered in
either case. This row covers the workspace, not the model.

## Who this is wrong for

If you use an AI assistant a few times a week, a browser tab is the better
tool. The setup cost here is only worth it with daily use.
