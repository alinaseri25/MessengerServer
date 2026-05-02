import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "CComponents"
import "theme"

ApplicationWindow {
    id: root
    width: 640
    height: 600
    visible: true

    signal serverConnectDisconnect(int portNumber)
    signal sendDatato(int listNumber)
    signal qmlLoaded()

    property int col1Width: 0
    property int col2Width: 0
    property int col3Width: 0
    property int entityId: 0    // 0 → new user, otherwise → edit user

    Theme { id: appTheme }

    color: appTheme.background

    background: Rectangle {
        color: appTheme.background
    }

    Toast{
        id: toastMessage
        themeManager: appTheme
    }

    Rectangle {
        anchors.fill: parent
        color: appTheme.background

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: appTheme.spacing.lg
            spacing: appTheme.spacing.md

            // ================= HEADER =================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: appTheme.control.heightLarge + appTheme.spacing.lg
                radius: appTheme.radius.md
                color: appTheme.surface
                border.color: appTheme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: appTheme.spacing.md
                    spacing: appTheme.spacing.md

                    TextField {
                        id: serverPort
                        text: "1008"
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: appTheme.control.heightMedium
                        color: appTheme.textPrimary
                        placeholderText: "Port"
                        placeholderTextColor: appTheme.textSecondary
                        background: Rectangle {
                            radius: appTheme.radius.sm
                            color: appTheme.surfaceAlt
                            border.color: appTheme.border
                            border.width: 1
                        }
                    }

                    CButton {
                        id: btnConnectDisconnect
                        text: "start"
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: appTheme.control.heightMedium

                        onClicked: {
                            serverConnectDisconnect(serverPort.text)
                        }
                    }

                    Text {
                        id: serverDetails
                        text: ""
                        Layout.fillWidth: true
                        color: appTheme.textSecondary
                        font.pixelSize: appTheme.fontSize.md
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    StatusIndicator {
                        id: indicator
                        width: 40
                        height: 40
                    }
                }
            }

            // ================= CONNECTION COUNT =================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: appTheme.radius.md
                color: appTheme.surface
                border.color: appTheme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: appTheme.spacing.md
                    spacing: appTheme.spacing.md

                    Text {
                        text: "Connections:"
                        color: appTheme.textPrimary
                        font.bold: true
                        font.pixelSize: appTheme.fontSize.md
                    }

                    Text {
                        id: connectionNumber
                        text: "0"
                        color: appTheme.accent
                        font.pixelSize: appTheme.fontSize.md
                        font.bold: true
                    }
                }
            }

            // ================= ENTITY LIST =================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: appTheme.radius.md
                color: appTheme.surface
                border.color: appTheme.border
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // ------ Header ------
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: appTheme.surfaceAlt
                        border.color: appTheme.border
                        border.width: 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: appTheme.spacing.sm
                            spacing: appTheme.spacing.sm

                            Text {
                                text: "Display Name"
                                color: appTheme.textOnAccent
                                font.bold: true
                                font.pixelSize: appTheme.fontSize.sm
                                Layout.preferredWidth: col1Width
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Username"
                                color: appTheme.textOnAccent
                                font.bold: true
                                font.pixelSize: appTheme.fontSize.sm
                                Layout.preferredWidth: col2Width
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Operations"
                                color: appTheme.textOnAccent
                                font.bold: true
                                font.pixelSize: appTheme.fontSize.sm
                                Layout.preferredWidth: col3Width
                            }
                        }
                    }

                    // ------ List ------
                    ListView {
                        id: listView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: myBackend.entityModel
                        clip: true
                        delegate: entityDelegate
                        boundsBehavior: Flickable.StopAtBounds
                    }
                }
            }

            // ================= ADD USER =================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: appTheme.radius.md
                color: appTheme.surface
                border.color: appTheme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: appTheme.spacing.md
                    spacing: appTheme.spacing.md

                    CButton {
                        id: btnAddUser
                        text: "+ Add New User"
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: appTheme.control.heightMedium
                        onClicked: {
                            userEditPopup.resetForm()
                            userEditPopup.open()
                        }
                    }
                }
            }

            // ================= DB STATUS =================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: appTheme.radius.md
                color: appTheme.surface
                border.color: appTheme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: appTheme.spacing.md
                    spacing: appTheme.spacing.md

                    Text {
                        text: "Database Status:"
                        color: appTheme.textPrimary
                        font.bold: true
                        font.pixelSize: appTheme.fontSize.md
                    }

                    Text {
                        id: databaseStatus
                        text: "Connecting ..."
                        color: appTheme.textSecondary
                        font.pixelSize: appTheme.fontSize.md
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // ================= DELEGATE =================
    Component {
        id: entityDelegate

        Rectangle {
            width: ListView.view.width
            height: 60
            radius: appTheme.radius.sm
            border.width: 1
            border.color: appTheme.border
            color: is_deleted ? appTheme.error :
                   (is_active ? appTheme.hoverColor : appTheme.surfaceAlt)

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: parent.color = appTheme.hoverColor
                onExited: {
                    parent.color = is_deleted ? appTheme.error :
                                   (is_active ? appTheme.hoverColor : appTheme.surfaceAlt)
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: appTheme.spacing.sm
                spacing: appTheme.spacing.sm

                Text {
                    text: display_name
                    color: appTheme.textPrimary
                    font.pixelSize: appTheme.fontSize.sm
                    Layout.preferredWidth: col1Width
                    elide: Text.ElideRight
                }

                Text {
                    text: username
                    color: appTheme.textSecondary
                    font.pixelSize: appTheme.fontSize.sm
                    Layout.preferredWidth: col2Width
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.preferredWidth: col3Width
                    spacing: appTheme.spacing.sm

                    IconButton {
                        text: is_deleted ? "↺" : "✖"
                        onClicked: myBackend.onSetDeleted(entity_id, !is_deleted)
                    }

                    IconButton {
                        text: is_active ? "⛔" : "✔"
                        onClicked: myBackend.onSetActivate(entity_id, !is_active)
                    }

                    IconButton {
                        text: "✎"
                        onClicked: {
                            userEditPopup.setUserValues(
                                entity_id,
                                display_name,
                                username,
                                ""
                            )
                            userEditPopup.open()
                        }
                    }
                }
            }
        }
    }

    // ================= POPUP =================
    Popup {
        id: userEditPopup
        modal: true
        focus: true
        width: 380
        height: 340

        x: (root.width - width) / 2
        y: (root.height - height) / 2

        background: Rectangle {
            radius: appTheme.radius.lg
            color: appTheme.surface
            border.color: appTheme.border
            border.width: 1
        }

        function setUserValues(id, display, username, password) {
            entityId = id
            tfDisplayName.text = display
            tfUsername.text = username
            tfPassword.text = password
        }

        function resetForm() {
            entityId = 0
            tfDisplayName.text = ""
            tfUsername.text = ""
            tfPassword.text = ""
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: appTheme.spacing.lg
            spacing: appTheme.spacing.md

            Text {
                text: entityId === 0 ? "Create New User" : "Edit User"
                font.pixelSize: appTheme.fontSize.xl
                font.bold: true
                color: appTheme.textPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: tfDisplayName
                placeholderText: "Display Name"
                Layout.fillWidth: true
                Layout.preferredHeight: appTheme.control.heightMedium
                color: appTheme.textPrimary
                placeholderTextColor: appTheme.textSecondary
                background: Rectangle {
                    radius: appTheme.radius.sm
                    color: appTheme.surfaceAlt
                    border.color: appTheme.border
                    border.width: 1
                }
            }

            TextField {
                id: tfUsername
                placeholderText: "Username"
                Layout.fillWidth: true
                Layout.preferredHeight: appTheme.control.heightMedium
                color: appTheme.textPrimary
                placeholderTextColor: appTheme.textSecondary
                background: Rectangle {
                    radius: appTheme.radius.sm
                    color: appTheme.surfaceAlt
                    border.color: appTheme.border
                    border.width: 1
                }
            }

            TextField {
                id: tfPassword
                placeholderText: "Password"
                echoMode: TextInput.Password
                Layout.fillWidth: true
                Layout.preferredHeight: appTheme.control.heightMedium
                color: appTheme.textPrimary
                placeholderTextColor: appTheme.textSecondary
                background: Rectangle {
                    radius: appTheme.radius.sm
                    color: appTheme.surfaceAlt
                    border.color: appTheme.border
                    border.width: 1
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: appTheme.spacing.md

                CButton {
                    text: "Cancel"
                    Layout.fillWidth: true
                    Layout.preferredHeight: appTheme.control.heightMedium
                    onClicked: userEditPopup.close()
                }

                CButton {
                    text: entityId === 0 ? "Create" : "Save"
                    Layout.fillWidth: true
                    Layout.preferredHeight: appTheme.control.heightMedium

                    onClicked: {
                        if (entityId === 0) {
                            myBackend.onCreateNewUser(
                                tfDisplayName.text,
                                tfUsername.text,
                                tfPassword.text
                            )
                        } else {
                            myBackend.onUpdateUser(
                                entityId,
                                tfDisplayName.text,
                                tfUsername.text,
                                tfPassword.text
                            )
                        }

                        userEditPopup.close()
                    }
                }
            }
        }
    }

    // ================= INIT =================
    Component.onCompleted: {
        col1Width = (width - 20) / 3
        col2Width = (width - 20) / 3
        col3Width = (width - 20) / 3

        serverConnectDisconnect.connect(myBackend.onConnectDisconnectClicked)
        sendDatato.connect(myBackend.onSendClicked)
        qmlLoaded.connect(myBackend.onQmlLoaded)

        indicator.setStatus("ERROR")
        qmlLoaded()
    }

    // ================= SIGNAL CONNECTIONS =================
    Connections {
        target: myBackend

        function onDataBaseState(dbState, msg) {
            databaseStatus.text = dbState
                    ? "Connected Successfully."
                    : "Error: " + msg
        }

        function onServerStateChanged(state, msg) {
            serverDetails.text = msg
            btnConnectDisconnect.text = state ? "stop" : "start"
            indicator.setStatus(state ? "OK" : "ERROR")
        }

        function onSocketsCount(count) {
            connectionNumber.text = count
        }

        function onDataFromSocket(data, index) {
            // Reserved
        }

        function onShowToastMessage(noError,_msg){
            if(_msg !== qsTr("")){
                toastMessage.showMessage(noError,_msg)
            }
        }
    }
}
