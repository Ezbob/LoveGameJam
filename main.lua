local camera = require "camera"
if DEBUG then
    io.stdout:setvbuf('no')
end
local enums = require "enums"
local bump = require "./modules/bump/bump"
local PlayerChar = require "char.PlayerChar"
local Rectangle = require "rectangle"
local AI = require "ai"
local Timer = require "./modules/hump/timer"
local Score = require "scoring"
local inspect = require "modules.inspect.inspect"
local Camera = require "modules.hump.camera"
local AsepriteAnim8Adaptor = require "char.AsepriteAnim8Adaptor"
local PunkChar = require "char.PunkChar"

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

love.window.setMode( SCREEN_VALUES.width, SCREEN_VALUES.height, {
    resizable = true,
    vsync = true,
    minwidth = SCREEN_VALUES.width,
    minheight = SCREEN_VALUES.height,
    fullscreen = false
})

love.window.setTitle( "Wrong Neighborhood" )

HAS_JOYSTICKS = #love.joystick.getJoysticks() > 0


GAMEOVER_COLORS =  {
    G = 255,
    B = 255
}

SCALE = {
    H = 2,
    V = 2
}

ENTITIES = {
    characters = {},
    players = {},
    enemies = {},
    objects = {},
    road = {
        SIDEWALK = {},
        STREET = {},
        STREET_LINES = {},
        planks = {},
        planks_top = {},
        PLANK_AND_SIDEWALK = {},
        barricades = {},
        GUTTER = {},
        flipped_gutter = {}
    },
    background = {}
}

CAMERA = nil

ASSETS = {
    character = {}
}

FONT = nil

function love.focus(focus)
    IN_FOCUS = focus
end

function love.load()
    -- Load Textures
    FONT = love.graphics.newFont("Assets/PressStart2P.ttf", DEBUG_FONT_SIZE)
    love.graphics.setFont(FONT)
    WORLD = bump.newWorld()
    IMAGES = {}

    ASSETS["character"] = {
        sheet = love.graphics.newImage("Assets/miniplayer.png"),
        grids = AsepriteAnim8Adaptor.getGridsFromJSON("Assets/miniplayer.json")
    }

    local p1 = PlayerChar(
        1,
        100,
        SCREEN_VALUES.height * 0.65,
        "player1"
    )

    local p2 = PlayerChar(
        2,
        100,
        SCREEN_VALUES.height * 0.55,
        "player2"
    )

    local e1 = PunkChar(
        700,
        SCREEN_VALUES.height * 0.7
    )

    local e2 = PunkChar(
        800,
        SCREEN_VALUES.height * 0.62
    )

    CAMERA = Camera(p1.x + (p1.width / 2), p2.y)

    CAMERA:zoom(2)

    table.insert(ENTITIES.players, p1)
    table.insert(ENTITIES.players, p2)
    table.insert(ENTITIES.enemies, e1)
    table.insert(ENTITIES.enemies, e2)

    for _, p in ipairs(ENTITIES.enemies) do
        table.insert(ENTITIES.characters, p)
        p:flipHorizontal()
    end

    for _, p in ipairs(ENTITIES.players) do
        table.insert(ENTITIES.characters, p)
    end

    if HAS_JOYSTICKS then
        ENTITIES.players[1].control_scheme = enums.control_schemes.controller
    end

    Score:setupTimer(0)
    Score:setupScoreCount(0)

    -- Init map
    CARS = love.graphics.newImage("Assets/CARS.png")
    GREEN_CAR = love.graphics.newQuad(0, 0, 128, 128, CARS:getWidth(), CARS:getHeight())
    YELLOW_CAR = love.graphics.newQuad(128, 0, 128, 128, CARS:getWidth(), CARS:getHeight())
    RED_CAR = love.graphics.newQuad(256, 0, 128, 128, CARS:getWidth(), CARS:getHeight())
    BLUE_CAR = love.graphics.newQuad(256 + 128, 0, 128, 128, CARS:getWidth(), CARS:getHeight())

    OBSTACLES = love.graphics.newImage("Assets/obstacles_small.png")
    STANDING_BARREL = love.graphics.newQuad(0, 0, 64, 64, OBSTACLES:getWidth(), OBSTACLES:getHeight())
    VERTICAL_BARREL = love.graphics.newQuad(64, 0, 64, 64, OBSTACLES:getWidth(), OBSTACLES:getHeight())
    DIAGONAL_BARREL = love.graphics.newQuad(128, 0, 64, 64, OBSTACLES:getWidth(), OBSTACLES:getHeight())
    BARRICADE_QUAD = love.graphics.newQuad(128 + 64, 0, 64, 64, OBSTACLES:getWidth(), OBSTACLES:getHeight())

    STREET = love.graphics.newImage("Assets/ASPHALT.png")
    ASPHALT = love.graphics.newQuad(0, 0, 64, 64, STREET:getWidth(), STREET:getHeight())
    PLANK_AND_SIDEWALK = love.graphics.newQuad(64, 0, 64, 64, STREET:getWidth(), STREET:getHeight())
    PLANK = love.graphics.newQuad(128, 0, 64, 64, STREET:getWidth(), STREET:getHeight())
    PLANK_TOP = love.graphics.newQuad(192, 0, 64, 64, STREET:getWidth(), STREET:getHeight())
    GUTTER = love.graphics.newQuad(192 + 64, 0, 64, 64, STREET:getWidth(), STREET:getHeight())
    SIDEWALK = love.graphics.newQuad(192 + 64 * 2, 0, 64, 64, STREET:getWidth(), STREET:getHeight())
    STREET_LINES = love.graphics.newQuad(192 + 64 * 3, 0, 64, 64, STREET:getWidth(), STREET:getHeight())

    INIT_WORLD(WORLD)

