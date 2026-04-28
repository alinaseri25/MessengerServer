import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 34
    height: 34
    radius: 6
    color: hovered ? "#e5e5e5" : "#f6f6f6"
    border.color: "#999"
    border.width: 1

    property alias text: iconLabel.text
    signal clicked()

    property bool hovered: false

    Text {
        id: iconLabel
        anchors.centerIn: parent
        color: "#333"
        font.pixelSize: 18
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }
}
