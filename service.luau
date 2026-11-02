--!nonstrict
-- Cursor Manager
--
-- Applies the configured cursor size at Noctalia startup and whenever the
-- "size" setting changes. On niri the cursor size is a compositor setting
-- (cursor { xcursor-size N } in config.kdl), so this rewrites that line and
-- lets niri hot-reload the config. On Hyprland and Sway it uses the runtime
-- IPC commands. GTK apps get the same size through gsettings.
--
-- Manual control:
--   noctalia msg plugin my-tools/cursor-manager:service all set 64
--   noctalia msg plugin my-tools/cursor-manager:service all apply

local DEFAULT_SIZE = 48
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

local function configuredSize()
    local value = noctalia.getConfig("size")
    if type(value) == "number" then
        return clampSize(value)
    end
    return DEFAULT_SIZE
end

local function applyGsettings(size)
    if not noctalia.commandExists("gsettings") then
        return
    end
    noctalia.runAsync({
        "gsettings", "set", "org.gnome.desktop.interface", "cursor-size", tostring(size),
    })
end

local function applyNiri(size)
    local path = noctalia.expandPath("~/.config/niri/config.kdl")
    local content = noctalia.readFile(path)
    if content == nil then
        noctalia.log("cursor-manager: niri config not found at " .. path)
        return false
    end

    -- Replace an existing xcursor-size inside the cursor block.
    local updated, replacements = content:gsub("(xcursor%-size%s+)%d+", "%1" .. size)

    if replacements == 0 then
        -- No xcursor-size yet: insert one right after "cursor {".
        local inserted, found = content:gsub("(cursor%s*{[^\n]*\n)", "%1    xcursor-size " .. size .. "\n", 1)
        if found > 0 then
            updated = inserted
        else
            -- No cursor block at all: append a complete one.
            updated = content .. "\n\ncursor {\n    xcursor-size " .. size .. "\n}\n"
        end
    end

    if updated == content then
        noctalia.log("cursor-manager: niri cursor size already " .. size)
        return true
    end

    local backup = path .. ".bak-cursor-manager"
    if not noctalia.fileExists(backup) then
        noctalia.writeFile(backup, content)
    end

    -- Write in place (no rename) so niri's config watcher keeps working.
    local ok, err = noctalia.writeFile(path, updated)
    if not ok then
        noctalia.log("cursor-manager: could not write niri config: " .. tostring(err))
        return false
    end

    noctalia.log("cursor-manager: niri xcursor-size set to " .. size)
    return true
end

local function applyHyprland(size)
    if not noctalia.commandExists("hyprctl") then
        return false
    end
    local theme = noctalia.getenv("XCURSOR_THEME") or "Adwaita"
    noctalia.runAsync({ "hyprctl", "setcursor", theme, tostring(size) })
    noctalia.log("cursor-manager: hyprctl setcursor " .. theme .. " " .. size)
    return true
end

local function applySway(size)
    if not noctalia.commandExists("swaymsg") then
        return false
    end
    local theme = noctalia.getenv("XCURSOR_THEME") or "Adwaita"
    noctalia.runAsync({ "swaymsg", "seat", "-", "xcursor_theme", theme, tostring(size) })
    noctalia.log("cursor-manager: sway xcursor_theme " .. theme .. " " .. size)
    return true
end

local function apply(size)
    size = clampSize(size or configuredSize())
    applyGsettings(size)

    local desktop = string.lower(noctalia.getenv("XDG_CURRENT_DESKTOP") or "")

    if noctalia.getenv("NIRI_SOCKET") ~= nil or string.find(desktop, "niri", 1, true) then
        return applyNiri(size)
    elseif noctalia.getenv("HYPRLAND_INSTANCE_SIGNATURE") ~= nil then
        return applyHyprland(size)
    elseif noctalia.getenv("SWAYSOCK") ~= nil then
        return applySway(size)
    end

    noctalia.log("cursor-manager: compositor not recognized; applied GTK cursor size " .. size)
    return true
end

apply(configuredSize())

function onConfigChanged()
    apply(configuredSize())
end

function onIpc(event, payload)
    if event == "set" then
        local size = tonumber(payload)
        if size == nil then
            noctalia.notifyError("Cursor Manager", "Payload must be a number, e.g. 64")
            return
        end
        size = clampSize(size)
        apply(size)
        noctalia.notify("Cursor Manager", "Cursor size set to " .. size .. " px")
    elseif event == "apply" then
        local size = configuredSize()
        apply(size)
        noctalia.notify("Cursor Manager", "Cursor size applied: " .. size .. " px")
    end
end
