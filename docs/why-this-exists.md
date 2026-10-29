# Why this exists

Korean / 한국어: [ko/why-this-exists.md](ko/why-this-exists.md)

I have used this setup every day for about a year. People kept asking why I
bothered, so here is the reasoning behind each row of the table in the README.

## Runs on hardware you control

A cloud workspace starts in seconds because it runs on the vendor's hardware.
The vendor also decides what it may reach, and can change that without asking
me. On my own machine I make those calls.

## Context survives the session

Hosted memory decides what is worth keeping, and what it keeps is usually a
summary. I wanted the agent to read the actual notes and decisions from earlier
sessions, unfiltered.

I was wrong about this for months. I treated it as a nice-to-have while I
worked on permissions. In daily use it has mattered more than almost anything
else here: an agent that starts from the repository plus everything the two of
us already settled is a different tool from one that starts from the repository.

## Desktop and browser control

Hosted agents limit browser and desktop access. On my machine I choose those
permissions, and I own it when I choose badly.

## Credentials and permissions

This is the row that made me build anything.

In the setups I used, credentials reached the agent through environment
variables, `.env` files, or command output. If the agent read one, a copy of it
was in the transcript. Removing the original did not remove that copy, and I
could not revoke it.

I learned this while writing a document about credential isolation. I had left
a token in a git remote URL, and one `git remote -v` copied it into the
transcript. I rotated the token and nothing was exploited. I have no log to
publish; this is my own account of it.

I wrote [ValetFS](https://github.com/WinM2M/valet-fs) because of that. Keys
stay on my phone and are served to the machine in memory while the phone allows
it. `valetfs exec` hands the value to a child process, so the agent writes the
command but never sees the key:

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
```

The installer checks the published SHA-256 before installing it. That checksum
comes from the same release as the binary, so it catches a bad download but
does not prove provenance; the README explains how to verify the cosign
signature instead.

The bootstrap asks before granting the agent permission to call `valetfs exec`
unprompted. A script can apply the setting; the decision about the permission
should be a person's.

I wrote ValetFS myself. It has not had a third-party security audit.

## Generates UI inside the loop

When the agent changes an interface, I want it to mount the result and look at
it before the next edit. Otherwise I am the one relaying what looks wrong,
every iteration.

## Keeps working while you sleep

The cloud is better at this. A hosted agent keeps running when my power, router
or laptop does not. I run an always-on machine with cron and a container restart
policy, which holds most of the time, and "most of the time" is not what a
datacentre means by uptime.

Scheduled work that cannot be missed goes to the cloud. The two are not
exclusive and I use both.

## Data stays where you put it

For individuals this matters less than it sounds. It starts mattering when a
contract or local law restricts where someone else's material may be processed.

## Cost you can predict

Owning the machine makes the workspace cost easier for me to estimate, though
hardware fails and electricity is not free either. Model API usage is metered
either way. This row is about the workspace, not the model.

## Who this is wrong for

If you use an AI assistant a few times a week, use a browser tab. I built this
for daily use and the setup cost is not worth it otherwise.
