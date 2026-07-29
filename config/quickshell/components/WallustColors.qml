# Walkthrough — Microphone Controls, Wallust CheatSheet, Click-Outside Dismissal, & Global Font Scaling

We implemented all 4 requested enhancements.

---

## Technical Summary

1. **Microphone (Input Device) Controls**:
   - Added a dedicated **MICROPHONE VOLUME** section inside [`components/VolumePanel.qml`](file:///home/tarzo/.config/quickshell/components/VolumePanel.qml).
   - Features a real-time Mic Volume Slider (`wpctl set-volume @DEFAULT_AUDIO_SOURCE@`), Mic Mute toggle button (`wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle`), and percentage display.

2. **Click-Outside Panel Dismissal**:
   - Configured `WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None` across `VolumePanel`, `NetworkPanel`, `SettingsPanel`, `ThemeSelectorWindow`, and `MediaPlayerWindow`.
   - Clicking anywhere outside an active panel automatically unfocuses and closes it cleanly.

3. **Wallust Theme Binds on CheatSheet**:
   - Updated [`components/CheatSheet.qml`](file:///home/tarzo/.config/quickshell/components/CheatSheet.qml) to inherit `rootBar._bg`, `rootBar._sur`, `rootBar._fg`, `rootBar._acc`, and `rootBar._muted`.
   - When switching to Wallust or any theme, the CheatSheet immediately updates its background, cards, key pills, and borders to match.

4. **Global Font Size Scaling Across Applets**:
   - Updated text elements across `VolumePanel`, `NetworkPanel`, `MediaPlayerWindow`, and `CheatSheet` to scale dynamically using `ThemeManager.globalFontSize`.
   - Changing **Font Size** in the Settings Panel will now scale font sizes across all popups and widgets in real time.
