// Styles for the emilia theme (Tokyo Night)
// Font themes - change fonts here, not throughout the UI

pragma Singleton

import QtQuick

QtObject {
    // Panel styling
    readonly property int panelHeight: 28
    readonly property int borderRadius: 4
    
    // Font theme - SET YOUR FONTS HERE
    readonly property string fontRegular: "JetBrainsMono"
    readonly property string fontBold: "JetBrainsMono"
    readonly property string fontIcons: "Material Design Icons Desktop"
    readonly property string fontNerd: "Material Design Icons Desktop"
    readonly property string fontSymbols: "MesloLGS NF"
    readonly property int fontSize: 9
    readonly property int fontHeight: 20
    
    // Spacing
    readonly property int padding: 4
    readonly property int moduleMargin: 6
    readonly property int pillRadius: 2
    
    // Bar dimensions
    readonly property int barWidthPercent: 90
    readonly property int offsetX: 3
    readonly property int offsetY: 0
}