-- =============================================================================
-- rc.lua — AwesomeWM + Vertex Theme (copycats)
-- Basado en config auditada, adaptada para vertex
-- =============================================================================
--
-- CAMBIOS RESPECTO A LA VERSION ANTERIOR:
--
--  [VERTEX-1] beautiful.init ahora carga themes/vertex/theme.lua
--
--  [VERTEX-2] awful.util.terminal, awful.util.tagnames, awful.util.taglist_buttons
--             y awful.util.tasklist_buttons son requeridos por theme.lua de
--             vertex — deben asignarse ANTES de llamar a beautiful.init
--
--  [VERTEX-3] awful.screen.connect_for_each_screen ahora llama a
--             theme.at_screen_connect(s) que vertex define internamente.
--             Esto configura: barra top, dock vertical izquierdo, taglist,
--             tasklist, wallpaper y quake terminal.
--
--  [VERTEX-4] Se elimina la wibar manual (s.mywibox:setup{...}) porque
--             vertex la construye en theme.at_screen_connect.
--
--  [VERTEX-5] awful.util.mymainmenu es el nombre que vertex usa internamente
--             para el launcher (línea 289 de theme.lua). Se asigna después
--             de crear mymainmenu.
--
--  [VERTEX-6] El widget de volumen de vertex usa lain.widget.alsabar (ALSA).
--             Con PipeWire+PulseAudio esto funciona vía pipewire-alsa.
--             Si el icono de volumen no responde, verificar:
--             `pacman -Q pipewire-alsa`
--
--  [VERTEX-7] El wifi widget lee /proc/net/wireless y asume interfaz wlan0.
--             Cambiar "wlan0" en theme.lua si tu interfaz tiene otro nombre
--             (`ip link` para verificar).
--
--  [VERTEX-8] MPD está configurado en theme.lua con music_dir hardcodeado.
--             Si no usas mpd, el widget simplemente no mostrará nada.
--             Para desactivarlo edita theme.lua y comenta el bloque "MPD".
--
--  [FIX-1..8] Todos los fixes y optimizaciones de la versión anterior se
--             conservan intactos.
--
-- =============================================================================

pcall(require, "luarocks.loader")

-- =============================================================================
-- LIBRERÍAS
-- =============================================================================
local gears         = require("gears")
local awful         = require("awful")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local menubar       = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")

require("awful.autofocus")
require("awful.hotkeys_popup.keys")

-- =============================================================================
-- MANEJO DE ERRORES
-- =============================================================================
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title  = "Error durante el inicio",
        text   = awesome.startup_errors
    })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true
        naughty.notify({
            preset = naughty.config.presets.critical,
            title  = "Error en ejecución",
            text   = tostring(err)
        })
        in_error = false
    end)
end

-- =============================================================================
-- VARIABLES GLOBALES
-- =============================================================================
-- terminal y modkey deben ser globales (awful las busca en _G)
terminal = "kitty"
modkey   = "Mod4"

local editor     = os.getenv("EDITOR") or "nano"
local editor_cmd = terminal .. " -e " .. editor

-- [VERTEX-2] awful.util.terminal es requerido por vertex (quake, alsamixer, etc.)
-- Debe asignarse ANTES de beautiful.init
awful.util.terminal = terminal

-- =============================================================================
-- LAYOUTS
-- =============================================================================
-- [OPT-1] Lista reducida a los más prácticos
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.floating,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
}

-- =============================================================================
-- TAGLIST Y TASKLIST BUTTONS
-- [VERTEX-2] Deben definirse antes de beautiful.init porque theme.lua los
-- referencia como awful.util.taglist_buttons y awful.util.tasklist_buttons
-- =============================================================================
awful.util.taglist_buttons = gears.table.join(
    awful.button({},         1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then client.focus:move_to_tag(t) end
    end),
    awful.button({},         3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then client.focus:toggle_tag(t) end
    end),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", { raise = true })
        end
    end),
    awful.button({}, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({}, 4, function() awful.client.focus.byidx(1)  end),
    awful.button({}, 5, function() awful.client.focus.byidx(-1) end)
)

