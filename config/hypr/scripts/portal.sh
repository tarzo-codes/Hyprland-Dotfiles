#!/usr/bin/env bash
sleep 1
killall -9 xdg-desktop-portal-hyprland xdg-desktop-portal-kde xdg-desktop-portal-gtk xdg-desktop-portal 2>/dev/null
nohup /usr/lib/xdg-desktop-portal-hyprland >/dev/null 2>&1 &
sleep 1
nohup /usr/lib/xdg-desktop-portal-kde >/dev/null 2>&1 &
sleep 1
nohup /usr/lib/xdg-desktop-portal-gtk >/dev/null 2>&1 &
sleep 1
nohup /usr/lib/xdg-desktop-portal >/dev/null 2>&1 &
