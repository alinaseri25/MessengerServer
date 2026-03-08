import QtQuick
import QtQuick.Controls
import "CComponents"

Item {
    width: 640
    height: 480
    visible: true

    signal serverConnectDisconnect(int portNumber)
    signal sendDatato(int listNumber)



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

    Rectangle{
        x: 0
        y: 430
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
        serverConnectDisconnect.connect(myBackend.onConnectDisconnectClicked)
        sendDatato.connect(myBackend.onSendClicked)
        indicator.setStatus("ERROR")
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
