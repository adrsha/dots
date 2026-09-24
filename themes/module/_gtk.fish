#!/usr/bin/env fish
# _gtk.fish — apply dark/light preference to GTK 3/4, Qt6, and the XDG portal.
#
# Firefox dark-mode: Firefox reads org.freedesktop.portal.Settings, which
# xdg-desktop-portal-gtk populates from gsettings and signals live via
# org.freedesktop.portal.Settings.SettingChanged.
#
# On Hyprland you need xdg-desktop-portal-gtk running alongside
# xdg-desktop-portal-hyprland so that the Settings interface is handled.
# Add to your hyprland.lua:
#   hl.on("hyprland.start", function()
#       hl.exec_cmd("/usr/lib/xdg-desktop-portal-gtk")
#   end)
#
# The old dbus-send call in this script used --type=method_call on
# Settings.Read — that just queries a value and does nothing useful.
# Removed. gsettings alone is the correct lever.

mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.config/qt6ct

set -l is_dark   (test "$THEME_VARIANT" = dark; and echo 1; or echo 0)
set -l scheme    (test "$THEME_VARIANT" = dark; and echo prefer-dark; or echo prefer-light)
set -l gtk_theme QuickshellSync

# GTK 3 & 4 — write both files from the same printf in one shot.
printf '[Settings]\ngtk-application-prefer-dark-theme=%s\n' $is_dark \
    | tee ~/.config/gtk-3.0/settings.ini > ~/.config/gtk-4.0/settings.ini

# This is the key line for Firefox live-switching.
# xdg-desktop-portal-gtk watches this gsettings key and emits
# SettingChanged, which Firefox and Electron apps receive.
gsettings set org.gnome.desktop.interface color-scheme $scheme 2>/dev/null

# Qt6 — colour scheme label in the Qt6 config (read by qt6ct).
printf '[Appearance]\ncolor_scheme=%s\n' $THEME_VARIANT > ~/.config/qt6ct/colorscheme.conf
set -Ux QT_QPA_PLATFORMTHEME qt6ct

# GTK_THEME: direct hint for Chromium/Electron apps that bypass the portal.
set -Ux GTK_THEME $gtk_theme