-- =============================================================================
-- TEMA
-- [VERTEX-1] Carga vertex. awful.util.tagnames lo define vertex internamente
-- como iconos FontAwesome (8 tags). Si prefieres números cambia la línea
-- awful.util.tagnames en theme.lua.
-- =============================================================================
beautiful.init(string.format("%s/.config/awesome/themes/vertex/theme.lua",
    os.getenv("HOME")))

-- =============================================================================
-- MENÚ
-- [VERTEX-5] Se asigna a awful.util.mymainmenu para que el launcher de
-- vertex lo pueda abrir con su botón izquierdo (theme.lua línea 289)
-- =============================================================================
local powermenu_items = {
    { "🔒 Lock",      function() awful.spawn("loginctl lock-session") end },
    { "🌙 Suspend",   function() awful.spawn("systemctl suspend")     end },
    { "💤 Hibernate", function() awful.spawn("systemctl hibernate")   end },
    { "🔄 Reboot",    function() awful.spawn("systemctl reboot")      end },
    { "⏻  Shutdown",  function() awful.spawn("systemctl poweroff")    end },
}

local myawesomemenu = {
    { "hotkeys",     function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "manual",      terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart",     awesome.restart },
    { "quit",        function() awesome.quit() end },
}

-- mymainmenu: global para menubar; también asignado a awful.util.mymainmenu
mymainmenu = awful.menu({
    items = {
        { "awesome",               myawesomemenu,                         beautiful.awesome_icon },
        { "power",                 powermenu_items },
        { "terminal",              terminal },
        { "system monitor (btop)", "kitty --class btop -e btop" },
        { "files (yazi)",          "kitty --class yazi -e yazi" },
        { "browser",               "firefox" },
        { "editor",                "code" },
        { "darktable",             "darktable" },
        { "nitrogen",              "nitrogen" },
    }
})

-- [VERTEX-5] El launcher de vertex llama a awful.util.mymainmenu:toggle()
awful.util.mymainmenu = mymainmenu

menubar.utils.terminal = terminal

-- =============================================================================
-- PANTALLAS
-- [VERTEX-3] vertex define theme.at_screen_connect(s) que construye:
--   · Wallpaper (desde theme.wallpaper o nitrogen si está activo)
--   · Tags con iconos FontAwesome
--   · Barra horizontal top (tasklist + clock + wifi + vol + bat + systray)
--   · Dock vertical izquierdo con taglist (aparece al hover)
--   · Quake terminal (dropdown con Mod4+`)
-- No se construye wibar manualmente aquí.
-- =============================================================================
awful.screen.connect_for_each_screen(function(s)
    beautiful.at_screen_connect(s)
end)

-- =============================================================================
-- MOUSE BINDINGS (escritorio)
-- =============================================================================
root.buttons(gears.table.join(
    awful.button({}, 3, function() mymainmenu:toggle() end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))

-- =============================================================================
-- KEYBINDINGS GLOBALES
-- =============================================================================
globalkeys = gears.table.join(

    -- Awesome
    awful.key({ modkey }, "s", hotkeys_popup.show_help,
        { description = "mostrar ayuda de teclas", group = "awesome" }),
    awful.key({ modkey }, "w", function() mymainmenu:show() end,
        { description = "menú principal", group = "awesome" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
        { description = "recargar awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "q", awesome.quit,
        { description = "salir de awesome", group = "awesome" }),

    -- Quake terminal (dropdown) — definido por vertex en at_screen_connect
    awful.key({ modkey }, "`",
        function()
            local s = awful.screen.focused()
            if s.quake then s.quake:toggle() end
        end,
        { description = "quake terminal (dropdown)", group = "launcher" }),

    -- Navegación de tags
    awful.key({ modkey }, "Left",   awful.tag.viewprev,
        { description = "tag anterior", group = "tag" }),
    awful.key({ modkey }, "Right",  awful.tag.viewnext,
        { description = "tag siguiente", group = "tag" }),
    awful.key({ modkey }, "Escape", awful.tag.history.restore,
        { description = "volver al tag anterior", group = "tag" }),

    -- Foco de clientes
    awful.key({ modkey }, "j",
        function() awful.client.focus.byidx(1) end,
        { description = "enfocar siguiente", group = "client" }),
    awful.key({ modkey }, "k",
        function() awful.client.focus.byidx(-1) end,
        { description = "enfocar anterior", group = "client" }),
    awful.key({ modkey }, "u", awful.client.urgent.jumpto,
        { description = "ir a cliente urgente", group = "client" }),
    awful.key({ modkey }, "Tab",
        function()
            awful.client.focus.history.previous()
            if client.focus then client.focus:raise() end
        end,
        { description = "alternar cliente previo", group = "client" }),

    -- Intercambio de clientes
    awful.key({ modkey, "Shift" }, "j",
        function() awful.client.swap.byidx(1)  end,
        { description = "intercambiar con siguiente", group = "client" }),
    awful.key({ modkey, "Shift" }, "k",
        function() awful.client.swap.byidx(-1) end,
        { description = "intercambiar con anterior", group = "client" }),

    -- Pantallas
    awful.key({ modkey, "Control" }, "j",
        function() awful.screen.focus_relative(1)  end,
        { description = "enfocar siguiente pantalla", group = "screen" }),
    awful.key({ modkey, "Control" }, "k",
        function() awful.screen.focus_relative(-1) end,
        { description = "enfocar pantalla anterior", group = "screen" }),

    -- Layout
    awful.key({ modkey }, "l",
        function() awful.tag.incmwfact( 0.05) end,
        { description = "ampliar área master", group = "layout" }),
    awful.key({ modkey }, "h",
        function() awful.tag.incmwfact(-0.05) end,
        { description = "reducir área master", group = "layout" }),
    awful.key({ modkey, "Shift" }, "h",
        function() awful.tag.incnmaster(1, nil, true) end,
        { description = "más ventanas master", group = "layout" }),
    awful.key({ modkey, "Shift" }, "l",
        function() awful.tag.incnmaster(-1, nil, true) end,
        { description = "menos ventanas master", group = "layout" }),
    awful.key({ modkey, "Control" }, "h",
        function() awful.tag.incncol(1, nil, true) end,
        { description = "más columnas", group = "layout" }),
    awful.key({ modkey, "Control" }, "l",
        function() awful.tag.incncol(-1, nil, true) end,
        { description = "menos columnas", group = "layout" }),
    awful.key({ modkey }, "space",
        function() awful.layout.inc(1)  end,
        { description = "layout siguiente", group = "layout" }),
    awful.key({ modkey, "Shift" }, "space",
        function() awful.layout.inc(-1) end,
        { description = "layout anterior", group = "layout" }),

    -- Restaurar cliente minimizado
    awful.key({ modkey, "Control" }, "n",
        function()
            local c = awful.client.restore()
            if c then
                c:emit_signal("request::activate", "key.unminimize", { raise = true })
            end
        end,
        { description = "restaurar minimizado", group = "client" }),

    -- Launchers
    awful.key({ modkey }, "Return",
        function() awful.spawn(terminal) end,
        { description = "abrir terminal", group = "launcher" }),
    awful.key({ modkey }, "r",
        function() awful.screen.focused().mypromptbox:run() end,
        { description = "prompt de ejecución", group = "launcher" }),
    awful.key({ modkey }, "p",
        function() menubar.show() end,
        { description = "menubar", group = "launcher" }),

    -- Prompt Lua
    awful.key({ modkey }, "x",
        function()
            awful.prompt.run {
                prompt       = "Lua: ",
                textbox      = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval",
            }
        end,
        { description = "ejecutar código Lua", group = "awesome" }),

    -- Audio — volumen (script personalizado)
    awful.key({}, "XF86AudioRaiseVolume",
        function() awful.spawn({ os.getenv("HOME") .. "/.local/bin/volume.sh", "up" })   end,
        { description = "subir volumen", group = "audio" }),
    awful.key({}, "XF86AudioLowerVolume",
        function() awful.spawn({ os.getenv("HOME") .. "/.local/bin/volume.sh", "down" }) end,
        { description = "bajar volumen", group = "audio" }),
    awful.key({}, "XF86AudioMute",
        function() awful.spawn({ os.getenv("HOME") .. "/.local/bin/volume.sh", "mute" }) end,
        { description = "silenciar audio", group = "audio" }),
    awful.key({}, "XF86AudioMicMute",
        function() awful.spawn("pactl set-source-mute @DEFAULT_SOURCE@ toggle") end,
        { description = "silenciar micrófono", group = "audio" }),

    -- Audio — reproducción
    awful.key({}, "XF86AudioPlay",
        function() awful.spawn("playerctl play-pause") end,
        { description = "play/pause", group = "media" }),
    awful.key({}, "XF86AudioNext",
        function() awful.spawn("playerctl next") end,
        { description = "siguiente pista", group = "media" }),
    awful.key({}, "XF86AudioPrev",
        function() awful.spawn("playerctl previous") end,
        { description = "pista anterior", group = "media" }),

    -- Brillo
    awful.key({}, "XF86MonBrightnessUp",
        function() awful.spawn("brightnessctl set +10%") end,
        { description = "subir brillo", group = "screen" }),
    awful.key({}, "XF86MonBrightnessDown",
        function() awful.spawn("brightnessctl set 10%-") end,
        { description = "bajar brillo", group = "screen" }),

    -- ThinkVantage → btop
    awful.key({}, "XF86Launch1",
        function() awful.spawn("kitty --class btop -e btop") end,
        { description = "abrir btop", group = "launcher" }),

    -- Capturas de pantalla
    awful.key({}, "Print",
        function()
            local dir  = os.getenv("HOME") .. "/Pictures/screenshots/"
            local file = dir .. os.date("%Y-%m-%d_%H-%M-%S") .. "_full.png"
            awful.spawn.easy_async(
                string.format("bash -c 'mkdir -p %s && scrot %s'", dir, file),
                function(_, _, _, exitcode)
                    if exitcode == 0 then
                        naughty.notify({ title = "Captura guardada", text = file, timeout = 4 })
                    else
                        naughty.notify({
                            preset = naughty.config.presets.critical,
                            title  = "Error al capturar",
                            text   = "scrot falló (código " .. exitcode .. ")",
                        })
                    end
                end
            )
        end,
        { description = "captura pantalla completa", group = "screenshot" }),

    awful.key({ modkey }, "Print",
        function()
            local dir  = os.getenv("HOME") .. "/Pictures/screenshots/"
            local file = dir .. os.date("%Y-%m-%d_%H-%M-%S") .. "_sel.png"
            awful.spawn.easy_async(
                string.format("bash -c 'mkdir -p %s && scrot -s %s'", dir, file),
                function(_, _, _, sc_exit)
                    if sc_exit == 0 then
                        awful.spawn.easy_async(
                            string.format("xclip -selection clipboard -t image/png -i %s", file),
                            function(_, _, _, xclip_exit)
                                local extra = xclip_exit == 0
                                    and "\nCopiada al portapapeles"
                                    or  "\n⚠ xclip falló, solo guardada"
                                naughty.notify({
                                    title   = "Selección guardada",
                                    text    = file .. extra,
                                    timeout = 4,
                                })
                            end
                        )
                    else
                        naughty.notify({
                            preset  = naughty.config.presets.critical,
                            title   = "Error al capturar",
                            text    = "scrot falló (código " .. sc_exit .. ")",
                        })
                    end
                end
            )
        end,
        { description = "captura por selección", group = "screenshot", on_release = true })
)

