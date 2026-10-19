# Baiji - Steam Frame-specific fork of DolphinXR, a fork of Dolphin

Baiji is a fork of
[dolphinXR](https://github.com/iChris4/dolphinXR/), a "developed with
the use of AI tools" (straight from their readme) fork of Dolphin.

Baiji's headline features:

* Native support of stereoscopic 3D and a VR mode. Play your games in
  3D as easily as playing them in an original Dolphin build. No
  fiddling with other external addons, just play your Wii and Gamecube
  games in 3D. Flat mode is still available for games that work best
  that way.
* Native understanding of the Steam Frame controller, and a default
  mapping for it that should be sensible for Wiimote + Nunchuck or a
  Gamecube controller.
* Other streamlining to work with the Steam Frame natively.

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

0. If you have installed a previous version of Baiji, make sure it's
   not running.
1. Start the Desktop environment in your Steam Frame.
2. Navigate to this URL in a browser.
3. Start `Konsole`, or the terminal of your choice.
4. Copy this by clicking on the little double-square next to these
   commands:

    ```bash
    cd
    wget https://github.com/thejerf/baijiSteamVR/releases/download/baiji-v0.2-alpha/baiji-v0.2-alpha.tar.bz2
    tar xjf baiji-v0.2-alpha.tar.bz2
    ```
5. Paste that into your Konsole session and hit "enter" on the
   keyboard.
6. On first install only, add the launcher to Steam:

   ```bash
   ssh frame "steamos-add-to-steam ./baiji/bin/baiji-vr"
   ```
   
`baiji-vr` will appear as an option in your Non-Steam Games library.

Once installed, use the configuration menu to set your path to your
ROM directory, or use File -> Open to play a ROM.

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

# Performance Issues

* Remarkably, there are still even some Gamecube games that the Steam
  Frame can struggle with. I have verified this with a native build of
  Dolphin 2609: The Steam Frame can only barely push Wind Waker
  at native resolution on one screen, and it still makes some stutters
  even so. The good news is, if you sit through the emulation stuttering,
  it actually doesn't look all that great in 3D. The cell shading effect
  flattens everything out into a rather visually boring 3D effect,
  rather than looking awesome, so we're not missing anything.

# Known Quirks

* You may need to recenter once to align the pointer in Stereoscopic
  3D mode.

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

## This Game Works Poorly In Stereoscopic 3D Or VR

The farther you push a game out of its native environment, the worse
it gets. Stereoscopic 3D is already pushing a lot of games. Any game
that works in VR is a minor miracle.

Issues about specific games in either 3D mode will not be accepted for
Baiji. Fixing them would require something more like a full
decompilation and rewrite project, not tweaks to Baiji.

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

* v0.2-alpha (not released yet)
  * Stopping the emulation should now, in all modes of access, produce
    some user-visible dialog asking if they are sure, rather than
    seeming to just freeze the game until you have the idea to go to
    the QT UI and answer the dialog box that appeared there.
  * Per reddit user FerrisTriangle, [some settings are necessary to
    use Immersive
    VR](https://www.reddit.com/r/SteamFrame/comments/1x01rte/comment/pevcr99/?context=3). I
    tested them out individually and identified two that seem to be
    necessary, so those two are now locked to the correct setting if
    Immersive VR is chosen.
  * Fixed the core QT UI not rendering while the game is emulating,
    which also fixes the fact that starting a game requires you to
    just know that you need to hit the Steam button. This also returns
    access to all the config you can change while the game is running,
    menus for accessing save states, etc.
  * Fixed what seems to be the last major performance regression
    against a natively-compiled Dolphin.
  * Added + and - to mapping on left & right bumper for Wii +
    Nunchuck.
  * Room View support improved, but probably still needs work.
  * Improved the way a surface is requested for flat 2D mode. I'm
    honestly uncertain if v0.1-alpha was broken, but if it was this
    should fix it, if it wasn't, this should make future builds less
    likely to break.
* v0.1-alpha - Initial release.
  * Many Frame-specific UI changes to make working with the Frame
    specifically slicker.
  * Support for the full Frame controllers with their XR profile.
  * Support for native display of stereoscopic 3D.
