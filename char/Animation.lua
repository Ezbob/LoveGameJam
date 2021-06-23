
local anim8 = require "modules.anim8.anim8"

-- Animation: Encapsulates a anim8 resouce, grid and animation
local Animation = {}

function Animation:new(image, character, frameSlices, duration, onLoop)
  local grid = anim8.newGrid(character.width, character.height, image:getWidth(), image:getHeight())
  local frames = grid(unpack(frameSlices))
  local r = {
    image = image,
    grid = grid,
    animation = anim8.newAnimation(frames, duration, onLoop),
    flippedH = false
  }
  setmetatable(r, self)
  self.__index = self
  return r
end

function Animation:drawAt(x, y)
  self.animation:draw(self.image, x, y)
end

function Animation:update(dt)
  self.animation:update(dt)
end

function Animation:flipHorizontal()
  self.flippedH = not self.flippedH
  self.animation:flipH()
end

function Animation:isFlippedHorizontal()
  return self.flippedH
end

-- Animation state machine
local AnimationStates = {
  currentAnimation = nil,
  animations = nil
}

function AnimationStates:new()
  local r = {
    currentAnimation = nil,
    animations = {}
  }
  setmetatable(r, self)
  self.__index = self
  return r
end

function AnimationStates:addAnimation(name, animation)
  self.animations[name] = animation
end

function AnimationStates:addNewState(name, args)
  self.animations[name] = Animation:new(unpack(args))
end

function AnimationStates:getCurrentAnimation()
  return self.currentAnimation
end

function AnimationStates:setCurrentAnimation(key)
  if self.animations[key] ~= nil then
    self.currentAnimation = self.animations[key]
  end
end

function AnimationStates:hasCurrentAnimation(key)
  return self.currentAnimation ~= nil and self.animations[key] == self.currentAnimation
end

return { Animation = Animation, AnimationStates = AnimationStates }