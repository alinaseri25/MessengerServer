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

    Rectangle{
        x: 0
        y: 0
        width: parent.width
        height: 100

        TextEdit {
            x: 20
            y: 30
            width: 100
            height: 30
            id: serverPort
            text: qsTr("1008")
        }

        CButton{
            x: 140
            y: 30
            width: 100
            height: 30
            id: btnConnectDisconnect
            text: qsTr("start")
            onClicked:{
                serverConnectDisconnect(serverPort.text)
            }
        }

        Text {
            x: 250
            y: 20
            width: 200
            height: 30
            id: serverDetails
            text: qsTr("")
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    StatusIndicator{
        id: indicator
        width: 50
        x: parent.width - width
        y: 10
    }

    Rectangle{
        x: 0
        y: 110
        width: parent.width
        height: 100

        Text {
            x: 20
            y: 30
            width: 100
            height: 30
            id: connectionNumber
            text: qsTr("0")
        }
    }

    Rectangle{
        x: 0
        y: 220
        width: parent.width
        height: 100

        TextEdit {
            x: 20
            y: 30
            width: 100
            height: 30
            id: connectionSelector
            text: qsTr("0")
        }

        CButton{
            x: 140
            y: 30
            width: 100
            height: 30
            id: btnSendData
            text: qsTr("send data")
            onClicked:{
                sendDatato(connectionSelector.text)
            }
        }
    }

    Rectangle{
        x: 0
        y: 330
        width: parent.width
        height: 100

        Text{
            x: 20
            y: 30
            width: 100
            height: 30
            id: connectionRcvData
            text: qsTr("-------------")
        }

        Text{
            x: 140
            y: 30
            width: 100
            height: 30
            id: connectionRcvIndex
            text: qsTr("--")
        }
    }

    Rectangle {
        x: 0
        y: 330
        width: parent.width
        height: 300

        Column {
            anchors.fill: parent


            // ---------------- Title Bar ----------------
            Rectangle {
                width: parent.width
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
                        horizontalAlignment: Text.AlignLeft
                    }

                    Text {
                        text: "Username"
                        color: "white"
                        font.bold: true
                        Layout.preferredWidth: col2Width
                        horizontalAlignment: Text.AlignLeft
                    }

                    Text {
                        text: "Operations"
                        color: "white"
                        font.bold: true
                        Layout.preferredWidth: col2Width
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }

            // ---------------- ListView ----------------
            ListView {
                id: listView
                width: parent.width
                height: parent.height - 40

                model: myBackend.entityModel
                delegate: entityDelegate
                clip: true
            }
        }

        // -------- Delegate --------
        Component {
            id: entityDelegate

            Rectangle {
                width: ListView.view.width
                height: 70
                radius: 6
                border.width: 1
                border.color: "#444"
                color: is_deleted ? "#ff4d4d"
                                  : (is_active ? "#8fff8f" : "#fff7a6")

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 0

                    Text {
                        text: display_name
                        color: "black"
                        Layout.preferredWidth: col1Width
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                    }

                    Text {
                        text: username
                        color: "black"
                        Layout.preferredWidth: col2Width
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.preferredWidth: col3Width
                        spacing: 8

                        // DELETE / UNDELETE ICON BUTTON
                        IconButton {
                            text: is_deleted ? "↺" : "✖"
                            onClicked: {
                                myBackend.onSetDeleted(entity_id,!is_deleted)
                            }
                        }

                        // ACTIVE / DEACTIVE ICON BUTTON
                        IconButton {
                            text: is_active ? "⛔" : "✔"
                            onClicked: {
                                myBackend.onSetActivate(entity_id,!is_active)
                            }
                        }

                        // EDIT ICON BUTTON
                        IconButton {
                            text: "✎"
                            onClicked: {
                                //myBackend.editEntity(entity_id)
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle{
        x: 0
        y: 530
        width: parent.width
        height: 100

        Text{
            x: 20
            y: 30
            width: 100
            height: 30
            id: databaseData
            text: qsTr("Data base Status : ")
        }

        Text{
            x: 140
            y: 30
            width: 100
            height: 30
            id: databaseStatus
            text: qsTr("Connecting ...")
        }
    }

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

    Connections{
        target: myBackend

        function onDataBaseState(dbState,msg){
            if(dbState)
            {
                databaseStatus.text = qsTr("Connected Successfully .")
            }
            else
            {
                databaseStatus.text =  qsTr("Error : ") + msg
            }
        }

        function onServerStateChanged(state,msg){
            serverDetails.text = msg
            if(state === true)
            {
                btnConnectDisconnect.text = qsTr("stop")
                indicator.setStatus("OK")
            }
            else
            {
                btnConnectDisconnect.text = qsTr("start")
                indicator.setStatus("ERROR")
            }
        }

        function onSocketsCount(count){
            connectionNumber.text = count
        }

        function onDataFromSocket(data,index){
            connectionRcvData.text = data
            connectionRcvIndex.text = index
        }
    }
}