-- =============================================================================
-- KEYBINDINGS DE CLIENTE
-- =============================================================================
clientkeys = gears.table.join(
    awful.key({ modkey }, "f",
        function(c) c.fullscreen = not c.fullscreen; c:raise() end,
        { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey, "Shift" }, "c",
        function(c) c:kill() end,
        { description = "cerrar ventana", group = "client" }),
    awful.key({ modkey, "Control" }, "space",
        awful.client.floating.toggle,
        { description = "toggle flotante", group = "client" }),
    awful.key({ modkey, "Control" }, "Return",
        function(c) c:swap(awful.client.getmaster()) end,
        { description = "mover a master", group = "client" }),
    awful.key({ modkey }, "o",
        function(c) c:move_to_screen() end,
        { description = "mover a otra pantalla", group = "client" }),
    awful.key({ modkey }, "t",
        function(c) c.ontop = not c.ontop end,
        { description = "toggle siempre encima", group = "client" }),
    awful.key({ modkey }, "n",
        function(c) c.minimized = true end,
        { description = "minimizar", group = "client" }),
    awful.key({ modkey }, "m",
        function(c) c.maximized = not c.maximized; c:raise() end,
        { description = "(des)maximizar", group = "client" }),
    awful.key({ modkey, "Control" }, "m",
        function(c) c.maximized_vertical = not c.maximized_vertical; c:raise() end,
        { description = "(des)maximizar vertical", group = "client" }),
    awful.key({ modkey, "Shift" }, "m",
        function(c) c.maximized_horizontal = not c.maximized_horizontal; c:raise() end,
        { description = "(des)maximizar horizontal", group = "client" })
)

