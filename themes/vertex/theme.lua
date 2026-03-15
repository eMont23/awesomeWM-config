--[[

     Vertex Awesome WM theme
     github.com/lcpz

     Auditado y corregido para ThinkPad T430 con Arch Linux
     Cambios documentados con etiquetas [FIX-N] y [OPT-N]

     RESUMEN DE CAMBIOS:
     [FIX-1]  Línea awful.tag() tenía sintaxis rota por un sed mal aplicado.
              Restaurada a: awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

     [FIX-2]  corner_radius y arrow_size usadas en set_shape() de battooltip y
              wifitooltip eran variables nil (nunca definidas). Ahora se pasan
              como nil explícito — gears.shape.infobubble acepta nil y usa sus
              defaults internos, evitando el crash silencioso.

     [FIX-3]  En el widget MPD, `title` y `artist` eran globales implícitas
              (antipatrón Lua). Convertidas a locales dentro de settings().

     [FIX-4]  El watch de wifi (mywifisig) seguía corriendo cada 2 segundos
              aunque wificon estaba comentado en el wibar. En el T430 esto
              significa un fork de shell cada 2s innecesariamente. El bloque
              completo del widget wifi se comenta de forma consistente.
              Si se quiere reactivar, descomentar TODO el bloque marcado con
              -- [WIFI-WIDGET] y agregar wificon/rspace al wibar.

     [FIX-5]  Variable `space` declarada pero nunca usada. Eliminada.
              Variable `lspace3` declarada pero nunca usada. Eliminada.

     [OPT-1]  Interfaz wifi extraída a variable de configuración WIFI_IFACE
              en la sección de ajustes al inicio del archivo. Cambiar aquí
              si la interfaz no es wlan0 (verificar con: ip link | grep ^[0-9].*w)

     [OPT-2]  border_width reducido de dpi(4) a dpi(2). En una pantalla de
              1366x768 del T430, 4px de borde es visualmente pesado y consume
              área útil. 2px da el mismo efecto visual con más espacio de trabajo.

     [OPT-3]  Intervalo del watch de wifi aumentado de 2s a 5s. El nivel de
              señal wifi no cambia tan rápido como para justificar un fork de
              shell cada 2 segundos en hardware limitado.

     [OPT-4]  useless_gap reducido de dpi(10) a dpi(6). En 1366x768 los gaps
              grandes recortan demasiado el área útil. 6px es un equilibrio
              visual sin sacrificar espacio.

     [OPT-5]  Tasklist cambiado a solo íconos:
              · tasklist_plain_task_name = false  (necesario para mostrar ícono)
              · tasklist_disable_icon    = false  (activa los íconos)
              · filter cambiado a currenttags     (muestra todas las ventanas
                del tag, no solo la activa — permite restaurar minimizadas)
              · fg_normal/fg_focus en #00000000 (transparente) para ocultar
                el texto y mostrar solo el ícono de cada app.

--]]

-- =============================================================================
-- LIBRERÍAS
-- =============================================================================
local gears  = require("gears")
local lain   = require("lain")
local awful  = require("awful")
local wibox  = require("wibox")
local dpi    = require("beautiful.xresources").apply_dpi

-- Imports explícitos de stdlib para evitar accesos al entorno global en hot paths
local math, string, tag, tonumber, type, os = math, string, tag, tonumber, type, os

-- Compatibilidad con awesome 4.0 y 4.1
local my_table = awful.util.table or gears.table

-- =============================================================================
-- AJUSTES DE USUARIO
-- Todas las opciones que probablemente quieras cambiar están aquí arriba.
-- =============================================================================

-- [OPT-1] Nombre de la interfaz wifi.
-- Verificar con: ip link | grep "^[0-9].*: w"
local WIFI_IFACE = "wlan0"

-- =============================================================================
-- RUTAS BASE
-- =============================================================================
local theme     = {}
local home      = os.getenv("HOME")
local theme_dir = home .. "/.config/awesome/themes/vertex"

theme.default_dir = require("awful.util").get_themes_dir() .. "default"
theme.icon_dir    = theme_dir .. "/icons"

