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
local Camera = require "camera"
local AnimationSet = require "char.AnimationSet"
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
    minheight= SCREEN_VALUES.height,
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

CAMERA_RECTANGLE = Camera:new {
    x = 0,
    y = 0,
    width = SCREEN_VALUES.width,
    height = SCREEN_VALUES.height
}

ASSETS = {

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
    local STD_CHR_WIDTH, STD_CHR_HEIGHT = 76, 104


    ASSETS["character"] = {
        sheet = love.graphics.newImage("Assets/miniplayer.png"),
        grids = AsepriteAnim8Adaptor.getGridsFromJSON("Assets/miniplayer.json")
    }

    local charbox = {width = STD_CHR_WIDTH, height = STD_CHR_HEIGHT}

    local p1 = PlayerChar:new {
        width = STD_CHR_WIDTH,
        height = STD_CHR_HEIGHT,
        x = 100,
        y = SCREEN_VALUES.height * 0.65,
        animations = AnimationSet:new(ASSETS["character"].sheet, charbox)
    }

    p1.animations:addNewState("idle", ASSETS["character"].grids["player1"]["idle"], 0.5)
    p1.animations:addNewState("walk", ASSETS["character"].grids["player1"]["walk"], 0.1)
    p1.animations:addNewState("punch", ASSETS["character"].grids["player1"]["punch"], 0.1)
    p1.animations:addNewState("kick", ASSETS["character"].grids["player1"]["kick"], 0.1)
    p1.animations:addNewState("death", ASSETS["character"].grids["player1"]["death"], 0.1, "pauseAtEnd")
    p1.animations:addNewState("stun", ASSETS["character"].grids["player1"]["stun"], 0.1)


    local e1 = PunkChar:new {
        width = STD_CHR_WIDTH,
        height = STD_CHR_HEIGHT,
        x = 700,
        y = SCREEN_VALUES.height * 0.7,
        animations = AnimationSet:new(ASSETS["character"].sheet, charbox)
    }

    e1.animations:addNewState("idle", ASSETS["character"].grids["enemy1"]["idle"], 0.5)
    e1.animations:addNewState("walk", ASSETS["character"].grids["enemy1"]["walk"], 0.1)
    e1.animations:addNewState("punch", ASSETS["character"].grids["enemy1"]["punch"], 0.1)
    e1.animations:addNewState("kick", ASSETS["character"].grids["enemy1"]["kick"], 0.1)
    e1.animations:addNewState("death", ASSETS["character"].grids["enemy1"]["death"], 2, "pauseAtEnd")
    e1.animations:addNewState("stun", ASSETS["character"].grids["enemy1"]["stun"], 0.1)

    table.insert(ENTITIES.characters, e1)
    table.insert(ENTITIES.characters, p1)
    table.insert(ENTITIES.players, p1)
    table.insert(ENTITIES.enemies, e1)

    for i, c in ipairs(ENTITIES.characters) do
        c:setCurrentAnimation("idle")
    end

    for i, e in ipairs(ENTITIES.enemies) do
        e:flipHorizontal()
    end

    if HAS_JOYSTICKS then
        ENTITIES.players[1].control_scheme = enums.control_schemes.controller
    end

    Score:setupTimer(0)
    Score:setupScoreCount(0)

    --[[
    STD_CHR_WIDTH, STD_CHR_HEIGHT = 76, 104

    local player1 = Character:newPlayerChar(
        100, SCREEN_VALUES.height * 0.7,
        200, 10, 1, STD_CHR_WIDTH, STD_CHR_HEIGHT)

    local torso_spacing = 25
    local head_room = 58
    local leg_length = 20

    player1:setBboxDimensions(
        player1.width - (torso_spacing * 2), -- frame width of animation has a padding of 2 * torso spacing to make all frame equal width
        player1.height - head_room, -- frame width of animation has a padding head_room (space over the head) to make all frame equal height
        { -- bounding box frame offsets, for drawing the frame
            x = torso_spacing,
            y = head_room - leg_length
        }
    )



    table.insert(ENTITIES.players, player1)

    Score:setupTimer(0)
    Score:setupScoreCount(0)

    IMAGE_ASSETS = {
        player1 = {
            idle = love.graphics.newImage("Assets/miniplayer_idle.png"),
            punch = love.graphics.newImage("Assets/miniplayer_punch.png"),
            walk = love.graphics.newImage("Assets/miniplayer_walk.png"),
            kick = love.graphics.newImage("Assets/miniplayer_kick.png"),
            death = love.graphics.newImage("Assets/miniplayer_death.png"),
            stun = love.graphics.newImage("Assets/miniplayer_stun.png")
        },
        punk = {
            idle = love.graphics.newImage("Assets/minienemy1_idle.png"),
            punch = love.graphics.newImage("Assets/minienemy1_punch.png"),
            walk = love.graphics.newImage("Assets/minienemy1_walk.png"),
            kick = love.graphics.newImage("Assets/minienemy1_kick.png"),
            death = love.graphics.newImage("Assets/minienemy1_death.png"),
            stun = love.graphics.newImage("Assets/minienemy1_stun.png")
        },
        heavy = {
            idle = love.graphics.newImage("Assets/minienemy2_idle.png"),
            kick = love.graphics.newImage("Assets/minienemy2_kick.png"),
            punch = love.graphics.newImage("Assets/minienemy2_punch.png"),
            walk = love.graphics.newImage("Assets/minienemy2_walk.png")
        }
    }


    local j = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.punch:getWidth(), char.punch:getHeight())
    local k = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.walk:getWidth(), char.walk:getHeight())
    local l = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.kick:getWidth(), char.kick:getHeight())
    local m = anim8.newGrid(64, 104, char.death:getWidth(), char.death:getHeight())
    local stun = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.stun:getWidth(), char.stun:getHeight())

    char = IMAGE_ASSETS['punk']
    local epi = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.idle:getWidth(), char.idle:getHeight())
    local epk = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.kick:getWidth(), char.kick:getHeight())
    local epp = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.punch:getWidth(), char.punch:getHeight())
    local epw = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.walk:getWidth(), char.walk:getHeight())
    local epd = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.death:getWidth(), char.death:getHeight())
    local epstun = anim8.newGrid(STD_CHR_WIDTH, STD_CHR_HEIGHT, char.stun:getWidth(), char.stun:getHeight())

    char = IMAGE_ASSETS['heavy']
    local ehi = anim8.newGrid(64, 104, char.idle:getWidth(), char.idle:getHeight())
    local ehk = anim8.newGrid(64, 104, char.kick:getWidth(), char.kick:getHeight())
    local ehp = anim8.newGrid(64, 104, char.punch:getWidth(), char.punch:getHeight())
    local ehw = anim8.newGrid(64, 104, char.walk:getWidth(), char.walk:getHeight())

    ANIMATION_ASSETS = {
        player1 = {
            idle = anim8.newAnimation(h('1-4', 1), 0.25),
            punch = anim8.newAnimation(j('1-4', 1), 0.1),
            walk = anim8.newAnimation(k('1-4', 1), 0.1),
            kick = anim8.newAnimation(l('1-4', 1), 0.1),
            death = anim8.newAnimation(m('1-4', 1), 0.25, "pauseAtEnd"),
            stun = anim8.newAnimation(stun('1-2', 1), {.05, .60}, "pauseAtEnd")
        },
        punk = {
            idle = anim8.newAnimation(epi('1-4', 1), 0.25),
            kick = anim8.newAnimation(epk('1-4', 1), 0.1),
            punch = anim8.newAnimation(epp('1-4', 1), 0.1),
            walk = anim8.newAnimation(epw('1-4', 1), 0.1),
            death = anim8.newAnimation(epd('1-6', 1), 0.25, "pauseAtEnd"),
            stun = anim8.newAnimation(epstun('1-2', 1), {.05, .60}, "pauseAtEnd")
        },
        heavy = {
            idle = anim8.newAnimation(ehi('1-4', 1), 0.25),
            kick = anim8.newAnimation(ehk('1-4', 1), 0.1),
            punch = anim8.newAnimation(ehp('1-4', 1), 0.1),
            walk = anim8.newAnimation(ehw('1-4', 1), 0.1)
        }
    }


    -- Init map
    CARS = love.graphics.newImage("Assets/CARS.png")
    GREEN_CAR = love.graphics.newQuad(0, 0, 128, 128, CARS:getWidth(), CARS:getHeight())
    YELLOW_CAR = love.graphics.newQuad(128, 0, 128, 128, CARS:getWidth(), CARS:getHeight())
    RED_CAR = love.graphics.newQuad(256, 0, 128, 128, CARS:getWidth(), CARS:getHeight())
    BLUE_CAR = love.graphics.newQuad(256 + 128, 0, 128, 128, CARS:getWidth(), CARS:getHeight())
]]--
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

    --[[
    player1:setAniState('idle')

    --- put your persons here

    local punk_enemy = NEW_PUNK(600, 600, STD_CHR_WIDTH, STD_CHR_HEIGHT)

    punk_enemy:setBboxDimensions(
        player1.width - (torso_spacing * 2), -- frame width of animation has a padding of 2 * torso spacing to make all frame equal width
        player1.height - head_room, -- frame width of animation has a padding head_room (space over the head) to make all frame equal height
        { -- bounding box frame offsets, for drawing the frame
            x = torso_spacing,
            y = head_room - leg_length
        }
    )

    table.insert(ENTITIES.enemies, punk_enemy)

    punk_enemy = NEW_PUNK(700, 650, STD_CHR_WIDTH, STD_CHR_HEIGHT)

    punk_enemy:setBboxDimensions(
        player1.width - (torso_spacing * 2), -- frame width of animation has a padding of 2 * torso spacing to make all frame equal width
        player1.height - head_room, -- frame width of animation has a padding head_room (space over the head) to make all frame equal height
        { -- bounding box frame offsets, for drawing the frame
            x = torso_spacing,
            y = head_room - leg_length
        }
    )

    table.insert(ENTITIES.enemies, punk_enemy)

    for index, enemy in ipairs(ENTITIES.enemies) do
        enemy:faceLeft()
    end
--]]
    INIT_WORLD(WORLD)
