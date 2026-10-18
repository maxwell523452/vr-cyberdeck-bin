# vr-cyberdeck-bin

my arch package for vr cyberdeck !!

## installation

### automatic (recommended)

run this one-liner to add the pacman repository, update system and install the package:

```bash
sudo sh -c 'grep -qxF "[vr-cyberdeck]" /etc/pacman.conf || printf "\n[vr-cyberdeck]\nSigLevel = Optional\nServer = https://github.com/maxwell523452/vr-cyberdeck-bin/releases/download/pacman-repo\n" >> /etc/pacman.conf' && sudo pacman -Syu --needed vr-cyberdeck-bin
```

### manual installation

download the latest `.pkg.tar.zst` from [GitHub Releases](https://github.com/maxwell523452/vr-cyberdeck-bin/releases) and install it:

```bash
sudo pacman -U vr-cyberdeck-bin-<version>-<release>-x86_64.pkg.tar.zst
```

### manual repository setup

add this block to the end of `/etc/pacman.conf`:

```ini
[vr-cyberdeck]
SigLevel = Optional
Server = https://github.com/maxwell523452/vr-cyberdeck-bin/releases/download/pacman-repo
```

then sync and install:

```bash
sudo pacman -Syu
sudo pacman -S vr-cyberdeck-bin
```

**note:** packages in this repository are currently unsigned, so signature verification is not required for this repository. only add it if you trust my project.

## credits

original repo: [deliciousmeatpop/vrcd](https://github.com/DeliciousMeatPop/VRCD)

i don't own the original project, just packaged it to make installation easier on arch :p

## pls dont forget to star !!!!!!
