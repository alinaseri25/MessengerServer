import QtQuick

QtObject {
    // ===== Mode =====
    property bool isDarkMode: true
    property bool isRTL: false

    readonly property int headerHeight: 48

    /* TEXT */

    readonly property color textPrimary: isDarkMode ? "#ffffff" : "#1a1a1a"
    readonly property color textSecondary: isDarkMode ? "#aaaaaa" : "#666666"
    readonly property color textOnAccent: "#ffffff"

    // ===== Colors =====
    readonly property color background: "#121212"
    readonly property color surface: "#1E1E1E"
    readonly property color surfaceAlt: "#242424"

    readonly property color accent: "#3daee9"
    readonly property color error: "#ff4d4d"
    readonly property color accentOrange: "#FF9800"
    readonly property color accentRed: "#D32F2F"

    readonly property color border: "#2C2C2C"
    readonly property color hoverColor: "#2A2A2A"

    /* SPACING */

    readonly property QtObject spacing: QtObject {

        readonly property int xs: 1
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 24
        readonly property int xxl: 32
    }

    /* RADIUS */

    readonly property QtObject radius: QtObject {

            readonly property int sm: 6
            readonly property int md: 12
            readonly property int lg: 14
            readonly property int xl: 18
    }

    /* FONT SIZE */

    readonly property QtObject fontSize: QtObject {

        readonly property int xs: 10
        readonly property int sm: 12
        readonly property int md: 14
        readonly property int lg: 18
        readonly property int xl: 24
    }

    /* MOTION */

    readonly property QtObject motion: QtObject {

        readonly property int fast: 120
        readonly property int normal: 180
        readonly property int slow: 260
    }

    /* CONTROL */

    readonly property QtObject control: QtObject {

        readonly property int heightSmall: 32
        readonly property int heightMedium: 40
        readonly property int heightLarge: 44
    }
}


