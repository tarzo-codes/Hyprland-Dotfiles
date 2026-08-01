pragma Singleton
import QtQuick
import QtCore

Item {
    id: root

    readonly property bool _initApps: {
        Qt.application.organization = "FluxDots";
        Qt.application.name = "FluxDots";
        return true;
    }

    Settings {
        id: moduleStore
        category: "BarModules"
        property string mode: "default" // "default" or "custom"
        property bool editMode: false
        property string appletLocation: "top" // "top", "bottom", "center"
        property string leftModules: "launcher,cpu,ram,disk,media"
        property string centerModules: "workspaces"
        property string rightModules: "song,network,volume,updates,clock,tray,power"
    }

    property alias mode: moduleStore.mode
    property alias editMode: moduleStore.editMode
    property alias appletLocation: moduleStore.appletLocation
    property alias leftModules: moduleStore.leftModules
    property alias centerModules: moduleStore.centerModules
    property alias rightModules: moduleStore.rightModules

    property bool isPreviewing: false
    property string previewLeft: ""
    property string previewCenter: ""
    property string previewRight: ""

    function setZone(moduleKey, zone) {
        var lefts = (leftModules || "").split(",");
        var centers = (centerModules || "").split(",");
        var rights = (rightModules || "").split(",");

        lefts = lefts.filter(function(m) { return m !== moduleKey && m !== ""; });
        centers = centers.filter(function(m) { return m !== moduleKey && m !== ""; });
        rights = rights.filter(function(m) { return m !== moduleKey && m !== ""; });

        if (zone === "left") lefts.push(moduleKey);
        else if (zone === "center") centers.push(moduleKey);
        else if (zone === "right") rights.push(moduleKey);

        leftModules = lefts.join(",");
        centerModules = centers.join(",");
        rightModules = rights.join(",");
    }

    function getZone(moduleKey) {
        var targetLeft = isPreviewing ? previewLeft : leftModules;
        var targetCenter = isPreviewing ? previewCenter : centerModules;
        var targetRight = isPreviewing ? previewRight : rightModules;

        var lefts = (targetLeft || "").split(",");
        var centers = (targetCenter || "").split(",");
        var rights = (targetRight || "").split(",");

        if (lefts.indexOf(moduleKey) !== -1) return "left";
        if (centers.indexOf(moduleKey) !== -1) return "center";
        if (rights.indexOf(moduleKey) !== -1) return "right";
        return "hidden";
    }

    function moveModule(moduleKey, dir) {
        var zone = getZone(moduleKey);
        if (zone === "hidden") return;

        var csvStr = (zone === "left") ? leftModules : ((zone === "center") ? centerModules : rightModules);
        var list = (csvStr || "").split(",").filter(function(m) { return m !== ""; });
        var idx = list.indexOf(moduleKey);
        if (idx === -1) return;

        if (dir === "up" || dir === "left") {
            if (idx > 0) {
                var temp = list[idx - 1];
                list[idx - 1] = list[idx];
                list[idx] = temp;
            }
        } else if (dir === "down" || dir === "right") {
            if (idx < list.length - 1) {
                var temp = list[idx + 1];
                list[idx + 1] = list[idx];
                list[idx] = temp;
            }
        }

        var newCsv = list.join(",");
        if (zone === "left") leftModules = newCsv;
        else if (zone === "center") centerModules = newCsv;
        else if (zone === "right") rightModules = newCsv;
    }

    function getModuleIndex(moduleKey) {
        var zone = getZone(moduleKey);
        if (zone === "hidden") return -1;
        var targetLeft = isPreviewing ? previewLeft : leftModules;
        var targetCenter = isPreviewing ? previewCenter : centerModules;
        var targetRight = isPreviewing ? previewRight : rightModules;
        var csvStr = (zone === "left") ? targetLeft : ((zone === "center") ? targetCenter : targetRight);
        var list = (csvStr || "").split(",").filter(function(m) { return m !== ""; });
        return list.indexOf(moduleKey);
    }

    function applyPreset(presetType) {
        if (presetType === "emilia_default" || presetType === "default") {
            leftModules = "launcher,cpu,ram,disk,media";
            centerModules = "workspaces";
            rightModules = "song,network,volume,updates,clock,tray,power";
        } else if (presetType === "minimal") {
            leftModules = "launcher,workspaces";
            centerModules = "title";
            rightModules = "volume,network,clock,power";
        } else if (presetType === "sysmon") {
            leftModules = "workspaces";
            centerModules = "media";
            rightModules = "cpu,gpu,ram,temp,disk,volume,network,clock,power";
        } else if (presetType === "full") {
            leftModules = "launcher,workspaces,title,pinnedApps";
            centerModules = "media,updates,weather";
            rightModules = "disk,cpu,ram,gpu,temp,volume,brightness,network,bluetooth,battery,clock,tray,theme,wallpaper,power";
        }
        mode = "custom";
    }

    function startPreview(presetType) {
        isPreviewing = true;
        if (presetType === "emilia_default" || presetType === "default") {
            previewLeft = "launcher,cpu,ram,disk,media";
            previewCenter = "workspaces";
            previewRight = "song,network,volume,updates,clock,tray,power";
        } else if (presetType === "minimal") {
            previewLeft = "launcher,workspaces";
            previewCenter = "title";
            previewRight = "volume,network,clock,power";
        } else if (presetType === "sysmon") {
            previewLeft = "workspaces";
            previewCenter = "media";
            previewRight = "cpu,gpu,ram,temp,disk,volume,network,clock,power";
        } else if (presetType === "full") {
            previewLeft = "launcher,workspaces,title,pinnedApps";
            previewCenter = "media,updates,weather";
            previewRight = "disk,cpu,ram,gpu,temp,volume,brightness,network,bluetooth,battery,clock,tray,theme,wallpaper,power";
        }
    }

    function stopPreview() {
        isPreviewing = false;
        previewLeft = "";
        previewCenter = "";
        previewRight = "";
    }
}