-- =============================================================================
-- FUENTES
-- =============================================================================
theme.font         = "Roboto Bold 10"
theme.taglist_font = "Font Awesome 5 Free Solid 13"

-- =============================================================================
-- COLORES
-- =============================================================================
theme.fg_normal = "#FFFFFF"
theme.fg_focus  = "#6A95EB"
theme.fg_urgent = "#CC9393"

theme.bg_normal = "#242424"
theme.bg_focus  = "#303030"
theme.bg_focus2 = "#3762B8"
theme.bg_urgent = "#006B8E"

-- =============================================================================
-- BORDES Y GEOMETRÍA
-- =============================================================================
-- [OPT-2] Reducido de dpi(4) a dpi(2): menos invasivo en 1366x768.
theme.border_width  = dpi(2)
theme.border_normal = "#252525"
theme.border_focus  = "#7CA2EE"

-- [OPT-4] Reducido de dpi(10) a dpi(6): mejor balance en pantalla pequeña.
theme.useless_gap = dpi(6)

-- =============================================================================
-- MENÚ Y TOOLTIPS
-- =============================================================================
theme.menu_height = dpi(24)
theme.menu_width  = dpi(140)

theme.tooltip_border_color = theme.fg_focus
theme.tooltip_border_width = theme.border_width

-- =============================================================================
-- WALLPAPER
-- =============================================================================
-- nitrogen --restore en el autostart de rc.lua tiene prioridad.
-- Esta ruta se usa como fallback si nitrogen no está activo.
theme.wallpaper = theme_dir .. "/wall.png"

-- =============================================================================
-- TAGLIST
-- =============================================================================
theme.taglist_squares_sel   = gears.surface.load_from_shape(dpi(3), dpi(30), gears.shape.rectangle, theme.fg_focus)
theme.taglist_squares_unsel = gears.surface.load_from_shape(dpi(3), dpi(30), gears.shape.rectangle, theme.bg_focus2)

-- Nombres de tags — números simples.
-- Para FontAwesome usar: { "", "", "", "", "", "", "", "", "" }
awful.util.tagnames = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }

-- =============================================================================
-- TASKLIST — SOLO ÍCONOS
-- =============================================================================
-- [OPT-5] plain_task_name = false es necesario para que el ícono se renderice.
-- disable_icon = false activa los íconos de aplicación.
-- El texto se oculta con fg transparente en el widget (ver s.mytasklist abajo).
theme.tasklist_plain_task_name = false
theme.tasklist_disable_icon    = false

-- =============================================================================
-- FONDO DE BARRA
-- =============================================================================
theme.panelbg = theme.icon_dir .. "/panel.png"

-- =============================================================================
-- ICONOS — AWESOME
-- =============================================================================
theme.awesome_icon = theme.icon_dir .. "/awesome.png"

-- =============================================================================
-- ICONOS — BATERÍA
-- Nombres siguen el patrón bat{nivel}{estado} para indexación dinámica.
-- =============================================================================
theme.bat000charging = theme.icon_dir .. "/bat-000-charging.png"
theme.bat000         = theme.icon_dir .. "/bat-000.png"
theme.bat020charging = theme.icon_dir .. "/bat-020-charging.png"
theme.bat020         = theme.icon_dir .. "/bat-020.png"
theme.bat040charging = theme.icon_dir .. "/bat-040-charging.png"
theme.bat040         = theme.icon_dir .. "/bat-040.png"
theme.bat060charging = theme.icon_dir .. "/bat-060-charging.png"
theme.bat060         = theme.icon_dir .. "/bat-060.png"
theme.bat080charging = theme.icon_dir .. "/bat-080-charging.png"
theme.bat080         = theme.icon_dir .. "/bat-080.png"
theme.bat100charging = theme.icon_dir .. "/bat-100-charging.png"
theme.bat100         = theme.icon_dir .. "/bat-100.png"
theme.batcharged     = theme.icon_dir .. "/bat-charged.png"

