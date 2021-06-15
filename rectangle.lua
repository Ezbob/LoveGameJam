
local Rectangle = {
  position = {
    x = 0,
    y = 0
  },
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
  local self_left = self.position.x
  local self_right = self.position.x + self.width
  local self_top = self.position.y
  local self_bottom = self.position.y + self.height

  local other_left = other.position.x
  local other_right = other.position.x + other.width
  local other_top = other.position.y
  local other_bottom = other.position.y + other.height

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
  if (not self.position) then self.position = {x = 0, y = 0} end
  if (x) then self.position.x = x end
  if (y) then self.position.y = y end
end

function Rectangle:getPosition()
  return self.position.x, self.position.y
end

function Rectangle:getDimensions()
  return self.width, self.height
end

function Rectangle:setDimensions(width, height)
  self.width = width
  self.height = height
end

return Rectangle