-- =============================================================================
-- TECLAS NUMÉRICAS → TAGS
-- =============================================================================
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag    = screen.tags[i]
                if tag then tag:view_only() end
            end,
            { description = "ver tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag    = screen.tags[i]
                if tag then awful.tag.viewtoggle(tag) end
            end,
            { description = "toggle tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then client.focus:move_to_tag(tag) end
                end
            end,
            { description = "mover cliente a tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then client.focus:toggle_tag(tag) end
                end
            end,
            { description = "toggle cliente en tag #" .. i, group = "tag" })
    )
end

-- =============================================================================
-- BOTONES DE CLIENTE (ratón)
-- =============================================================================
clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

root.keys(globalkeys)

-- =============================================================================
-- REGLAS DE CLIENTES
-- =============================================================================
awful.rules.rules = {

    -- Regla global
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus        = awful.client.focus.filter,
            raise        = true,
            keys         = clientkeys,
            buttons      = clientbuttons,
            screen       = awful.screen.preferred,
            placement    = awful.placement.no_overlap + awful.placement.no_offscreen,
        }
    },

    -- Ventanas flotantes por defecto
    {
        rule_any = {
            instance = { "DTA", "copyq", "pinentry" },
            class    = {
                "Arandr", "Blueman-manager", "Gpick", "Kruler",
                "MessageWin", "Sxiv", "Tor Browser", "Wpa_gui",
                "veromix", "xtightvncviewer",
            },
            name  = { "Event Tester" },
            role  = { "AlarmWindow", "ConfigManager", "pop-up" },
        },
        properties = { floating = true }
    },

    -- btop: flotante, centrado, siempre encima
    {
        rule = { class = "btop" },
        properties = {
            floating          = true,
            ontop             = true,
            placement         = awful.placement.centered,
            width             = 900,
            height            = 600,
            titlebars_enabled = false,
            maximized         = false,
        }
    },

    -- [VERTEX-4] Titlebars desactivadas — vertex no las usa en su diseño.
    -- Las ventanas flotantes con diálogos pueden habilitarlas si se quiere.
    {
        rule_any  = { type = { "normal", "dialog" } },
        properties = { titlebars_enabled = false }
    },
}