end

function INIT_WORLD(WORLD)

    for i, c in ipairs(ENTITIES.characters) do
        c.name = ("%s%i"):format(c.type, i)
        WORLD:add(c, c.x, c.y, c.width, c.height)
    end

    for i = 0, 275, 1 do
        table.insert(ENTITIES.road.planks_top, Rectangle:new { x = i * 58, y = SCREEN_VALUES.height * (2/5) - 94 - 64, width = 64, height = 64 })
        table.insert(ENTITIES.road.planks,  Rectangle:new { x = i * 58, y = SCREEN_VALUES.height * (2/5) - 94, width = 64, height = 64 })
        table.insert(ENTITIES.road.PLANK_AND_SIDEWALK, Rectangle:new { x = i * 58, y = SCREEN_VALUES.height * (2/5) - 30, width = 64, height = 64 })
        table.insert(ENTITIES.road.SIDEWALK, Rectangle:new { x = i * 58, y = SCREEN_VALUES.height * (2/5) + 34, width = 64, height = 64 })
        table.insert(ENTITIES.road.GUTTER, Rectangle:new { x = i * 58, y = SCREEN_VALUES.height * (2/5) + 98, width = 64, height = 64 })
        table.insert(ENTITIES.road.STREET, Rectangle:new { x = i * 58, y = SCREEN_VALUES.height * (2/5) + 98 + 64, width = 64, height = 64 })
        table.insert(ENTITIES.road.STREET_LINES, Rectangle:new { x = i * 58, y = SCREEN_VALUES.height * (2/5) + 98 + 64 * 3, width = 64, height = 64 })
    end

    WORLD:add( { name = "left bounding box" }, 5, 0, 1, SCREEN_VALUES.height)
    WORLD:add( { name = "top bounding box" }, 5, SCREEN_VALUES.height * (2/5), SCREEN_VALUES.width * 10, 1)
    WORLD:add( { name = "bottom bounding box" }, 5, SCREEN_VALUES.height * 0.9, SCREEN_VALUES.width * 10, 1)
    WORLD:add( { name = "right bounding box" }, SCREEN_VALUES.width * 10, 0, 1, SCREEN_VALUES.height)

    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500 - (64 * 2), width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500 - 64, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500 + 64 , width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500 + 64 * 2, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500 + 64 * 3, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500 + 64 * 4, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500 + 64 * 5, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500 + 64 * 6, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = 5, y = 500 + 64 * 7, width = 64, height = 64 })

    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 - (64 * 2), width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 - 64, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 , width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 + 64, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 + 64 * 2, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 + 64 * 3 , width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 + 64 * 4, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 + 64 * 5, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 + 64 * 6, width = 64, height = 64 })
    table.insert(ENTITIES.road.barricades, Rectangle:new { x = SCREEN_VALUES.width * 10 - (5 + 64), y = 500 + 64 * 7, width = 64, height = 64 })


    for i, rect in ipairs(ENTITIES.road.barricades) do
        WORLD:add( { name = string.format("%d barricade", i) }, rect.x, rect.y, rect.width, rect.height)
    end

