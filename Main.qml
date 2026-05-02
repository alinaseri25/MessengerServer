import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "CComponents"

Item {
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

    Rectangle {
        anchors.fill: parent
        color: "#f2f4f7"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 14

            // ---------------- HEADER ----------------
            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 8
                color: "#ffffff"
                border.color: "#d0d3d8"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    TextEdit {
                        id: serverPort
                        text: "1008"
                        Layout.preferredWidth: 80
                        height: 32
                    }

                    CButton {
                        id: btnConnectDisconnect
                        text: "start"
                        Layout.preferredWidth: 100
                        height: 32

                        onClicked: {
                            serverConnectDisconnect(serverPort.text)
                        }
                    }

                    Text {
                        id: serverDetails
                        text: ""
                        Layout.fillWidth: true
                        color: "#333"
                        verticalAlignment: Text.AlignVCenter
                    }

                    StatusIndicator {
                        id: indicator
                        width: 40
                    }
                }
            }

            // ---------------- SOCKET COUNT ----------------
            Rectangle {
                Layout.fillWidth: true
                height: 70
                radius: 8
                color: "#ffffff"
                border.color: "#d0d3d8"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    Text {
                        text: "Connections:"
                        font.bold: true
                    }

                    Text {
                        id: connectionNumber
                        text: "0"
                        color: "#222"
                    }
                }
            }

            // ---------------- SEND DATA ----------------
            // Rectangle {
            //     Layout.fillWidth: true
            //     height: 90
            //     radius: 8
            //     color: "#ffffff"
            //     border.color: "#d0d3d8"

            //     RowLayout {
            //         anchors.fill: parent
            //         anchors.margins: 12
            //         spacing: 12

            //         TextEdit {
            //             id: connectionSelector
            //             text: "0"
            //             Layout.preferredWidth: 80
            //             height: 30
            //         }

            //         CButton {
            //             id: btnSendData
            //             text: "send data"
            //             Layout.preferredWidth: 110
            //             height: 32

            //             onClicked: {
            //                 sendDatato(connectionSelector.text)
            //             }
            //         }
            //     }
            // }

            // ---------------- RECEIVED DATA ----------------
            // Rectangle {
            //     Layout.fillWidth: true
            //     height: 90
            //     radius: 8
            //     color: "#ffffff"
            //     border.color: "#d0d3d8"

            //     RowLayout {
            //         anchors.fill: parent
            //         anchors.margins: 12
            //         spacing: 12

            //         Text {
            //             text: "Data:"
            //             font.bold: true
            //         }

            //         Text {
            //             id: connectionRcvData
            //             text: "-------------"
            //         }

            //         Text {
            //             text: "Index:"
            //             font.bold: true
            //         }

            //         Text {
            //             id: connectionRcvIndex
            //             text: "--"
            //         }
            //     }
            // }

            // ---------------- ENTITY LIST ----------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: "#ffffff"
                border.color: "#d0d3d8"

                ColumnLayout {
                    anchors.fill: parent

                    // ------ Header ------
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        color: "#2c3e50"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10

                            Text {
                                text: "Display Name"
                                color: "white"
                                font.bold: true
                                Layout.preferredWidth: col1Width
                            }

                            Text {
                                text: "Username"
                                color: "white"
                                font.bold: true
                                Layout.preferredWidth: col2Width
                            }

                            Text {
                                text: "Operations"
                                color: "white"
                                font.bold: true
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
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 70
                radius: 8
                color: "#ffffff"
                border.color: "#d0d3d8"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    CButton {
                        id: btnAddUser
                        text: "+ Add New User"
                        Layout.preferredWidth: 150
                        onClicked: {
                            userEditPopup.resetForm()
                            userEditPopup.open()
                        }
                    }
                }
            }

            // ---------------- DB STATUS ----------------
            Rectangle {
                Layout.fillWidth: true
                height: 70
                radius: 8
                color: "#ffffff"
                border.color: "#d0d3d8"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text { text: "Database Status:"; font.bold: true }
                    Text { id: databaseStatus; text: "Connecting ..." }
                }
            }
        }
    }

    // -------- Delegate --------
    Component {
        id: entityDelegate

        Rectangle {
            width: ListView.view.width
            height: 60
            radius: 6
            border.width: 1
            border.color: "#ccc"
            color: is_deleted ? "#ffcccc" :
                   (is_active ? "#d6ffd6" : "#fff3c2")

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: display_name
                    Layout.preferredWidth: col1Width
                    elide: Text.ElideRight
                }

                Text {
                    text: username
                    Layout.preferredWidth: col2Width
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.preferredWidth: col3Width
                    spacing: 8

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

    Popup {
        id: userEditPopup
        modal: true
        focus: true
        width: 350
        height: 320


        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        background: Rectangle {
            radius: 10
            color: "white"
            border.color: "#aaa"
        }

        // --------- function for filling data when editing ---------
        function setUserValues(id, display, username, password) {
            entityId = id
            tfDisplayName.text = display
            tfUsername.text = username
            tfPassword.text = password
        }

        // --------- function to reset popup (for creating new user) ---------
        function resetForm() {
            entityId = 0
            tfDisplayName.text = ""
            tfUsername.text = ""
            tfPassword.text = ""
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // ----- Title -----
            Text {
                text: entityId === 0 ? "Create New User" : "Edit User"
                font.pixelSize: 20
                font.bold: true
                color: "#2c3e50"
                Layout.alignment: Qt.AlignHCenter
            }

            // ----- Form -----
            TextField {
                id: tfDisplayName
                placeholderText: "Display Name"
                Layout.fillWidth: true
            }

            TextField {
                id: tfUsername
                placeholderText: "Username"
                Layout.fillWidth: true
            }

            TextField {
                id: tfPassword
                placeholderText: "Password"
                echoMode: TextInput.Password
                Layout.fillWidth: true
            }

            // ----- Buttons -----
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                CButton {
                    text: "Cancel"
                    Layout.fillWidth: true
                    onClicked: userEditPopup.close()
                }

                CButton {
                    text: entityId === 0 ? "Create" : "Save"
                    Layout.fillWidth: true

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

    // ---------------- INIT ----------------
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

    // ---------------- SIGNAL CONNECTIONS ----------------
    Connections {
        target: myBackend

        function onDataBaseState(dbState, msg) {
            databaseStatus.text = dbState ?
                                  "Connected Successfully." :
                                  "Error: " + msg
        }

        function onServerStateChanged(state, msg) {
            serverDetails.text = msg
            btnConnectDisconnect.text = state ? "stop" : "start"
            indicator.setStatus(state ? "OK" : "ERROR")
        }

        function onSocketsCount(count) {
            //connectionNumber.text = count
        }

        function onDataFromSocket(data, index) {
            //connectionRcvData.text = data
            //connectionRcvIndex.text = index
        }
    }
}
