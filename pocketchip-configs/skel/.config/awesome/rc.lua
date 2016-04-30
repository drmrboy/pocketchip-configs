-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- disable startup-notification globally
local oldspawn = awful.util.spawn
awful.util.spawn = function (s)
  oldspawn(s, false)
end

dbg = function (msg)
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "DBG MSG:",
                     text = msg })
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ client API
focus_next_client = function ()
    if awful.client.next(1) == home_screen.client then
        awful.client.focus.byidx( 2 )
    else
        awful.client.focus.byidx( 1 )
    end

    if client.focus then
        client.focus:raise()
    end
end

focus_client_by_window_id = function (window_id)
    for _, c in ipairs(client.get()) do
        if c.window == window_id then
            client.focus = c
            if client.focus then
                client.focus:raise()
            end
        end
    end
end

focus_home_screen = function ()
    client.focus = home_screen.client
    client.focus:raise()
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/home/chip/.config/awesome/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    -- awful.layout.suit.floating,
    -- awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1 }, s, layouts[1])
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ }                  , "XF86PowerOff", focus_home_screen),
    awful.key({ modkey,           }, "Tab", focus_next_client),
    awful.key({ "Control",        }, "Tab", focus_next_client),
    awful.key({ modkey,           }, "Return", function () awful.util.spawn("dmenu_run") end)
)

clientkeys = awful.util.table.join(
    awful.key({ "Control"         }, "q", 
        function (c)
            if c ~= home_screen.client then
                c:kill()
            end
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
    keynumber = math.min(9, math.max(#tags[s], keynumber));
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    -- left click and mode allows you to move windows
    awful.button({ modkey }, 1, awful.mouse.client.move),
    -- right click when holding mod
    awful.button({ "Control" }, 1, function (c) awful.util.spawn("xdotool click 3") end))

-- Set global keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = 0,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
match_home_screen = function (c)
  if c.pid == home_screen.pid then
      return true
  end
  return false
end

match_onboard = function (c)
  if c.class == "feh" then
      return true
  end
  return false
end

client.add_signal("unfocus", function (c)
  if c == onboard.client then
      awful.util.spawn("xdotool search --name feh windowactivate")
  end
end)

client.add_signal("manage", function (c, startup)
    if not startup then
      if match_onboard(c) then
          onboard.client = c
          c.ontop = true
      end

      if match_home_screen(c) then
          home_screen.client = c
      end

      -- Put windows in a smart way, only if they does not set an initial position.
      if not c.size_hints.user_position and not c.size_hints.program_position then
          awful.placement.no_overlap(c)
          awful.placement.no_offscreen(c)
      end
    end
end)
-- }}}

-- {{{ Startup applications
onboard = {}
onboard.pid = awful.util.spawn_with_shell("/usr/bin/onboard $HOME/.config/onboard /usr/share/pocketchip-onboard/")
awful.util.spawn_with_shell("xmodmap /usr/local/share/kbd/keymaps/pocketChip.map")
home_screen = {}
home_screen.pid = awful.util.spawn_with_shell("pocket-home")
-- }}}