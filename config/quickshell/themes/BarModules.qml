pragma Singleton
import QtQuick
import "../config"

Item {
    id: root

    property alias mode:           CentralConfig.mode
    property alias editMode:       CentralConfig.editMode
    property alias appletLocation: CentralConfig.appletLocation
    property alias leftModules:    CentralConfig.leftModules
    property alias centerModules:  CentralConfig.centerModules
    property alias rightModules:   CentralConfig.rightModules

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
