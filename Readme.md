# Baiji - Steam Frame-specific fork of DolphinXR, a fork of Dolphin

Baiji is an AI-slop fork of
[dolphinXR](https://github.com/iChris4/dolphinXR/), a "developed with
the use of AI tools" (straight from their readme) fork of Dolphin.

Baiji may be AI slop but this Readme.md is organic and home-grown by a
human.

Baiji is intended to be a near-term fork that directly integrates with
the Steam Frame, removing the complication of trying to figure out how
to stream VR from a remote computer, deal with VR control schemes,
etc., and so forth, making a fork of Dolphin that _just works_ in 3D
on the Steam Frame.

3D? Did I say 3D? Yes, 3D. Core Dolphin has a long-standing feature
called [stereoscopic
3D](https://wiki.dolphin-emu.org/index.php?title=Stereoscopic_3D_Setup),
which allows the running of Dolphin on a 3D monitor or with 3D
glasses. However the hardware is specialized and the setup was not VR
aware, so a default Dolphin install can only run flat on a virtual
screen.

The primary purpose of this fork is to make this stereoscopic 3D Just
Work™. I can't show what this looks like in a static shot on GitHub,
but if you can cross your eyes, here's [Super Mario Galaxy 2 in
stereoscopic 3D on
YouTube](https://www.youtube.com/watch?v=XmgdqCL2toE). I found a
normal phone a pretty good way to view that with cross-eyes; getting
the sizing right on a desktop is pretty challenging.

In principle it is as easy as installing Baiji, getting a legal file
Dolphin can read as a Wii game, and starting the ROM. Baiji should
come up with a sensible Steam Frame controller mapping for a WiiMote +
Nunchunk, in stereoscopic 3D, with sensible performance settings
(which includes "precompiling shaders" before startup, though you may
see some initial stutters as the cache is built out), and be off to
the races. In practice, this is the work of a long weekend and I've
tested a whopping 4 games, only one from the Gamecube, and one of
which had an early crash with at least one of the development
version.

So don't expect miracles.

But I figured this had gotten to the point where more eyes was the
better way to go.

A ["Baiji" is a possibly-extinct subspecies of
dolphin](https://en.wikipedia.org/wiki/Baiji). Most dolphin species
have clumsy, branding-unfriendly names like "Hector's Dolphin". Baiji
is a nice snappy name. Baiji are also possibly extinct, which
represents the fact I don't necessarily expect this to be a long-term
fork of the Dolphin project. I expect that someday, they will
incorporate the major features of this project into the
mainline, and that will mark the end of this fork. However, due to
their completely rational and justifiable policy about AI, it may take
some time because they can not and will not just pick this code up.

I also aspire to demonstrate the utility for any emulator of any 3D
system of building a native Steam Frame build that Just Works™ with
similar stereoscopic 3D, until someday the release of Baiji is looked
back as the harbinger of when running the Emustation or similar
install script doesn't just install a bunch of flat emulators but
installs 3D-aware emulators for all the 3D systems. Especially the
3DS, because as the only native 3D commercial gaming system that will
not have the issues with eye-twisting things like text behind other 3D
objects and stuff.

I aspire to see the Steam Frame become considered
_the_ definitive way to emulate 3D-based systems because of the additional
3D experience it can offer, out of the box, such that anyone can use
it without trying to get widely disparate enviromnents and libraries
and streaming and everything set up. Perhaps even, dare I think it,
that this use case becomes considered one of the definitive reasons to
get a Steam Frame. Vive le matériel libre.

# Features

* Steam Frame-centric default settings, including mappings and such.
* Integrated Stereoscopic 3D, including some new settings not in the
  original 3D support of use in VR.
* Retained the VR work from the dolphinXR branch, selectable in a
  drop-down.
* Also retained flat mode, where at least the default Steam Frame
  configurations can be of some use.
* Controller configuration that works in the Steam Frame UI.

# Installation And Startup

Unfortunately, as far as I can tell, it is not currently possible to
release this as a Flatpak, because Flatpak software can not get to the
VR infrastructure. I expect this to change over time, but who knows
when.

Snapshots are not available yet. For now, install by building from source
with the instructions below.

## Install From Snapshot

Hey, if you're seeing this, congratulations, you've snuck in before
the official release. These instructions should work, but if you would
be so kind as to let me announce this tomorrow morning, that'd be
great, thank you.

(These instructions assume you haven't changed the `steamos` user. If
you don't know what that means, you haven't. I think some paths end up
in the executable. If you have changed it, you may need to do some
symlinking or hardlinking to have this end up unpacked into
`/home/steamos/baiji`.)

1. Start the Desktop environment in your Steam Frame.
2. Navigate to this URL in a browser.
3. Start `Konsole`, or the terminal of your choice.
4. Copy this by clicking on the little double-square next to these
   commands:

   ```bash
   cd
   wget https://github.com/thejerf/baijiSteamVR/releases/download/baiji-v0.1-alpha/baiji-v0.1-alpha.tar.bz2
   tar xjf baiji-v0.1-alpha.tar.bz2
   ssh frame "steamos-add-to-steam ./baiji/bin/baiji-vr"
   ```
5. Paste that into your Konsole session and hit "enter" on the
   keyboard.
   
`baiji-vr` will appear as an option in your Non-Steam Games library.

From there you'll need to load it up with your legally-acquired ROMs.

## Build and Install From an x86_64 Linux Machine

This is the maintained way to build a Steam Frame version. The host needs
Git and Podman. If the AArch64 KDE SDK is not already present in the
checkout, Flatpak is needed on the first build to install it into ignored
`state/` build data. This SDK is a compiler sysroot; Baiji itself is built
as a regular executable, not a Flatpak. QEMU's AArch64 emulator is installed
in the build image, so the host does not need to provide it.

1. Turn on Developer Mode on the Frame and enable SSH access. Configure an
   SSH host alias on your Linux machine (replace the example address with
   the Frame's IP address):

   ```sshconfig
   Host frame
       HostName 192.168.1.123
       User steamos
   ```

   Verify the connection with `ssh frame`. If you use a different alias,
   pass it instead of `frame` in the deploy command below.

2. Clone baiji, set up some necessary cross-compilation code, build,
   and deploy:

   ```bash
   git clone --recurse-submodules https://github.com/thejerf/baijiSteamVR.git
   cd baijiSteamVR
   ./scripts/compile-cross-sdk.sh
   ./scripts/deploy-frame.sh frame
   ssh frame "steamos-add-to-steam ./baiji/bin/baiji-vr"
   ```

   Debug symbols are omitted by default. To include them, run the build command as
   `DEBUG_SYMBOLS=1 ./scripts/compile-cross-sdk.sh`.

   These instructions build the current checkout rather than a packaged
   release, so the code may be unstable.

   The build stages the Frame-compatible files under
   `state/stage-frame/home/steamos/baiji` before transferring them. The
   deploy script installs Baiji's executables, private libraries, and data
   under `~/baiji`.

3. On the Frame, launch `~/baiji/bin/baiji-vr` from a Desktop terminal, or
   add that path as a non-Steam game to launch it from Big
   Picture. Add legally dumped game images through Baiji's open dialog or configure the
   game search paths in Baiji.

I don't use Windows but any ol' AI can probably adapt this to a
Windows or MacOS build process pretty easily. If an AI offers to build
you an "emulation-based" toolchain, where it runs a native ARM
toolchain on an x86 CPU, decline that. It was miserably slow. I don't
know about ARM-based Mac OS machines.

# Ownership

I see a number of other people are working on similar forks. Honestly,
I don't really care to own this. All I want is the stereoscopic 3D,
even if you pursue VR being another option, because of the ability to
manipulate the stereoscopic 3D settings as I have them in this repo
and the utility I think that will have. (Skies of Arcadia is seriously
eye-crossing if you don't turn down the 3D.) Have a look at the
reconfigured UI for the VR panel in this branch and how it allows you
to select the various options. If anyone wants to have their AI look
over my patch stream, break it down by feature, and incorporate it
into your project, that's great. You can have the branding too if you
like. I don't care.

# Known Quirks

* In Stereoscopic 3D mode, stopping the emulation (default the "View"
  button, the button on top of the left controller) pops up a dialog
  box in the QT environment asking you if you want to stop
  emulation. The user experience is that emulation just freezes and
  there is no indication of this. You must hit the Steam button to
  pull up the Steam UI, and then, it seems to be random whether it
  shows the default Steam OS controls for stopping or resuming the
  game or the QT UI. You can select the QT UI from the list of running
  windows on the left, then click "Yes", and emulation will stop and
  control return to the main UI.
* You may need to recenter once to align the pointer in Stereoscopic
  3D mode.
* If you choose to emulate in Flat Mode, your controllers will be in
  laser mode when you click "play". You *must* be in gamepad mode to
  actually play the game. I panicked several times during
  development that I had broken controller support but it was just
  that I had forgotten to switch.
* I believe this is the case in core Dolphin as well, but the main UI
  is mostly frozen during emulation. But only mostly. Still, best just
  to treat it as frozen until you stop the emulation.
* I left the "immersive VR" work in from the dolphinXR branch if you
  want to play with it, but something seems to be pretty wrong with
  this port of it. I didn't spend much time diagnosing it and probably
  sent the AI down the completely wrong track anyhow.

# The Usual Fake FAQs

Most FAQs aren't really "frequently asked", they're just made up
things the developer expects to be asked. This list is no different.

## Why Are Issues Closed On This Repo?

My dear friend gamer. I'm very happy to see you. I hope this
repository brings you fun and joy.

But can I level with you?

I didn't do this work so I could spend the next several months
addressing issues like _When I Jam The Wii Virtual Console "Ocarina Of
Time" Into Baiji, Equipping The Boomerang Makes Link's Head
Disappear Unless I Am Standing On My Head In Real Life_.

This is shared in a spirit of fun... and that includes me, having fun,
bulding something together with the community, not volunteering to be
personally responsible for getting Baiji running on every Steam Frame
in the world.

Moreover, the truth is, this is a very complicated repo to make issues
into: 

* This project is not competent to address emulation issues inside
  of Dolphin.
  
  Making emulation changes is an extremely complicated and
  frought process; what fixes one issue in a game breaks hundreds of
  other games. If there is an emulation issue in Baiji, the simple, but
  harsh truth is, it's going to stay there.
  
  The upstream Dolphin team has the skills, the testing
  infrastructure, the decades of awareness, and the community to make
  changes. Even with the mighty power of
  *AI*... AI... Ai... ai... i... I do not have the skills, the testing
  infrastructure, or the community. So the best thing is just not to
  start accepting issues that are not going to go anywhere anyhow.

  The only exception is that some blessed soul may make a PR that does
  an upstream pull from the Dolphin project. That I may be able to
  accept. But that's the only emulation fix this project is likely to
  make.

* No Wii or Gamecube game was designed to run this way. They will do
  weird things. They will put all their action into stuff that is
  very, very out-of-frame for the TV that is virtually impossible to
  focus on. The entire UI will sit in a 2D plane that is somehow
  behind the action visually, yet sitting on top of it.
  
  No game quirk of this nature is in scope for Baiji (or Dolphin, for
  that matter). "Fixing" this would require someone to directly modify
  the ROM as a fan patch; there's nothing much the emulator can do
  about it. Some games are going to be like Super Mario Galaxy -
  quirky, but ultimately quite enhanced by the 3D. Some games will
  probably be rendered unplayable. Many games will be in between. All
  you can do is try them.

* The only things that are really "Baiji" about this project are the
  utilization of OpenXR to implement the stereoscopic 3D, a few
  additional controls for the stereoscopic 3D, and the
  specialization of the UI to the Steam Frame.
  
  Basically everything else is out-of-scope. Immersive VR is part of
  the dolphinXR project. Which, as I write this, is still under
  development and I am now at least a week behind them, which means
  it's not an accurate representation of their current state. If that
  project asks me to remove the immersive VR from this one, I will
  comply. If someone does a tested PR, we can pull it in.
  
Really, the only useful things to the project are PRs, not bug
reports. 

So, on that topic...

## How Do I Fix A Bug?

This is VERY IMPORTANT: In an era of AI, the value you bring to a PR
submitted to any project *IS NOT THE CODE*. Code is not free, but its
value is rapidly dropping.

The value you bring is [in the
*TESTING*](https://jerf.org/iri/post/2026/what_value_code_in_ai_era/).

Code used to have some value. Most of that value is gone. Not quite
all, but most. What Baiji and other products need is *TESTING*. Both
for quality, and for the user experience.

I have an AI too. I too can run a prompt that says "make a Minecraft
clone, make no mistakes, kthxbye". The result will be superficially
playable, but not even remotely fun or good.

It may seem like I'm not actually answering the question in the
heading, but the answer is, the way you fix a bug is to set up your
coding environment, you can use whatever you like to fix something,
but then you need to test it. It is *WORSE THAN USELESS* for you to
type a prompt into your AI and immediately rush to submit it as a
PR. I would literally _rather not have that PR at all_.

What I need is for you to _test_ your PRs.

If you create a PR, and you test it, you have something that may be of
value to the project.

Once you have a tested branch in your local repo(s), the AI can walk
you through the process of creating a PR if you don't already
know. The PR prompt will hopefull guide you in this as well, but
please tell us all what testing you have done on your PR.

That doesn't mean you need to have tested every possible interaction
with every possible feature on every possible game. Goodness knows
Baiji's work doesn't even remotely rise to that standard either! But
it is very helpful to know what testing has and has not been done, so
we can know what to look out for, and others may know to make their
own PRs against your PR. Do not be shy to say "I haven't tested this
with X". The space of "all possible Wii and Gamecube games" is
huge.

Because the true value of a PR is testing, note that _testing_ someone
else's PR can be as valuable or even more valuable than coming up with
one of your own. Before starting a PR check the PR tab and see if
there's anything either close to your work or is what you'd have
made. If so, please join with that PR rather than source a new
one by building that PR yourself and running it on your local Steam
Frame. There is nothing as valuable as the _second_ pair of eyes on a
PR!

## Why Not A Flatpak?

As near as I can tell, it is currently *impossible* to get to VR from
a flatpak, and the reason why can only be fixed by Valve.

To get to VR, you need to open a Unix socket to the VR server. The VR
server has some validation on the incoming PID and possibly some other
checks that flatpaks can't pass. The AI and tried some hacking around
but I was focused on getting this to work at all and didn't bang on
this too hard.

A successful Flatpak PR that proves me wrong is one I'd accept with gusto.

This also, unfortunately, suggests that until this is fixed, it may
not be a great idea to try to pack this with Emustation or
anything. If they disagree I have no objection, but I would suggest
that at least as I write this, this project is not necessarily ready
for that sort of prime time.

## Why Did You Rename This Project? Are You Trying To Steal Credit Or Something?

No, this is actually out of politeness to the Dolphin project, and I
believe in accordance with their wishes. The name of the project isn't
just about the name of the executable or the title screen that comes
up when you run it. It's about who is standing behind it and who is
responsible for it.

The Dolphin team is not behind this project. In particular that means,
if the pieces break, you own them, maybe I have a bit of
responsibility for them, but the Dolphin team has no responsibility
whatsoever. Not even the polite one of at least listening to your
problem. The correct solution for the Dolphin project, if anyone
doeesn't pick up what I have repeatedly tried to lay down, and files a
bug with them, or starts a forum thread about bugs in Baiji, or
anything else like that, is to immediately close it/lock it, and scold
you a bit for putting it in the wrong place.

Renaming this project is part of a statement that says, if you have a
problem with Baiji, you do not go to the Dolphin forum for support any
more than you'd go there for support with LibreOffice.

Anyone who distributes a very modified version of an open source
project, especially if like me the _know_ upstream can not and will
not take their patches as-is, _should_ rename the project.

Me trying to steal credit would look like me trying to erase all signs
of the Dolphin heritage out of the executable entirely.

Instead: I am a mere minnow next to the awesome Dolphin project. I am standing
on the shoulder of their giantness, and to a lesser but still
significant extent, on the work of the dolphinXR fork. I am
deeply appreciative and while I want to help the Steam Frame, this is
a mere trivial "one long weekend" gloss on top of the
who-knows-how-many person-centuries of work the Dolphin project
represents. Do not overestimate my "contribution". Nothing in this
paragraph is a joke or even slightly sarcastic.

On that note, if I've screwed up licensing or if anyone from the
Dolphin project has opinions about the details around how I've done
this, I am very open to change, correction, PRs on this matter,
etc. This is a sign of me trying to do it very correctly and
carefully, not carelessly, and not to steal credit.

## What PRs Would Be Nice?

Here's my current wishlist:

* As mentioned, some way of distributing an unmodified Flatpak, BUT
  isn't super, super hacky. Remember, you can't really run a script on
  the outside; this has to work with "flatpak run" to be a "real"
  flatpak. I'd rather just distribute this as-is than
  distribute a Flakpak almost certain to break in the near
  future. This may require changes from Valve.
* An uninstall script that gets all the little config tidbits left
  lying around the home directory, in case the user tires of Baiji.
* An informed opinion (from some experience in play) about how to map
  some of the hotkey actions to the controller. Both Wiimote +
  Nunchuck and Gamecube controllers are pretty full up on the
  controls. We _need_ a "stop emulation" button, but it's not clear
  where to put save/restore state and a whole bunch of other useful
  functionality like that until we get some use under our belt.
* If it becomes clear the core Dolphin project is keying in on support
  that may obsolete this project, especially direct support for
  stereoscopic 3D in an OpenXR environment, a migration script to move
  configuration and saved games into a target Dolphin installation.
* A UI accessible in stereoscopic 3D mode that allows real-time
  modification of the stereo settings, and committing them to
  game-specific configuration.
  
  When I wrote the bit about how important testing is, this is the PR
  I had in mind. It is easy to put together a garbage UI. For
  instance, it is tempting to make the various numbers a slider. But
  if _all_ you can do is slide them, it is very difficult to build a
  slider that is accurate. The especially tend to jerk at the very
  end just as you are releasing the button, and trying to make very
  small angular adjustments to change a value is not easy. Something
  like "point at the control and use thumbstick to adjust" may help,
  but then you need documentation the user can use to figure that out
  in realtime as they use it.
  
  Also bear in mind that once a stereoscopic 3D frame is rendered,
  it's just two flat images. Modifications must be run on live
  games, because once a frame is rendered it's locked in.
  
  Another interesting thing to play around with in such a dialog is a
  cull plane for the near frame. I haven't played with this long but
  eye strain is a real issue, and it may be preferable to cull things
  that are too near than to let users try to see them. It can also be
  used as a test that the user needs to reduce the stereo or something.
* I also don't know if this is technically possible, but I would be
  interested in seeing if there is some sensible way to offer a slider
  that just pushes everything _back_, away from the user, in case a
  game takes place largely in the near frame, but without distorting
  the game in any other way by compensating in the camera
  matrix, or, at least, distorting it minimally. Or forward, as the
  case may be, though "back, out of the part of the 3D space that
  causes eye strain/pain" seems like the more important use case.
* Any bug fixes in the UI, of course.
* A PR to make it so when you stop the emulation, the dialog box for
  "would you like to stop emulation" comes up in VR space, rather than
  in the QT UI. The latter is very easy to miss.
* A PR to update the immersive VR to work correctly.
* Emulation issues that you have a _very very_ good case are somehow
  Steam Frame-specific and justify a Steam Frame-specific
  fix. Otherwise I'd consider the emulation path off-limits.

# Command Line Tooling

## Command Line Usage

Command line is inherited from Dolphin, just renamed. This has not
been gone over with a fine-toothed comb and may contain options not
relevant to the Steam Frame, may partially or completely not work on a
Steam Frame (e.g. I have no idea what a "movie" will do on a Steam
Frame, especially in its various modes), etc.

```
Usage: baiji [options]... [FILE]...

Options:
  --version             show program's version number and exit
  -h, --help            show this help message and exit
  -u USER, --user=USER  User folder path
  -m MOVIE, --movie=MOVIE
                        Play a movie file
  -e <file>, --exec=<file>
                        Load the specified file
  -n <16-character ASCII title ID>, --nand_title=<16-character ASCII title ID>
                        Launch a NAND title
  -C <System>.<Section>.<Key>=<Value>, --config=<System>.<Section>.<Key>=<Value>
                        Set a configuration option
  -s <file>, --save_state=<file>
                        Load the initial save state
  -d, --debugger        Show the debugger pane and additional View menu options
  -l, --logger          Open the logger
  -b, --batch           Run Dolphin without the user interface (Requires
                        --exec or --nand-title)
  -c, --confirm         Set Confirm on Stop
  -v VIDEO_BACKEND, --video_backend=VIDEO_BACKEND
                        Specify a video backend
  -a AUDIO_EMULATION, --audio_emulation=AUDIO_EMULATION
                        Choose audio emulation from [HLE|LLE]
```

Available DSP emulation engines are HLE (High Level Emulation) and
LLE (Low Level Emulation). HLE is faster but less accurate whereas
LLE is slower but close to perfect. Note that LLE has two submodes (Interpreter and Recompiler)
but they cannot be selected from the command line.

## Baiji Tool Usage

```
usage: baiji-tool COMMAND -h

commands supported: [convert, verify, header, extract]
```

```
Usage: convert [options]... [FILE]...

Options:
  -h, --help            show this help message and exit
  -u USER, --user=USER  User folder path, required for temporary processing
                        files.Will be automatically created if this option is
                        not set.
  -i FILE, --input=FILE
                        Path to disc image FILE.
  -o FILE, --output=FILE
                        Path to the destination FILE.
  -f FORMAT, --format=FORMAT
                        Container format to use. Default is RVZ. [iso|gcz|wia|rvz]
  -s, --scrub           Scrub junk data as part of conversion.
  -b BLOCK_SIZE, --block_size=BLOCK_SIZE
                        Block size for GCZ/WIA/RVZ formats, as an integer.
                        Suggested value for RVZ: 131072 (128 KiB)
  -c COMPRESSION, --compression=COMPRESSION
                        Compression method to use when converting to WIA/RVZ.
                        Suggested value for RVZ: zstd [none|zstd|bzip|lzma|lzma2]
  -l COMPRESSION_LEVEL, --compression_level=COMPRESSION_LEVEL
                        Level of compression for the selected method. Ignored
                        if 'none'. Suggested value for zstd: 5
```

```
Usage: verify [options]...

Options:
  -h, --help            show this help message and exit
  -u USER, --user=USER  User folder path, required for temporary processing
                        files.Will be automatically created if this option is
                        not set.
  -i FILE, --input=FILE
                        Path to disc image FILE.
  -a ALGORITHM, --algorithm=ALGORITHM
                        Optional. Compute and print the digest using the
                        selected algorithm, then exit. [crc32|md5|sha1|rchash]
```

```
Usage: header [options]...

Options:
  -h, --help            show this help message and exit
  -i FILE, --input=FILE
                        Path to disc image FILE.
  -b, --block_size      Optional. Print the block size of GCZ/WIA/RVZ formats,
then exit.
  -c, --compression     Optional. Print the compression method of GCZ/WIA/RVZ
                        formats, then exit.
  -l, --compression_level
                        Optional. Print the level of compression for WIA/RVZ
                        formats, then exit.
```

```
Usage: extract [options]...

Options:
  -h, --help            show this help message and exit
  -i FILE, --input=FILE
                        Path to disc image FILE.
  -o FOLDER, --output=FOLDER
                        Path to the destination FOLDER.
  -p PARTITION, --partition=PARTITION
                        Which specific partition you want to extract.
  -s SINGLE, --single=SINGLE
                        Which specific file/directory you want to extract.
  -l, --list            List all files in volume/partition. Will print the
                        directory/file specified with --single if defined.
  -q, --quiet           Mute all messages except for errors.
  -g, --gameonly        Only extracts the DATA partition.
```

# Dolphin Links

Relevant links for the original Dolphin underneath Baiji:

* [Homepage](https://dolphin-emu.org/)
* [Project Site](https://github.com/dolphin-emu/dolphin) 
* [Forums](https://forums.dolphin-emu.org/) but DO NOT report Baiji
 bugs
* [Wiki](https://wiki.dolphin-emu.org/)
* [GitHub Wiki](https://github.com/dolphin-emu/dolphin/wiki) 
* [Issue
  Tracker](https://bugs.dolphin-emu.org/projects/emulator/issues) but
  DO NOT... you ought to have gotten this by now... report Baiji bugs
* [FAQ](https://dolphin-emu.org/docs/faq/)
