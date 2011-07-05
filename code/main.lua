require "sprite"
local physics = require "physics"


local function initEnemeyDeath()
	enemyDeathSheet = sprite.newSpriteSheet("enemy-death-sheet-1.png", 24, 24)
	enemyDeathSet = sprite.newSpriteSet(enemyDeathSheet, 1, 4)
	sprite.add(enemyDeathSet, "enemyDeathSheet1", 1, 5, 1000, 1)
end

local function initPlayerDeath()
	playerDeathSheet = sprite.newSpriteSheet("player-death-sheet.png", 18, 18)
	playerDeathSet = sprite.newSpriteSet(playerDeathSheet, 1, 10)
	sprite.add(playerDeathSet, "playerDeathSheet", 1, 10, 2000, 1)
end

local function initTerrain()
	-- NOTE: getting emulator bug with images; hard to tell wtf, so aborting for now
	if(true) then
		return
	end
	
	terrain1 = display.newImage("debug-terrain.png", 0, 0)
	mainGroup:insert(terrain1)
	terrain2 = display.newImage("debug-terrain.png", 0, 0)
	mainGroup:insert(terrain2)
	terrain1.x = 0
	terrain1.y = 0
--	terrain2.isVisible = false
--	terrain2.x = 0
	--terrain2.y = terrain1.y + terrain1.height + 4
	
	print("terrain1.y: ", terrain1.y, ", stage.y: ", stage.y)
	
	terrainScroller = {}
	terrainScroller.speed = TERRAIN_SCROLL_SPEED
	terrainScroller.onTerrain = terrain1
	terrainScroller.offTerrain = terrain2
	terrainScroller.targetY = -terrain1.height
	
	function terrainScroller:tick(millisecondsPassed)
		local deltaX = self.onTerrain.x
		local deltaY = self.onTerrain.y - self.targetY
		local dist = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))

		local moveX = self.speed * (deltaX / dist)
		local moveY = self.speed * (deltaY / dist)
		print("self.onTerrain.y: ", self.onTerrain.y)

		if (self.speed >= dist) then
			self.y = self.targetY
			self.onTerrain.y = self.offTerrain.y + self.offTerrain.height
			local oldOn = self.onTerrain
			self.onTerrain = self.offTerrain
			self.offTerrain = oldOn
		else
			self.onTerrain.x = self.onTerrain.x - moveX
			self.onTerrain.y = self.onTerrain.y - moveY
			self.offTerrain.x = self.onTerrain.x
			self.offTerrain.y = self.onTerrain.y + self.onTerrain.height + 2
		end
	end
end

function startScrollingTerrain()
	--addLoop(terrainScroller)
end

function stopScrollingTerrain()
	--removeLoop(terrainScroller)
end

local function initHealthBar()
	healthBarBackground = display.newImage("health-bar-background.png", 0, 0)
	mainGroup:insert(healthBarBackground)
	healthBarBackground.x = stage.width - healthBarBackground.width - 8
	healthBarBackground.y = 8
	
	healthBarForeground = display.newImage("health-bar-foreground.png", 0, 0)
	mainGroup:insert(healthBarForeground)
	healthBarForeground.x = healthBarBackground.x
	healthBarForeground.y = healthBarBackground.y
	healthBarForeground:setReferencePoint(display.TopLeftReferencePoint)
end

local function initSounds()
	planeShootSound = audio.loadSound("plane-shoot.wav")
	enemyDeath1Sound = audio.loadSound("enemy-death-1.mp3")
	playerHitSound = audio.loadSound("player-hit-sound.mp3")
	playerDeathSound = audio.loadSound("player-death-sound.mp3")
end

-- from 0 to 1
function setHealth(value)
	if(value <= 0) then
		value = 0.1
	end
	
	healthBarForeground.xScale = value
	-- NOTE: Makah-no-sense, ese. Basically, setting width is bugged, and Case #677 is documented.
	-- Meaning, no matter what reference point you set, it ALWAYS resizes from center when setting width/height.
	-- So, we just increment based on the negative xReference of "how far my left is from my left origin".
	-- Wow, that was a fun hour.
	healthBarForeground.x = healthBarBackground.x + healthBarForeground.xReference
end

function createEnemyDeath(targetX, targetY)
	local si = sprite.newSprite(enemyDeathSet)
	mainGroup:insert(si)
	si.name = "enemyDeathSetYo"
	si:prepare()
	function onEnd(event)
		if(event.phase == "loop") then
			event.sprite:removeSelf()
		end
	end
	si:addEventListener("sprite", onEnd)
	si:play()
	si.x = targetX
	si.y = targetY
	return si
end

