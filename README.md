# Update Notifier

A system tray icon that tells you, at a glance, whether your machine has
updates waiting.

**Green** — you are up to date.
**Red** — updates are available.
**Grey** — checking, or installing.

Those are the defaults; the shape and every colour can be changed from the
menu. It checks every ten minutes in the background, and no daemon runs as
root.

Works on **Fedora** (`dnf`) and on **Arch based systems** including
**CachyOS**, Manjaro and EndeavourOS (`pacman`). The package manager is
detected at startup.

---

## Install

### Fedora

Download the `.rpm` from the [Releases](../../releases) page, then:

```bash
sudo dnf install ./update-fedora-rawhide-1.5.0-1.fc46.noarch.rpm
```

### Arch, CachyOS and derivatives

Download the `.pkg.tar.zst` from the [Releases](../../releases) page, then:

```bash
sudo pacman -U ./update-notifier-tray-1.5.0-1-any.pkg.tar.zst
```

Install `pacman-contrib` as well if you do not have it. It provides
`checkupdates`, which is what lets the app look for updates **without asking
for a password**:

```bash
sudo pacman -S --needed pacman-contrib
```

Without it the app falls back to `pacman -Qu`, which only sees updates that
have already been synced, so the count can be stale.

### Either way

The package manager pulls in every dependency on its own. Start it from your
application menu ("Fedora Update Notifier"), or from a terminal:

```bash
update-fedora-rawhide
```

To have it come back on every login, tick **Start with system** in the menu.

### Uninstall

```bash
sudo dnf remove update-fedora-rawhide      # Fedora
sudo pacman -R update-notifier-tray        # Arch
```

That leaves the autostart entry behind, since it lives in your home
directory. Remove it too if you want a clean slate:

```bash
rm -f ~/.config/autostart/update-fedora-rawhide.desktop
```

---

## The menu

| Item | What it does |
|---|---|
| **Check now** | Checks immediately, without waiting for the timer. |
| **Install updates…** | Opens a terminal running the upgrade. You watch it and can abort. |
| **Show package list** | Lists what is pending. |
| **Appearance** | Icon shape and the colour of each state, each row previewed with the real icon. |
| **Start with system** | Adds or removes the autostart entry. |
| **Quit** | Closes the tray icon. |

When the pending updates include a kernel or an NVIDIA package, the menu says
so on its own line. That is deliberate: a new kernel means an out-of-tree
driver has to be rebuilt, and that is what tells you a reboot is coming. It
recognises both families — `kernel*` and `akmod-nvidia` on Fedora, `linux*`
and `nvidia-dkms` on Arch.

---

## Appearance

**Appearance** in the menu sets two things, and nothing is described in words
that can be shown instead: every row carries the icon it would produce, each
colour name is written in its own colour, and the state rows show their
current colour as an icon rather than spelling it out in brackets.

**Icon** — five shapes: `arrow`, `box`, `dot`, `shield`, `refresh`.

**Colour, per state** — seven options: blue, green, grey, white, black, red,
yellow, chosen independently for update, idle and working.

Both take effect immediately and are remembered in:

```
~/.config/update-fedora-rawhide/colors.conf
```

```ini
shape   = arrow
update  = red
idle    = green
working = grey
```

The file is plain text, so you can edit it by hand as well. A bad value is
ignored and the default is used, so a broken config can never stop the icon
from showing up.

---

## How it works

Checking is read-only and runs as your own user, so it needs no password and
nothing privileged sits in the background:

| Distro | Command |
|---|---|
| Fedora | `dnf check-update` |
| Arch | `checkupdates` (falls back to `pacman -Qu`) |

`checkupdates` syncs a temporary database instead of touching the system one,
which is why it works unprivileged.

Only **Install updates…** needs root, and it asks through `pkexec` at the
moment you click it — in a visible terminal, so you see exactly what is being
installed and can stop it. The terminal is whichever of konsole, alacritty,
kitty, ptyxis, gnome-terminal, xfce4-terminal, foot or xterm is present.

Every external call happens on a background thread, so the menu never freezes
while a check is running.

---

## Building the packages yourself

### RPM

```bash
sudo dnf install rpm-build rpmdevtools
rpmdev-setuptree

VERSION=1.5.0
git archive --format=tar.gz \
    --prefix=update-fedora-rawhide-$VERSION/ \
    -o ~/rpmbuild/SOURCES/update-fedora-rawhide-$VERSION.tar.gz HEAD

rpmbuild -ba packaging/update-fedora-rawhide.spec
```

The finished package lands in `~/rpmbuild/RPMS/noarch/`.

### Arch package

On an Arch machine, the normal way:

```bash
cd packaging && makepkg -si
```

From any machine, including a non-Arch one, there is also:

```bash
./packaging/build-arch-package.sh 1.5.0
```

It assembles the `.pkg.tar.zst` by hand — a pacman package is just a tar with
`.PKGINFO`, then `.MTREE`, then the files, in that order — and needs only
`bsdtar` and `zstd`. The result lands in `dist/`.

---

## Requirements

A desktop whose tray speaks StatusNotifier — KDE Plasma, or GNOME with the
AppIndicator extension. Dependencies (`python-gobject`, `gtk3`,
`libappindicator-gtk3`, `libnotify`) are installed automatically.

## License

MIT.
