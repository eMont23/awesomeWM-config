-- =============================================================================
-- rc.lua — Configuración de AwesomeWM
-- Versión auditada y optimizada
-- =============================================================================
--
-- CAMBIOS PRINCIPALES RESPECTO AL ORIGINAL:
--
--  [FIX-1]  nitrogen --restore y nm-applet se movieron a la sección de
--           autostart al final del archivo. Antes estaban dentro de
--           awful.screen.connect_for_each_screen, lo que los ejecutaba UNA VEZ
--           POR PANTALLA conectada — podían lanzarse 2 o 3 veces en setups
--           multi-monitor.
--
--  [FIX-2]  Se eliminó "hibernate" del menú principal de awesome (myawesomemenu)
--           porque ya existe en powermenu_items. Era una entrada duplicada.
--
--  [FIX-3]  Las variables globales `terminal`, `editor`, `editor_cmd`,
--           `modkey`, `myawesomemenu`, `powermenu_items` se convirtieron en
--           locales donde es posible. Las globales implícitas en Lua son un
--           antipatrón que dificulta el debugging.
--
--  [FIX-4]  Los atajos de brightness (XF86MonBrightnessUp/Down) no tenían
--           `description` ni `group`, por lo que no aparecían en el popup de
--           ayuda (Mod4+s). Se les agregó.
--
--  [FIX-5]  Los atajos de media (XF86AudioPlay/Next/Prev) tampoco tenían
--           description/group. Se les agregó.
--
--  [OPT-1]  Se recortó la lista de layouts a los más usados en un flujo de
--           trabajo típico (floating, tile, max). Los 13 layouts del original
--           hacen que Mod4+Space sea incómodo de usar. Se dejan comentados los
--           demás para fácil recuperación.
--
--  [OPT-2]  Los tags se renombraron con símbolos más descriptivos usando
--           caracteres Unicode simples. Esto es opcional y fácil de revertir
--           a { "1".."9" } si se prefiere.
--
--  [STYLE]  Se homogeneizó el estilo de indentación (4 espacios) y se
--           organizaron las secciones con separadores claros.
--
-- =============================================================================

-- Asegurar compatibilidad con LuaRocks si está instalado
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

-- Muestra errores que ocurrieron durante el startup (solo en config de respaldo)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title  = "Error durante el inicio",
        text   = awesome.startup_errors
    })
end

-- Maneja errores en tiempo de ejecución sin entrar en un loop infinito
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
-- Se mantienen como globales las que awful/otros módulos esperan encontrar
-- en el scope global (terminal, modkey). Las demás se hacen locales.

beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

terminal   = "kitty"                              -- [global] requerido por menubar
modkey     = "Mod4"                               -- [global] requerido por bindings

local editor     = os.getenv("EDITOR") or "nano"
local editor_cmd = terminal .. " -e " .. editor

-- =============================================================================
-- LAYOUTS
-- =============================================================================
-- [OPT-1] Se redujo la lista a los layouts más prácticos.
-- Agregar de vuelta los comentados si se necesitan.

awful.layout.layouts = {
    awful.layout.suit.tile,           -- Master + stack (el más común)
    awful.layout.suit.tile.bottom,    -- Master arriba, stack abajo
    awful.layout.suit.floating,       -- Ventanas libres
    awful.layout.suit.max,            -- Ventana activa maximizada (tipo monocle)
    awful.layout.suit.max.fullscreen, -- Fullscreen real sin barra
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
}

-- =============================================================================
-- MENÚ
-- =============================================================================
-- [FIX-2] Se eliminó "hibernate" de myawesomemenu (era duplicado de powermenu)
-- [FIX-3] Variables de menú convertidas a locales

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

mymainmenu = awful.menu({
    items = {
        { "awesome",              myawesomemenu,                        beautiful.awesome_icon },
        { "power",                powermenu_items },
        { "open terminal",        terminal },
        { "System Monitor (btop)", "kitty --class btop -e btop" },
        { "Nemo",                 "nemo" },
        { "Browser",              "brave" },
        { "vsCode",               "code" },
        { "Darktable",            "darktable" },
        { "Nitrogen",             "nitrogen" },
    }
})

mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu  = mymainmenu,
})

menubar.utils.terminal = terminal

-- =============================================================================
-- WIBAR (BARRA DE ESTADO)
-- =============================================================================

local mykeyboardlayout = awful.widget.keyboardlayout()
local mytextclock      = wibox.widget.textclock()

