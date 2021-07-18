local Rectangle = require "rectangle"
local Class = require "modules.hump.class"

local Hitbox = Class {__includes = Rectangle}

function Hitbox:init(tag, x, y, offset_x, offset_y, w, h)
  Rectangle.init(self, 0, 0, w, h)
  self.name = tag
  self.active = false
  self.x = x
  self.y = y
  self.offset_x = offset_x or 0
  self.offset_y = offset_y or 0
end

function Hitbox:isActive()
  return self.active
end

function Hitbox:setActive(active)
  self.active = active
  return self.active
end

function Hitbox:drawDebug()
  if self.active then
    Rectangle.draw(self, "fill")
  else
    Rectangle.draw(self, "line")
  end
end

return Hitbox