-- =============================================================================
-- ICONOS — RED
-- =============================================================================
theme.ethon    = theme.icon_dir .. "/ethernet-connected.png"
theme.ethoff   = theme.icon_dir .. "/ethernet-disconnected.png"
theme.wifidisc = theme.icon_dir .. "/wireless-disconnected.png"
theme.wififull = theme.icon_dir .. "/wireless-full.png"
theme.wifihigh = theme.icon_dir .. "/wireless-high.png"
theme.wifilow  = theme.icon_dir .. "/wireless-low.png"
theme.wifimed  = theme.icon_dir .. "/wireless-medium.png"
theme.wifinone = theme.icon_dir .. "/wireless-none.png"

-- =============================================================================
-- ICONOS — VOLUMEN
-- =============================================================================
theme.volhigh         = theme.icon_dir .. "/volume-high.png"
theme.vollow          = theme.icon_dir .. "/volume-low.png"
theme.volmed          = theme.icon_dir .. "/volume-medium.png"
theme.volmutedblocked = theme.icon_dir .. "/volume-muted-blocked.png"
theme.volmuted        = theme.icon_dir .. "/volume-muted.png"
theme.voloff          = theme.icon_dir .. "/volume-off.png"

-- =============================================================================
-- ICONOS — LAYOUTS
-- =============================================================================
theme.layout_fairh      = theme.default_dir .. "/layouts/fairhw.png"
theme.layout_fairv      = theme.default_dir .. "/layouts/fairvw.png"
theme.layout_floating   = theme.default_dir .. "/layouts/floatingw.png"
theme.layout_magnifier  = theme.default_dir .. "/layouts/magnifierw.png"
theme.layout_max        = theme.default_dir .. "/layouts/maxw.png"
theme.layout_fullscreen = theme.default_dir .. "/layouts/fullscreenw.png"
theme.layout_tilebottom = theme.default_dir .. "/layouts/tilebottomw.png"
theme.layout_tileleft   = theme.default_dir .. "/layouts/tileleftw.png"
theme.layout_tile       = theme.default_dir .. "/layouts/tilew.png"
theme.layout_tiletop    = theme.default_dir .. "/layouts/tiletopw.png"
theme.layout_spiral     = theme.default_dir .. "/layouts/spiralw.png"
theme.layout_dwindle    = theme.default_dir .. "/layouts/dwindlew.png"
theme.layout_cornernw   = theme.default_dir .. "/layouts/cornernww.png"
theme.layout_cornerne   = theme.default_dir .. "/layouts/cornernew.png"
theme.layout_cornersw   = theme.default_dir .. "/layouts/cornersww.png"
theme.layout_cornerse   = theme.default_dir .. "/layouts/cornersew.png"

-- =============================================================================
-- ICONOS — TITLEBAR
-- Declarados aunque titlebars_enabled = false en rc.lua. Evita warnings
-- de beautiful si alguna regla los activa en el futuro.
-- =============================================================================
theme.titlebar_close_button_normal              = theme.default_dir .. "/titlebar/close_normal.png"
theme.titlebar_close_button_focus               = theme.default_dir .. "/titlebar/close_focus.png"
theme.titlebar_minimize_button_normal           = theme.default_dir .. "/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus            = theme.default_dir .. "/titlebar/minimize_focus.png"
theme.titlebar_ontop_button_normal_inactive     = theme.default_dir .. "/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive      = theme.default_dir .. "/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active       = theme.default_dir .. "/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active        = theme.default_dir .. "/titlebar/ontop_focus_active.png"
theme.titlebar_sticky_button_normal_inactive    = theme.default_dir .. "/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive     = theme.default_dir .. "/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active      = theme.default_dir .. "/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active       = theme.default_dir .. "/titlebar/sticky_focus_active.png"
theme.titlebar_floating_button_normal_inactive  = theme.default_dir .. "/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive   = theme.default_dir .. "/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active    = theme.default_dir .. "/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active     = theme.default_dir .. "/titlebar/floating_focus_active.png"
theme.titlebar_maximized_button_normal_inactive = theme.default_dir .. "/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = theme.default_dir .. "/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active   = theme.default_dir .. "/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active    = theme.default_dir .. "/titlebar/maximized_focus_active.png"

