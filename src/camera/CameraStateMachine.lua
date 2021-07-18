local Class = require "modules.hump.class"

local CameraStateMachine = Class {}

function CameraStateMachine:init()
  self.paths = {}
  self.currentKey = nil
end

function CameraStateMachine:setCurrentState(key, reset)
  self.currentKey = key
  if reset and self.paths[self.currentKey] then
    self.paths[self.currentKey]:reset()
  end
end

function CameraStateMachine:addCameraState(key, cameraPath)
  self.paths[key] = cameraPath
end

function CameraStateMachine:update(dt)
  local path = self.paths[self.currentKey]
  if path then
    path:update(dt)
  end
end

function CameraStateMachine:getCurrentPath()
  return self.currentKey
end

function CameraStateMachine:isCurrentPathFinished()
  local p = self.paths[self.currentKey]
  if p then
    return p:isFinished()
  else
    return false
  end
end

return CameraStateMachine