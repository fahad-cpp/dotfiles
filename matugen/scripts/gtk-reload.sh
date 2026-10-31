#!/usr/bin/env bash
# Toggling the colour-scheme makes running GTK apps re-read colors.css
command -v gsettings >/dev/null || exit 0
current=$(gsettings get org.gnome.desktop.interface color-scheme)
if [[ "$current" == "'prefer-dark'" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
fi
