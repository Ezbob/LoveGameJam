
local anim8 = require "modules.anim8.anim8"
local inspect = require "modules.inspect.inspect"

-- Animation: Encapsulates a anim8 resouce, grid and animation

local function newSheet(image, character)
  local grid = anim8.newGrid(character.width, character.height,
    image:getWidth(), image:getHeight())
  return {
    image = image,
    grid = grid
  }
end

-- Animation state machine

local AnimationSet = {}

function AnimationSet:new(image, box)
  local r = {
    sheet = newSheet(image, box),
    set = {}
  }
  setmetatable(r, self)
  self.__index = self
  return r
end

function AnimationSet:addNewState(name, frameSlices, duration, onLoop)
  local frames = self.sheet.grid(unpack(frameSlices))
  self.set[name] = anim8.newAnimation(frames, duration, onLoop)
end

function AnimationSet:hasState(name)
  return self.set[name] ~= nil
end

function AnimationSet:getState(name)
  return self.set[name]
end

function AnimationSet:drawState(name, x, y)
  local state = self:getState(name)
  if state then
    state:draw(self.sheet.image, x, y)
  end
end

function AnimationSet:updateState(name, dt)
  local state = self:getState(name)
  if state then
    state:update(dt)
  end
end

return AnimationSet