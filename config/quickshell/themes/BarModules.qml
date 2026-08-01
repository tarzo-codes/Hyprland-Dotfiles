pragma Singleton
import QtQuick
import "../config"

Item {
    id: root

    property string mode:           CentralConfig.mode
    property bool   editMode:       CentralConfig.editMode
    property string appletLocation: CentralConfig.appletLocation
    property string leftModules:    CentralConfig.leftModules
    property string centerModules:  CentralConfig.centerModules
    property string rightModules:   CentralConfig.rightModules

    Binding { target: root; property: "mode"; value: CentralConfig.mode }
    Binding { target: root; property: "editMode"; value: CentralConfig.editMode }
    Binding { target: root; property: "appletLocation"; value: CentralConfig.appletLocation }
    Binding { target: root; property: "leftModules"; value: CentralConfig.leftModules }
    Binding { target: root; property: "centerModules"; value: CentralConfig.centerModules }
    Binding { target: root; property: "rightModules"; value: CentralConfig.rightModules }

    property bool isPreviewing: false
    property string previewLeft: ""
    property string previewCenter: ""
    property string previewRight: ""

    function setZone(moduleKey, zone) {
        CentralConfig.setZone(moduleKey, zone);
        CentralConfig.mode = "custom";
    }

    function getZone(moduleKey) {
        return CentralConfig.getZone(moduleKey);
    }

    function moveModule(moduleKey, dir) {
        CentralConfig.moveModule(moduleKey, dir);
        CentralConfig.mode = "custom";
    }

    function getModuleIndex(moduleKey) {
        return CentralConfig.getModuleIndex(moduleKey);
    }

    function applyPreset(presetType) {
        CentralConfig.applyPreset(presetType);
        CentralConfig.mode = "custom";
    }
}
