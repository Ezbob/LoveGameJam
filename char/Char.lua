local Rectangle = require "rectangle"
local Hitbox = require "char.Hitbox"

local Char = Rectangle:new({
  type = "char",
  health = 100,
  movement_speed = 0,
  effects = {
    stunned = false
  },
  animations = nil,
  hitboxes = nil
})

function  Char:new(o)
  local r = o or {}
  r.animations = r.animations or {}
  r.hitboxes = r.hitboxes or {}
  setmetatable(r, self)
  self.__index = self
  return r
end

function Char:update(dt)
  self.animations:getCurrentAnimation():update(dt)
  for key, hitbox in pairs(self.hitboxes) do
    hitbox.x = self.x + hitbox.offset_x
    hitbox.y = self.y + hitbox.offset_y
  end
end

function Char:draw()
  self.animations:getCurrentAnimation():drawAt(self.x, self.y)
end

function Char:flipHorizontal()
  self.animations:getCurrentAnimation():flipH()
end

function Char:flipVertical()
  self.animations:getCurrentAnimation():flipV()
end

function Char:drawDebug(style)
  Rectangle.draw(self, style)
  for k,hitbox in pairs(self.hitboxes) do
    hitbox:drawDebug()
  end
end

function Char:addHitbox(tag, x_offset, y_offset, width, height)
  self.hitboxes[tag] = Hitbox:new({
    type = tag,
    offset_x = x_offset,
    offset_y = y_offset,
    width = width,
    height = height
  })
end

return Char