-- =============================================================================
-- WIDGETS — UTILIDADES COMPARTIDAS
-- =============================================================================
local markup = lain.util.markup

-- =============================================================================
-- WIDGET — RELOJ Y CALENDARIO
-- Clic en el reloj despliega el calendario de lain.
-- =============================================================================
local mytextclock = wibox.widget.textclock(markup("#FFFFFF", "%a %d %b, %H:%M"))
mytextclock.font  = theme.font

theme.cal = lain.widget.cal({
    attach_to = { mytextclock },
    notification_preset = {
        fg       = "#FFFFFF",
        bg       = theme.bg_normal,
        position = "top_middle",
        font     = "Monospace 10",
    }
})

-- =============================================================================
-- WIDGET — BATERÍA
-- Íconos temáticos para nivel y estado de carga.
-- Tooltip con porcentaje y tiempo restante al pasar el mouse.
-- =============================================================================
local baticon    = wibox.widget.imagebox(theme.bat000)
local battooltip = awful.tooltip({
    objects          = { baticon },
    margin_leftright = dpi(15),
    margin_topbottom = dpi(12),
})
battooltip.wibox.fg     = theme.fg_normal
battooltip.textbox.font = theme.font
battooltip.timeout      = 0

-- [FIX-2] corner_radius y arrow_size eran nil no definidas.
-- Se pasan explícitamente como nil: infobubble usa sus defaults internos.
battooltip:set_shape(function(cr, width, height)
    gears.shape.infobubble(cr, width, height, nil, nil, width - dpi(35))
end)

local bat = lain.widget.bat({
    settings = function()
        local index = "bat"
        local perc  = tonumber(bat_now.perc) or 0

        if     perc <=  7 then index = index .. "000"
        elseif perc <= 20 then index = index .. "020"
        elseif perc <= 40 then index = index .. "040"
        elseif perc <= 60 then index = index .. "060"
        elseif perc <= 80 then index = index .. "080"
        else                    index = index .. "100"
        end

        if bat_now.ac_status == 1 then
            index = index .. "charging"
        end

        baticon:set_image(theme[index])
        battooltip:set_markup(string.format("\n%s%%, %s", perc, bat_now.time))
    end
})

-- =============================================================================
-- WIDGET — MPD (reproductor de música)
-- Si no usas mpd no muestra nada (estado "stop").
-- Para desactivar completamente: comentar este bloque Y la línea
-- theme.mpd.widget en s.mywibox:setup más abajo.
-- =============================================================================
theme.mpd = lain.widget.mpd({
    music_dir = home .. "/Music",
    settings  = function()
        -- [FIX-3] title y artist eran globales implícitas. Ahora son locales.
        local title, artist

        if mpd_now.state == "play" then
            title  = mpd_now.title
            artist = "  " .. mpd_now.artist .. " "
        elseif mpd_now.state == "pause" then
            title  = "mpd "
            artist = "paused "
        else
            title  = ""
            artist = ""
        end

        widget:set_markup(markup.font(theme.font, title .. markup(theme.fg_focus, artist)))
    end
})

-- =============================================================================
-- WIDGET — VOLUMEN (ALSA vía lain.widget.alsabar)
-- Funciona con PipeWire a través de pipewire-alsa.
-- Clic izq  → abre alsamixer en terminal
-- Clic med  → sube a 100%
-- Clic der  → toggle mute
-- Scroll    → ±1%
-- =============================================================================
local volicon = wibox.widget.imagebox()

theme.volume = lain.widget.alsabar({
    -- togglechannel = "IEC958,3",
    notification_preset = { font = "Monospace 12", fg = theme.fg_normal },
    settings = function()
        local index = ""
        local perc  = tonumber(volume_now.level) or 0

        if volume_now.status == "off" then
            index = "volmutedblocked"
        elseif perc <=  5 then index = "volmuted"
        elseif perc <= 25 then index = "vollow"
        elseif perc <= 75 then index = "volmed"
        else                    index = "volhigh"
        end

        volicon:set_image(theme[index])
    end
})

