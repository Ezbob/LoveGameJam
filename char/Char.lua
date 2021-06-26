local Rectangle = require "rectangle"
local Hitbox = require "char.Hitbox"
local inspect = require "modules.inspect.inspect"

local Char = Rectangle:new {
  type = "char",
}

function Char:new(o)
  local r = o or {}
  r.effects = r.effects or nil
  r.health = r.health or 100
  r.movement_speed = r.movement_speed or 0
  r.animations = r.animations or nil
  r.hitboxes = r.hitboxes or nil
  r.alive = true
  r.currentAnimation = r.currentAnimation or 'idle'
  setmetatable(r, self)
  self.__index = self
  return r
end

function Char:update(dt)
  self.animations:updateState(self.currentAnimation, dt)

  for _, hitbox in pairs(self.hitboxes) do
    hitbox.x = self.x + hitbox.offset_x
    hitbox.y = self.y + hitbox.offset_y
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
  self.hitboxes[tag] = Hitbox:new({
    type = tag,
    offset_x = x_offset,
    offset_y = y_offset,
    width = width,
    height = height
  })
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