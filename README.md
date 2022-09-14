# C4-deployment-tool
This utility is a simple archive generator for the C4 project.

ATM it is only confirmed working on linux, though it ought to work fine
on windows with a bit of effort (mostly just adding .exe in places).

You can use `--help` for a list of arguments, though those are just to
override options in deploy_options.ini. No they do not get cached.


There may be bugs. I haven't really tested everything beyond basic functionality,
and frankly I'm probably one of five people who will ever use this anyways.

# Usage
You need to place your bins in the binaries dir. They use the default output
names so:
- linux: `CortexCommand`
- windows: `Cortex Command x64.exe`

If one is missing that step will be skipped. If both are missing the tool
will complain.

After those are in, and you ensure you set `deploy_option.ini`'s `datapath`
to where your c4 data dir is, along with setting version to what you want,
just run `c4-deployment-tool`.


# Compiling
You are probably better off just grabbing a release. Not really worth installing
an entire compiler just for a tiny tool like this.

If you *really* want to though, you need to install [v (https://vlang.io/)](https://vlang.io/).
I've bundled the needed modules alongside this just to make life a bit easier
for non-autists, but understand that karoscript is **not** part of the C4 project,
rather it is part of something else of mine.

Also I have no clue why the hell `-prod` is broken but tbf V is still indev.



Tl;dr: `./build_deploy.sh`
