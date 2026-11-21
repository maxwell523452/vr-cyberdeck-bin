# vr-cyberdeck-bin

my arch package for vr cyberdeck !!

## installation

### automatic (recommended)

run this one-liner to trust the signing key, add the pacman repository, update system and install the package:

```bash
sudo sh -c 'curl -fsSLo /tmp/vr-cyberdeck.gpg https://github.com/maxwell523452/vr-cyberdeck-bin/releases/download/pacman-repo/vr-cyberdeck.gpg && pacman-key --add /tmp/vr-cyberdeck.gpg && pacman-key --lsign-key 31E2D89A9C8721ED5BDCEE294CF28534145E2B89 && { grep -qxF "[vr-cyberdeck]" /etc/pacman.conf || printf "\n[vr-cyberdeck]\nSigLevel = Required DatabaseRequired\nServer = https://github.com/maxwell523452/vr-cyberdeck-bin/releases/download/pacman-repo\n" >> /etc/pacman.conf; }' && sudo pacman -Syu --needed vr-cyberdeck-bin
```

if the key that gets downloaded is not the one with the fingerprint below, `--lsign-key` fails and the repository is not added.

### manual installation

download the latest `.pkg.tar.zst` **and** its `.sig` from [GitHub Releases](https://github.com/maxwell523452/vr-cyberdeck-bin/releases) into the same folder and install it:

```bash
sudo pacman -U vr-cyberdeck-bin-<version>-<release>-x86_64.pkg.tar.zst
```

### manual repository setup

first trust the signing key:

```bash
curl -fsSLo /tmp/vr-cyberdeck.gpg https://github.com/maxwell523452/vr-cyberdeck-bin/releases/download/pacman-repo/vr-cyberdeck.gpg
gpg --show-keys --with-fingerprint /tmp/vr-cyberdeck.gpg
sudo pacman-key --add /tmp/vr-cyberdeck.gpg
sudo pacman-key --lsign-key 31E2D89A9C8721ED5BDCEE294CF28534145E2B89
```

the fingerprint that gpg prints must be exactly:

```
31E2D89A9C8721ED5BDCEE294CF28534145E2B89
```

then add this block to the end of `/etc/pacman.conf`:

```ini
[vr-cyberdeck]
SigLevel = Required DatabaseRequired
Server = https://github.com/maxwell523452/vr-cyberdeck-bin/releases/download/pacman-repo
```

then sync and install:

```bash
sudo pacman -Syu
sudo pacman -S vr-cyberdeck-bin
```

**note:** packages and the database in this repository are signed now. if you added the old unsigned repo before (`SigLevel = Optional`), change it to the block above.

## debian / ubuntu

this repo is for arch only. on debian/ubuntu use the `.deb` that upstream publishes on their [releases page](https://github.com/DeliciousMeatPop/VRCD/releases).

## quest usb access

the package ships a udev rule so your user can talk to the headset without root. if the quest is not detected, unplug it, plug it back in and accept the usb debugging prompt on the headset. for android phones install `android-udev`.

## how updates work

a workflow checks for new upstream releases every day and opens a pull request. i review it, merge it, and the package gets built, signed and published automatically.

## credits

original repo: [deliciousmeatpop/vrcd](https://github.com/DeliciousMeatPop/VRCD)

i don't own the original project, just repackaged the official `.deb` to make installation easier on arch :p

maintained by Maxwell

## pls dont forget to star !!!!!!
