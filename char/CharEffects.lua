local CharEffects = {
  stunned = false
}

function CharEffects:new(o)
    local r = o or {}
    self.__index = self
    setmetatable(r, self)
    return r
end

return CharEffects