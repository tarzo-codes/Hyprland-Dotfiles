#!/usr/bin/env bash
# X11/Xwayland diagnostic — run: bash x11-diag.sh
# then paste the output back.

LOG=/tmp/x11-diag.log
exec > >(tee "$LOG") 2>&1

echo "== session =="
echo "DISPLAY=$DISPLAY"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"

echo -e "\n== systemd user env =="
systemctl --user show-environment | grep -E 'DISPLAY|WAYLAND'

echo -e "\n== /tmp/.X11-unix =="
ls -ld /tmp/.X11-unix 2>&1

echo -e "\n== tmpfiles rule for x11 =="
cat /usr/lib/tmpfiles.d/x11.conf 2>&1

echo -e "\n== Xwayland binary =="
which Xwayland 2>&1
pacman -Q xorg-xwayland 2>&1

echo -e "\n== Xwayland running? =="
pgrep -a Xwayland 2>&1 || echo "not running"

echo -e "\n== kwinrc [Xwayland] section =="
grep -A5 '^\[Xwayland\]' ~/.config/kwinrc 2>&1

echo -e "\n== xeyes test (2s timeout) =="
timeout 2 xeyes 2>&1
echo "(exit code: $?)"

echo -e "\n== recent journal mentions of xwayland =="
journalctl --user -b --no-pager | grep -i xwayland | tail -20

echo -e "\n== done — log saved to $LOG =="