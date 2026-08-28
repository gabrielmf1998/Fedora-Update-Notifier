# Update Check Fedora Rawhide

A system tray icon that tells you, at a glance, whether your Fedora Rawhide
machine has updates waiting.

**Green** — you are up to date.
**Red** — updates are available.
**Grey** — checking, or installing.

Those are the defaults; each state's colour can be changed from the menu.

It checks every ten minutes in the background. No daemon runs as root.

---

## Install

Download the `.rpm` from the [Releases](../../releases) page, then:

```bash
sudo dnf install ./update-fedora-rawhide-1.3.0-1.fc46.noarch.rpm
```

`dnf` pulls in every dependency on its own. Start it from your application
menu ("Fedora Rawhide Updates"), or from a terminal:

```bash
update-fedora-rawhide
```

To have it come back on every login, tick **Start with system** in the menu.

### Uninstall

```bash
sudo dnf remove update-fedora-rawhide
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
| **Install updates…** | Opens a terminal running `dnf upgrade`. You watch it and can abort. |
| **Show package list** | Lists what is pending. |
| **Appearance** | Icon shape and the colour of each state, each row previewed with the real icon. |
| **Start with system** | Adds or removes the autostart entry. |
| **Quit** | Closes the tray icon. |

When the pending updates include a kernel or an NVIDIA package, the menu says
so on its own line. That is deliberate: on Rawhide a new kernel means the
out-of-tree NVIDIA module has to be rebuilt, and that is what tells you a
reboot is coming.

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

Checking runs `dnf check-update` as your own user. That command is read-only,
so it needs no password and nothing privileged sits in the background.

Only **Install updates…** needs root, and it asks through `pkexec` at the
moment you click it — in a visible terminal, so you see exactly what is being
installed and can stop it.

Every external call happens on a background thread, so the menu never freezes
while a check is running.

---

## Building the RPM yourself

```bash
sudo dnf install rpm-build rpmdevtools
rpmdev-setuptree

VERSION=1.3.0
git archive --format=tar.gz \
    --prefix=update-fedora-rawhide-$VERSION/ \
    -o ~/rpmbuild/SOURCES/update-fedora-rawhide-$VERSION.tar.gz HEAD

rpmbuild -ba packaging/update-fedora-rawhide.spec
```

The finished package lands in `~/rpmbuild/RPMS/noarch/`.

---

## Requirements

Fedora with a tray that speaks StatusNotifier — KDE Plasma, or GNOME with the
AppIndicator extension. Dependencies (`python3-gobject`, `gtk3`,
`libappindicator-gtk3`, `libnotify`) are installed automatically by `dnf`.

## License

MIT.
