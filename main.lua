love.filesystem.setRequirePath('?.lua;?/init.lua;src/?.lua;?/main.lua;modules/?/?.lua;modules/?.lua')

if DEBUG then
    io.stdout:setvbuf('no')
end

local Gamestate = require "hump.gamestate"
local Mainstate = require "gamestates.Mainstate"

IN_FOCUS = false
DEBUG = true
SCREEN_VALUES = {
    width = 1600,
    height = 960
}
GAME_SPEED = 1
DETECTION_ZONE_WIDTH = 200
DEBUG_FONT_SIZE = 16
GAME_OVER = false

WINDOW_CONFIG = {
    resizable = true,
    vsync = true,
    minwidth = SCREEN_VALUES.width,
    minheight = SCREEN_VALUES.height,
    fullscreen = false
}

HAS_JOYSTICKS = #love.joystick.getJoysticks() > 0

GAMESTATES = {
    main = Mainstate
}

love.graphics.setDefaultFilter("nearest")

love.window.setTitle("Wrong Neighborhood")

love.window.setMode( SCREEN_VALUES.width, SCREEN_VALUES.height, WINDOW_CONFIG)

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(GAMESTATES.main)
end

function love.update(dt)
    if love.keyboard.isDown("escape") or
        ( HAS_JOYSTICKS and love.joystick.getJoysticks()[1]:isGamepadDown('guide') ) then
        love.event.quit();
    end
end