-- =============================================================================
-- SEÑALES
-- =============================================================================

client.connect_signal("manage", function(c)
    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position
    then
        awful.placement.no_offscreen(c)
    end
end)

-- Titlebar dinámica (solo se activa si titlebars_enabled = true en alguna regla)
client.connect_signal("request::titlebars", function(c)
    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )
    awful.titlebar(c):setup {
        { awful.titlebar.widget.iconwidget(c), buttons = buttons, layout = wibox.layout.fixed.horizontal },
        { { align = "center", widget = awful.titlebar.widget.titlewidget(c) }, buttons = buttons, layout = wibox.layout.flex.horizontal },
        { awful.titlebar.widget.floatingbutton(c), awful.titlebar.widget.maximizedbutton(c),
          awful.titlebar.widget.stickybutton(c), awful.titlebar.widget.ontopbutton(c),
          awful.titlebar.widget.closebutton(c), layout = wibox.layout.fixed.horizontal() },
        layout = wibox.layout.align.horizontal,
    }
end)

-- Focus follows mouse
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

-- Color de borde según foco
client.connect_signal("focus",   function(c) c.border_color = beautiful.border_focus  end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- =============================================================================
-- AUTOSTART
-- [FIX-1] Se ejecutan una sola vez. nitrogen --restore mantiene el wallpaper
-- personalizado; si prefieres el wallpaper de vertex, comenta esa línea y
-- vertex usará themes/vertex/wall.png automáticamente.
-- =============================================================================
local function once(cmd)
    local findme = cmd:match("^%S+")
    awful.spawn.with_shell(
        string.format("pgrep -u $USER -x '%s' > /dev/null || %s", findme, cmd)
    )
end

awful.spawn("setxkbmap -layout latam")
once("nitrogen --restore")
once("nm-applet")
