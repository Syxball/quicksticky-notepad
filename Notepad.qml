import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "NotepadModel.js" as NotepadModel

Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property var pages: [{ text: "", color: "" }]
  property int currentPage: 0
  property bool stateLoaded: false
  property string mode: "text" // "text" | "preview"
  property bool showSettings: false
  property var settings: NotepadModel.defaultSettings()
  readonly property int pageCount: root.pages.length

  readonly property var currentPageData: (root.currentPage >= 0 && root.currentPage < root.pages.length)
    ? root.pages[root.currentPage] : { text: "", color: "" }
  readonly property string currentPageText: root.currentPageData.text || ""
  readonly property string currentPageColor: root.currentPageData.color || ""

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", root.border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  readonly property int cornerRadius: Style.cornerRadius
  property int contentMargin: Style.spacing.panelPadding

  // User-adjustable window geometry. Width/height are the user's chosen
  // size (drag-resized or Alt+Shift+Arrow), clamped to the panel each time
  // it's read. Offsets are relative to screen-center (mouse-dragged by the
  // title bar or Alt+Arrow), also clamped so the card can't leave the panel.
  property real userCardWidth: Style.space(460)
  property real userCardHeight: Style.space(400)
  property real cardOffsetX: 0
  property real cardOffsetY: 0
  // True once the user drags/Alt+Arrow-moves the window this session, so a
  // configured startup corner never fights a deliberate move.
  property bool userMoved: false
  readonly property real minCardWidth: Style.space(320)
  readonly property real minCardHeight: Style.space(240)
  property int cardWidth: Math.max(root.minCardWidth, Math.min(root.userCardWidth, panel.width - Style.gapsOut * 2))
  property int cardHeight: Math.max(root.minCardHeight, Math.min(root.userCardHeight, panel.height - Style.gapsOut * 2))

  // Converts the card's current on-screen position (which may be a
  // startup-corner snap, not offset-driven at all) into the equivalent
  // center-relative offset, so switching to manual move/resize continues
  // smoothly from there instead of jumping to center+delta.
  function seedManualOffset() {
    root.cardOffsetX = card.x - (panel.width - card.width) / 2
    root.cardOffsetY = card.y - (panel.height - card.height) / 2
    root.userMoved = true
  }

  function resetGeometry() {
    root.userCardWidth = Style.space(460)
    root.userCardHeight = Style.space(400)
    root.cardOffsetX = 0
    root.cardOffsetY = 0
    root.userMoved = false
  }

  // Note color overrides the card background; text/icons switch to a
  // readable color computed from that background rather than the theme's.
  readonly property color cardColor: root.currentPageColor ? root.currentPageColor : root.background
  readonly property color contentForeground: {
    var readable = NotepadModel.readableTextColor(root.currentPageColor)
    return readable ? readable : root.foreground
  }

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy"
  readonly property string statePath: root.stateDir + "/notepad.json"

  function open(payloadJson) {
    root.opened = true
    Qt.callLater(function() { if (root.mode === "text") textArea.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "quicksticky.notepad")
  }

  function setCurrentText(value) {
    var next = root.pages.slice()
    next[root.currentPage] = { text: value, color: next[root.currentPage].color }
    root.pages = next
    saveTimer.restart()
  }

  function setPageColor(colorHex) {
    var next = root.pages.slice()
    next[root.currentPage] = { text: next[root.currentPage].text, color: colorHex }
    root.pages = next
    saveTimer.restart()
  }

  function goToPage(index) {
    if (index < 0 || index >= root.pages.length) return
    root.currentPage = index
    textArea.text = root.currentPageText
    autoRenderTimer.stop()
  }

  function nextPage() { root.goToPage(root.currentPage + 1) }
  function prevPage() { root.goToPage(root.currentPage - 1) }

  function newPage() {
    var next = root.pages.slice()
    next.push(NotepadModel.defaultPage(root.settings.defaultColor))
    root.pages = next
    root.goToPage(next.length - 1)
    saveTimer.restart()
  }

  function updateSettings(patch) {
    root.settings = Object.assign({}, root.settings, patch)
    saveTimer.restart()
  }

  function setDefaultColor(colorHex) {
    root.updateSettings({ defaultColor: colorHex })
  }

  function setStartupPosition(pos) {
    root.updateSettings({ startupPosition: pos })
  }

  function setAutoRenderPreview(enabled) {
    root.updateSettings({ autoRenderPreview: enabled })
  }

  function deletePage() {
    if (root.pages.length <= 1) return
    var next = root.pages.slice()
    next.splice(root.currentPage, 1)
    root.pages = next
    root.goToPage(Math.min(root.currentPage, next.length - 1))
    saveTimer.restart()
  }

  function loadState(raw) {
    if (root.stateLoaded) return
    var state = NotepadModel.parseNotepadFile(raw)
    root.pages = state.pages
    root.currentPage = state.currentPage
    root.settings = state.settings
    root.stateLoaded = true
    textArea.text = root.currentPageText
  }

  function flushState() {
    if (!root.stateLoaded) return
    notepadFile.setText(NotepadModel.serializeNotepad(root.pages, root.currentPage, root.settings))
  }

  Process {
    id: ensureDirProc
    command: ["mkdir", "-p", root.stateDir]
    running: false
  }

  FileView {
    id: notepadFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadState(text())
    onLoadFailed: root.loadState("")
  }

  Timer {
    id: saveTimer
    interval: 400
    repeat: false
    onTriggered: root.flushState()
  }

  // When enabled, switches to Preview a beat after typing stops — restarted
  // on every keystroke so it only fires once you actually pause. Going back
  // to Text still needs the button/click (Preview isn't editable), so this
  // only automates the type -> see-it-rendered direction.
  Timer {
    id: autoRenderTimer
    interval: 800
    repeat: false
    onTriggered: {
      if (root.settings.autoRenderPreview && root.mode === "text")
        root.mode = "preview"
    }
  }

  Component.onCompleted: {
    ensureDirProc.running = true
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "quicksticky-notepad"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      // Fully reactive rather than a one-shot pixel computation: panel.width/
      // height start at a Qt placeholder size before the compositor reports
      // real layer-shell geometry, so this must recompute once they change,
      // not bake in a number from whatever they were at load time.
      readonly property real startupMargin: Style.space(16)
      readonly property bool startupRight: root.settings.startupPosition === "top-right" || root.settings.startupPosition === "bottom-right"
      readonly property bool startupLeft: root.settings.startupPosition === "top-left" || root.settings.startupPosition === "bottom-left"
      readonly property bool startupBottom: root.settings.startupPosition === "bottom-left" || root.settings.startupPosition === "bottom-right"
      readonly property bool startupTop: root.settings.startupPosition === "top-left" || root.settings.startupPosition === "top-right"

      x: (!root.userMoved && startupRight) ? Math.max(0, panel.width - width - startupMargin)
        : (!root.userMoved && startupLeft) ? Math.min(panel.width - width, startupMargin)
        : Math.max(0, Math.min(panel.width - width, (panel.width - width) / 2 + root.cardOffsetX))
      y: (!root.userMoved && startupBottom) ? Math.max(0, panel.height - height - startupMargin)
        : (!root.userMoved && startupTop) ? Math.min(panel.height - height, startupMargin)
        : Math.max(0, Math.min(panel.height - height, (panel.height - height) / 2 + root.cardOffsetY))
      color: root.cardColor
      borderSpec: root.borderSpec
      padding: root.contentMargin

      Behavior on color { ColorAnimation { duration: 150 } }

      MouseArea { anchors.fill: parent; onClicked: {} }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: Style.space(8)

        // ---- Row 1: title (drag handle), text/preview switch, close.
        Item {
          id: titleRow
          width: parent.width
          height: Style.space(28)

          // Drag-to-move. Declared first so the buttons in the Row below
          // stack on top and keep receiving their own clicks.
          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            property point lastPos: Qt.point(0, 0)

            onPressed: function(mouse) {
              lastPos = Qt.point(mouse.x, mouse.y)
              root.seedManualOffset()
            }
            onPositionChanged: function(mouse) {
              if (!pressed) return
              root.cardOffsetX += (mouse.x - lastPos.x)
              root.cardOffsetY += (mouse.y - lastPos.y)
            }

            ToolTip {
              visible: parent.containsMouse
              text: "Drag to move · Alt+Arrows"
              delay: 600
            }
          }

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Quick Sticky"
            color: root.contentForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            font.bold: true
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Repeater {
              model: [
                { label: "Text", value: "text" },
                { label: "Preview", value: "preview" }
              ]

              // A self-drawn toggle rather than the shared Button: its selected-state
              // fill/text color is theme-token driven (can resolve against the global
              // accent instead of our card color), which goes unreadable against
              // non-default note colors. Deriving both states from contentForeground
              // directly guarantees contrast against any card color.
              delegate: Rectangle {
                readonly property bool tabSelected: root.mode === modelData.value

                implicitWidth: tabLabel.implicitWidth + Style.space(16)
                implicitHeight: tabLabel.implicitHeight + Style.space(8)
                radius: Style.cornerRadius
                color: tabSelected ? Util.alpha(root.contentForeground, 0.18) : "transparent"
                border.color: root.contentForeground
                border.width: Math.max(1, Style.space(1))

                Text {
                  id: tabLabel
                  anchors.centerIn: parent
                  text: modelData.label
                  color: root.contentForeground
                  font.family: Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  font.bold: tabSelected
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.mode = modelData.value
                    if (modelData.value === "text")
                      Qt.callLater(function() { textArea.forceActiveFocus() })
                  }
                }
              }
            }

            PanelActionButton {
              iconText: "⚙"
              tooltipText: "Settings"
              foreground: root.contentForeground
              onClicked: root.showSettings = !root.showSettings
            }

            PanelActionButton {
              iconText: "✕"
              tooltipText: "Close"
              foreground: root.contentForeground
              onClicked: root.dismiss()
            }
          }
        }

        // ---- Row 2: page navigation, note color swatches.
        Item {
          id: row2
          width: parent.width
          height: Style.space(24)

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Page " + (root.currentPage + 1) + " / " + root.pageCount
              color: Qt.darker(root.contentForeground, 1.3)
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              rightPadding: Style.space(8)
            }

            PanelActionButton {
              iconText: "‹"
              tooltipText: "Previous page"
              foreground: root.contentForeground
              enabled: root.currentPage > 0
              onClicked: root.prevPage()
            }

            PanelActionButton {
              iconText: "›"
              tooltipText: "Next page"
              foreground: root.contentForeground
              enabled: root.currentPage < root.pageCount - 1
              onClicked: root.nextPage()
            }

            PanelActionButton {
              iconText: "+"
              tooltipText: "New page"
              foreground: root.contentForeground
              onClicked: root.newPage()
            }

            PanelActionButton {
              iconText: "－"
              tooltipText: "Delete page"
              foreground: root.contentForeground
              hoverColor: "#e06c75"
              enabled: root.pageCount > 1
              onClicked: root.deletePage()
            }
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Repeater {
              model: NotepadModel.palette

              Rectangle {
                required property var modelData

                width: Style.space(18)
                height: Style.space(18)
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: modelData.value || root.background
                border.width: root.currentPageColor === modelData.value ? 2 : 1
                border.color: root.currentPageColor === modelData.value
                  ? root.contentForeground
                  : Qt.darker(root.contentForeground, 1.6)

                MouseArea {
                  id: swatchMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.setPageColor(modelData.value)
                }

                ToolTip {
                  visible: swatchMouse.containsMouse
                  text: modelData.name
                  delay: 400
                }
              }
            }
          }
        }

        // ---- Settings drawer: expands in place when the gear is clicked.
        // Populated one setting at a time.
        Column {
          id: settingsDrawer
          visible: root.showSettings
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "SETTINGS"
            color: Qt.darker(root.contentForeground, 1.3)
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            font.letterSpacing: 1
            topPadding: Style.space(2)
          }

          Item {
            width: parent.width
            height: Style.space(20)

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Default note color"
              color: root.contentForeground
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
            }

            Row {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(5)

              Repeater {
                model: NotepadModel.palette

                Rectangle {
                  required property var modelData

                  width: Style.space(14)
                  height: Style.space(14)
                  radius: width / 2
                  anchors.verticalCenter: parent.verticalCenter
                  color: modelData.value || root.background
                  border.width: root.settings.defaultColor === modelData.value ? 2 : 1
                  border.color: root.settings.defaultColor === modelData.value
                    ? root.contentForeground
                    : Qt.darker(root.contentForeground, 1.6)

                  MouseArea {
                    id: defaultSwatchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setDefaultColor(modelData.value)
                  }

                  ToolTip {
                    visible: defaultSwatchMouse.containsMouse
                    text: modelData.name
                    delay: 400
                  }
                }
              }
            }
          }

          Item {
            width: parent.width
            height: Style.space(20)

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Startup position"
              color: root.contentForeground
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
            }

            Row {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(4)

              Repeater {
                model: [
                  { name: "Center", value: "center", glyph: "⊙" },
                  { name: "Top left", value: "top-left", glyph: "↖" },
                  { name: "Top right", value: "top-right", glyph: "↗" },
                  { name: "Bottom left", value: "bottom-left", glyph: "↙" },
                  { name: "Bottom right", value: "bottom-right", glyph: "↘" }
                ]

                // Same self-drawn approach as the Text/Preview tabs: colors
                // derive from contentForeground directly rather than the
                // shared Button's theme-token selected state, which isn't
                // guaranteed to stay readable against an arbitrary card color.
                delegate: Rectangle {
                  required property var modelData
                  readonly property bool posSelected: root.settings.startupPosition === modelData.value

                  width: Style.space(18)
                  height: Style.space(18)
                  radius: Style.cornerRadius
                  color: posSelected ? Util.alpha(root.contentForeground, 0.18) : "transparent"
                  border.color: root.contentForeground
                  border.width: Math.max(1, Style.space(1))

                  Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    color: root.contentForeground
                    font.family: Style.font.family
                    font.pixelSize: Style.font.bodySmall
                    font.bold: posSelected
                  }

                  MouseArea {
                    id: posMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setStartupPosition(modelData.value)
                  }

                  ToolTip {
                    visible: posMouse.containsMouse
                    text: modelData.name
                    delay: 400
                  }
                }
              }
            }
          }

          Item {
            width: parent.width
            height: Style.space(20)

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Auto-render preview"
              color: root.contentForeground
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
            }

            Rectangle {
              id: autoRenderSwitch
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(30)
              height: Style.space(17)
              radius: height / 2
              color: root.settings.autoRenderPreview
                ? Util.alpha(root.contentForeground, 0.45)
                : Util.alpha(root.contentForeground, 0.16)
              border.color: root.contentForeground
              border.width: 1

              Rectangle {
                width: Style.space(13)
                height: Style.space(13)
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.settings.autoRenderPreview ? parent.width - width - 2 : 2
                color: root.contentForeground

                Behavior on x { NumberAnimation { duration: 120 } }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setAutoRenderPreview(!root.settings.autoRenderPreview)
              }
            }
          }

          Text {
            text: "HOTKEYS"
            color: Qt.darker(root.contentForeground, 1.3)
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            font.letterSpacing: 1
            topPadding: Style.space(6)
          }

          Repeater {
            model: [
              { action: "Move window", keys: "Alt + Arrows" },
              { action: "Resize window", keys: "Alt + Shift + Arrows" },
              { action: "Reset window", keys: "Alt + 0" }
            ]

            Item {
              required property var modelData

              width: parent.width
              height: Style.space(18)

              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: parent.modelData.action
                color: root.contentForeground
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
              }

              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: parent.modelData.keys
                color: Qt.darker(root.contentForeground, 1.3)
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
              }
            }
          }
        }

        Rectangle {
          id: divider
          width: parent.width
          height: Style.spacing.hairline
          color: root.contentForeground
          opacity: 0.12
        }

        // ---- Body: text editor and rendered preview occupy the same
        // space; only one is visible at a time per the mode switch above.
        Item {
          id: body
          width: parent.width
          height: parent.height - titleRow.height - row2.height - divider.height
            - (settingsDrawer.visible ? settingsDrawer.height : 0)
            - parent.spacing * (settingsDrawer.visible ? 4 : 3)

          ScrollView {
            anchors.fill: parent
            clip: true
            visible: root.mode === "text"

            TextArea {
              id: textArea
              width: body.width
              wrapMode: TextArea.Wrap
              selectByMouse: true
              color: root.contentForeground
              selectionColor: Style.selectionFillFor(root.contentForeground, Color.accent)
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              background: null
              placeholderText: "Type a quick note in markdown…"
              placeholderTextColor: Qt.darker(root.contentForeground, 1.6)

              onTextChanged: {
                // Guarded by the same divergence check as the save call below,
                // so loading a page or switching pages (which set text to
                // already match currentPageText) never counts as "typing" and
                // triggers an unwanted auto-switch to Preview.
                if (root.stateLoaded && text !== root.currentPageText) {
                  root.setCurrentText(text)
                  if (root.settings.autoRenderPreview) autoRenderTimer.restart()
                }
              }

              // Overrides the default word-jump on Ctrl+Left/Right in favor of
              // page navigation, and Qt's default Alt+Arrow (none) in favor
              // of window move/resize, since a notepad's pages and window
              // geometry matter more here than in-line word/caret movement.
              Keys.onPressed: function(event) {
                var step = 24
                if (event.key === Qt.Key_Escape) {
                  root.dismiss()
                  event.accepted = true
                } else if (event.modifiers & Qt.ControlModifier) {
                  if (event.key === Qt.Key_Right) { root.nextPage(); event.accepted = true }
                  else if (event.key === Qt.Key_Left) { root.prevPage(); event.accepted = true }
                  else if (event.key === Qt.Key_N) { root.newPage(); event.accepted = true }
                } else if (event.modifiers & Qt.AltModifier) {
                  var resizing = event.modifiers & Qt.ShiftModifier
                  if (event.key === Qt.Key_0) {
                    root.resetGeometry(); event.accepted = true
                  } else if (event.key === Qt.Key_Right) {
                    if (resizing) { root.userCardWidth += step }
                    else { root.seedManualOffset(); root.cardOffsetX += step }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Left) {
                    if (resizing) { root.userCardWidth = Math.max(root.minCardWidth, root.userCardWidth - step) }
                    else { root.seedManualOffset(); root.cardOffsetX -= step }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Down) {
                    if (resizing) { root.userCardHeight += step }
                    else { root.seedManualOffset(); root.cardOffsetY += step }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Up) {
                    if (resizing) { root.userCardHeight = Math.max(root.minCardHeight, root.userCardHeight - step) }
                    else { root.seedManualOffset(); root.cardOffsetY -= step }
                    event.accepted = true
                  }
                }
              }
            }
          }

          ScrollView {
            anchors.fill: parent
            clip: true
            visible: root.mode === "preview"

            Text {
              width: body.width
              wrapMode: Text.Wrap
              textFormat: Text.MarkdownText
              text: root.currentPageText
              color: root.contentForeground
              linkColor: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }
          }
        }
      }

      // ---- Resize grip, bottom-right corner. Declared after Column so it
      // stacks on top and stays grabbable over the body content.
      Rectangle {
        id: resizeGrip
        width: Style.space(16)
        height: Style.space(16)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "transparent"

        Text {
          anchors.centerIn: parent
          text: "◢"
          color: root.contentForeground
          opacity: 0.5
          font.pixelSize: Style.font.bodySmall
        }

        MouseArea {
          id: resizeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.SizeFDiagCursor
          property point lastPos: Qt.point(0, 0)

          onPressed: function(mouse) { lastPos = Qt.point(mouse.x, mouse.y) }
          onPositionChanged: function(mouse) {
            if (!pressed) return
            root.userCardWidth = Math.max(root.minCardWidth, root.userCardWidth + (mouse.x - lastPos.x))
            root.userCardHeight = Math.max(root.minCardHeight, root.userCardHeight + (mouse.y - lastPos.y))
          }

          ToolTip {
            visible: resizeMouse.containsMouse
            text: "Drag to resize · Alt+Shift+Arrows"
            delay: 500
          }
        }
      }
    }
  }
}
