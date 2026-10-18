import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "device-battery-levels"
  implicitWidth: Style.space(42)
  implicitHeight: barSize

  property var mouseBattery: ({ name: "", percent: -1, status: "" })
  property var keyboardBattery: ({ name: "", percent: -1, status: "" })
  property var headphonesBattery: ({ name: "", percent: -1, status: "" })
  property bool popupOpen: false

  function close() { popupOpen = false }
  function refreshBattery() { if (!batteryProc.running) batteryProc.running = true }

  Process {
    id: batteryProc
    command: ["sh", Qt.resolvedUrl("battery-status.sh").toString().replace("file://", "")]
    stdout: StdioCollector {
      id: batteryOut
      onStreamFinished: {
        var lines = text.split("\n")
        var mouse = { name: "", percent: -1, status: "" }
        var keyboard = { name: "", percent: -1, status: "" }
        var headphones = { name: "", percent: -1, status: "" }
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("=")
          if (parts.length < 2) continue
          if (parts[0] === "MOUSE_NAME") mouse.name = parts.slice(1).join("=")
          else if (parts[0] === "MOUSE_CAPACITY") mouse.percent = parseInt(parts[1])
          else if (parts[0] === "MOUSE_STATUS") mouse.status = parts.slice(1).join("=").toLowerCase()
          else if (parts[0] === "KEYBOARD_NAME") keyboard.name = parts.slice(1).join("=")
          else if (parts[0] === "KEYBOARD_CAPACITY") keyboard.percent = parseInt(parts[1])
          else if (parts[0] === "KEYBOARD_STATUS") keyboard.status = parts.slice(1).join("=").toLowerCase()
          else if (parts[0] === "HEADPHONES_NAME") headphones.name = parts.slice(1).join("=")
          else if (parts[0] === "HEADPHONES_CAPACITY") headphones.percent = parseInt(parts[1])
          else if (parts[0] === "HEADPHONES_STATUS") headphones.status = parts.slice(1).join("=").toLowerCase()
        }
        root.mouseBattery = mouse
        root.keyboardBattery = keyboard
        root.headphonesBattery = headphones
      }
    }
    onExited: function(code) { if (code !== 0) { root.mouseBattery = ({ name: "", percent: -1, status: "" }); root.keyboardBattery = ({ name: "", percent: -1, status: "" }); root.headphonesBattery = ({ name: "", percent: -1, status: "" }) } }
  }

  Timer { interval: 2000; running: true; repeat: true; onTriggered: root.refreshBattery() }
  Component.onCompleted: refreshBattery()

  Item {
    anchors.centerIn: parent
    width: Style.space(26)
    height: Style.space(16)
    scale: 0.5

    Rectangle {
      x: 0; y: 1
      width: parent.width - Style.space(3); height: parent.height - Style.space(2)
      radius: Style.space(3)
      color: "transparent"
      border.width: Style.space(1.5)
      border.color: root.bar.barForeground
    }
    Rectangle {
      x: parent.width - Style.space(3); y: parent.height / 2 - Style.space(3)
      width: Style.space(3); height: Style.space(6)
      radius: Style.space(1)
      color: root.bar.barForeground
    }
    Text {
      anchors.centerIn: parent
      text: "ϟ"
      color: root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.popupOpen = !root.popupOpen
    onEntered: if (root.bar) root.bar.showTooltip(root, "Wireless device batteries")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(300))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(8)

      Text {
        text: "Device Battery Levels"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }
      Text {
        text: "Mouse"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }
      Text {
        visible: root.mouseBattery.percent >= 0
        text: root.mouseBattery.name || "Wireless mouse"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.small
        opacity: 0.75
      }
      Text {
        text: root.mouseBattery.percent >= 0 ? root.mouseBattery.percent + "% · " + (root.mouseBattery.status ? root.mouseBattery.status.charAt(0).toUpperCase() + root.mouseBattery.status.slice(1) : "Status unavailable") : "No wireless mouse battery detected"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
      }
      Rectangle {
        width: column.width
        height: 1
        color: root.bar.barForeground
        opacity: 0.15
      }
      Text {
        text: "Keyboard"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }
      Text {
        visible: root.keyboardBattery.percent >= 0
        text: root.keyboardBattery.name || "Wireless keyboard"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.small
        opacity: 0.75
      }
      Text {
        text: root.keyboardBattery.percent >= 0 ? root.keyboardBattery.percent + "% · " + (root.keyboardBattery.status ? root.keyboardBattery.status.charAt(0).toUpperCase() + root.keyboardBattery.status.slice(1) : "Status unavailable") : "No wireless keyboard battery detected"
        width: column.width
        wrapMode: Text.WordWrap
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
      }
      Rectangle {
        width: column.width
        height: 1
        color: root.bar.barForeground
        opacity: 0.15
      }
      Text {
        text: "Headphones"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }
      Text {
        visible: root.headphonesBattery.percent >= 0
        text: root.headphonesBattery.name || "Wireless headphones"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.small
        opacity: 0.75
      }
      Text {
        text: root.headphonesBattery.percent >= 0 ? root.headphonesBattery.percent + "% · " + (root.headphonesBattery.status ? root.headphonesBattery.status.charAt(0).toUpperCase() + root.headphonesBattery.status.slice(1) : "Status unavailable") : "No wireless headphones battery detected"
        width: column.width
        wrapMode: Text.WordWrap
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
      }
    }
  }
}
