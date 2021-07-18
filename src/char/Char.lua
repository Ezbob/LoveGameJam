local Rectangle = require "rectangle"
local Hitbox = require "char.Hitbox"
local inspect = require "modules.inspect.inspect"
local Class = require "modules.hump.class"

local Char = Class {
  __includes = Rectangle,
  name = "char", -- collision id
}

function Char:init(x, y, w, h, animationSet, currentAnimation, spriteOffsets, health)
  Rectangle.init(self, x, y, w, h)

  self.health = health or 100
  self.animations = animationSet
  self.spriteOffsets = spriteOffsets or {x = -w, y = -h }
  self.alive = true
  self.facingRight = true
  self.currentAnimation = currentAnimation or 'idle'
end

function Char:update(dt)
  self.animations:updateState(self.currentAnimation, dt)

  for _, hitbox in pairs(self.hitboxes) do
    hitbox.x = self.x + hitbox.offset_x
    hitbox.y = self.y + hitbox.offset_y
  end

  if self.health < 0 then
    self:die()
  end
end

function Char:isFacingRight()
  return self.facingRight
end

function Char:faceRight()
  local state = self.animations:getState(self.currentAnimation)
  if not state then
    return
  end
  local isAnimationFlipped = state.flippedH
  if isAnimationFlipped then
    self.animations:flipAllHorizontal()
    self.facingRight = true
  end
end

function Char:faceLeft()
  local state = self.animations:getState(self.currentAnimation)
  if not state then
    return
  end
  local isAnimationFlipped = state.flippedH
  if not isAnimationFlipped then
    self.animations:flipAllHorizontal()
    self.facingRight = false
  end
end

function Char:draw()
  self.animations:drawState(self.currentAnimation,
    self.x + self.spriteOffsets.x,
    self.y + self.spriteOffsets.y
  )
  if DEBUG then
    Rectangle.draw(self)
    for k, hitbox in pairs(self.hitboxes) do
      hitbox:drawDebug()
    end
  end
end

function Char:setCurrentAnimation(name)
  if name ~= nil then
    self.currentAnimation = name
  end
end

function Char:flipHorizontal()
  local state = self.animations:getState(self.currentAnimation)
  if state then
    state:flipH()
  end
end

function Char:flipVertical()
  local state = self.animations:getState(self.currentAnimation)
  if state then
    state:flipV()
  end
end

function Char:addHitbox(tag, x_offset, y_offset, width, height)
  if self.hitboxes == nil then
    self.hitboxes = {}
  end
  self.hitboxes[tag] = Hitbox(tag, math.floor(self.x + x_offset), math.floor(self.y + y_offset), x_offset, y_offset, width, height)
end

function Char:removeHitbox(tag)
  self.hitboxes[tag] = nil
end

function Char:getHitbox(tag)
  return self.hitboxes[tag]
end

function Char:getHitboxes()
  return self.hitboxes
end

function Char:isAlive()
  return self.alive
end

function Char:die()
  self.alive = false
  self:setCurrentAnimation('death')
end

return Char