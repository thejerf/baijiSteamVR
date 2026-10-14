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

## Install From Snapshot

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

# Performance Tips and Tricks

* Wii emulation itself has a problem called _shader stutter_, where
  the first time you're doing "something", where "something" is hard
  to define but is often
  "the first time you've seen some particular object or effect in the game",
  there will be a hitch in the emulation while it is
  "compiling a shader". You can see Dolphin's own [extensive
  discussion of this problem and their Ubershader
  solution](https://dolphin-emu.org/blog/2017/07/30/ubershaders/).
  
  That's an old blog post and some of the discussion about specific
  hardware is out of date. However, the general problem hasn't gone
  anywhere.
  
  And the Steam Frame is not powerful enough to run Ubershaders. You
  should almost certainly leave the default setting to compile the
  shaders in advance on. You can try Hybrid mode; note that can take
  a minute or two (literally, minutes) to start, but may help. You can
  fiddle with the "Skip Drawing" if you really want to try to avoid
  the hitches, at the price of potentially having popin or breaking
  certain features.
  
  But be aware this seems to be intrinsic to the problem of Wii
  Emulation. The only "solution" is to (eventually) stream this from
  something that supports full 3D to the Frame and can handle an
  Ubershader.
* Remarkably, there are still even some Gamecube games that the Steam
  Frame can struggle with. I have verified this with a native build of
  Dolphin 2609: The Steam Frame can only barely push Wind Waker
  at native resolution on one screen, and it still makes some stutters
  even so. The good news is, if you sit through the emulation stuttering,
  it actually doesn't look all that great in 3D. The cell shading effect
  flattens everything out into a rather visually boring 3D effect,
  rather than looking awesome, so we're not missing anything.

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
  that I had forgotten to switch. There is a dialog that should remind
  you. Note this is an aspect of the Steam OS, not Baiji.
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
problem. The correct solution for the Dolphin project, if anyone files a
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
a mere trivial "couple o' weekends" gloss on top of the
who-knows-how-many person-centuries of work the Dolphin project
represents. Do not overestimate my "contribution". Nothing in this
paragraph is a joke or even slightly sarcastic.

On that note, if I've screwed up licensing or if anyone from the
Dolphin project has opinions about the details around how I've done
this, I am very open to change, correction, PRs on this matter,
etc. This is a sign of me trying to do it very correctly and
carefully, not carelessly, and not to steal credit.

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

# Known Quirks/Bugs That Don't Seem Fixable

For any of these, a PR that proves me wrong would be great, but as far
as I know these are currently not reasonable fixable:

* When the QT UI is visible during 3D emulation, SteamOS spatializes
  Baiji's emulation output to be coming from the location of the QT
  UI, not the emulation. The Frame's OS does not seem to offer a way
  to bypass this for just one application. It seems to have a switch
  that could be thrown for the whole OS but I'm not touching it.

# Changelog

* Todo before release:
  * Check Room View in VR, can probably leave that rendering while the
    Steam UI is up
  * Check the Reddit feedback about the settings that make VR work,
    and lock the ones that _must_ be set for Immersive VR to work,
    when Immersive VR is selected.

* v0.2-alpha (not released yet)
  * Added + and - to mapping on left & right bumper for Wii +
    Nunchuck.
  * Turning on Room View with the Steam UI stops rendering in Stereo
    and VR mode and pauses the emulation, rather than continuing to
    render and emulate and making it look like it was ignoring
    controls.
    
    Ideally, we'd leave the game UI up if you bring up the Steam UI,
    and only stop displaying the game if you go to full room view
    mode, but once focus is removed from the game, baiji can't tell
    what you're doing. Since we can't be smart about this, we have to
    not display the game even if you only are looking at the Steam UI.
    
    This may be a bug in the UI's Room View support; it shouldn't let
    us draw on it. If it correctly ignored our draw requests we could
    get it to work like most other games, which still render in the
    background.
  * Improved the way a surface is requested for flat 2D mode. I'm
    honestly uncertain if v0.1-alpha was broken, but if it was this
    should fix it, if it wasn't, this should make future builds less
    likely to break.
* v0.1-alpha - Initial release.
  * Many Frame-specific UI changes to make working with the Frame
    specifically slicker.
  * Support for the full Frame controllers with their XR profile.
  * Support for native display of stereoscopic 3D.
