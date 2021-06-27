local Rectangle = require "rectangle"
local Hitbox = require "char.Hitbox"
local inspect = require "modules.inspect.inspect"
local Class = require "modules.hump.class"
local AnimationSet = require "char.AnimationSet"

local Char = Class {
  __includes = Rectangle,
  type = "char"
}

function Char:init(x, y, w, h, currentAnimation, image)
  Rectangle.init(self, x, y, w, h)
  self.animations = AnimationSet(image, {width = self.width, height = self.height})
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
  self.animations:drawState(self.currentAnimation, self.x, self.y)
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

function Char:drawDebug(style)
  Rectangle.draw(self, style)
  for k,hitbox in pairs(self.hitboxes) do
    hitbox:drawDebug()
  end
end

function Char:addHitbox(tag, x_offset, y_offset, width, height)
  if self.hitboxes == nil then
    self.hitboxes = {}
  end
  self.hitboxes[tag] = Hitbox(tag, x_offset, y_offset, width, height)
end

function Char:removeHitbox(tag)
  self.hitboxes[tag] = nil
end

function Char:getHitbox(tag)
  return self.hitboxes[tag]
end

function Char:isAlive()
  return self.alive
end

function Char:die()
  self.alive = false
end

return Char