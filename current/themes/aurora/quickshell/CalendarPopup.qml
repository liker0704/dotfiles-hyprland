import QtQuick
import QtQuick.Layouts

Item {
    id: cal

    property color accent: "#7aa8ff"
    property color fg: "#e6e6f0"
    property color fgDim: "#a5a9c2"
    property color fgMuted: "#6f7590"
    property color bgHighlight: "#3f4053"

    property int displayMonth: new Date().getMonth()
    property int displayYear: new Date().getFullYear()
    property int todayDay: new Date().getDate()
    property int todayMonth: new Date().getMonth()
    property int todayYear: new Date().getFullYear()

    readonly property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]
    readonly property var dayLabels: ["Mo","Tu","We","Th","Fr","Sa","Su"]

    function daysInMonth(m, y) { return new Date(y, m + 1, 0).getDate() }
    function firstDayOfWeek(m, y) { var d = new Date(y, m, 1).getDay(); return d === 0 ? 6 : d - 1 }

    function prevMonth() {
        if (displayMonth === 0) { displayMonth = 11; displayYear-- }
        else displayMonth--
    }
    function nextMonth() {
        if (displayMonth === 11) { displayMonth = 0; displayYear++ }
        else displayMonth++
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Header: < Month Year >
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "◀"; color: cal.fgDim; font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cal.prevMonth() }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: cal.monthNames[cal.displayMonth] + " " + cal.displayYear
                color: cal.fg; font.family: Appearance.font.ui
                font.pixelSize: 14; font.weight: Font.Bold
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "▶"; color: cal.fgDim; font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cal.nextMonth() }
            }
        }

        // Day-of-week labels
        Grid {
            columns: 7; Layout.fillWidth: true
            columnSpacing: 0; rowSpacing: 0
            Repeater {
                model: cal.dayLabels
                Text {
                    width: (cal.width) / 7; text: modelData
                    horizontalAlignment: Text.AlignHCenter
                    color: cal.fgMuted; font.family: Appearance.font.ui
                    font.pixelSize: 11; font.weight: Font.Bold
                }
            }
        }

        // Day grid
        Grid {
            columns: 7; Layout.fillWidth: true; Layout.fillHeight: true
            columnSpacing: 0; rowSpacing: 2

            Repeater {
                model: 42

                Rectangle {
                    property int dayNum: {
                        var offset = cal.firstDayOfWeek(cal.displayMonth, cal.displayYear)
                        var num = index - offset + 1
                        return num
                    }
                    property bool isCurrentMonth: dayNum >= 1 && dayNum <= cal.daysInMonth(cal.displayMonth, cal.displayYear)
                    property bool isToday: isCurrentMonth && dayNum === cal.todayDay && cal.displayMonth === cal.todayMonth && cal.displayYear === cal.todayYear

                    width: (cal.width) / 7; height: 28
                    radius: 8
                    color: isToday ? cal.accent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: parent.isCurrentMonth ? parent.dayNum.toString() : ""
                        color: parent.isToday ? "#000000" : cal.fgDim
                        font.family: Appearance.font.ui
                        font.pixelSize: 12
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
