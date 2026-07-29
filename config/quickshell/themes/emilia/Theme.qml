// Theme.qml - Emilia theme wrapper
// Shows the bar on all screens using the Variants pattern

import QtQuick
import Quickshell
import "Bar.qml" as EmiliaBar

Variants {
    model: Quickshell.screens;

    delegate: Component {
        EmiliaBar {
            modelData: modelData
        }
    }
}