end

function INIT_WORLD(WORLD)

    for i, c in ipairs(ENTITIES.characters) do
        c.name = ("%s%i"):format(c.type, i)
        WORLD:add(c, c.x, c.y, c.width, c.height)
    end

    for i = 0, 275, 1 do
        table.insert(ENTITIES.road.planks_top, Rectangle( i * 58, SCREEN_VALUES.height * (2/5) - 94 - 64, 64, 64 ))
        table.insert(ENTITIES.road.planks,  Rectangle( i * 58, SCREEN_VALUES.height * (2/5) - 94, 64, 64 ))
        table.insert(ENTITIES.road.PLANK_AND_SIDEWALK, Rectangle( i * 58, SCREEN_VALUES.height * (2/5) - 30, 64, 64 ))
        table.insert(ENTITIES.road.SIDEWALK, Rectangle( i * 58, SCREEN_VALUES.height * (2/5) + 34, 64, 64 ))
        table.insert(ENTITIES.road.GUTTER, Rectangle( i * 58, SCREEN_VALUES.height * (2/5) + 98, 64, 64 ))
        table.insert(ENTITIES.road.STREET, Rectangle( i * 58, SCREEN_VALUES.height * (2/5) + 98 + 64, 64, 64 ))
        table.insert(ENTITIES.road.STREET_LINES, Rectangle( i * 58, SCREEN_VALUES.height * (2/5) + 98 + 64 * 3, 64, 64 ))
    end

    WORLD:add( { name = "left bounding box" }, 5, 0, 1, SCREEN_VALUES.height)
    WORLD:add( { name = "top bounding box" }, 5, SCREEN_VALUES.height * (2/5), SCREEN_VALUES.width * 10, 1)
    WORLD:add( { name = "bottom bounding box" }, 5, SCREEN_VALUES.height * 0.9, SCREEN_VALUES.width * 10, 1)
    WORLD:add( { name = "right bounding box" }, SCREEN_VALUES.width * 10, 0, 1, SCREEN_VALUES.height)

    for i = 0, 11, 1 do
        table.insert(ENTITIES.road.barricades, Rectangle( 5, 372 + (64 * i), 64, 64 ))
    end

    for i = 0, 11, 1 do
        table.insert(ENTITIES.road.barricades, Rectangle( SCREEN_VALUES.width * 10 - (5 + 64), 372 + (64 * i), 64, 64 ))
    end

    for i, rect in ipairs(ENTITIES.road.barricades) do
        WORLD:add( { name = string.format("%d barricade", i) }, rect.x, rect.y, rect.width, rect.height)
    end

end

function love.update(dt)

    if love.keyboard.isDown("escape") or
        ( HAS_JOYSTICKS and love.joystick.getJoysticks()[1]:isGamepadDown('guide') ) then
        love.event.quit();
    end

    local isAnyAlive = true
    for i, p in ipairs(ENTITIES.players) do
        isAnyAlive = isAnyAlive and p:isAlive();
    end
    if not isAnyAlive then
        GAME_OVER = true
        GAMEOVER_COLORS.G = math.max(GAMEOVER_COLORS.G - dt * 148, 0)
        GAMEOVER_COLORS.B = math.max(GAMEOVER_COLORS.B - dt * 148, 0)
    end

    for i, c in ipairs(ENTITIES.characters) do
        c:update(dt)
    end

    if not GAME_OVER then
        Score:updateTimer(dt)
    end

    Timer.update(dt)

    local p1 = ENTITIES.players[1]

    CAMERA:lookAt(p1.x, p1.y)

