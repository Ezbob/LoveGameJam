local Class = require "modules.hump.class"

local CameraState = Class {}

function CameraState:update() end

function CameraState:reset() end

function CameraState:isFinished()
  return true
end

return CameraState