local Char = require "char.Char"
local Class = require "modules.hump.class"
local inspect = require "modules.inspect.inspect"
local AnimationSet = require "char.AnimationSet"

local PunkChar = Class {
  __includes = Char,
  name = "punk" -- collision id
}

function PunkChar:init(x, y, animationTag, signal, collision, sheet, grid, width, height)
  width = width or 25
  height = height or 45
  collision = collision
  sheet = sheet
  grid = grid
  animationTag = animationTag or "enemy1"

  Char.init(self, x, y, width, height, AnimationSet(sheet, {width = 76, height = 104}),
      'idle',
      {x = -width, y =  -(height + 10)}
  )

  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.collision = collision

  self:addHitbox("body", 0, 5, width, width + 10)
  self:addHitbox("punch_right", width + 10, 8, 12, 12)
  self:addHitbox("punch_left", -22, 8, 12, 12)
  self:addHitbox("kick_right", width + 10, 20, 15, 12)
  self:addHitbox("kick_left", -25, 20, 15, 12)

  self.animations:addNewState("idle", grid[animationTag]["idle"], 0.5)
  self.animations:addNewState("walk", grid[animationTag]["walk"], 0.1)
  self.animations:addNewState("punch", grid[animationTag]["punch"], 0.1, function ()
    self:punchEnd()
  end)
  self.animations:addNewState("kick", grid[animationTag]["kick"], 0.1, function ()
    self:kickEnd()
  end)
  self.animations:addNewState("death", grid[animationTag]["death"], 0.4, "pauseAtEnd")
  self.animations:addNewState("stun", grid[animationTag]["stun"], 0.1)

  self.collision:add(self, self.x, self.y, self.width, self.height)
end

function PunkChar:punchEnd()
  self.isPunching = false
  local hitbox = nil
  if self.facingRight then
    hitbox = self.hitboxes['punch_right']
  else
    hitbox = self.hitboxes['punch_left']
  end
  self.signal:emit('punch', self, hitbox)
end

function PunkChar:kickEnd()
  self.isKicking = false
  local hitbox = nil
  if self.facingRight then
    hitbox = self.hitboxes['kick_right']
  else
    hitbox = self.hitboxes['kick_left']
  end
  self.signal:emit('kick', self, hitbox)
end

return PunkChar