function createPlayerDeath(targetX, targetY)
	local si = sprite.newSprite(playerDeathSet)
	mainGroup:insert(si)
	si.name = "playerDeathSetYo"
	si:prepare()
	function onEnd(event)
		if(event.phase == "loop") then
			event.sprite:removeSelf()
		end
	end
	si:addEventListener("sprite", onEnd)
	si:play()
	si.x = targetX
	si.y = targetY
	return si
end

local function createPlayer()
	local img = display.newImage("plane.png")
	mainGroup:insert(img)
	img.speed = PLAYER_MOVE_SPEED -- pixels per second
	img.name = "Player"
	img.maxHitPoints = 3
	img.hitPoints = 3
	
	physics.addBody( img, { density = 1.0, friction = 0.3, bounce = 0.2, 
								bodyType = "kinematic", 
								isBullet = true, isSensor = true, isFixedRotation = true,
								filter = { categoryBits = 1, maskBits = 28 }
							} )
								
function img:move(x, y)
	self.x = x
	self.y = y
end
	
function img:onBulletHit(event)
	self.hitPoints = self.hitPoints - 1
	setHealth(self.hitPoints / self.maxHitPoints)
	if(self.hitPoints <= 0) then
		self.isVisible = false
		audio.play(playerDeathSound, {loops=0})
		createPlayerDeath(self.x, self.y)
		stopPlayerInteraction()
		endGame()
	else
		audio.play(playerHitSound, {loops=0})
	end
end
	
function img:tick(millisecondsPassed)
	if(self.x == planeXTarget) then
		return
	else
		local deltaX = self.x - planeXTarget
		local deltaY = self.y - planeYTarget
		local dist = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))

		local moveX = self.speed * (deltaX / dist)
		local moveY = self.speed * (deltaY / dist)

		if (self.speed >= dist) then
			self.x = planeXTarget
			self.y = planeYTarget
		else
			self.x = self.x - moveX
			self.y = self.y - moveY
		end
	end	
end
	
	return img
end

local function createEnemyPlane(filename, name, startX, startY, bottom)
	local img = display.newImage(filename)
	mainGroup:insert(img)
	img.name = name
	img.speed = ENEMY_1_SPEED
	img.x = startX
	img.y = startY
	img.bottom = bottom
	img.fireTime = 1500 -- milliseconds
	img.fired = false
	
	
	physics.addBody( img, { density = 1.0, friction = 0.3, bounce = 0.2, 
								bodyType = "kinematic", 
								isBullet = true, isSensor = true, isFixedRotation = true,
								filter = { categoryBits = 4, maskBits = 3 }
							} )
								
	addLoop(img)
	
	function img:destroy()
		removeLoop(self)
		self:removeSelf()
	end
	
	function onHit(self, event)
		if(event.other.name == "Bullet") then
			createEnemyDeath(self.x, self.y)
			local enemyDeath1SoundChannel = audio.play(enemyDeath1Sound, {loops=0})
			audio.setVolume(.25, {channel = enemyDeath1SoundChannel})
			self:dispatchEvent({name="enemyDead", target=self})
			self:destroy()
			event.other:destroy()
		end
	end
	
	img.collision = onHit
	img:addEventListener("collision", img)
	
	function img:tick(millisecondsPassed)
		
		if(self.fired == false) then
			self.fireTime = self.fireTime - millisecondsPassed
			if(self.fireTime <= 0) then
				self.fired = true
				createEnemyBullet(self.x, self.y, plane)
			end
		end
			
		
		if(self.y > bottom) then
			return
		else
			local deltaX = 0
			local deltaY = self.y - bottom
			local dist = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))

			local moveX = self.speed * (deltaX / dist)
			local moveY = self.speed * (deltaY / dist)

			if (self.speed >= dist) then
				self.y = bottom
				self:destroy()
			else
				self.y = self.y - moveY
			end
		end
			
	end
	
	return img	
end

local function createBullet1(startX, startY)
	if(bullets + 1 > MAX_BULLET_COUNT) then
		return
	else
		bullets = bullets + 1
	end
	
	local img = display.newImage("player-bullet-1.png")
	mainGroup:insert(img)
	img.name = "Bullet"
	img.speed = 10 -- pixels per second
	img.x = startX
	img.y = startY
	
	physics.addBody( img, { density = 1.0, friction = 0.3, bounce = 0.2, 
								bodyType = "kinematic", 
								isBullet = true, isSensor = true, isFixedRotation = true,
								filter = { categoryBits = 2, maskBits = 4 }
							} )
								
	addLoop(img)
	
	function img:destroy()
		bullets = bullets - 1
		removeLoop(self)
		self:removeSelf()
	end
	
	function onHit(self, event)
		if(event.other.name == "Bullet") then
			self:destroy()
			event.other:destroy()
		end
	end
	
	img.collision = onHit
	img:addEventListener("collision", img)
	
	function img:tick(millisecondsPassed)
		if(self.y < 0) then
			self:destroy()
			return
		else
			local deltaX = 0
			local deltaY = self.y - 0
			local dist = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))

			local moveX = self.speed * (deltaX / dist)
			local moveY = self.speed * (deltaY / dist)
			
			if (self.speed >= dist) then
				self:destroy()
			else
				self.y = self.y - moveY
			end
		end
	end
	
	return img
