love.filesystem.setRequirePath('?.lua;?/init.lua;?/main.lua;modules/?/?.lua;modules/?.lua')

if DEBUG then
    io.stdout:setvbuf('no')
end
local enums = require "enums"
local bump = require "bump"
local Rectangle = require "rectangle"
local AI = require "ai"
local Score = require "scoring"
local inspect = require "inspect"
local AsepriteMetaParser = require "AsepriteMetaParser"

local Timer = require "hump.timer"
local Camera = require "hump.camera"
local Signal = require "hump.signal"
local Gamestate = require "hump.gamestate"

local PunkChar = require "char.PunkChar"
local PlayerChar = require "char.PlayerChar"

local Mainstate = require "gamestates.Mainstate"
local TiledLevel = require "TiledLevel"

--local test = require "test"
--love.event.quit()

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

love.graphics.setDefaultFilter('nearest')

love.window.setMode( SCREEN_VALUES.width, SCREEN_VALUES.height, {
    resizable = true,
    vsync = true,
    minwidth = SCREEN_VALUES.width,
    minheight = SCREEN_VALUES.height,
    fullscreen = false
})

love.window.setTitle( "Wrong Neighborhood" )

HAS_JOYSTICKS = #love.joystick.getJoysticks() > 0

GAMESTATES = {
    main = Mainstate
}

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

function love.draw()
    --D:draw()
end

--[[
function draw_debuxes()
    local colItems, len = WORLD:getItems()
    for i = 1, len do
        local x,y,w,h = WORLD:getRect(colItems[i])
        love.graphics.rectangle("line", x, y, w, h)
    end

    for index, player in ipairs(ENTITIES.players) do
        --- bounding box for kicking and punching
        if player.punch_box.isActive then
            love.graphics.rectangle("fill", player.punch_box.x, player.punch_box.y, player.punch_box.width, player.punch_box.height)
        else
            love.graphics.rectangle("line", player.punch_box.x, player.punch_box.y, player.punch_box.width, player.punch_box.height)
        end
        if player.kick_box.isActive then
            love.graphics.rectangle("fill", player.kick_box.x, player.kick_box.y, player.kick_box.width, player.kick_box.height)
        else
            love.graphics.rectangle("line", player.kick_box.x, player.kick_box.y, player.kick_box.width, player.kick_box.height)
        end
    end

    for index, enemy in ipairs(ENTITIES.enemies) do
        --- bounding box for kicking and punching
        if enemy.punch_box.isActive then
            love.graphics.rectangle("fill", enemy.punch_box.x, enemy.punch_box.y, enemy.punch_box.width, enemy.punch_box.height)
        else
            love.graphics.rectangle("line", enemy.punch_box.x, enemy.punch_box.y, enemy.punch_box.width, enemy.punch_box.height)
        end
        if enemy.kick_box.isActive then
            love.graphics.rectangle("fill", enemy.kick_box.x, enemy.kick_box.y, enemy.kick_box.width, enemy.kick_box.height)
        else
            love.graphics.rectangle("line", enemy.kick_box.x, enemy.kick_box.y, enemy.kick_box.width, enemy.kick_box.height)
            --enemy.kick_box:draw()
        end
    end
end

function DEBUG_info()

    love.graphics.printf("FPS: " .. love.timer.getFPS(), 20, 1 * DEBUG_FONT_SIZE, 1000, "left" )
    love.graphics.printf("Player1.x: " .. ENTITIES.players[1].x, 20, 2 * DEBUG_FONT_SIZE, 1000, "left" )
    love.graphics.printf("Player1.y: " .. ENTITIES.players[1].y, 20, 3 * DEBUG_FONT_SIZE, 1000, "left" )
    love.graphics.printf("enemy1.x: " .. ENTITIES.enemies[1].x, 20, 4 * DEBUG_FONT_SIZE, 1000, "left" )
    love.graphics.printf("enemy1.y: " .. ENTITIES.enemies[1].y, 20, 5 * DEBUG_FONT_SIZE, 1000, "left" )
    love.graphics.printf("enemy1 within trigger field? " .. tostring(ENTITIES.enemies[1].x <= ENTITIES.players[1].x + DETECTION_ZONE_WIDTH),
        20, 6 * DEBUG_FONT_SIZE, 1000, "left")
    love.graphics.printf("enemy1 triggered? " .. tostring(ENTITIES.enemies[1].triggered), 20, 7 * DEBUG_FONT_SIZE, 1000, "left")
    love.graphics.printf("Facing left? " .. tostring(ENTITIES.players[1]:isFacingLeft()), 20, 8 * DEBUG_FONT_SIZE, 1000, "left")
    love.graphics.printf("player health " .. (ENTITIES.players[1].health), 20, 9 * DEBUG_FONT_SIZE, 1000, "left")
    love.graphics.printf("enemy health " .. (ENTITIES.enemies[1].health), 20, 10 * DEBUG_FONT_SIZE, 1000, "left")
end
--]]