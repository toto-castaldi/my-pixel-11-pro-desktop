-- Hyprland 0.55 configuration (Lua, hl.* API) for the Android Terminal VM.
-- Linked into ~/.config/hypr/hyprland.lua by install.sh (design/desktop).
-- The graphics environment (zink on gfxstream Vulkan) comes from
-- ~/weston.env through systemd/weston.service, not from this file.

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-------------------
---- PROGRAMS ----
-------------------

local terminal = "foot"
local menu     = "fuzzel"
local locker   = "pidof hyprlock || hyprlock"
-- swaybg draws on the CPU (wl_shm): hyprpaper 0.8 needs a GPU buffer format
-- (AB4H) that gfxstream does not support (design/desktop).
local wallpaper = "swaybg -m fill -i ~/.config/hypr/wallpaper.png"

-- Screenshots are saved as PNG in $HOME/Pictures/Screenshots (README).
-- The area capture saves nothing if the slurp selection is cancelled.
local shotFile = 'mkdir -p "$HOME/Pictures/Screenshots" && f="$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"'
local shotDone = ' && notify-send "Screenshot" "Salvato in $f"'
local shotFull = shotFile .. ' && grim "$f"' .. shotDone
local shotArea = shotFile .. ' && g="$(slurp)" && grim -g "$g" "$f"' .. shotDone
-- Clipboard history: cliphist stores every text copied, fuzzel picks one
-- entry and wl-copy puts it back in the clipboard.
local clipStore   = "wl-paste --type text --watch cliphist store"
local clipHistory = "cliphist list | fuzzel --dmenu --prompt 'Clipboard: ' | cliphist decode | wl-copy"
-- Clipboard shared with Android: the Terminal app agent uses wayland-0,
-- Hyprland opens wayland-1; the script links the first to the second
-- (design/session). Run at every start, also after a watchdog restart.
local agentSocket = "systemd-cat -t session-socket ~/.local/libexec/my-pixel-11-pro-desktop/session-socket link"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Make the session visible to D-Bus activated and systemd user services.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE DISPLAY")
    hl.exec_cmd("waybar")
    hl.exec_cmd(wallpaper)
    hl.exec_cmd("mako")
    hl.exec_cmd(clipStore)
    hl.exec_cmd(agentSocket)
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,
        col = {
            active_border   = "rgba(33ccffee)",
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding = 6,
        shadow = {
            enabled = false,
        },
        -- Blur is off to keep the load on the virtualized GPU low.
        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout    = "it",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",
        follow_mouse = 1,
        sensitivity  = 0,
    },
})

---------------------
---- KEYBINDINGS ----
---------------------

-- SUPER and Tab never reach Hyprland from the Terminal app window: Android
-- takes them (SPIKE-001). ALT is the main modifier, CTRL + ALT is used where
-- an accidental press would be costly. AltGr stays free for the it layout.
local mainMod = "ALT"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { description = "Terminale" })
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd(menu),     { description = "Launcher" })
hl.bind(mainMod .. " + Q",      hl.dsp.window.close(),     { description = "Chiudi la finestra" })
hl.bind(mainMod .. " + F4",     hl.dsp.window.close(),     { description = "Chiudi la finestra" })
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }), { description = "Finestra flottante" })
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen(), { description = "Schermo intero" })
hl.bind(mainMod .. " + P",         hl.dsp.exec_cmd(shotFull), { description = "Screenshot dello schermo" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(shotArea), { description = "Screenshot di un'area" })
hl.bind("CTRL + ALT + V",       hl.dsp.exec_cmd(clipHistory), { description = "Cronologia della clipboard" })
hl.bind("CTRL + ALT + L",       hl.dsp.exec_cmd(locker),   { description = "Blocca lo schermo" })
hl.bind("CTRL + ALT + Q",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
    { description = "Esci dalla sessione" })

-- Move focus with mainMod + arrow keys.
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspace with mainMod + [1-9, 0], move the active window there
-- with mainMod + SHIFT. Keycodes (code:10 = key 1) keep the binds
-- independent of what SHIFT produces on the it layout.
for i = 1, 10 do
    local code = "code:" .. (9 + i)
    hl.bind(mainMod .. " + " .. code,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + wheel.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + left/right button and dragging.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland.
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})
