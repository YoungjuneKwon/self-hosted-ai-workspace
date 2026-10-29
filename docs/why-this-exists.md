# Why this exists

Korean / 한국어: [ko/why-this-exists.md](ko/why-this-exists.md)

Every row of the table in the README is a thing I ran into while working with
coding agents every day for about a year. This page is the reasoning.

## Runs on hardware you control

A cloud workspace runs in the vendor's building. That is not a complaint — it
is what makes it start in two seconds. But it means the boundary of what you
can do is drawn by someone whose interests are adjacent to yours, not identical
to them, and it can move without asking you.

## Context survives the session

Hosted memory features are real and getting better. They are also opinionated
about what is worth remembering, and they summarise. A directory of files does
not summarise. When an agent can write a note today and read it in three weeks,
without anyone deciding on your behalf which parts mattered, the quality of
long work changes.

This is the row I underestimated longest. The difference between an agent that
starts from your repository and an agent that starts from your repository *plus
everything the two of you have already settled* is larger than it sounds.

## Desktop and browser control

Hosted agents can drive a browser, within limits that exist for good reasons.
On your own machine the limits are yours to set, which means you can also set
them badly. That is the trade.

## Credentials and permissions

This is the row that made me build anything at all.

The default way to give an agent access to something is to put a key where the
agent can read it. An environment variable, a `.env`, a token in a git remote.
Once it is there, it is there for every process, every session, every backup,
and every log line that happens to echo it.

And agents read things. An agent that reads a key has put a copy of it in its
own transcript, which is now a second place the key lives, in a form you do not
control and cannot revoke.

I know this because it happened to me, in the middle of writing a document
about not letting it happen. A token had been sitting in a git remote URL; one
`git remote -v` put it in a transcript. Nothing was exploited. The token was
rotated. But the structure that allowed it was the structure almost everyone is
running.

[ValetFS](https://github.com/WinM2M/valet-fs) is the answer I built. Keys live
on your phone. The daemon serves them to this machine in memory, never to disk,
only while the phone allows it, and `valetfs exec` hands the value to a child
process so it never passes through the agent at all:

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
```

The agent writes that line. The agent never sees the key.

It is pre-installed here because this workspace exists partly to make that the
default rather than the thing you get around to. You can leave it out with
`--no-valetfs`, and the rest still works.

Full disclosure: I wrote ValetFS. Its security work has been reviewed by me and
not by an independent third party.

## Generates UI inside the loop

A coding agent that can only emit code files is working with one hand. Being
able to generate and mount an interface in the same loop — and then look at it
— closes a feedback cycle that otherwise needs a human in the middle of every
iteration.

## Keeps working while you sleep

**The cloud wins this one.** A hosted agent runs on a schedule in a datacentre
with redundant power and a network that does not depend on your router. Your
machine depends on your router, your power, and your laptop lid.

You can narrow the gap. A machine that stays on, a cron entry, a container with
a restart policy — this is roughly what I run, and it holds most of the time.
"Most of the time" is honest, and it is not what a datacentre means by uptime.

If unattended, scheduled, must-not-miss work is the centre of what you do, use
the cloud for that part. The two are not exclusive. People who own houses still
stay in hotels.

## Data stays where you put it

Self-explanatory, and for most individuals it matters less than it sounds. It
starts mattering the moment a client contract, an NDA, or a jurisdiction has an
opinion about where their material is processed.

## Cost you can predict

Credit and subscription pricing is set by the vendor and changes when they
decide it does. A machine you own has a cost you already know. Model API calls
are still metered either way — this row is about the workspace, not the model.

## Who this is wrong for

If you use an AI assistant a few times a week, this is a worse deal than a
browser tab, and I would not use it in your position. Buying a house to spend
four nights a year in it is not frugality.

This is for the people who are there every day.
