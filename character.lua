local enums = require "enums"
local rectangle = require("rectangle")
local Timer = require "./modules/hump/timer"
local inspect = require "modules.inspect.inspect"

local HitBox = rectangle:new {
    isActive = false,
    charYOffset = 0
}

local Character = rectangle:new {
    health = 100,
    movement_speed = 0,
    attack_damage = 0,
    attackTimer = 0,
    animationState = nil,
    effects = {
        stunned = false
    },
    bbox = {
        width = 0,
        height = 0,
        offsets_x = 0,
        offsets_y = 0
    },
    punch_box = HitBox:new {
        charYOffset = 14
    },
    kick_box = HitBox:new {
        charYOffset = 30
    }
}


function Character:newEnemy(x, y, health, movement_speed, attack_damage, width, height)
    local new_enemy = Character:new({
        x = x,
        y = y,
        health = health,
        movement_speed = movement_speed,
        attack_damage = attack_damage,
        width = width,
        height = height
    })
    new_enemy.triggered = false
    return new_enemy
end

function Character:setBboxDimensions(width, height, offsets)
    if offsets ~= nil then
        self.bbox.offsets_x = offsets.x
        self.bbox.offsets_y = offsets.y
    end

    if width ~= nil then
        self.bbox.width = width
    end
    if width ~= nil then
        self.bbox.height = height
    end
end

function Character:setKickBox(width, height, bodyYOffset, isActive)
    self.kick_box:setDimensions(width, height)

    if bodyYOffset ~= nil then
        self.kick_box.charYOffset = bodyYOffset
    end
    if isActive ~= nil then
        self.kick_box.isActive = isActive
    end
end

function Character:setPunchBox(width, height, bodyYOffset, isActive)
    self.punch_box:setDimensions(width, height)

    if bodyYOffset ~= nil then
        self.punch_box.charYOffset = bodyYOffset
    end
    if isActive ~= nil then
        self.punch_box.isActive = isActive
    end
end

function Character:getKickBoxDimensions()
    return self.kick_box.width, self.kick_box.height
end

function Character:getBboxDimensions()
    return self.bbox.width, self.bbox.height
end

function Character:getBboxPosition()
    return self.x - self.bbox.offsets_x, self.y - self.bbox.offsets_y
end

function Character:Update()
    if not self.trigged then return end;

    if self.kind == "heavy" then

    end
    if self.kind == "punk" then

    end
end

function Character:getName()
    if self.kind == "player" then
        return string.format(self.kind .. "%i", self.id)
    end
    return self.kind
end

function Character:setAniState(state, doClone)
    local name = self:getName()
    local charAnimations = ANIMATION_ASSETS[name]
    local charImages = IMAGE_ASSETS[name]

    if doClone then
        self.animation = charAnimations[state]:clone()
    else
        self.animation = charAnimations[state]
    end

    self.animationState = state
    self.image = charImages[state]
end


--[[
Preserves the facing direction, unlike setAniState
]]
function Character:goToState(state, doClone)
    local wasFacingLeft = self:isFacingLeft()
    self:setAniState(state, doClone)
    if wasFacingLeft then
        self:faceLeft()
    else
        self:faceRight()
    end
end

function Character:getAniState()
    return self.animationState
end

function Character:newPlayerChar(x, y, movement_speed, attack_damage, id, width, height)
    return Character:new {
        x = x,
        y = y,
        health = 100,
        movement_speed = movement_speed,
        attack_damage = attack_damage,
        width = width,
        height = height,
        control_scheme = enums.control_schemes.left_control_scheme,
        punching = false,
        kicking = false,
        kind = "player",
        id = id,
        kick_delay = 0.4,
        punch_delay = 0.24
    }
end

local function update_as_left(delta_time)
    local x = 0
    local y = 0
    local punch = false
    local kick = false
    local jump = false
    if love.keyboard.isDown("a") then
        x = x - 1
    end
    if love.keyboard.isDown("d") then
        x = x + 1
    end
    if love.keyboard.isDown("w") then
        y = y - 1
    end
    if love.keyboard.isDown("s") then
        y = y + 1
    end
    if love.keyboard.isDown("q") then
        punch = true
    end
    if love.keyboard.isDown("e") then
        kick = true
    end
    return x, y, punch, kick
end

local function update_as_right(delta_time)
    local x = 0
    local y = 0
    local punch = false
    local kick = false
    local jump = false
    if love.keyboard.isDown("j") then
        x = x - 1
    end
    if love.keyboard.isDown("l") then
        x = x + 1
    end
    if love.keyboard.isDown("i") then
        y = y - 1
    end
    if love.keyboard.isDown("k") then
        y = y + 1
    end
    if love.keyboard.isDown("u") then
        punch = true
    end
    if love.keyboard.isDown("o") then
        kick = true
    end
    return x, y, punch, kick
end

local function update_as_controller(delta_time, player_id)
    if love.joystick.getJoystickCount() == 0 then return end

    local joystick = love.joystick.getJoysticks()[player_id]
    local x = 0
    local y = 0
    local punch = false
    local kick = false
    local jump = false
    if joystick:isGamepadDown("dpleft") then
        x = x - 1
    elseif math.abs(joystick:getAxis( 1 )) > 0.2 then
        x = joystick:getAxis( 1 )
    end
    if joystick:isGamepadDown("dpright") then
        x = x + 1
    end
    if joystick:isGamepadDown("dpup") then
        y = y - 1
    end
    if joystick:isGamepadDown("dpdown") then
        y = y + 1
    elseif math.abs(joystick:getAxis( 2 )) > 0.2 then
        y = joystick:getAxis( 2 )
    end
    if joystick:isGamepadDown("a") then
        punch = true
    end
    if joystick:isGamepadDown("b") then
        kick = true
    end
    return x, y, punch, kick
