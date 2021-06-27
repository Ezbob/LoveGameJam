local Char = require "char.Char"
local Class = require "modules.hump.class"
local inspect = require "modules.inspect.inspect"

local PlayerChar = Class {
  __includes = Char,
  type = "player",
  name = "player" -- collision id
}

function PlayerChar:init(id, x, y, animationTag, signal, collision, sheet, grid, width, height)
  width = width or 76
  height = height or 104
  collision = collision
  sheet = sheet
  grid = grid
  signal = signal
  animationTag = animationTag

  Char.init(self, x, y, width, height, 'idle', sheet)

  self.playerId = id
  self.animationTimeout = 0
  self.collision = collision
  self.signal = signal
  self.isPunching = false
  self.isKicking = false

  self:addHitbox("body", 25, 50, 25, 50)
  self:addHitbox("punch_right", 62, 56, 12, 12)
  self:addHitbox("punch_left", 2, 56, 12, 12)
  self:addHitbox("kick_right", 57, 71, 20, 12)
  self:addHitbox("kick_left", -2, 71, 20, 12)

  self.animations:addNewState("idle", grid[animationTag]["idle"], 0.5)
  self.animations:addNewState("walk", grid[animationTag]["walk"], 0.1)
  self.animations:addNewState("punch", grid[animationTag]["punch"], 0.1, function ()
    self:punchEnd()
  end)
  self.animations:addNewState("kick", grid[animationTag]["kick"], 0.1, function ()
    self:kickEnd()
  end)
  self.animations:addNewState("death", grid[animationTag]["death"], 0.1, "pauseAtEnd")
  self.animations:addNewState("stun", grid[animationTag]["stun"], 0.1)

  self.collision:add(self, self.x, self.y, self.width, self.height)
end

function PlayerChar:die()
  Char.die(self)
  self:setCurrentAnimation('death')
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

function PlayerChar:punchEnd()
  self.isPunching = false
  local hitbox = nil
  if self:isFacingRight() then
    hitbox = self.hitboxes['punch_right']
  else
    hitbox = self.hitboxes['punch_left']
  end
  self.signal:emit('player_punch', self, hitbox)
end

function PlayerChar:kickEnd()
  self.isKicking = false
  local hitbox = nil
  if self:isFacingRight() then
    hitbox = self.hitboxes['kick_right']
  else
    hitbox = self.hitboxes['kick_left']
  end
  self.signal:emit('player_kick', self, hitbox)
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
  if not self.alive then
    return
  end

  local control = nil
  if self.playerId == 1 then
    control = update_as_left
  else
    control = update_as_right
  end

  if self.isPunching or self.isKicking then
    return
  end

  local x, y, punch, kick = control(dt)

  self:move(x, y)

  local nextAnimation = "idle"
  if x ~= 0 or y ~= 0 then
    if x < 0 then
      self:faceLeft()
    elseif x > 0 then
      self:faceRight()
    end
    nextAnimation = 'walk'
  elseif punch and not ( self.isPunching or self.isKicking) then
    nextAnimation = 'punch'
    self.isPunching = true
  elseif kick and not (self.isKicking or self.isKicking) then
    nextAnimation = 'kick'
    self.isKicking = true
  end

  self:setCurrentAnimation(nextAnimation)
end

return PlayerChar