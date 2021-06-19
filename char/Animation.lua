
local anim8 = require "modules.anim8.anim8"


-- Animation: Encapsulates a anim8 resouce, grid and animation
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
    grid = grid,
    animation = anim8.newAnimation(frames, duration, onLoop)
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


-- Animation state machine
local AnimationStates = {
  currentAnimation = nil,
  animations = {}
}

function AnimationStates:new()
  local r = {}
  setmetatable(r, self)
  self.__index = self
  return r
end

function AnimationStates:addAnimation(name, animation)
  self.animations[name] = animation
end

function AnimationStates:addNewAnimation(name, args)
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