end

function Character:updatePlayer(delta_time)
    if (enums.control_schemes.left_control_scheme == self.control_scheme) then
        return update_as_left()
    elseif (enums.control_schemes.right_control_scheme == self.control_scheme) then
        return update_as_right()
    elseif (enums.control_schemes.controller == self.control_scheme) then
        return update_as_controller(delta_time, self.id)
    end
end

function Character:death()
    if self:getAniState() ~= "death" then
        self.health = 0 -- make sure it's dead
        self:goToState('death', true)
        self:setKickBox(0, 0, 0, false)
        self:setPunchBox(0, 0, 0, false)

        if WORLD:hasItem(self) then
            WORLD:remove(self)
        end
    end
end

function Character:punch(timer)
    local name = self:getName()

    if self.kicking or self.effects.stunned then return end

    self:goToState('punch')

    if not self.punching then
        self.attackTimer = love.timer.getTime() + 0.5
        self.animation:gotoFrame(1)
        timer.after(self.punch_delay, function()
            self.punch_box.isActive = true
        end)
        timer.after(self.punch_delay + 0.3, function()
            self.punching = false
        end)
        self.punching = true
    end
end

function Character:stun(knockbackDist)
    if not self.effects.stunned then
        self:goToState("stun")
        if self.kick_box.isActive then
            self.kick_box.isActive = false
            self.kicking = false
        end
        if self.punch_box.isActive then
            self.punch_box.isActive = false
            self.punching = false
        end

        self.effects.stunned = true

        Timer.after(0.6, function()
            self.effects.stunned = false
        end)

        if knockbackDist then
            if self:isFacingLeft() then
                self.x = self.x + knockbackDist
            else
                self.x = self.x - knockbackDist
            end
        end
    end
end

function Character:isFacingLeft()
    return self.animation.flippedH
end

function Character:faceLeft()
    if not self:isFacingLeft() then
        self.animation:flipH()
    end
end

function Character:faceRight()
    if self:isFacingLeft() then
        self.animation:flipH()
    end
end

function Character:walk()
    self:setAniState('walk')
end

function Character:idle()
    self:setAniState('idle')
end

function Character:kick(timer)

    if self.punching or self.effects.stunned then return end

    local wasFacingLeft = self:isFacingLeft()

    self:setAniState('kick')

    if wasFacingLeft then
        self:faceLeft()
    else
        self:faceRight()
    end

    if not self.kicking then
        self.attackTimer = love.timer.getTime() + 0.5
        self.animation:gotoFrame(1)
        timer.after(self.punch_delay, function()
            self.kick_box.isActive = true
        end)
        timer.after(self.punch_delay + 0.4, function()
            self.kicking = false
        end)
        self.kicking = true
    end
end

local function characterCollisionFilter(me, other)
    local name = me:getName()

    if name == "punk" or name == "heavy" then
        if other.kind then
            local other_name = other:getName()
            if other_name == "punk" or other_name == "heavy" then
                return "cross"
            else
                return "slide"
            end
        end
    end

    return "slide"
end

function Character:move(movement_x, movement_y)
    if self.effects.stunned then return end

    local intendedX = self.x + movement_x
    local intendedY = self.y + movement_y
    local actualX, actualY, col, len = WORLD:move(self, intendedX, intendedY, characterCollisionFilter)
    self.x = actualX
    self.y = actualY
end

function Character:handleAttackBoxes()
    local w, h = self:getBboxDimensions()
    local pb_right_edge, kb_right_edge

    if self:isFacingLeft() then
        pb_right_edge = math.abs( self.punch_box.width - w ) -- because the kick/punch box isn't as wide as the person bbox
        kb_right_edge = math.abs( self.kick_box.width - w )

        self.punch_box:setPosition(self.x - w + pb_right_edge, self.y + self.punch_box.charYOffset)
        self.kick_box:setPosition(self.x - w + kb_right_edge, self.y + self.kick_box.charYOffset)

        print(self.punch_box.x, self.punch_box.y)
    elseif not self:isFacingLeft() then
        self.punch_box.x = self.x + w
        self.punch_box.y = self.y + self.punch_box.charYOffset;

        self.kick_box.x = self.x + w;
        self.kick_box.y = self.y + self.kick_box.charYOffset;
    end

    if self.attackTimer < love.timer.getTime() then
        self.kick_box.isActive = false
        self.punch_box.isActive = false
    end
end


--[[
    check if the self character's punch and kick boxes collide with the otherCharacter's bbox.
    Takes a optional callback wherein the hit reaction can be expressed using the two characters as arguments
]]
function Character:checkCollision(otherCharacter, onPunchCallback, onKickCallback)
    if self.punch_box.isActive then

        if self.punch_box:isIntersectingRectangles(otherCharacter) then

            --scoreTable:pushScore(100)

            if onPunchCallback ~= nil then
                onPunchCallback(self, otherCharacter)
            else
                if self:isFacingLeft() then
                    otherCharacter:move(-100, 0)
                else
                    otherCharacter:move(100, 0)
                end
            end
        end
    end

    if self.kick_box.isActive then

        if self.kick_box:isIntersectingRectangles(otherCharacter) then

            --scoreTable:pushScore(200)

            if onKickCallback ~= nil then
                onKickCallback(self, otherCharacter)
            else
                if self:isFacingLeft() then
                    otherCharacter:move(-300, 0)
                else
                    otherCharacter:move(300, 0)
                end
            end
        end
    end
end

function Character:looseHealth(attackDamage)
    self.health = self.health - attackDamage
end

function Character:isAlive()
    return self.health > 0
end

return Character