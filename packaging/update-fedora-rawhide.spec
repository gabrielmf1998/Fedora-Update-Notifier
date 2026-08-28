Name:           update-fedora-rawhide
Version:        1.1.0
Release:        1%{?dist}
Summary:        Tray icon that watches for Fedora Rawhide updates

License:        MIT
URL:            https://github.com/gabrielmf1998/update-check-fedora-rawhide
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

# Nada a compilar: o pacote é um script Python mais arquivos de dados, então
# não há BuildRequires. Manter python3-devel aqui só obrigaria quem constrói a
# instalar um pacote de desenvolvimento sem uso.

Requires:       python3
Requires:       python3-gobject
Requires:       gtk3
Requires:       libappindicator-gtk3
Requires:       libnotify
Requires:       dnf
# O menu "Install updates…" e "Show package list" abrem um terminal.
Recommends:     konsole
# pkexec, usado para autenticar a instalação dos pacotes.
Requires:       polkit

%description
A small system tray indicator for Fedora Rawhide, where the package set moves
almost every day.

The icon is green when the system is up to date and red when updates are
waiting. It checks every ten minutes in the background and the menu offers a
manual check, the package list, and a one click upgrade that runs in a
terminal so you can watch it and abort if needed.

Because Rawhide ships a new kernel very often — and a new kernel means the
out of tree NVIDIA module has to be rebuilt — the menu calls out separately
whether the pending updates include kernel or driver packages. That is the
piece of information that tells you a reboot is coming.

Checking is done as your own user with a read only "dnf check-update".
Only the actual upgrade asks for a password, through pkexec. Nothing runs
as root in the background.

The colour of each of the three states can be chosen from the menu, from
seven options, and is remembered in ~/.config/update-fedora-rawhide.

%prep
%autosetup

%build
# Nada a construir.

%install
install -Dpm 0755 src/%{name} %{buildroot}%{_bindir}/%{name}

# Os ícones vão para o tema hicolor: é o único lugar que a bandeja do KDE
# resolve de forma confiável. Um diretório avulso via set_icon_theme_path()
# registra certo no D-Bus mas não desenha.
for f in icons/*.svg; do
    install -Dpm 0644 "$f" \
        %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/$(basename "$f")
done

install -Dpm 0644 desktop/%{name}.desktop \
    %{buildroot}%{_datadir}/applications/%{name}.desktop

install -Dpm 0644 README.md %{buildroot}%{_docdir}/%{name}/README.md

%files
%license LICENSE
%doc %{_docdir}/%{name}/README.md
%{_bindir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/scalable/apps/update-arrow-*.svg

%changelog
* Fri Aug 28 2026 Gabriel <empresagabriel24@gmail.com> - 1.1.0-1
- Colours are now chosen from the menu, per state, out of seven options.
- One icon file per colour, so the tray never has to reread a changed file.

* Fri Aug 28 2026 Gabriel <empresagabriel24@gmail.com> - 1.0.0-1
- First release.
- Tray icon with green/red state, ten minute polling and manual check.
- Highlights kernel and NVIDIA updates, which are the ones that need a reboot.
- "Start with system" toggle writes a user autostart entry.
