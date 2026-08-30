function defaultPage(color) {
  return { text: "", color: String(color || "") }
}

var startupPositions = ["center", "top-left", "top-right", "bottom-left", "bottom-right"]

function defaultSettings() {
  return { defaultColor: "", startupPosition: "center" }
}

function defaultState() {
  return { pages: [defaultPage()], currentPage: 0, settings: defaultSettings() }
}

function normalizePage(p) {
  if (typeof p === "string") return { text: p, color: "" }
  if (p && typeof p === "object") return { text: String(p.text || ""), color: String(p.color || "") }
  return defaultPage()
}

function normalizeSettings(s) {
  var d = defaultSettings()
  if (!s || typeof s !== "object") return d
  var startupPosition = startupPositions.indexOf(s.startupPosition) >= 0 ? s.startupPosition : d.startupPosition
  return { defaultColor: String(s.defaultColor || d.defaultColor), startupPosition: startupPosition }
}

function parseNotepadFile(text) {
  var raw = String(text || "").trim()
  if (!raw) return defaultState()

  try {
    var parsed = JSON.parse(raw)
    var pages = Array.isArray(parsed.pages) ? parsed.pages.map(normalizePage) : []
    if (pages.length === 0) pages = [defaultPage()]

    var currentPage = Number(parsed.currentPage)
    if (isNaN(currentPage) || currentPage < 0 || currentPage >= pages.length) currentPage = 0

    return { pages: pages, currentPage: currentPage, settings: normalizeSettings(parsed.settings) }
  } catch (e) {
    return defaultState()
  }
}

function serializeNotepad(pages, currentPage, settings) {
  return JSON.stringify({
    version: 2,
    pages: pages,
    currentPage: currentPage,
    settings: normalizeSettings(settings)
  }, null, 2) + "\n"
}

function luminance(hex) {
  var h = String(hex || "").replace("#", "")
  if (h.length === 3) h = h.split("").map(function(c) { return c + c }).join("")
  if (h.length !== 6) return 1

  var r = parseInt(h.substr(0, 2), 16) / 255
  var g = parseInt(h.substr(2, 2), 16) / 255
  var b = parseInt(h.substr(4, 2), 16) / 255
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

// Empty string means "no override" — caller falls back to the theme foreground.
function readableTextColor(hex) {
  if (!hex) return ""
  return luminance(hex) > 0.6 ? "#1a1a1a" : "#f5f5f5"
}

var palette = [
  { name: "Default", value: "" },
  { name: "Yellow", value: "#f5e6a8" },
  { name: "Pink", value: "#f3b6c9" },
  { name: "Green", value: "#b8e6b0" },
  { name: "Blue", value: "#a8d4f5" },
  { name: "Purple", value: "#d4b8f0" },
  { name: "Orange", value: "#f5c396" }
]

if (typeof module !== "undefined") {
  module.exports = {
    defaultPage: defaultPage,
    defaultSettings: defaultSettings,
    defaultState: defaultState,
    parseNotepadFile: parseNotepadFile,
    serializeNotepad: serializeNotepad,
    readableTextColor: readableTextColor,
    palette: palette,
    startupPositions: startupPositions
  }
}
