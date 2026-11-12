pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import QtQuick.Dialogs
import shikou_eigo

ApplicationWindow {
    id: root

    width: 1180
    height: 780
    minimumWidth: 820
    minimumHeight: 560
    visible: true
    title: qsTr("試験向英語学習")
    color: theme.background

    SystemPalette {
        id: systemPalette
    }

    // The palette is derived from the active Plasma color scheme, so the app
    // follows KDE's light/dark themes without hard-coding a separate palette.
    QtObject {
        id: theme

        readonly property color background: systemPalette.window
        readonly property color surface: systemPalette.base
        readonly property color surfaceMuted: systemPalette.alternateBase
        readonly property color text: systemPalette.windowText
        readonly property color textMuted: systemPalette.placeholderText
        readonly property color accent: systemPalette.highlight
        readonly property color accentPressed: systemPalette.highlight
        readonly property color border: systemPalette.mid
        readonly property color success: systemPalette.highlight
        readonly property color warning: "#f67400"
    }

    StudyBackend {
        id: backend

        onSource_changed: {
            if (sourceEditor.text !== backend.sourceText) {
                sourceEditor.text = backend.sourceText
                sourceEditor.cursorPosition = sourceEditor.text.length
            }
            root.refreshTokens()
        }
        onTranslations_changed: {
            // Translation edits are already visible in their TextField. Do not
            // rebuild the token view here, because that would steal focus.
        }
        onDirty_changed: dirtyDot.visible = backend.dirty
        onStatus_changed: statusLabel.text = backend.statusMessage
        onDocument_loaded: {
            root.title = backend.currentFile
                ? qsTr("試験向英語学習 — %1").arg(backend.currentFile)
                : qsTr("試験向英語学習")
        }
    }

    property var tokenLines: []

    function refreshTokens() {
        try {
            tokenLines = JSON.parse(backend.tokensJson || "[]")
        } catch (error) {
            console.warn("Failed to refresh tokens:", error)
            tokenLines = []
        }
    }

    header: ToolBar {
        height: 58
        background: Rectangle {
            color: theme.surface
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: theme.border
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 14
            spacing: 8

            Image {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                source: "qrc:/qt/qml/shikou_eigo/icons/io.github.yukirawa.ShikouEigo.svg"
                fillMode: Image.PreserveAspectFit
            }

            Label {
                text: qsTr("試験向英語学習")
                color: theme.text
                font.pixelSize: 17
                font.bold: true
            }

            Label {
                text: qsTr("単語の上に日本語訳を手動で追加")
                color: theme.textMuted
                font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }

            ToolButton {
                text: qsTr("新規")
                icon.name: "document-new"
                onClicked: {
                    if (backend.dirty) {
                        confirmDialog.open()
                    } else {
                        backend.newDocument()
                    }
                }
            }
            ToolButton {
                text: qsTr("開く")
                icon.name: "document-open"
                onClicked: openDialog.open()
            }
            ToolButton {
                text: qsTr("保存")
                icon.name: "document-save"
                enabled: backend.dirty || backend.currentFile === ""
                onClicked: {
                    if (backend.currentFile === "") {
                        saveDialog.open()
                    } else {
                        backend.saveDocument(backend.currentFile)
                    }
                }
            }
        }
    }

    footer: Rectangle {
        height: 32
        color: theme.surface
        Rectangle {
            width: parent.width
            height: 1
            color: theme.border
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8
            Rectangle {
                id: dirtyDot
                implicitWidth: 7
                implicitHeight: 7
                radius: 4
                color: theme.warning
                visible: backend.dirty
            }
            Label {
                id: statusLabel
                text: backend.statusMessage
                color: theme.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Label {
                text: qsTr("翻訳済み %1 / %2").arg(backend.translatedCount).arg(backend.totalCount)
                color: theme.textMuted
                font.pixelSize: 12
            }
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Vertical
        handle: Rectangle {
            implicitHeight: 5
            color: SplitHandle.pressed ? theme.accent : theme.border
        }

        Pane {
            SplitView.preferredHeight: 245
            SplitView.minimumHeight: 170
            padding: 16
            background: Rectangle { color: theme.background }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: qsTr("英文本文")
                        color: theme.text
                        font.bold: true
                        font.pixelSize: 15
                    }
                    Label {
                        text: qsTr("入力した英文を単語に分けて表示します")
                        color: theme.textMuted
                        font.pixelSize: 12
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: qsTr("自動翻訳は使用しません")
                        color: theme.textMuted
                        font.pixelSize: 12
                    }
                }

                TextArea {
                    id: sourceEditor
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: qsTr("ここに英文本文を入力してください…")
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    font.pixelSize: 16
                    color: theme.text
                    background: Rectangle {
                        color: theme.surface
                        radius: 6
                        border.color: sourceEditor.activeFocus ? theme.accent : theme.border
                        border.width: sourceEditor.activeFocus ? 2 : 1
                    }
                    onTextChanged: backend.setSourceText(text)
                }
            }
        }

        Pane {
            SplitView.fillHeight: true
            SplitView.minimumHeight: 260
            padding: 16
            background: Rectangle { color: theme.background }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: qsTr("単語と日本語訳")
                        color: theme.text
                        font.bold: true
                        font.pixelSize: 15
                    }
                    Label {
                        text: qsTr("各単語の上にある欄に日本語訳を入力します")
                        color: theme.textMuted
                        font.pixelSize: 12
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: qsTr("Tab / Shift+Tab で移動")
                        color: theme.textMuted
                        font.pixelSize: 12
                    }
                }

                ScrollView {
                    id: tokenScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth
                    contentHeight: tokenColumn.implicitHeight

                    ColumnLayout {
                        id: tokenColumn
                        width: tokenScroll.availableWidth
                        spacing: 14

                        Label {
                            Layout.fillWidth: true
                            visible: backend.totalCount === 0
                            text: qsTr("本文を入力すると、ここに単語ごとの翻訳欄が表示されます")
                            color: theme.textMuted
                            horizontalAlignment: Text.AlignHCenter
                            padding: 32
                        }

                        Repeater {
                            model: root.tokenLines

                            delegate: Flow {
                                id: lineDelegate
                                required property var modelData
                                required property int index

                                width: tokenColumn.width
                                spacing: 4

                                Repeater {
                                    model: lineDelegate.modelData

                                    delegate: Item {
                                        id: tokenItem
                                        required property var modelData

                                        readonly property bool isWord: tokenItem.modelData.isWord

                                        TextMetrics {
                                            id: tokenMetrics
                                            text: tokenItem.modelData.text
                                            font.pixelSize: 17
                                        }

                                        implicitWidth: tokenItem.isWord
                                            ? Math.max(96, tokenMetrics.advanceWidth + 18)
                                            : Math.max(10, tokenMetrics.advanceWidth + 6)
                                        implicitHeight: 68

                                        TextField {
                                            id: translationField
                                            visible: tokenItem.isWord
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 32
                                            text: tokenItem.modelData.translation
                                            placeholderText: qsTr("訳")
                                            horizontalAlignment: TextInput.AlignHCenter
                                            color: theme.text
                                            font.pixelSize: 14
                                            selectByMouse: true
                                            background: Rectangle {
                                                color: theme.surfaceMuted
                                                radius: 5
                                                border.color: translationField.activeFocus ? theme.accent : theme.border
                                                border.width: translationField.activeFocus ? 2 : 1
                                            }
                                            onTextEdited: {
                                                backend.setTranslation(tokenItem.modelData.key, text)
                                            }
                                            onEditingFinished: {
                                                backend.setTranslation(tokenItem.modelData.key, text)
                                            }
                                            onAccepted: {
                                                translationField.focus = false
                                            }
                                            Keys.onPressed: function(event) {
                                                if (event.key === Qt.Key_Tab) {
                                                    const direction = event.modifiers & Qt.ShiftModifier ? false : true
                                                    const next = translationField.nextItemInFocusChain(direction)
                                                    if (next) {
                                                        next.forceActiveFocus()
                                                        event.accepted = true
                                                    }
                                                }
                                            }
                                        }

                                        Label {
                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: tokenItem.modelData.text
                                            color: tokenItem.isWord
                                                ? (translationField.text.trim() === "" ? theme.text : theme.accent)
                                                : (tokenItem.modelData.text.trim() === "" ? "transparent" : theme.text)
                                            font.pixelSize: 17
                                            font.bold: tokenItem.isWord
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: openDialog
        title: qsTr("学習データを開く")
        fileMode: FileDialog.OpenFile
        nameFilters: [qsTr("試験向英語学習データ (*.json)"), qsTr("すべてのファイル (*)")]
        onAccepted: backend.openDocument(decodeURIComponent(selectedFile.toString().replace("file://", "")))
    }

    FileDialog {
        id: saveDialog
        title: qsTr("学習データを保存")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("試験向英語学習データ (*.json)")]
        defaultSuffix: "json"
        onAccepted: backend.saveDocument(decodeURIComponent(selectedFile.toString().replace("file://", "")))
    }

    Shortcut {
        sequence: "Ctrl+N"
        onActivated: {
            if (backend.dirty) {
                confirmDialog.open()
            } else {
                backend.newDocument()
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+O"
        onActivated: openDialog.open()
    }

    Shortcut {
        sequence: "Ctrl+S"
        onActivated: {
            if (backend.currentFile === "") {
                saveDialog.open()
            } else {
                backend.saveDocument(backend.currentFile)
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+S"
        onActivated: saveDialog.open()
    }

    Shortcut {
        sequence: "Ctrl+Q"
        onActivated: Qt.quit()
    }

    Dialog {
        id: confirmDialog
        title: qsTr("未保存の変更があります")
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Discard | Dialog.Cancel
        onAccepted: backend.newDocument()
        Label {
            text: qsTr("現在の変更は保存されていません。")
            color: theme.text
        }
    }
}
