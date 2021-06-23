local Rectangle = require "rectangle"

local Hitbox = Rectangle:new()

function Hitbox:new(o)
  local r = o or {}
  r.active = false
  r.offset_x = r.offset_x or 0
  r.offset_y = r.offset_y or 0
  setmetatable(r, self)
  self.__index = self
  return r
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
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
  else
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
  end
end

return Hitbox