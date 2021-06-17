
local Rectangle = {
  x = 0,
  y = 0,
  width = 0,
  height = 0
}

function Rectangle:new(o)
  local r = o or {}
  setmetatable(r, self)
  self.__index = self -- using self here enable inheritance
  return r
end

function Rectangle:isIntersectingRectangles(other)
  local self_left = self.x
  local self_right = self.x + self.width
  local self_top = self.y
  local self_bottom = self.y + self.height

  local other_left = other.x
  local other_right = other.x + other.width
  local other_top = other.y
  local other_bottom = other.y + other.height

  if self_right >= other_left and
  self_left <= other_right and
  self_bottom >= other_top and
  self_top <= other_bottom then
      return true
  else
      return false
  end
end

function Rectangle:setPosition(x, y)
  if (x) then self.x = x end
  if (y) then self.y = y end
end

function Rectangle:getPosition()
  return self.x, self.y
end

function Rectangle:getDimensions()
  return self.width, self.height
end

function Rectangle:setDimensions(width, height)
  self.width = width
  self.height = height
end

function Rectangle:draw(style)
  love.graphics.rectangle(style or "line", self.x, self.y, self.width, self.height)
end

return Rectangle