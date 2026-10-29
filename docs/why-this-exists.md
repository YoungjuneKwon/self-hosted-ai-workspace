# Why this exists

Korean / 한국어: [ko/why-this-exists.md](ko/why-this-exists.md)

The reasoning behind each row of the table in the README.

## Runs on hardware you control

A cloud workspace starts in seconds because it runs on the vendor's hardware.
The vendor therefore also decides what it may reach, and can change that
without notice. On your own machine those limits are yours to set.

## Context survives the session

Hosted memory decides what is worth keeping, and what it keeps is usually a
summary. A directory of files keeps what was written, unedited, until someone
deletes it.

This is easy to undervalue next to more visible concerns like permissions. In
practice it is the row that changes daily work the most: an agent that starts
from the repository plus everything already settled with it is a different
tool from one that starts from the repository alone.

## Desktop and browser control

Hosted agents constrain browser and desktop access, for defensible reasons. On
your own machine those permissions are yours to choose, including badly. That
is the trade-off, stated plainly rather than sold as an advantage.

## Credentials and permissions

This is the row the rest of the design follows from.

The usual way to give an agent access to a service is to put a key somewhere
the agent can read: an environment variable, a `.env` file, a token in a git
remote URL. The problem is the reading. Once an agent reads a key in order to
use it, a copy exists in its transcript. Deleting the original does not delete
the copy, and the copy cannot be revoked.

The failure does not require carelessness. A token embedded in a git remote URL
reaches the transcript on the first `git remote -v`, a command an agent runs
routinely and no one thinks of as a disclosure.

[ValetFS](https://github.com/WinM2M/valet-fs) addresses this by keeping keys on
a phone and serving them to the machine in memory, only while the phone allows
it. `valetfs exec` passes the value to a child process, so the agent writes the
command without seeing the key:

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
```

The installer checks the published SHA-256 before installing. That checksum
ships from the same release as the binary, so it catches a bad download but
does not establish provenance; the README gives the cosign command for that.

The bootstrap asks before granting the agent permission to call `valetfs exec`
unprompted. A script can apply the setting; the decision to grant standing
access to a vault should be made by a person.

ValetFS is published by the same author as this repository and has not had a
third-party security audit.

## Generates UI inside the loop

An agent that can only write interface code needs a human to look at the result
and describe what is wrong, every iteration. An agent that can mount what it
built and inspect it closes that loop without the relay.

## Keeps working while you sleep

The cloud wins this row. A hosted agent keeps running when a home machine's
power, network or laptop lid does not. An always-on host with cron and a
container restart policy holds most of the time, and "most of the time" is not
what a datacentre means by uptime.

Scheduled work that cannot be missed belongs in the cloud. Nothing here argues
otherwise.

## Data stays where you put it

For an individual this matters less than it sounds. It starts mattering when a
contract or a jurisdiction restricts where someone else's material may be
processed.

## Cost you can predict

Owning the machine makes the workspace cost easier to estimate, though hardware
fails and electricity is not free. Model API usage is metered either way. This
row is about the workspace, not the model.

## Who this is wrong for

Used a few times a week, a browser tab is the better tool. The setup cost here
only pays back under daily use.