--[[
    -- For each player update
    for i, player in ipairs(ENTITIES.players) do

        if not GAME_OVER then
            --check if game is over
            GAME_OVER = not (GAME_OVER or player:isAlive())
        end

        player.animation:update(dt)

        if player:isAlive() then
            local x, y, punch, kick = player:updatePlayer()

            if not punch and not kick and player.attackTimer < love.timer.getTime() then
                player:move(
                    player.movement_speed * GAME_SPEED * x * dt,
                    player.movement_speed * GAME_SPEED * y * dt
                )
            end

            if x < 0 then
                player:faceLeft()
            end

            if 0 < x then
                player:faceRight()
            end

            if punch and player.attackTimer < love.timer.getTime() then
                player:punch(Timer)
            end

            if kick and player.attackTimer < love.timer.getTime() then
                player:kick(Timer)
            end

            if (x ~= 0 or y ~= 0) and player.attackTimer < love.timer.getTime() then
                player:goToState('walk')
            elseif (player.attackTimer < love.timer.getTime()) then
                player:goToState('idle')
            end

            player:handleAttackBoxes()
        else
            player:death()
        end

    end

    if GAME_OVER then

    end

    AI:update(dt, Score, Timer)
    --]]
end

function love.draw()
    CAMERA:attach()

    local function DrawBackgroundTiles(tiles, cameraRect, texture, quad, offsetX, offsetY, rotation)
        offsetX = offsetX or 0
        offsetY = offsetY or 0
        for i, g in ipairs(tiles) do
            --if g:isIntersectingRectangles(cameraRect) then
            love.graphics.draw(texture, quad, g.x + offsetX, g.y + offsetY, rotation)
            --end
        end
    end

    DrawBackgroundTiles(ENTITIES.road.planks_top, CAMERA, STREET, PLANK_TOP)
    DrawBackgroundTiles(ENTITIES.road.planks, CAMERA, STREET, PLANK)
    DrawBackgroundTiles(ENTITIES.road.PLANK_AND_SIDEWALK, CAMERA, STREET, PLANK_AND_SIDEWALK)
    DrawBackgroundTiles(ENTITIES.road.SIDEWALK, CAMERA, STREET, SIDEWALK)
    DrawBackgroundTiles(ENTITIES.road.GUTTER, CAMERA, STREET, GUTTER)
    DrawBackgroundTiles(ENTITIES.road.STREET_LINES, CAMERA, STREET, STREET_LINES)

    DrawBackgroundTiles(ENTITIES.road.STREET, CAMERA, STREET, ASPHALT)
    DrawBackgroundTiles(ENTITIES.road.STREET, CAMERA, STREET, ASPHALT, 0, 64)
    DrawBackgroundTiles(ENTITIES.road.STREET, CAMERA, STREET, ASPHALT, 0, 64 * 3)
    DrawBackgroundTiles(ENTITIES.road.STREET, CAMERA, STREET, ASPHALT, 0, 64 * 4)
    DrawBackgroundTiles(ENTITIES.road.SIDEWALK, CAMERA, STREET, SIDEWALK, 64, 64 * 9, math.pi)
    DrawBackgroundTiles(ENTITIES.road.GUTTER, CAMERA, STREET, GUTTER, 64, 64 * 7, math.pi)
    DrawBackgroundTiles(ENTITIES.road.barricades, CAMERA, OBSTACLES, BARRICADE_QUAD)

    --- end of background ---

    for i, c in ipairs(ENTITIES.characters) do
        c:draw()
    end


    if GAME_OVER then

        local old_f = love.graphics.getFont()
        love.graphics.setColor(255, GAMEOVER_COLORS.G, GAMEOVER_COLORS.B, 255)
        local f = love.graphics.newFont("Assets/PressStart2P.ttf", 75)
        love.graphics.setFont(f)

        local text_length = f:getWidth("Game Over")
        local position = { x = CAMERA.width / 2 - text_length, y = CAMERA.height / 2 - 75 }

        love.graphics.print("Game Over", position.x, position.y)

        love.graphics.setFont(old_f)
    end

    if DEBUG then
        for i, c in ipairs(ENTITIES.characters) do
            c:drawDebug();
        end
    --[[
        love.graphics.translate(x_offset, y_offset)
        DEBUG_info()
        love.graphics.translate(-x_offset, -y_offset)
        draw_debuxes()
        love.graphics.rectangle("fill", 5, 0, 1, SCREEN_VALUES.height)
        love.graphics.rectangle("fill", 5, SCREEN_VALUES.height * (2/5), SCREEN_VALUES.width * 10, 1)
        love.graphics.rectangle("fill", 5, SCREEN_VALUES.height * 0.9, SCREEN_VALUES.width * 10, 1)
        love.graphics.rectangle("fill", SCREEN_VALUES.width * 10, 0, 1, SCREEN_VALUES.height)

        local w, h = ENTITIES.players[1]:getBboxDimensions()

        love.graphics.rectangle("line", ENTITIES.players[1].x + DETECTION_ZONE_WIDTH, 0, 1, SCREEN_VALUES.height )
        love.graphics.rectangle("line", ENTITIES.players[1].x + w - DETECTION_ZONE_WIDTH, 0, 1, SCREEN_VALUES.height )

    --]]
    end
    CAMERA:detach()

    Score:drawTimer()

end

function love.resize(width, height)
    SCALE.H = (width / SCREEN_VALUES.width) * 2
    SCALE.V = (height / SCREEN_VALUES.height) * 2
end

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
