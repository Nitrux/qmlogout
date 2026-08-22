import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import org.mauikit.controls as Maui

Window {
    id: root
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint

    property int selectedIndex: 0
    property int activatedIndex: -1
    property int remainingSeconds: ActionTimeout
    readonly property real screenDpi: (root.screen && root.screen.pixelDensity > 0)
        ? root.screen.pixelDensity * 25.4
        : Screen.pixelDensity * 25.4
    readonly property real iconScale: screenDpi >= 200 ? 2.0 : screenDpi >= 160 ? 1.5 : 1.0
    readonly property int iconSize: Math.round(64 * iconScale)
    readonly property int avatarSize: Math.round(56 * iconScale)
    readonly property var actions: [
        { name: qsTr("Logout"), icon: "system-log-out", glyph: "\uf08b", method: "logout", key: "e" },
        { name: qsTr("Lock"), icon: "system-lock-screen", glyph: "\uf023", method: "lock", key: "l" },
        { name: qsTr("Reboot"), icon: "system-reboot", glyph: "\uf021", method: "reboot", key: "r" },
        { name: qsTr("Suspend"), icon: "system-suspend", glyph: "\uf186", method: "suspend", key: "u" },
        { name: qsTr("Hibernate"), icon: "system-suspend-hibernate", glyph: "\uf2dc", method: "hibernate", key: "h" },
        { name: qsTr("Shutdown"), icon: "system-shutdown", glyph: "\uf011", method: "shutdown", key: "s" }
    ]

    function triggerAction(index) {
        selectedIndex = index
        activatedIndex = index
        countdownTimer.stop()
        activationTimer.restart()
    }

    function moveSelection(delta) {
        selectedIndex = (selectedIndex + delta + actions.length) % actions.length
        Qt.callLater(function() { actionRepeater.itemAt(selectedIndex).forceActiveFocus() })
    }


    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, OverlayOpacity)

        Rectangle {
            id: outerSurface
            anchors.centerIn: parent
            width: sessionCard.width + 12
            height: sessionCard.height + 12
            color: Qt.alpha(Maui.Theme.backgroundColor, 0.42)
            radius: Maui.Style.radiusV + 6
            border.width: 0
        }

        RowLayout {
            id: headerRow
            x: sessionCard.x
            y: sessionCard.y - height - 12
            width: sessionCard.width - Maui.Style.defaultPadding
            spacing: Maui.Style.space.large

            Maui.SectionHeader {
                Layout.fillWidth: true
                template.text1: qsTr("Select Action")
                template.text2: qsTr("Choose a session management action within <b>%1</b> seconds.").arg(root.remainingSeconds)
                template.label1.font: Maui.Style.h2Font
                template.label2.font.pointSize: Maui.Style.fontSizes.small
                template.label2.textFormat: Text.RichText
                label2.wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: Maui.Style.space.small

                ColumnLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: 0

                    Label {
                        Layout.alignment: Qt.AlignRight
                        text: sessionManager.realName
                        color: Maui.Theme.textColor
                    }

                    Label {
                        Layout.alignment: Qt.AlignRight
                        visible: sessionManager.showUptime
                        text: qsTr("Uptime: %1").arg(sessionManager.uptime)
                        color: Maui.Theme.textColor
                        opacity: 0.72
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.avatarSize
                    Layout.preferredHeight: root.avatarSize
                    radius: root.avatarSize / 2
                    color: Qt.rgba(0, 0, 0, 0)
                    border.width: 1
                    border.color: Maui.Theme.highlightColor

                    Maui.IconItem {
                        anchors.fill: parent
                        anchors.margins: 1
                        imageSource: sessionManager.avatarUrl
                        iconSizeHint: Math.round(32 * root.iconScale)
                        imageSizeHint: -1
                        imageWidth: root.avatarSize - 2
                        imageHeight: root.avatarSize - 2
                        fillMode: Image.PreserveAspectCrop
                        maskRadius: (root.avatarSize - 2) / 2
                    }
                }
            }
        }

        Rectangle {
            id: sessionCard
            anchors.centerIn: parent
            width: 640
            height: 420
            color: Qt.alpha(Maui.Theme.backgroundColor, 0.76)
            radius: Maui.Style.radiusV + 3
            border.width: 1
            border.color: Qt.alpha(Maui.Theme.textColor, 0.10)

            GridLayout {
                anchors.fill: parent
                anchors.margins: 40
                columns: 3
                rows: 2
                columnSpacing: Maui.Style.space.large
                rowSpacing: Maui.Style.space.large

                Repeater {
                    id: actionRepeater
                    model: root.actions

                    delegate: Maui.Chip {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        focus: index === root.selectedIndex
                        focusPolicy: Qt.StrongFocus
                        hoverEnabled: true
                        padding: 0
                        spacing: 0
                        color: Qt.rgba(0, 0, 0, 0)
                        background: Rectangle {
                            radius: Maui.Style.radiusV
                            color: index === root.selectedIndex
                                   ? Qt.rgba(Maui.Theme.textColor.r, Maui.Theme.textColor.g, Maui.Theme.textColor.b, 0.08)
                                   : Qt.rgba(0, 0, 0, 0)
                            Behavior on color {
                                ColorAnimation { duration: 180; easing.type: Easing.InOutQuad }
                            }
                        }
                        opacity: index === root.selectedIndex ? 1.0 : 0.78
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

                        onHoveredChanged: if (hovered) {
                            root.selectedIndex = index
                            forceActiveFocus()
                        }

                        contentItem: ColumnLayout {
                            spacing: 0

                            Maui.IconItem {
                                id: actionIcon
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: root.iconSize
                                Layout.preferredHeight: root.iconSize
                                visible: sessionManager.iconMode !== "nerd"
                                iconSource: modelData.icon
                                iconSizeHint: root.iconSize
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    saturation: index === root.selectedIndex ? 0.0 : -1.0
                                    brightness: root.activatedIndex === index ? -0.18 : 0.0
                                    Behavior on saturation { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                                }
                            }

                            Label {
                                id: nerdIcon
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: root.iconSize
                                Layout.preferredHeight: root.iconSize
                                visible: sessionManager.iconMode === "nerd"
                                text: modelData.glyph
                                color: Maui.Theme.textColor
                                font.family: "Symbols Nerd Font"
                                font.pointSize: root.iconSize * 0.72 * 72 / root.screenDpi
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    saturation: index === root.selectedIndex ? 0.0 : -1.0
                                    brightness: root.activatedIndex === index ? -0.18 : 0.0
                                    Behavior on saturation { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                                }
                            }

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.name
                                color: Maui.Theme.textColor
                            }
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) {
                                Qt.quit()
                            } else if (event.key === Qt.Key_Left) {
                                root.moveSelection(-1)
                            } else if (event.key === Qt.Key_Right) {
                                root.moveSelection(1)
                            } else if (event.key === Qt.Key_Up) {
                                root.moveSelection(-3)
                            } else if (event.key === Qt.Key_Down) {
                                root.moveSelection(3)
                            } else if (event.text.length > 0 && event.text.toLowerCase() === modelData.key) {
                                root.selectedIndex = index
                                root.triggerAction(index)
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                root.selectedIndex = index
                                root.triggerAction(index)
                            } else {
                                return
                            }
                            event.accepted = true
                        }

                        onClicked: {
                            root.selectedIndex = index
                            root.triggerAction(index)
                        }
                    }
                }
            }
        }

        Button {
            id: cancelButton
            anchors.horizontalCenter: sessionCard.horizontalCenter
            y: sessionCard.y + sessionCard.height + Maui.Style.space.large
            width: 100
            height: Maui.Style.rowHeight
            activeFocusOnTab: true
            text: qsTr("Cancel")
            onClicked: Qt.quit()
            Keys.onEscapePressed: Qt.quit()
        }
    }

    onActiveChanged: if (active) actionRepeater.itemAt(selectedIndex).forceActiveFocus()

    Timer {
        id: activationTimer
        interval: 140
        repeat: false
        onTriggered: {
            var action = root.actions[root.selectedIndex]
            sessionManager[action.method]()
            Qt.quit()
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.remainingSeconds > 0)
                root.remainingSeconds--
            if (root.remainingSeconds <= 0) {
                stop()
                root.triggerAction(root.selectedIndex)
            }
        }
    }

    Component.onCompleted: {
        actionRepeater.itemAt(selectedIndex).forceActiveFocus()
        countdownTimer.start()
    }
}
