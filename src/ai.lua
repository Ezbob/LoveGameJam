local rectangle = require "rectangle"
local Class = require "modules.hump.class"
local inspect = require "modules.inspect.inspect"
local vector = require "modules.hump.vector-light"

local AI = Class {
	enemy_dead_zone_y = 15,
	enemy_dead_zone_x = 15
}

function AI:init(entities, timer)
	self.entities = entities
	self.timer = timer
end

function AI:attack(currentEnemy, timer)
	local choice = math.random(0, 3)
	if choice <= 2 then
		currentEnemy:punch(timer)
	else
		currentEnemy:kick(timer)
	end
end

local function triggeredEnemies(enemies, players)
	local i = 0
	local n = table.getn(enemies)

	return function ()
		i = i + 1
		if i > n then return end

		local currentEnemy = enemies[i]

		if currentEnemy:isAlive() then
			local ex = currentEnemy.x

			for pi, currentPlayer in ipairs(players) do

				if currentPlayer:isAlive() then
					local px = currentPlayer.x
					local pw = currentPlayer.width

					local lowerDetectionBoundary = px - DETECTION_ZONE_WIDTH
					local upperDetectionBoundary = px + pw + DETECTION_ZONE_WIDTH

					if lowerDetectionBoundary < ex and ex <= upperDetectionBoundary then
						return currentEnemy, currentPlayer
					end
				end
			end

		end
	end
end

function AI:update(dt)

	for enemy, player in triggeredEnemies(self.entities.enemies, self.entities.players) do

			local ex, ey = enemy:getPosition()
			local ew, eh = enemy:getDimensions()
			local px, py = player:getPosition()
			local pw, ph = player:getDimensions()

			if not (
				ex > px + pw + self.enemy_dead_zone_x or
				ex < px - self.enemy_dead_zone_x or
				ey > py + pw + self.enemy_dead_zone_y or
				ey < py - self.enemy_dead_zone_y
				) then
				enemy:stop()
			else
				local x, y = vector.mul(dt, vector.mul(enemy.vx, vector.normalize(vector.sub(px, py, ex, ey))))
				enemy:move(x,y)
			end

	end

	--[[
	for i, currentEnemy in ipairs(self.entities.enemies) do
		if currentEnemy:isAlive() then
			local ex, ey = currentEnemy:getPosition()
			local ew, eh = currentEnemy:getDimensions()
			for pi, currentPlayer in ipairs(self.entities.players) do

				if currentPlayer:isAlive() then
					local px, py = currentPlayer:getPosition()
					local pw, ph = currentPlayer:getDimensions()

					local lowerDetectionBoundary = px - DETECTION_ZONE_WIDTH
					local upperDetectionBoundary = px + pw + DETECTION_ZONE_WIDTH

					if lowerDetectionBoundary < ex and ex <= upperDetectionBoundary then
						return currentEnemy, currentPlayer
					end
				end
			end


			local lowerDetectionBoundary = px - DETECTION_ZONE_WIDTH
			local upperDetectionBoundary = px + pw + DETECTION_ZONE_WIDTH

			if lowerDetectionBoundary < ex and ex <= upperDetectionBoundary then
				if not (
					ex > px + pw + self.enemy_dead_zone_x or
					ex < px - self.enemy_dead_zone_x or
					ey > py + pw + self.enemy_dead_zone_y or
					ey < py - self.enemy_dead_zone_y
					) then
				
				else
					local x, y = vector.mul(dt, vector.mul(currentEnemy.vx, vector.normalize(vector.sub(px, py, ex, ey))))
					currentEnemy:move(x,y)
				end
			end

		end
	end
--]]
	--[[
	for i, currentEnemy in ipairs(ENTITIES.enemies) do

		currentEnemy.animation:update(dt)

		if currentEnemy:isAlive() then
			for index, player in ipairs(ENTITIES.players) do

				local w, h = player:getBboxDimensions()
				local currentEnemyX, currentEnemyY = currentEnemy:getPosition()
				local playerX, playerY = player:getPosition()

				if currentEnemyX <= playerX + DETECTION_ZONE_WIDTH and
					currentEnemyX >= playerX + w - DETECTION_ZONE_WIDTH and player:isAlive() then
					currentEnemy.triggered = true
				else
					currentEnemy.triggered = false
				end

				if currentEnemy.triggered then

					if not (
						currentEnemyX > playerX + w + self.enemy_dead_zone_x or
						currentEnemyX < playerX - w - self.enemy_dead_zone_x or
						currentEnemyY > playerY + self.enemy_dead_zone_y or
						currentEnemyY < playerY - self.enemy_dead_zone_y
						) then
						-- current enemy within "striking distance"

						if currentEnemyX > playerX + (w / 2) then
							-- if the enemy is on the right of the player, face left
							currentEnemy:faceLeft()
						else
							-- else face right
							currentEnemy:faceRight()
						end

						self:attack(currentEnemy, timer)

						-- change this to something useful
						currentEnemy:checkCollision(
							player,
							function(me, other)
								other:looseHealth(me.attack_damage * 0.1)
								--other:stun()
							end,
							function(me, other)
								other:looseHealth(me.attack_damage * 0.2)
								--other:stun()
							end
						)

					else
						-- else we move to get to the striking distance

						--- Horizontal movement
						if currentEnemyX > playerX + w + self.enemy_dead_zone_x then

							currentEnemy:move(-currentEnemy.movement_speed * dt, 0)

							currentEnemy:setAniState('walk')
							currentEnemy:faceLeft()

						elseif currentEnemyX < playerX - w - self.enemy_dead_zone_x then

							currentEnemy:move(currentEnemy.movement_speed * dt, 0)

							currentEnemy:setAniState('walk')
							currentEnemy:faceRight()
						end

						--- Vertical movement
						if currentEnemyY > playerY + self.enemy_dead_zone_y then
							-- enemy top to down

							currentEnemy:move(0, -currentEnemy.movement_speed * dt)
							currentEnemy:setAniState('walk')

						elseif currentEnemyY < playerY - self.enemy_dead_zone_y then
							-- enemy down to top

							currentEnemy:move(0, currentEnemy.movement_speed * dt)
							currentEnemy:setAniState('walk')
						end
					end

				elseif not (currentEnemy.triggered or currentEnemy.effects.stunned) then
					-- not triggered
					currentEnemy:goToState('idle')
				end

				player:checkCollision(
					currentEnemy,
					function(me, other)
						other:looseHealth(me.attack_damage * 0.15)
					   -- other:stun()
					end,
					function(me, other)
						other:looseHealth(me.attack_damage * 0.2)
						other:stun()
					end
				)

			end
			currentEnemy:handleAttackBoxes()
		else
			currentEnemy:death()
		end
	end
	--]]
end

return AI