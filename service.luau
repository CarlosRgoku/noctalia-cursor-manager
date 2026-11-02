--!nonstrict
-- Cursor Manager
--
-- Applies the configured cursor theme and size at Noctalia startup and whenever
-- the settings change. On niri both values live in the compositor config
-- (cursor { xcursor-theme "macOS"; xcursor-size 48 }); apply-niri.sh rewrites
-- those lines, validates the result with `niri validate` and lets niri
-- hot-reload the config. On Hyprland and Sway it uses the runtime IPC commands.
-- GTK apps get the same values through gsettings.
--
-- Manual control:
--   noctalia msg plugin my-tools/cursor-manager:service all set 64
--   noctalia msg plugin my-tools/cursor-manager:service all set-theme macOS
--   noctalia msg plugin my-tools/cursor-manager:service all apply

local DEFAULT_SIZE = 48
local DEFAULT_THEME = "macOS"
local MIN_SIZE = 16
local MAX_SIZE = 128

local function clampSize(value)
    local n = math.floor(value)
    if n < MIN_SIZE then
        return MIN_SIZE
    end
    if n > MAX_SIZE then
        return MAX_SIZE
    end
    return n
end

local function cleanTheme(value)
    if type(value) ~= "string" then
        return ""
    end
    value = value:gsub('"', "")
    value = value:gsub("[^%w%-%._ ]", "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

local function configuredSize()
    local value = noctalia.getConfig("size")
    if type(value) == "number" then
        return clampSize(value)
    end
    return DEFAULT_SIZE
end

local function configuredTheme()
    local value = cleanTheme(noctalia.getConfig("theme"))
    if value ~= "" then
        return value
    end
    return DEFAULT_THEME
end

local function applyGsettings(theme, size)
    if not noctalia.commandExists("gsettings") then
        return
    end
    noctalia.runAsync({
        "gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", theme,
    })
    noctalia.runAsync({
        "gsettings", "set", "org.gnome.desktop.interface", "cursor-size", tostring(size),
    })
end

local function applyNiri(theme, size)
    local dir = noctalia.pluginDir()
    if dir == nil then
        noctalia.log("cursor-manager: pluginDir() unavailable")
        return false
    end

    local script = dir .. "/apply-niri.sh"
    if not noctalia.fileExists(script) then
        noctalia.log("cursor-manager: helper not found: " .. script)
        return false
    end

    noctalia.runAsync({ "bash", script, theme, tostring(size) }, function(result)
        if result.exitCode ~= 0 then
            noctalia.log("cursor-manager: niri apply failed: " .. tostring(result.stderr))
        else
            noctalia.log("cursor-manager: " .. tostring(result.stdout))
        end
    end)
    return true
end

local function applyHyprland(theme, size)
    if not noctalia.commandExists("hyprctl") then
        return false
    end
    noctalia.runAsync({ "hyprctl", "setcursor", theme, tostring(size) })
    noctalia.log("cursor-manager: hyprctl setcursor " .. theme .. " " .. size)
    return true
end

local function applySway(theme, size)
    if not noctalia.commandExists("swaymsg") then
        return false
    end
    noctalia.runAsync({ "swaymsg", "seat", "-", "xcursor_theme", theme, tostring(size) })
    noctalia.log("cursor-manager: sway xcursor_theme " .. theme .. " " .. size)
    return true
end

local function apply(theme, size)
    theme = theme or configuredTheme()
    size = clampSize(size or configuredSize())
    applyGsettings(theme, size)

    local desktop = string.lower(noctalia.getenv("XDG_CURRENT_DESKTOP") or "")

    if noctalia.getenv("NIRI_SOCKET") ~= nil or string.find(desktop, "niri", 1, true) then
        return applyNiri(theme, size)
    elseif noctalia.getenv("HYPRLAND_INSTANCE_SIGNATURE") ~= nil then
        return applyHyprland(theme, size)
    elseif noctalia.getenv("SWAYSOCK") ~= nil then
        return applySway(theme, size)
    end

    noctalia.log("cursor-manager: compositor not recognized; applied GTK cursor " .. theme .. " " .. size)
    return true
end

apply(configuredTheme(), configuredSize())

function onConfigChanged()
    apply(configuredTheme(), configuredSize())
end

function onIpc(event, payload)
    if event == "set" then
        local size = tonumber(payload)
        if size == nil then
            noctalia.notifyError("Cursor Manager", "Payload must be a number, e.g. 64")
            return
        end
        size = clampSize(size)
        apply(configuredTheme(), size)
        noctalia.notify("Cursor Manager", "Cursor size set to " .. size .. " px")
    elseif event == "set-theme" then
        local theme = cleanTheme(payload)
        if theme == "" then
            noctalia.notifyError("Cursor Manager", "Payload must be a theme name, e.g. macOS")
            return
        end
        apply(theme, configuredSize())
        noctalia.notify("Cursor Manager", "Cursor theme set to " .. theme)
    elseif event == "apply" then
        local theme = configuredTheme()
        local size = configuredSize()
        apply(theme, size)
        noctalia.notify("Cursor Manager", "Cursor applied: " .. theme .. " " .. size .. " px")
    end
end
