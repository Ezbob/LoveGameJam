
local anim8 = require "modules.anim8.anim8"

local Animation = {
  image = nil,
  grid = nil,
  animation = nil
}

function Animation:new(image, character, frameSlices, duration, onLoop)
  local grid = anim8.newGrid(character.width, character.height, image:getWidth(), image:getHeight())
  local frames = grid(unpack(frameSlices))
  local r = {
    image = image,
    grid = grid
  }
  if onLoop ~= nil then
    print("hello", onLoop)
    r.animation = anim8.newAnimation(frames, duration, onLoop)
  else
    r.animation = anim8.newAnimation(frames, duration)
  end
  setmetatable(r, self)
  self.__index = self
  return r
end

function Animation:drawAt(x, y)
    self.animation:draw(self.image, x, y)
end

return Animation