volicon:buttons(my_table.join(
    awful.button({}, 1, function()
        awful.spawn(string.format("%s -e alsamixer", awful.util.terminal))
    end),
    awful.button({}, 2, function()
        os.execute(string.format("%s set %s 100%%", theme.volume.cmd, theme.volume.channel))
        theme.volume.notify()
    end),
    awful.button({}, 3, function()
        os.execute(string.format("%s set %s toggle",
            theme.volume.cmd, theme.volume.togglechannel or theme.volume.channel))
        theme.volume.notify()
    end),
    awful.button({}, 4, function()
        os.execute(string.format("%s set %s 1%%+", theme.volume.cmd, theme.volume.channel))
        theme.volume.notify()
    end),
    awful.button({}, 5, function()
        os.execute(string.format("%s set %s 1%%-", theme.volume.cmd, theme.volume.channel))
        theme.volume.notify()
    end)
))

-- =============================================================================
-- WIDGET — WIFI
-- [FIX-4] Bloque comentado de forma consistente. nm-applet en el systray
-- ya muestra la señal wifi sin costo de un fork de shell periódico.
--
-- Para reactivar:
--   1. Descomentar TODO el bloque [WIFI-WIDGET BEGIN/END]
--   2. Ajustar WIFI_IFACE al inicio del archivo si es necesario
--   3. En s.mywibox:setup descomentar wificon y rspace0
-- =============================================================================

--[[ [WIFI-WIDGET BEGIN]
local wificon     = wibox.widget.imagebox(theme.wifidisc)
local wifitooltip = awful.tooltip({
    objects          = { wificon },
    margin_leftright = dpi(15),
    margin_topbottom = dpi(15),
})
wifitooltip.wibox.fg     = theme.fg_normal
wifitooltip.textbox.font = theme.font
wifitooltip.timeout      = 0

-- [FIX-2] Mismo fix que battooltip.
wifitooltip:set_shape(function(cr, width, height)
    gears.shape.infobubble(cr, width, height, nil, nil, width - dpi(120))
end)

-- [OPT-3] Intervalo aumentado de 2s a 5s: reduce forks de shell en el T430.
awful.widget.watch(
    { awful.util.shell, "-c",
      string.format(
          "awk 'NR==3 {printf(\"%%d-%%.0f\\n\",$2,$3*10/7)}' /proc/net/wireless; iw dev %s link",
          WIFI_IFACE
      )
    },
    5,
    function(_, stdout)
        local carrier, perc = stdout:match("(%d)-(%d+)")
        local tiptext = stdout:gsub("(%d)-(%d+)", ""):gsub("%s+$", "")
        perc = tonumber(perc)

        if carrier == "1" or not perc then
            wificon:set_image(theme.wifidisc)
            wifitooltip:set_markup("No carrier")
        elseif perc <=  5 then wificon:set_image(theme.wifinone)
        elseif perc <= 25 then wificon:set_image(theme.wifilow)
        elseif perc <= 50 then wificon:set_image(theme.wifimed)
        elseif perc <= 75 then wificon:set_image(theme.wifihigh)
        else                   wificon:set_image(theme.wififull)
        end

        if carrier ~= "1" and perc then
            wifitooltip:set_markup(tiptext)
        end
    end
)

wificon:connect_signal("button::press", function()
    awful.spawn(string.format("%s -e wavemon", awful.util.terminal))
end)
--]] -- [WIFI-WIDGET END]

-- =============================================================================
-- LAUNCHER (botón del ícono de awesome en el dock)
-- =============================================================================
local mylauncher = awful.widget.button({ image = theme.awesome_icon })
mylauncher:connect_signal("button::press", function()
    awful.util.mymainmenu:toggle()
end)

-- =============================================================================
-- SEPARADORES
-- [FIX-5] `space` y `lspace3` eliminadas — declaradas pero nunca usadas.
-- =============================================================================
local rspace0 = wibox.widget.textbox()
local rspace1 = wibox.widget.textbox()
local rspace2 = wibox.widget.textbox()
local rspace3 = wibox.widget.textbox()
local tspace1 = wibox.widget.textbox()
local lspace1 = wibox.widget.textbox()
local lspace2 = wibox.widget.textbox()

