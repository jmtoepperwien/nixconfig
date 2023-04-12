#!/bin/sh

# Session
export XDG_SESSION_TYPE=wayland

# Wayland stuff
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
export GDK_BACKEND=wayland

exec systemd-cat --identifier=gnome-wayland dbus-run-session gnome-session
