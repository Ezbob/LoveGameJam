local Class = require "modules.hump.class"
local CameraState = require "camera.CameraState"

local CameraHold = Class {
  __includes = CameraState
}

function CameraHold:init(camera, point, smoother)
  self.camera = camera
  self.point = point
  self.smoother = smoother
end

function CameraHold:update()
  if self.point ~= nil then
    self.camera.smoother = self.smoother
    self.camera:lockPosition(self.point.x, self.point.y)
  end
end

return CameraHold