end

local function createBullet2(startX, startY)
	if(bullets + 1 > MAX_BULLET_COUNT) then
		return
	else
		bullets = bullets + 1
	end
	
	local img = display.newImage("player-bullet-2.png")
	mainGroup:insert(img)
	img.name = "Bullet"
	img.speed = 10 -- pixels per second
	img.x = startX
	img.y = startY
	
	physics.addBody( img, { density = 1.0, friction = 0.3, bounce = 0.2, 
								bodyType = "kinematic", 
								isBullet = true, isSensor = true, isFixedRotation = true,
								filter = { categoryBits = 2, maskBits = 4 }
							} )
								
	addLoop(img)
	
	function img:destroy()
		bullets = bullets - 1
		removeLoop(self)
		self:removeSelf()
	end
	
	function onHit(self, event)
		if(event.other.name == "Bullet") then
			self:destroy()
			event.other:destroy()
		end
	end
	
	img.collision = onHit
	img:addEventListener("collision", img)
	
	function img:tick(millisecondsPassed)
		if(self.y < 0) then
			self:destroy()
			return
		else
			local deltaX = 0
			local deltaY = self.y - 0
			local dist = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))

			local moveX = self.speed * (deltaX / dist)
			local moveY = self.speed * (deltaY / dist)
			
			if (self.speed >= dist) then
				self:destroy()
			else
				self.y = self.y - moveY
			end
		end
	end
	
	return img
end

function createPowerUp(x, y)
	local img = display.newImage("icon-power-up.png")
	img.x = x
	img.y = y
	img.lifetime = 5000 -- milliseconds
	
	physics.addBody( img, { density = 1.0, friction = 0.3, bounce = 0.2, 
								bodyType = "kinematic", 
								isBullet = false, isSensor = true, isFixedRotation = true,
								filter = { categoryBits = 16, maskBits = 1 }
							} )
							
	function onHit(self, event)
		if(event.other.name == "Player") then
			addPowerUp()
			self:removeSelf()
		end
	end
	
	function img:tick(millisecondsPassed)
		self.lifetime = self.lifetime - millisecondsPassed
		if(self.lifetime <= 0) then
			self:removeSelf()
		end
	end
	
	img.collision = onHit
	img:addEventListener("collision", img)
	
	return img
end

function createEnemyBullet(startX, startY, target)
	local img = display.newImage("bullet.png")
	mainGroup:insert(img)
	img.name = "Bullet"
	img.speed = ENEMY_1_BULLET_SPEED
	img.x = startX
	img.y = startY
	img.targetX = target.x
	img.targetY = target.y
	-- TODO: use math.deg vs. manual conversion
	img.rot = math.atan2(img.y -  img.targetY,  img.x - img.targetX) / math.pi * 180 -90;
	img.angle = (img.rot -90) * math.pi / 180;
	
	physics.addBody( img, { density = 1.0, friction = 0.3, bounce = 0.2, 
								bodyType = "kinematic", 
								isBullet = true, isSensor = true, isFixedRotation = true,
								filter = { categoryBits = 8, maskBits = 1 }
							} )
								
	addLoop(img)
	
function onHit(self, event)
	if(event.other.name == "Player") then
		event.other:onBulletHit()
		self:destroy()
	end
end

img.collision = onHit
img:addEventListener("collision", img)
	
	function img:destroy()
		removeLoop(self)
		self:removeSelf()
	end
	
	function img:tick(millisecondsPassed)
		
		-- TODO: make sure using milliseconds vs. hardcoding step speed
		
		--print("angle: ", self.angle, ", math.cos(self.angle): ", math.cos(self.angle))
		self.x = self.x + math.cos(self.angle) * self.speed
	   	self.y = self.y + math.sin(self.angle) * self.speed
		
		--[[
		local deltaX = self.x + math.cos(self.angle)
		local deltaY = self.y + math.sin(self.angle)
		local dist = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))

		local moveX = self.speed * (deltaX / dist)
		local moveY = self.speed * (deltaY / dist)
		
		if (self.speed >= dist) then
			self:destroy()
		else
			self.x = self.x + moveX
			self.y = self.y + moveY
		end
		]]--
	end
	
	return img