end

function love.update(dt)

    if love.keyboard.isDown("escape") or
        ( HAS_JOYSTICKS and love.joystick.getJoysticks()[1]:isGamepadDown('guide') ) then
        love.event.quit();
    end
--[[
    local isAnyAlive = true
    for i, p in ipairs(ENTITIES.players) do
        isAnyAlive = isAnyAlive and p:isAlive();
    end
    if not isAnyAlive then
        GAME_OVER = true
        GAMEOVER_COLORS.G = math.max(GAMEOVER_COLORS.G - dt * 148, 0)
        GAMEOVER_COLORS.B = math.max(GAMEOVER_COLORS.B - dt * 148, 0)
    end
--]]
    for i, c in ipairs(ENTITIES.characters) do
        c:update(dt)
    end

    if not GAME_OVER then
        Score:updateTimer(dt)
    end

    Timer.update(dt)


    --    ENTITIES.players[1].animation:update(dt)

    --[[
    if not GAME_OVER then
        Score:updateTimer(dt)
        Score:updateScoreCount(dt)
    end

    Timer.update(dt)

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

    --love.graphics.scale(SCALE.H, SCALE.V)


        --[[
    Score:drawScoreCount()
    --]]
    -- Draw each animation and object within the frame

    --[[
    local x_offset, y_offset
    if (locked_camera) then

    else
        x_offset = (ENTITIES.players[1].x - (SCREEN_VALUES.width / 4))
        y_offset = SCREEN_VALUES.height / 2

        CAMERA_RECTANGLE.x = x_offset
        CAMERA_RECTANGLE.y = y_offset

        love.graphics.translate(-x_offset, -y_offset)
    end
--]]


    Score:drawTimer()

    --- background ---


    local function DrawBackgroundTiles(tiles, cameraRect, texture, quad, offsetX, offsetY, rotation)
        offsetX = offsetX or 0
        offsetY = offsetY or 0
        for i, g in ipairs(tiles) do
            if g:isIntersectingRectangles(cameraRect) then
                love.graphics.draw(texture, quad, g.x + offsetX, g.y + offsetY, rotation)
            end
        end
    end

    DrawBackgroundTiles(ENTITIES.road.planks_top, CAMERA_RECTANGLE, STREET, PLANK_TOP)
    DrawBackgroundTiles(ENTITIES.road.planks, CAMERA_RECTANGLE, STREET, PLANK)
    DrawBackgroundTiles(ENTITIES.road.PLANK_AND_SIDEWALK, CAMERA_RECTANGLE, STREET, PLANK_AND_SIDEWALK)
    DrawBackgroundTiles(ENTITIES.road.SIDEWALK, CAMERA_RECTANGLE, STREET, SIDEWALK)
    DrawBackgroundTiles(ENTITIES.road.GUTTER, CAMERA_RECTANGLE, STREET, GUTTER)
    DrawBackgroundTiles(ENTITIES.road.STREET_LINES, CAMERA_RECTANGLE, STREET, STREET_LINES)

    DrawBackgroundTiles(ENTITIES.road.STREET, CAMERA_RECTANGLE, STREET, ASPHALT)
    DrawBackgroundTiles(ENTITIES.road.STREET, CAMERA_RECTANGLE, STREET, ASPHALT, 0, 64)
    DrawBackgroundTiles(ENTITIES.road.STREET, CAMERA_RECTANGLE, STREET, ASPHALT, 0, 64 * 3)
    DrawBackgroundTiles(ENTITIES.road.STREET, CAMERA_RECTANGLE, STREET, ASPHALT, 0, 64 * 4)
    DrawBackgroundTiles(ENTITIES.road.SIDEWALK, CAMERA_RECTANGLE, STREET, SIDEWALK, 64, 64 * 9, math.pi)
    DrawBackgroundTiles(ENTITIES.road.GUTTER, CAMERA_RECTANGLE, STREET, GUTTER, 64, 64 * 7, math.pi)

    --- end of background ---

    DrawBackgroundTiles(ENTITIES.road.barricades, CAMERA_RECTANGLE, OBSTACLES, BARRICADE_QUAD)

    for i, c in ipairs(ENTITIES.characters) do
        c:draw()
    end
--[[
    for i = 1, #ENTITIES.road.barricades do
        local barricade = ENTITIES.road.barricades[i]
        if barricade:isIntersectingRectangles(CAMERA_RECTANGLE) then
            love.graphics.draw(OBSTACLES, BARRICADE_QUAD, barricade.x, barricade.y)
        end
    end

    for i = 1, #ENTITIES.enemies do
        local enemy = ENTITIES.enemies[i]
        if enemy:isIntersectingRectangles(CAMERA_RECTANGLE) then
            local x, y = enemy:getBboxPosition()
            enemy.animation:draw(enemy.image, x, y, 0, 1, 1)
        end
    end

    for _, player in ipairs(ENTITIES.players) do
        local x, y = player:getBboxPosition()
        player.animation:draw(player.image, x, y, 0, 1, 1)
    end
--]]

    --[[
    if GAME_OVER then

        local old_f = love.graphics.getFont()
        love.graphics.setColor(255, GAMEOVER_COLORS.G, GAMEOVER_COLORS.B, 255)
        local f = love.graphics.newFont("Assets/PressStart2P.ttf", 75)
        love.graphics.setFont(f)

        local text_length = f:getWidth("Game Over")
        local position = { x = CAMERA_RECTANGLE.width / 2 - text_length, y = CAMERA_RECTANGLE.height / 2 - 75 }

        love.graphics.print("Game Over", position.x, position.y)

        love.graphics.setFont(old_f)
    end

    --]]
    if DEBUG then
        for i, c in ipairs(ENTITIES.characters) do
            c:drawDebug();
        end
    end
    --[[
    if DEBUG then
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
    end
       --]]

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
