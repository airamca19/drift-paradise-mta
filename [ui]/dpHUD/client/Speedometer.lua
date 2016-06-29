Speedometer = {}
Speedometer.visible = false
local DRAW_POST_GUI = false
local MAX_SPEED = 50
local SPEED_SECTORS_COUNT = 134

local screenWidth, screenHeight = guiGetScreenSize()
local originalSize = 400
local width, height = Utils.screenScale(250), Utils.screenScale(250)
local screenOffset = Utils.screenScale(20)

local fallbackTo2d = false

local textureShader
local renderTarget
local maskShader

local circleTextures = {}
local imageIndexPrev = 0

local font
local circleTargetColor = {213, 0, 40}

local assetsTextures = {}

local function getVehicleSpeed()
	if not localPlayer.vehicle then
		return 0
	end
	return math.floor(localPlayer.vehicle.velocity:getLength() * 180)
end

local function getVehicleSpeedString()
	local speed = getVehicleSpeed()
	if speed < 100 then
		if speed < 10 then
			speed = "00" .. tostring(speed)
		else
			speed = "0" .. tostring(speed)
		end
	else
		speed = tostring(speed)
	end
	return speed
end

local function drawSpeedometer(x, y, width, height)
	-- Круг скорости
	dxDrawImage(x, y, width, height, assetsTextures.circle, 0, 0, 0, tocolor(255, 255, 255, 200))
	local speed = getVehicleSpeed()
	local angle = math.max(-270, -speed * 2)
	local imageIndex = math.min(math.floor(-angle / 90) + 1, 3)
	angle = angle + 90 * (imageIndex - 1)
	if imageIndexPrev ~= imageIndex then
		maskShader:setValue("sPicTexture", circleTextures[imageIndex])
		imageIndexPrev = imageIndex
	end
	maskShader:setValue("gUVRotAngle", math.rad(angle))
	local mul = math.min(1, speed / MAX_SPEED)
	local circleColor = tocolor(
		255 - (255 - circleTargetColor[1]) * mul, 
		255 - (255 - circleTargetColor[2]) * mul, 
		255 - (255 - circleTargetColor[3]) * mul
	)
	dxDrawImage(x, y, width, height, maskShader, 0, 0, 0, circleColor)
	dxDrawImage(x, y, width, height, assetsTextures.numbers)

	-- Скорость
	local gear = getVehicleCurrentGear(localPlayer.vehicle)
	if gear == 0 then
		gear = "r"
	end
	if speed == 0 then
		gear = "n"
	end
	dxDrawImage(x, y, width, height, assetsTextures["gear_" .. gear])
	dxDrawText(getVehicleSpeedString(), x, y, x + width, y + height, tocolor(255, 255, 255, 255), 1, font, "center", "bottom")
end

addEventHandler("onClientRender", root, function ()
	if not Speedometer.visible then
		return
	end
	if not localPlayer.vehicle then
		return
	end	
	if localPlayer.vehicle.controller ~= localPlayer then
		return
	end
	if fallbackTo2d then
		drawSpeedometer(screenWidth - width - screenOffset, screenHeight - height - screenOffset, width, height)
	else
		-- Отрисовка спидометра в renderTarget
		dxSetRenderTarget(renderTarget, true)
		drawSpeedometer(0, 0, originalSize, originalSize)
		dxSetRenderTarget()

		textureShader:setValue("sPicTexture", renderTarget)
		
		dxDrawImage(
			screenWidth - width - screenOffset,
			screenHeight - height - screenOffset, 
			width, 
			height,
			textureShader, 
			0, 0, 0, 
			tocolor(255, 255, 255, 200), 
			DRAW_POST_GUI
		)
	end
end)

function Speedometer.start()
	if renderTarget then
		return false
	end
	font = dxCreateFont("assets/fonts/speed.ttf", 90, false)
	renderTarget = dxCreateRenderTarget(originalSize, originalSize, true)
	textureShader = exports.dpAssets:createShader("texture3d.fx")
	maskShader = exports.dpAssets:createShader("mask3d.fx")
	local maskTexture = dxCreateTexture("assets/textures/speedometer/mask.png")
	for i = 1, 3 do
		circleTextures[i] = dxCreateTexture("assets/textures/speedometer/circle"..tostring(i)..".png")
	end
	maskShader:setValue("sMaskTexture", maskTexture)
	maskShader:setValue("gUVRotCenter", 0.5, 0.5)
	if not (renderTarget and textureShader) then
		fallbackTo2d = true
		outputDebugString("Speedometer: Fallback to 2d")
		return
	end

	assetsTextures = {}
	assetsTextures.circle = dxCreateTexture("assets/textures/speedometer/circle.png")
	assetsTextures.numbers = dxCreateTexture("assets/textures/speedometer/numbers.png")
	for i = 1, 5 do
		assetsTextures["gear_"..i] = dxCreateTexture("assets/textures/speedometer/" .. i ..".png")
	end
	assetsTextures["gear_r"] = dxCreateTexture("assets/textures/speedometer/r.png")
	assetsTextures["gear_n"] = dxCreateTexture("assets/textures/speedometer/n.png")
end

function Speedometer.setRotation(x, y, z)
	if not x or not y then
		return false
	end
	if not z then
		z = 0
	end
	if not textureShader then
		return false
	end
	dxSetShaderTransform(textureShader, x, y, z)
end

function Speedometer.setVisible(visible)
	Speedometer.visible = not not visible
	if visible then
		circleTargetColor = {exports.dpUI:getThemeColor()}
	end
end

addEvent("dpUI.updateTheme", false)
addEventHandler("dpUI.updateTheme", root, function ()
	circleTargetColor = {exports.dpUI:getThemeColor()}
end)