end

function addPowerUp()
	setPowerUpLevel(powerUpLevel + 1)
end

function removePowerUp()
	if(powerUpLevel > 1) then
		setPowerUpLevel(powerUpLevel - 1)
	end
end

function removeLoop(o)
	for i,v in ipairs(tickers) do
		if(v == o) then
			table.remove(tickers, i)
			return
		end	
	end
	print("!! item not found !!")
end

local function startFiringBullets()
	addLoop(bulletRegulator)
	bulletRegulator:tick(333)
end

local function stopFiringBullets()
	removeLoop(bulletRegulator)
end


function addLoop(o)
	table.insert(tickers, o)
end

function removeLoop(o)
	for i,v in ipairs(tickers) do
		if(v == o) then
			table.remove(tickers, i)
			return
		end	
	end
	print("!! item not found !!")
end

function animate(event)
	local now = system.getTimer()
	local difference = now - lastTick
	lastTick = now
	
	for i,v in ipairs(tickers) do
		v:tick(difference)
	end
end

function move(o, x, y)
	o.x = x
	o.y = y
end

function move(x, y)
	self.x = x
	self.y = y
end

function onTouch(event)
	if(event.phase == "began") then
		startFiringBullets()
		if(planeShootSoundChannel == nil) then
			audio.setVolume( .25, { channel=1 } )
			planeShootSoundChannel = audio.play(planeShootSound, {channel=1, loops=-1, fadein=100})
		end
	end
		
		
	if(event.phase == "began" or event.phase == "moved") then
		planeXTarget = event.x
		planeYTarget = event.y
	end
	
	if(event.phase == "ended" or event.phase == "cancelled") then
		stopPlayerInteraction()
	end
end

function stopPlayerInteraction()
	stopFiringBullets()
	audio.fadeOut({channel=1, time=100})
	planeShootSoundChannel = nil
end

function endGame()
	print("endGame")
	Runtime:removeEventListener("enterFrame", animate )
	Runtime:removeEventListener("touch", onTouch)
	timer.cancel(gameTimer)
	gameTimer = nil
	stopScrollingTerrain()
end

function startGame()
	Runtime:addEventListener("enterFrame", animate )
	Runtime:addEventListener("touch", onTouch)
	local t = {}
	t.powerCount = 10
	t.POWER_MAX_COUNT = 10
	function t:timer(event)
		--event.time
		-- timer.cancel( event.source ) 
		local randomX = stage.width * math.random()
		if(randomX < 20) then
			randomX = 20
		end
		
		if(randomX > stage.width - 20) then
			randomX = stage.width - 20
		end
			
		local enemyPlane = createEnemyPlane("enemy-1.png", "Enemy1", randomX, 0, stage.height)
		function onDead(event)
			t.powerCount = t.powerCount - 1
			if(t.powerCount <= 0) then
				t.powerCount = t.POWER_MAX_COUNT
				createPowerUp(event.target.x, event.target.y)
			end
		end
		enemyPlane:addEventListener("enemyDead", onDead)
	end
	
	gameTimer = timer.performWithDelay(500, t, 0)
	
	startScrollingTerrain()
end



physics.start()
physics.setDrawMode( "normal" )
physics.setGravity( 0, 0 )

ENEMY_1_SPEED = 4
ENEMY_1_BULLET_SPEED = 7
MAX_BULLET_COUNT = 6
PLAYER_MOVE_SPEED = 7
TERRAIN_SCROLL_SPEED = 1

mainGroup = display.newGroup()

tickers = {}
powerUpLevel = 1
bullets = 0
bulletRegulator = {} -- Mount up!
bulletRegulator.fireSpeed = 200
bulletRegulator.lastFire = 0
bulletRegulator.fireFunc = nil
function bulletRegulator:tick(millisecondsPassed)
	self.lastFire = self.lastFire + millisecondsPassed
	if(self.lastFire >= self.fireSpeed) then
		self.fireFunc(plane.x, plane.y)
		self.lastFire = 0
	end
end

local function setPowerUpLevel(level)
	powerUpLevel = level
	if(powerUpLevel == 1) then
		bulletRegulator.fireFunc = createBullet1
	elseif(powerUpLevel == 2) then
		bulletRegulator.fireFunc = createBullet2
	end
end

stage = display.getCurrentStage()
initTerrain()
initEnemeyDeath()
initHealthBar()
initSounds()
initPlayerDeath()
setPowerUpLevel(powerUpLevel)

plane = createPlayer()

lastTick = system.getTimer()

addLoop(plane)

planeXTarget = stage.width / 2
planeYTarget = stage.height / 2
plane:move(planeXTarget, planeYTarget)

startGame()


