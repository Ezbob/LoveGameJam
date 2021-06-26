local Char = require "char.Char"
local AnimationSet = require "char.AnimationSet"

local PlayerChar = Char:new()

function PlayerChar:new(o)
  local r = o or {}
  r.type = "player"
  setmetatable(r, self)
  self.__index = self

  r:addHitbox("body", 25, 50, 25, 50)
  r:addHitbox("punch_right", 55, 54, 24, 20)
  r:addHitbox("punch_left", -3, 54, 24, 20)
  r:addHitbox("kick_right", 55, 77, 28, 20)
  r:addHitbox("kick_left", -7, 77, 28, 20)
  return r
end

function PlayerChar:die()
  Char.die(self)
  self:setCurrentAnimation('death')
end

function PlayerChar:setupAnimations(sheet, grids, entity)
  self.animations = AnimationSet:new(sheet, {width = self.width, height = self.height})
  self.animations:addNewState("idle", grids[entity]["idle"], 0.5)
  self.animations:addNewState("walk", grids[entity]["walk"], 0.1)
  self.animations:addNewState("punch", grids[entity]["punch"], 0.1)
  self.animations:addNewState("kick", grids[entity]["kick"], 0.1)
  self.animations:addNewState("death", grids[entity]["death"], 0.1, "pauseAtEnd")
  self.animations:addNewState("stun", grids[entity]["stun"], 0.1)
end

-- Shorthand for creating a new player
function PlayerChar:newPlayer(id, x, y, animationTag, width, height, sheet, grid)
  width = width or 76
  height = height or 104
  sheet = sheet or ASSETS["character"].sheet
  grid = grid or ASSETS["character"].grids
  animationTag = animationTag or "player1"

  local newChar = PlayerChar:new {
    playerId = id,
    width = width,
    height = height,
    x = x,
    y = y,
    collision = WORLD
  }

  newChar:setupAnimations(sheet, grid, animationTag)
  return newChar
end

local function playerCollisionFilter(me, other)
  if other.type == "punk" or other.type == "heavy" or other.type == "player" then
      return "cross"
  end

  return "slide"
end

function PlayerChar:move(relative_x, relative_y)
  local actualX, actualY, col, len = self.collision:move(self, self.x + relative_x, self.y + relative_y, playerCollisionFilter)
  self.x = actualX
  self.y = actualY
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

function PlayerChar:update(dt)
  Char.update(self, dt)

  local control = nil
  if self.playerId == 1 then
    control = update_as_left
  else
    control = update_as_right
  end

  local x, y, punch, kick = control(dt)

  self:move(x, y)

  local nextAnimation = "idle"
  if x ~= y then
    if x < 0 then
      self:faceLeft()
    elseif x > 0 then
      self:faceRight()
    end
    nextAnimation = 'walk'
  elseif punch then
    nextAnimation = 'punch'
  elseif kick then
    nextAnimation = 'kick'
  end

  self:setCurrentAnimation(nextAnimation)
end

return PlayerChar