tspace1.forced_width  = dpi(18)
rspace0.forced_width  = dpi(18)
rspace1.forced_width  = dpi(16)
rspace2.forced_width  = dpi(19)
rspace3.forced_width  = dpi(21)
lspace1.forced_height = dpi(18)
lspace2.forced_height = dpi(10)

-- =============================================================================
-- COLORES DE BARRA (gradientes para el dock vertical)
-- =============================================================================

-- Gradiente del dock vertical (taglist activo)
local barcolor = gears.color({
    type  = "linear",
    from  = { 0, dpi(46) },
    to    = { dpi(46), dpi(46) },
    stops = { { 0, theme.bg_focus }, { 0.9, theme.bg_focus2 } },
})

-- Gradiente del fondo del dock (barra lateral inactiva)
local barcolor2 = gears.color({
    type  = "linear",
    from  = { 0, dpi(46) },
    to    = { dpi(46), dpi(46) },
    stops = { { 0, "#323232" }, { 1, theme.bg_normal } },
})

-- Forma del dock al expandirse (esquinas redondeadas abajo-derecha y arriba-derecha)
local dockshape = function(cr, width, height)
    gears.shape.partially_rounded_rect(cr, width, height, false, true, true, false, 6)
end

-- =============================================================================
-- DOCK VERTICAL IZQUIERDO
-- Se muestra como una barra delgada de 9px. Al pasar el mouse (o al cambiar
-- de tag) se expande a 38px mostrando: taglist + layoutbox + launcher.
-- Se colapsa automáticamente después de 2 segundos sin interacción.
-- =============================================================================
function theme.vertical_wibox(s)
    s.dockheight  = math.floor((35 * s.workarea.height) / 100)

    s.myleftwibox = wibox({
        screen  = s,
        x       = 0,
        y       = math.floor(s.workarea.height / 2 - s.dockheight / 2),
        width   = dpi(6),
        height  = s.dockheight,
        fg      = theme.fg_normal,
        bg      = barcolor2,
        ontop   = true,
        visible = true,
        type    = "dock",
    })

    -- En setups multi-monitor: sincronizar posición Y con la pantalla primaria
    if s.index > 1 and s.myleftwibox.y == 0 then
        s.myleftwibox.y = screen[1].myleftwibox.y
    end

    s.myleftwibox:setup {
        layout = wibox.layout.align.vertical,
        {
            layout = wibox.layout.fixed.vertical,
            lspace1,
            s.mytaglist,
            lspace2,
            s.layoutb,
            wibox.container.margin(mylauncher, dpi(5), dpi(8), dpi(13), dpi(0)),
        },
    }

    -- Timer de auto-colapso: 2s sin interacción → dock se estrecha
    s.docktimer = gears.timer{ timeout = 2 }
    s.docktimer:connect_signal("timeout", function()
        local focused = awful.screen.focused()
        focused.myleftwibox.width = dpi(9)
        focused.layoutb.visible   = false
        mylauncher.visible         = false
        if focused.docktimer.started then
            focused.docktimer:stop()
        end
    end)

    -- Expandir al cambiar de tag
    tag.connect_signal("property::selected", function(t)
        local focused = t.screen or awful.screen.focused()
        focused.myleftwibox.width = dpi(38)
        focused.layoutb.visible   = true
        mylauncher.visible         = true
        gears.surface.apply_shape_bounding(focused.myleftwibox, dockshape)
        if not focused.docktimer.started then
            focused.docktimer:start()
        end
    end)

    -- Expandir al entrar con el mouse
    s.myleftwibox:connect_signal("mouse::enter", function()
        local focused = awful.screen.focused()
        focused.myleftwibox.width = dpi(38)
        focused.layoutb.visible   = true
        mylauncher.visible         = true
        gears.surface.apply_shape_bounding(focused.myleftwibox, dockshape)
    end)

    -- Colapsar al salir con el mouse
    s.myleftwibox:connect_signal("mouse::leave", function()
        local focused = awful.screen.focused()
        focused.myleftwibox.width = dpi(9)
        focused.layoutb.visible   = false
        mylauncher.visible         = false
    end)