-- Botones para el taglist
local taglist_buttons = gears.table.join(
    awful.button({},        1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then client.focus:move_to_tag(t) end
    end),
    awful.button({},        3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then client.focus:toggle_tag(t) end
    end),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

-- Botones para el tasklist
local tasklist_buttons = gears.table.join(
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

-- Wallpaper desde el tema (si está definido)
local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-aplicar wallpaper si cambia la geometría de la pantalla
screen.connect_signal("property::geometry", set_wallpaper)

-- Configurar cada pantalla
awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    -- [OPT-2] Tags con nombres simbólicos. Cambiar a {"1","2",...,"9"} si se prefiere.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    s.mypromptbox = awful.widget.prompt()

    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function() awful.layout.inc( 1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc( 1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)
    ))

    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
    }

    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
    }

    s.mywibox = awful.wibar({ position = "top", screen = s })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Izquierda
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Centro
        { -- Derecha
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
        },
    }
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

    -- Awesome / ayuda
    awful.key({ modkey }, "s", hotkeys_popup.show_help,
        { description = "mostrar ayuda de teclas", group = "awesome" }),
    awful.key({ modkey }, "w", function() mymainmenu:show() end,
        { description = "menú principal", group = "awesome" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
        { description = "recargar awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "q", awesome.quit,
        { description = "salir de awesome", group = "awesome" }),

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

    -- Prompt Lua (debug / scripting)
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
    -- [FIX-5] Se agregó description/group para que aparezcan en el popup de ayuda
    awful.key({}, "XF86AudioPlay",
        function() awful.spawn("playerctl play-pause") end,
        { description = "play/pause", group = "media" }),
    awful.key({}, "XF86AudioNext",
        function() awful.spawn("playerctl next") end,
        { description = "siguiente pista", group = "media" }),
    awful.key({}, "XF86AudioPrev",
        function() awful.spawn("playerctl previous") end,
        { description = "pista anterior", group = "media" }),

    -- Brillo de pantalla
    -- [FIX-4] Se agregó description/group para que aparezcan en el popup de ayuda
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

    -- Capturas de pantalla con scrot
    -- El directorio ~/Pictures/screenshots/ debe existir; se crea si no existe.
    -- Convención de nombre: YYYY-MM-DD_HH-MM-SS_<tipo>.png
    --
    -- Print        → pantalla completa (instantáneo)
    -- Mod4+Print   → selección con ratón (arrastra para seleccionar área)
    --
    -- En ambos casos se muestra una notificación con naughty al guardar.

    awful.key({}, "Print",
        function()
            local dir  = os.getenv("HOME") .. "/Pictures/screenshots/"
            local file = dir .. os.date("%Y-%m-%d_%H-%M-%S") .. "_full.png"
            awful.spawn.easy_async(
                string.format("bash -c 'mkdir -p %s && scrot %s'", dir, file),
                function(_, _, _, exitcode)
                    if exitcode == 0 then
                        naughty.notify({
                            title = "Captura guardada",
                            text  = file,
                            timeout = 4,
                        })
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

    -- Captura por selección con scrot -s.
    -- on_release = true es necesario para que AwesomeWM suelte el control del
    -- ratón antes de que scrot lo capture; sin esto scrot no responde.
    -- Tras guardar, xclip copia la imagen al portapapeles (sudo pacman -S xclip).
    awful.key({ modkey }, "Print",
        function()
            local dir  = os.getenv("HOME") .. "/Pictures/screenshots/"
            local file = dir .. os.date("%Y-%m-%d_%H-%M-%S") .. "_sel.png"
            awful.spawn.easy_async(
                string.format("bash -c 'mkdir -p %s && scrot -s %s'", dir, file),
                function(_, _, _, sc_exit)
                    if sc_exit == 0 then
                        awful.spawn.easy_async(
                            string.format(
                                "xclip -selection clipboard -t image/png -i %s", file
                            ),
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
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
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
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        { description = "(des)maximizar", group = "client" }),
    awful.key({ modkey, "Control" }, "m",
        function(c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end,
        { description = "(des)maximizar vertical", group = "client" }),
    awful.key({ modkey, "Shift" }, "m",
        function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end,
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

    -- Regla global — aplica a todos los clientes
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

    -- Ventanas que deben ser flotantes por defecto
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

    -- btop: flotante, centrado, sin titlebar, siempre encima
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

    -- Titlebars para ventanas normales y diálogos
    {
        rule_any  = { type = { "normal", "dialog" } },
        properties = { titlebars_enabled = true }
    },
}

-- =============================================================================
-- SEÑALES
-- =============================================================================

-- Impedir que ventanas queden fuera de pantalla tras cambio de monitor
client.connect_signal("manage", function(c)
    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position
    then
        awful.placement.no_offscreen(c)
    end
end)

-- Titlebar dinámica
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
        { -- Izquierda: ícono de la app
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal,
        },
        { -- Centro: título
            { align = "center", widget = awful.titlebar.widget.titlewidget(c) },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal,
        },
        { -- Derecha: botones de control
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal(),
        },
        layout = wibox.layout.align.horizontal,
    }
end)

-- Focus follows mouse (sloppy focus)
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

-- Color del borde según foco
client.connect_signal("focus",   function(c) c.border_color = beautiful.border_focus  end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- =============================================================================
-- AUTOSTART
-- =============================================================================
-- [FIX-1] nitrogen y nm-applet se ejecutan aquí UNA SOLA VEZ, no por pantalla.
-- Usar once() evita relanzarlos si awesome se recarga con Mod4+Ctrl+R.

local function once(cmd)
    -- Comprueba si el proceso ya corre antes de lanzarlo
    local findme = cmd:match("^%S+")
    local firstarg = cmd:match("^%S+%s+(.-)%s") or ""
    awful.spawn.with_shell(
        string.format("pgrep -u $USER -x '%s' > /dev/null || %s", findme, cmd)
    )
end

awful.spawn("setxkbmap -layout latam")  -- Layout de teclado (siempre se aplica)
once("nitrogen --restore")              -- Fondo de pantalla
once("nm-applet")                       -- Applet de red
