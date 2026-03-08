import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15  // اگر از Material استفاده می‌کنید

Rectangle {
    // ... تعاریف اولیه
    property color colorOk: "#00FF00"
    property color colorWarning: "#FFD700"
    property color colorError: "#FF0000"

    property string curStatus: "ERROR"

    id: statusIndicator
    width: 50; height: 50; radius: width / 2
    color: colorName
    border.width: 2; border.color: "black"
    property color colorName: colorOk // رنگ اصلی که در صورت OK بودن نمایش داده می‌شود

    // تعریف tooltip دستی
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            tooltipText.text = "وضعیت: " + curStatus
            tooltip.show(tooltipText.text)
        }
        onExited: {
            tooltip.hide()
        }
    }

    // متن تیپ
    Text {
        id: tooltipText
        text: ""
        visible: false
        color: "white"
        font.pixelSize: 12
        wrapMode: Text.Wrap
        //background: Rectangle { color: "black"; radius: 4 }
        padding: 6
    }

    // نمایش تیپ
    ToolTip {
        id: tooltip
        text: tooltipText.text
        x: 10
        y: 20
        visible: tooltipText.text !== ""
        //hideDelay: 1000
    }// تعریف tooltip دستی


    // --- انیمیشن چشمک زن ---
    SequentialAnimation {
        id: blinker
        // اجرای نامحدود برای چشمک زدن
        loops: Animation.Infinite
        running: false // در ابتدا اجرا نشود

        // 1. رفتن به رنگ سفید (چشمک زدن)
        PropertyAnimation {
            target: statusIndicator
            property: "color"
            // 'from' در اینجا مهم نیست، چون در زمان اجرا 'running' آن را تنظیم می‌کنیم
            to: "white"
            duration: 400
            easing.type: Easing.InOutQuad
        }
        // 2. بازگشت به رنگ اصلی تنظیم شده (colorName)
        PropertyAnimation {
            target: statusIndicator
            property: "color"
            to: statusIndicator.color // بازگشت به رنگی که در 'colorName' تنظیم شده است
            duration: 400
            easing.type: Easing.InOutQuad
        }
    }

    // تابع برای تغییر وضعیت و کنترل انیمیشن
    function setStatus(status) {
        var newColor;
        switch (status) {
            case "OK":
                newColor = colorOk;
                blinker.stop(); // توقف چشمک زدن
                break;
            case "WARNING":
                newColor = colorWarning;
                break;
            case "ERROR":
                newColor = colorError;
                break;
            default:
                newColor = colorOk;
                blinker.stop();
                break;
        }

        // 1. اگر رنگ تغییر کرده، آن را اعمال کن
        if (statusIndicator.color !== newColor) {
            statusIndicator.color = newColor;
        }

        // 2. اگر نیاز به چشمک زدن است، انیمیشن را شروع کن (یا دوباره تنظیم کن)
        if (status === "WARNING" || status === "ERROR" || status === "OK") {
            // برای اطمینان از اجرای درست، انیمیشن را متوقف و دوباره شروع می‌کنیم
            blinker.stop();
            blinker.start();
        }
        curStatus = status
    }

    Component.onCompleted: {
    }

    // مطمئن شوید که تابع فراخوانی شده، setStatus است.
}