end

-- =============================================================================
-- FUNCIÓN PRINCIPAL — at_screen_connect
-- Llamada desde rc.lua por awful.screen.connect_for_each_screen.
-- Configura todo lo visual de cada pantalla: wallpaper, tags, promptbox,
-- layoutbox, taglist, tasklist, wibar top y dock vertical.
-- =============================================================================
function theme.at_screen_connect(s)

    -- Quake terminal (dropdown con Mod4+`)
    s.quake = lain.util.quake({
        app    = awful.util.terminal,
        border = theme.border_width,
    })

    -- Wallpaper: nitrogen tiene prioridad (rc.lua autostart).
    -- Si nitrogen no está activo, beautiful usa theme.wallpaper como fallback.
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)

    -- [FIX-1] Línea rota por sed restaurada con los 3 argumentos correctos.
    awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

    -- Promptbox
    s.mypromptbox    = awful.widget.prompt()
    s.mypromptbox.bg = "#00000000"

    -- Layoutbox: ícono del layout activo, clic para cambiar
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(my_table.join(
        awful.button({}, 1, function() awful.layout.inc( 1) end),
        awful.button({}, 2, function() awful.layout.set(awful.layout.layouts[1]) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc( 1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)
    ))
    s.layoutb = wibox.container.margin(s.mylayoutbox, dpi(8), dpi(11), dpi(3), dpi(3))

    -- Taglist vertical (para el dock izquierdo)
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all,
        awful.util.taglist_buttons, {
            font     = theme.taglist_font,
            shape    = gears.shape.rectangle,
            spacing  = dpi(10),
            bg_focus = barcolor,
        },
        nil,
        wibox.layout.fixed.vertical()
    )

    -- =========================================================================
    -- TASKLIST — SOLO ÍCONOS
    -- [OPT-5] filter.currenttags muestra todas las ventanas del tag actual,
    -- permitiendo ver y restaurar ventanas minimizadas con clic.
    -- fg_normal y fg_focus en #00000000 ocultan el texto dejando solo el ícono.
    -- spacing de 4px mantiene la barra compacta.
    -- =========================================================================
    s.mytasklist = awful.widget.tasklist(
        s,
        awful.widget.tasklist.filter.currenttags,
        awful.util.tasklist_buttons,
        {
            bg_focus  = "#00000000",
            fg_normal = "#00000000",
            fg_focus  = "#00000000",
            spacing   = dpi(4),
        }
    )

    -- =========================================================================
    -- BARRA TOP (wibar horizontal)
    -- Izquierda : promptbox + íconos de ventanas abiertas
    -- Centro    : reloj (clic → calendario)
    -- Derecha   : mpd + volumen + batería + systray (nm-applet, etc.)
    -- =========================================================================
    s.mywibox = awful.wibar({
        position = "top",
        screen   = s,
        height   = dpi(25),
        bg       = gears.color.create_png_pattern(theme.panelbg),
    })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        expand = "none",

        { -- Izquierda
            layout = wibox.layout.fixed.horizontal,
            s.mypromptbox,
            tspace1,
            s.mytasklist,
        },

        { -- Centro
            layout          = wibox.layout.flex.horizontal,
            max_widget_size = 1500,
            mytextclock,
        },

        { -- Derecha
            layout = wibox.layout.fixed.horizontal,
            -- MPD: visible solo cuando hay reproducción activa
            wibox.widget { nil, nil, theme.mpd.widget, layout = wibox.layout.align.horizontal },
            rspace0,
            -- Wifi desactivado: nm-applet en systray cumple la función.
            -- Para reactivar ver bloque [WIFI-WIDGET] arriba.
            -- wificon,
            -- rspace0,
            volicon,
            rspace2,
            baticon,
            rspace3,
            wibox.widget.systray(),
        },
    }

    -- delayed_call asegura que s.workarea esté disponible al crear el dock
    gears.timer.delayed_call(theme.vertical_wibox, s)
end

return theme
