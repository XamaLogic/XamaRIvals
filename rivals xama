											
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
if RunService:IsServer() then
	local store = DataStoreService:GetDataStore("XamaSettings")
	local remote = Instance.new("RemoteFunction")
	remote.Name = "XamaSettings"
	remote.Parent = ReplicatedStorage

	remote.OnServerInvoke = function(plr, action, data)
		local key = "u_" .. plr.UserId
		if action == "Save" and type(data) == "table" then
			local clean = {}
			for k, v in pairs(data) do
				local t = type(v)
				if type(k) == "string" and (t == "boolean" or t == "number" or t == "string") then
					clean[k] = v
				end
			end
			return pcall(function()
				store:SetAsync(key, clean)
			end)
		elseif action == "Load" then
			local ok, result = pcall(function()
				return store:GetAsync(key)
			end)
			if ok then
				return result
			end
		end
		return nil
	end

	return
end
local player = Players.LocalPlayer

local DISCORD_LINK = "discord.gg/your-invite-here"
local MENU_KEY = Enum.KeyCode.RightShift
local AIM_KEY = Enum.KeyCode.Q
local THEMES = {
	White = { Accent = Color3.fromRGB(255, 255, 255), Light = Color3.fromRGB(190, 190, 190) },
	Silver = { Accent = Color3.fromRGB(200, 200, 200), Light = Color3.fromRGB(150, 150, 150) },
	Gray = { Accent = Color3.fromRGB(140, 140, 140), Light = Color3.fromRGB(100, 100, 100) },
}
local THEME_NAMES = { "White", "Silver", "Gray" }

local C = {
	Dark = Color3.fromRGB(0, 0, 0),
	Navy = Color3.fromRGB(24, 24, 24),
	Accent = THEMES.White.Accent,
	Light = THEMES.White.Light,
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(200, 200, 200),
	Good = Color3.fromRGB(255, 255, 255),
	Bad = Color3.fromRGB(70, 70, 70),
	Off = Color3.fromRGB(32, 32, 32),
	Btn = Color3.fromRGB(18, 18, 18),
	BtnHover = Color3.fromRGB(55, 55, 55),
}

local rng = Random.new()
local allConns = {}   -- every global connection, so Unload can clean up

local function keep(conn)
	table.insert(allConns, conn)
	return conn
end
local function new(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

-- Square theme: every "corner" is 0 radius
local function corner(obj, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, 0) }, obj)
end

-- Anything that uses the accent color registers here so the Accent dropdown can recolor it
local accentUpdaters = {}

local function onAccent(fn)
	table.insert(accentUpdaters, fn)
	fn()
end

local function applyTheme(theme)
	C.Accent = theme.Accent
	C.Light = theme.Light
	for _, fn in ipairs(accentUpdaters) do
		pcall(fn)
	end
end

local function glassStroke(obj, thickness)
	local stroke = new("UIStroke", {
		Thickness = thickness or 1.5,
		Color = Color3.new(1, 1, 1),
		Transparency = 0.1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
	local grad = new("UIGradient", { Rotation = 45 }, stroke)
	onAccent(function()
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C.Light),
			ColorSequenceKeypoint.new(0.5, C.Accent),
			ColorSequenceKeypoint.new(1, C.Light),
		})
	end)
	return stroke
end

local function label(parent, text, size, position, font, textSize, color, alignX)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Size = size,
		Position = position,
		Font = font,
		TextSize = textSize,
		TextColor3 = color or C.Text,
		TextStrokeTransparency = 0.8,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextXAlignment = alignX or Enum.TextXAlignment.Center,
		BorderSizePixel = 0,
	}, parent)
end

local function makeDraggable(handle, target)
	local dragging, dragStart, startPos = false, nil, nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	keep(UserInputService.InputChanged:Connect(function(input)
		if dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))
end

-- ScreenGui -------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "Xama",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

local blur = new("BlurEffect", { Size = 0, Name = "XamaBlur" }, Lighting)

-- Twinkling stars (square dots) -------------------------------------------
local function addStars(panel, count)
	local holder = new("Frame", {
		Name = "Stars",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		BorderSizePixel = 0,
		ZIndex = 0,
	}, panel)

	for _ = 1, count do
		local s = rng:NextNumber(1.5, 3)
		local star = new("Frame", {
			Size = UDim2.fromOffset(s, s),
			Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber()),
			BackgroundColor3 = (rng:NextInteger(1, 3) == 1) and C.Light or Color3.new(1, 1, 1),
			BackgroundTransparency = rng:NextNumber(0.05, 0.4),
			BorderSizePixel = 0,
			ZIndex = 0,
		}, holder)

		TweenService:Create(
			star,
			TweenInfo.new(rng:NextNumber(0.8, 2.5), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 2)),
			{ BackgroundTransparency = 0.95 }
		):Play()
	end
end

-- Panel -----------------------------------------------------------------
local function glassPanel(name, size, position, starCount)
	local panel = new("Frame", {
		Name = name,
		Size = size,
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
	}, gui)
	corner(panel)
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C.Navy),
			ColorSequenceKeypoint.new(1, C.Dark),
		}),
		Rotation = 60,
	}, panel)
	glassStroke(panel, 1.5)

	addStars(panel, starCount or 35)

	local shine = new("Frame", {
		Name = "Shine",
		Size = UDim2.new(1, 0, 0.35, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 0,
	}, panel)
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 90,
	}, shine)

	new("UIScale", { Scale = 1 }, panel)
	return panel
end

local function openPanel(panel)
	local scale = panel:FindFirstChildOfClass("UIScale")
	scale.Scale = 0.85
	panel.Visible = true
	tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

local function closePanel(panel, callback)
	local scale = panel:FindFirstChildOfClass("UIScale")
	tween(scale, 0.25, { Scale = 0.88 })
	task.delay(0.27, function()
		panel.Visible = false
		if callback then
			callback()
		end
	end)
end

-- Button ----------------------------------------------------------------
local function makeButton(parent, text, size, position, color)
	local base = color or C.Btn
	local btn = new("TextButton", {
		Text = text,
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = base,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = C.Text,
		TextStrokeTransparency = 0.8,
		BorderSizePixel = 0,
	}, parent)

	local stroke = new("UIStroke", {
		Color = C.Light,
		Transparency = 0.3,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, btn)

	local scale = new("UIScale", { Scale = 1 }, btn)

	onAccent(function()
		stroke.Color = C.Light
	end)

	btn.MouseEnter:Connect(function()
		tween(btn, 0.15, { BackgroundColor3 = C.BtnHover })
		tween(stroke, 0.15, { Transparency = 0 })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.15, { BackgroundColor3 = base })
		tween(stroke, 0.15, { Transparency = 0.3 })
		tween(scale, 0.1, { Scale = 1 })
	end)
	btn.MouseButton1Down:Connect(function()
		tween(scale, 0.08, { Scale = 0.95 })
	end)
	btn.MouseButton1Up:Connect(function()
		tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
	end)

	return btn
end

-- 1) LOADING SCREEN -----------------------------------------------------
local loadPanel = glassPanel("Loading", UDim2.fromOffset(380, 190), UDim2.fromScale(0.5, 0.5), 40)

label(loadPanel, "XAMA", UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 24),
	Enum.Font.GothamBlack, 38, C.Text)

local loadStatus = label(loadPanel, "Starting...", UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 86),
	Enum.Font.GothamMedium, 15, C.SubText)

local barBack = new("Frame", {
	Size = UDim2.new(1, -60, 0, 8),
	Position = UDim2.fromOffset(30, 128),
	BackgroundColor3 = C.Off,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
}, loadPanel)

local barFill = new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
}, barBack)
local barGrad = new("UIGradient", {}, barFill)
onAccent(function()
	barGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.Light),
		ColorSequenceKeypoint.new(1, C.Accent),
	})
end)

-- SETTINGS (shared by the engines and the UI) ------------------------------
local S = {
	-- targets
	TeamCheck = true,
	IncludeNPCs = true,   -- also target dummies / NPCs (handy for testing in Studio)

	-- aimbot
	AimEnabled = false,
	AimType = "Smooth",   -- Smooth / Snap / Sticky
	VisibleCheck = true,
	LowestHealth = false,
	MaxDistance = 150,
	AimDelay = 0,         -- milliseconds
	SmoothX = 0.27,
	SmoothY = 0.50,
	Intensity = 1,
	HitPart = "Random",   -- Random (40% head / 50% body) / Head / Torso
	HitChance = 0.9,      -- chance the aim lands (the rest aims just off-target)

	-- FOV circle
	FovOn = true,
	FovFill = false,
	FovRadius = 120,
	FovMethod = "Center", -- Center / Mouse

	-- visuals
		Chams = true,
	NameESP = false,
	ChamsCount = 3,
	ChamsRange = 300,
	FillColor = "Red",
	OutlineColor = "Purple",
	FillTransparency = 0.35,
}

local COLOR_PRESETS = {
	Red = Color3.fromRGB(255, 40, 70),
	Purple = Color3.fromRGB(170, 60, 255),
	Blue = Color3.fromRGB(40, 120, 255),
	Green = Color3.fromRGB(60, 255, 140),
	Pink = Color3.fromRGB(255, 90, 200),
	White = Color3.fromRGB(255, 255, 255),
}
local COLOR_NAMES = { "Red", "Purple", "Blue", "Green", "Pink", "White" }

-- Bridge for your own gun scripts (see the header comment)
local Bridge = {
	SilentAim = false,
	NoRecoil = false,
	NoSpread = false,
	HitChance = S.HitChance,
	GetAimPosition = function()
		return nil
	end,
}
_G.Xama = Bridge

-- Shared list of every Humanoid in the world (players AND dummies/NPCs)
local Tracker = { humanoids = {}, users = 0, conns = {} }

function Tracker.Acquire()
	Tracker.users += 1
	if Tracker.users == 1 then
		for _, inst in ipairs(workspace:GetDescendants()) do
			if inst:IsA("Humanoid") then
				Tracker.humanoids[inst] = true
			end
		end
		table.insert(Tracker.conns, workspace.DescendantAdded:Connect(function(inst)
			if inst:IsA("Humanoid") then
				Tracker.humanoids[inst] = true
			end
		end))
		table.insert(Tracker.conns, workspace.DescendantRemoving:Connect(function(inst)
			if inst:IsA("Humanoid") then
				Tracker.humanoids[inst] = nil
			end
		end))
	end
end

function Tracker.Release()
	Tracker.users = math.max(0, Tracker.users - 1)
	if Tracker.users == 0 then
		for _, c in ipairs(Tracker.conns) do
			c:Disconnect()
		end
		table.clear(Tracker.conns)
		table.clear(Tracker.humanoids)
	end
end

local function isValidTarget(hum, ignoreTeam)
	local model = hum.Parent
	if not model or model == player.Character then
		return false
	end
	if hum.Health <= 0 then
		return false
	end
	local owner = Players:GetPlayerFromCharacter(model)
	if owner then
		if not ignoreTeam and S.TeamCheck and owner.Team ~= nil and owner.Team == player.Team then
			return false
		end
	elseif not S.IncludeNPCs then
		return false
	end
	return true
end

local TARGET_PART_NAMES = { "UpperTorso", "Torso", "HumanoidRootPart" }

local function getTargetPart(model)
	for _, partName in ipairs(TARGET_PART_NAMES) do
		local part = model:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			return part
		end
	end
end

-- AIMBOT ENGINE ---------------------------------------------------------
local Aim = {}

do
	local BREAKOUT = 50           -- mouse pixels/frame that break the lock (not in Sticky)
	local COOLDOWN = 0.8          -- seconds before it can lock again after a breakout/release
	local REROLL = 0.8            -- seconds between head/body/miss rolls
	local MISS_OFFSET = 4         -- studs off-target on a "miss"
	local RENDER_NAME = "XamaAimbot"

	local locked = false
	local target = nil            -- a Humanoid
	local lockedAt = 0
	local cooldownUntil = 0
	local mouseDelta = 0
	local blockedTime = 0
	local aimMode = "Body"
	local nextRollAt = 0
	local missOffset = Vector3.zero
	local bound = false
	local acquired = false
	local conns = {}

	-- Outlined FOV circle (stays round so it matches the real aim radius)
	local circle = new("Frame", {
		Name = "AimCircle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(S.FovRadius * 2, S.FovRadius * 2),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 0,
	}, gui)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, circle)
	local circleStroke = new("UIStroke", {
		Thickness = 2,
		Color = C.Light,
		Transparency = 0.05,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, circle)
	local centerDot = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, circle)

	local function paintCircle()
		circle.BackgroundColor3 = C.Accent
		circleStroke.Color = locked and C.Good or C.Light
	end
	onAccent(paintCircle)

	function Aim.RefreshCircle()
		circle.Visible = S.AimEnabled and S.FovOn
		local r = S.FovRadius
		circle.Size = UDim2.fromOffset(r * 2, r * 2)
		circle.BackgroundTransparency = S.FovFill and 0.88 or 1
		if S.FovMethod == "Center" then
			circle.Position = UDim2.fromScale(0.5, 0.5)
		end
	end

	local function getFovCenter(camera)
		if S.FovMethod == "Mouse" then
			return UserInputService:GetMouseLocation()
		end
		return camera.ViewportSize / 2
	end

	local function hasLineOfSight(camera, part, model)
		local ignore = { model }
		if player.Character then
			table.insert(ignore, player.Character)
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = ignore
		params.RespectCanCollide = true
		local origin = camera.CFrame.Position
		return workspace:Raycast(origin, part.Position - origin, params) == nil
	end

	-- (in front of camera?, pixels from the FOV center)
	local function screenInfo(camera, part, center)
		local v = camera:WorldToViewportPoint(part.Position)
		return v.Z > 0, (Vector2.new(v.X, v.Y) - center).Magnitude
	end

	local function findTarget(camera, center)
		local best, bestScore = nil, math.huge
		for hum in pairs(Tracker.humanoids) do
			if isValidTarget(hum) then
				local part = getTargetPart(hum.Parent)
				if part then
					local studs = (part.Position - camera.CFrame.Position).Magnitude
					if studs <= S.MaxDistance then
						local inFront, pixels = screenInfo(camera, part, center)
						if inFront and pixels <= S.FovRadius
							and (not S.VisibleCheck or hasLineOfSight(camera, part, hum.Parent)) then
							local score = S.LowestHealth and (hum.Health * 1000 + pixels) or pixels
							if score < bestScore then
								best, bestScore = hum, score
							end
						end
					end
				end
			end
		end
		return best
	end

	-- Decide where to aim: head / body / slightly off (a miss)
	local function rollAim()
		if math.random() > S.HitChance then
			aimMode = "Miss"
			local angle = math.random() * math.pi * 2
			missOffset = Vector3.new(math.cos(angle), 0.3, math.sin(angle)).Unit * MISS_OFFSET
		elseif S.HitPart == "Head" then
			aimMode = "Head"
		elseif S.HitPart == "Torso" then
			aimMode = "Body"
		else
			-- Random: with a 90% hit chance this works out to 40% head / 50% body
			aimMode = (math.random() < 4 / 9) and "Head" or "Body"
		end
		nextRollAt = os.clock() + REROLL
	end

	local function getAimPosition(part)
		if aimMode == "Head" then
			local head = target.Parent:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				return head.Position
			end
		elseif aimMode == "Miss" then
			return part.Position + missOffset
		end
		return part.Position
	end

	local function releaseLock()
		locked = false
		target = nil
		blockedTime = 0
		paintCircle()
	end

	local function lockOn(hum)
		target = hum
		locked = true
		lockedAt = os.clock()
		blockedTime = 0
		rollAim()
		paintCircle()
	end

	Bridge.GetAimPosition = function()
		if not locked or not target or not target.Parent then
			return nil
		end
		local part = getTargetPart(target.Parent)
		return part and getAimPosition(part) or nil
	end

	local function step(dt)
		local moved = mouseDelta
		mouseDelta = 0

		local camera = workspace.CurrentCamera
		if not camera then return end

		local center = getFovCenter(camera)
		if S.FovMethod == "Mouse" then
			circle.Position = UDim2.fromOffset(center.X, center.Y)
		end

		-- Break out by flicking the mouse hard (not in Sticky mode)
		if locked and S.AimType ~= "Sticky" and moved > BREAKOUT then
			releaseLock()
			cooldownUntil = os.clock() + COOLDOWN
			return
		end

		-- Auto lock: whoever is inside the circle gets locked
		if not locked then
			if os.clock() >= cooldownUntil then
				local found = findTarget(camera, center)
				if found then
					lockOn(found)
				end
			end
			if not locked then return end
		end

		-- Drop the lock if the target is gone / dead
		local part = isValidTarget(target) and getTargetPart(target.Parent)
		if not part then
			releaseLock()
			return
		end

		local camPos = camera.CFrame.Position
		if (part.Position - camPos).Magnitude > S.MaxDistance * 1.2 then
			releaseLock()
			return
		end

		local inFront, pixels = screenInfo(camera, part, center)
		if not inFront or pixels > S.FovRadius * 2 then
			releaseLock()
			return
		end

		-- Lose the lock if a wall has been in the way for a bit
		if S.VisibleCheck then
			if hasLineOfSight(camera, part, target.Parent) then
				blockedTime = 0
			else
				blockedTime += dt
				if blockedTime > 0.4 then
					releaseLock()
					return
				end
			end
		end

		-- Aim delay before the pull starts
		if os.clock() - lockedAt < S.AimDelay / 1000 then
			return
		end

		if os.clock() >= nextRollAt then
			rollAim()
		end
		local aimPos = getAimPosition(part)
		local toAim = aimPos - camPos
		if toAim.Magnitude < 0.01 then return end

		if S.AimType == "Snap" then
			camera.CFrame = CFrame.lookAt(camPos, aimPos)
			return
		end

		-- Smooth / Sticky: separate horizontal (X) and vertical (Y) smoothing
		local strengthX = math.clamp((1 - S.SmoothX) * S.Intensity, 0, 1)
		local strengthY = math.clamp((1 - S.SmoothY) * S.Intensity, 0, 1)
		if S.AimType == "Sticky" then
			strengthX = math.max(strengthX, 0.85)
			strengthY = math.max(strengthY, 0.85)
		end
		local alphaX = 1 - (1 - strengthX) ^ (dt * 60)
		local alphaY = 1 - (1 - strengthY) ^ (dt * 60)

		local look = camera.CFrame.LookVector
		local want = toAim.Unit
		local yaw = math.atan2(-look.X, -look.Z)
		local pitch = math.asin(math.clamp(look.Y, -1, 1))
		local wantYaw = math.atan2(-want.X, -want.Z)
		local wantPitch = math.asin(math.clamp(want.Y, -1, 1))

		local dYaw = (wantYaw - yaw + math.pi) % (2 * math.pi) - math.pi
		local newYaw = yaw + dYaw * alphaX
		local newPitch = math.clamp(pitch + (wantPitch - pitch) * alphaY, -1.45, 1.45)

		camera.CFrame = CFrame.new(camPos) * CFrame.fromEulerAnglesYXZ(newPitch, newYaw, 0)
	end

	function Aim.SetEnabled(on)
		S.AimEnabled = on

		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		table.clear(conns)
		if bound then
			RunService:UnbindFromRenderStep(RENDER_NAME)
			bound = false
		end
		if acquired then
			Tracker.Release()
			acquired = false
		end
		releaseLock()
		mouseDelta = 0
		Aim.RefreshCircle()

		if not on then
			return
		end

		Tracker.Acquire()
		acquired = true

		table.insert(conns, UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				mouseDelta += input.Delta.Magnitude
			end
		end))

		-- Q = manual lock / release
		table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
			if processed or input.KeyCode ~= AIM_KEY then return end

			if locked then
				releaseLock()
				cooldownUntil = os.clock() + COOLDOWN
			else
				local camera = workspace.CurrentCamera
				if camera then
					local found = findTarget(camera, getFovCenter(camera))
					if found then
						lockOn(found)
					end
				end
			end
		end))

		-- Run right AFTER Roblox's own camera update so the aim isn't overwritten
		RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, step)
		bound = true
	end

	-- Called when you change how the lock behaves
	function Aim.Reroll()
		if locked then
			rollAim()
		end
	end
end

-- VISUALS ENGINE (chams + name ESP on the nearest players) -----------------
local Visuals = {}

do
	local REFRESH = 0.2
	local highlights = {}   -- [model] = Highlight
	local billboards = {}   -- [model] = BillboardGui
	local conn = nil
	local running = false
	local timer = 0

	local function clearAll()
		for model, h in pairs(highlights) do
			h:Destroy()
			highlights[model] = nil
		end
		for model, b in pairs(billboards) do
			b:Destroy()
			billboards[model] = nil
		end
	end

	local function refresh()
		local myChar = player.Character
		local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not root then
			clearAll()
			return
		end

		local list = {}
		for hum in pairs(Tracker.humanoids) do
			if isValidTarget(hum, true) then
				local model = hum.Parent
				local part = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
				if part then
					local d = (part.Position - root.Position).Magnitude
					if d <= S.ChamsRange then
						table.insert(list, { model = model, dist = d })
					end
				end
			end
		end
		table.sort(list, function(a, b)
			return a.dist < b.dist
		end)

		local keep_ = {}
		for i = 1, math.min(S.ChamsCount, #list) do
			local model = list[i].model
			keep_[model] = list[i].dist
		end

		-- Chams (Highlight)
		for model in pairs(keep_) do
			if S.Chams then
				local h = highlights[model]
				if not h or h.Parent ~= model then
					highlights[model] = new("Highlight", {
						Name = "XamaChams",
						Adornee = model,
						FillColor = COLOR_PRESETS[S.FillColor],
						OutlineColor = COLOR_PRESETS[S.OutlineColor],
						FillTransparency = S.FillTransparency,
						OutlineTransparency = 0,
						DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
					}, model)
				end
			end
		end
		for model, h in pairs(highlights) do
			if not S.Chams or not keep_[model] then
				h:Destroy()
				highlights[model] = nil
			end
		end

		-- Name ESP (BillboardGui above the head)
		for model, dist in pairs(keep_) do
			if S.NameESP then
				local head = model:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					local owner = Players:GetPlayerFromCharacter(model)
					local nameText = owner and owner.DisplayName or model.Name
					local text = nameText .. "\n" .. math.floor(dist) .. " studs"

					local b = billboards[model]
					if not b or b.Parent ~= head then
						b = new("BillboardGui", {
							Name = "XamaName",
							Adornee = head,
							AlwaysOnTop = true,
							Size = UDim2.fromOffset(160, 36),
							StudsOffset = Vector3.new(0, 2.6, 0),
						}, head)
						new("TextLabel", {
							Name = "Text",
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Font = Enum.Font.GothamBold,
							TextSize = 13,
							TextColor3 = Color3.new(1, 1, 1),
							TextStrokeTransparency = 0.4,
						}, b)
						billboards[model] = b
					end
					b.Text.Text = text
				end
			end
		end
		for model, b in pairs(billboards) do
			if not S.NameESP or not keep_[model] then
				b:Destroy()
				billboards[model] = nil
			end
		end
	end

	local function start()
		running = true
		Tracker.Acquire()
		timer = 0
		conn = RunService.Heartbeat:Connect(function(dt)
			timer += dt
			if timer >= REFRESH then
				timer = 0
				refresh()
			end
		end)
		refresh()
	end

	local function stop()
		running = false
		if conn then
			conn:Disconnect()
			conn = nil
		end
		clearAll()
		Tracker.Release()
	end

	-- Call whenever Chams / Name ESP / their settings change
	function Visuals.Update()
		local want = S.Chams or S.NameESP
		if want and not running then
			start()
		elseif not want and running then
			stop()
		elseif running then
			for _, h in pairs(highlights) do
				h.FillColor = COLOR_PRESETS[S.FillColor]
				h.OutlineColor = COLOR_PRESETS[S.OutlineColor]
				h.FillTransparency = S.FillTransparency
			end
			refresh()
		end
	end

	function Visuals.Shutdown()
		if running then
			stop()
		end
	end
end

-- UI CONTROLS -----------------------------------------------------------
local orderCounters = setmetatable({}, { __mode = "k" })

local function nextOrder(parent)
	orderCounters[parent] = (orderCounters[parent] or 0) + 1
	return orderCounters[parent]
end

-- A titled card inside a column
local function section(column, title)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(column),
	}, column)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, holder)

	local head = label(holder, title, UDim2.new(1, 0, 0, 18), nil,
		Enum.Font.GothamBold, 14, C.SubText, Enum.TextXAlignment.Left)
	head.LayoutOrder = 1

	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Dark,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	}, holder)
	local cardStroke = new("UIStroke", {
		Color = C.Light,
		Transparency = 0.7,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, card)
	onAccent(function()
		cardStroke.Color = C.Light
	end)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, card)
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, card)
	return card
end

local function checkbox(card, text, default, callback, keyText)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(card),
	}, card)

	local box = new("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 0, 0.5, -8),
		BackgroundColor3 = C.Off,
		BorderSizePixel = 0,
	}, row)
	local boxStroke = new("UIStroke", {
		Color = C.Light,
		Transparency = 0.4,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, box)

	label(row, text, UDim2.new(1, -70, 1, 0), UDim2.fromOffset(26, 0),
		Enum.Font.GothamMedium, 14, C.Text, Enum.TextXAlignment.Left)
	if keyText then
		label(row, keyText, UDim2.fromOffset(40, 22), UDim2.new(1, -40, 0, 0),
			Enum.Font.GothamBold, 13, C.Text, Enum.TextXAlignment.Right)
	end

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
	}, row)

	local obj = { Value = default }

	local function render()
		tween(box, 0.15, { BackgroundColor3 = obj.Value and C.Accent or C.Off })
		tween(boxStroke, 0.15, { Transparency = obj.Value and 0 or 0.4 })
	end

	function obj.Set(v, silent)
		obj.Value = v
		render()
		if callback and not silent then
			callback(v)
		end
	end

	hit.MouseButton1Click:Connect(function()
		obj.Set(not obj.Value)
	end)

	onAccent(function()
		box.BackgroundColor3 = obj.Value and C.Accent or C.Off
		boxStroke.Color = C.Light
	end)

	return obj
end

local function slider(card, text, min, max, default, step, fmt, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(card),
	}, card)

	label(row, text, UDim2.new(0.6, 0, 0, 18), UDim2.fromOffset(0, 0),
		Enum.Font.GothamMedium, 14, C.Text, Enum.TextXAlignment.Left)
	local valueLabel = label(row, "", UDim2.new(0.4, 0, 0, 18), UDim2.new(0.6, 0, 0, 0),
		Enum.Font.GothamBold, 13, C.Light, Enum.TextXAlignment.Right)

	local minus = new("TextButton", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(0, 22),
		BackgroundTransparency = 1,
		Text = "-",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = C.Text,
	}, row)
	local plus = new("TextButton", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -18, 0, 22),
		BackgroundTransparency = 1,
		Text = "+",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = C.Text,
	}, row)

	local track = new("Frame", {
		Size = UDim2.new(1, -48, 0, 6),
		Position = UDim2.fromOffset(24, 29),
		BackgroundColor3 = C.Off,
		BorderSizePixel = 0,
	}, row)

	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
	}, track)

	local knob = new("Frame", {
		Size = UDim2.fromOffset(10, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, track)

	local hit = new("TextButton", {
		Size = UDim2.new(1, -44, 0, 22),
		Position = UDim2.fromOffset(22, 21),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
	}, row)

	local obj = { Value = default }

	function obj.Set(v, silent)
		v = math.clamp(v, min, max)
		v = math.floor(v / step + 0.5) * step
		v = math.clamp(v, min, max)
		obj.Value = v
		local ratio = (v - min) / (max - min)
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueLabel.Text = string.format(fmt, v)
		if callback and not silent then
			callback(v)
		end
	end

	local function updateFromX(x)
		local ratio = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		obj.Set(min + (max - min) * ratio)
	end

	local dragging = false
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	keep(UserInputService.InputChanged:Connect(function(input)
		if dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end))
	keep(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	minus.MouseButton1Click:Connect(function()
		obj.Set(obj.Value - step)
	end)
	plus.MouseButton1Click:Connect(function()
		obj.Set(obj.Value + step)
	end)

	onAccent(function()
		fill.BackgroundColor3 = C.Accent
	end)

	obj.Set(default, true)
	return obj
end

local function dropdown(card, text, options, default, callback)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(card),
	}, card)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, holder)

	local title = label(holder, text, UDim2.new(1, 0, 0, 18), nil,
		Enum.Font.GothamMedium, 14, C.Text, Enum.TextXAlignment.Left)
	title.LayoutOrder = 1

	local selector = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = C.Off,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = default,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	}, holder)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, selector)
	local selStroke = new("UIStroke", {
		Color = C.Light,
		Transparency = 0.4,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, selector)
	onAccent(function()
		selStroke.Color = C.Light
	end)
	local arrow = label(selector, "v", UDim2.fromOffset(24, 28), UDim2.new(1, -28, 0, 0),
		Enum.Font.GothamBold, 13, C.Light, Enum.TextXAlignment.Center)

	local list = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Dark,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Visible = false,
		LayoutOrder = 3,
	}, holder)
	new("UIStroke", {
		Color = C.Light,
		Transparency = 0.6,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, list)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local obj = { Value = default }

	function obj.Set(v, silent)
		obj.Value = v
		selector.Text = v
		list.Visible = false
		arrow.Text = "v"
		if callback and not silent then
			callback(v)
		end
	end

	for i, option in ipairs(options) do
		local opt = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = C.BtnHover,
			BackgroundTransparency = 1,
			Text = option,
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = i,
		}, list)
		new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, opt)
		opt.MouseEnter:Connect(function()
			opt.BackgroundTransparency = 0
		end)
		opt.MouseLeave:Connect(function()
			opt.BackgroundTransparency = 1
		end)
		opt.MouseButton1Click:Connect(function()
			obj.Set(option)
		end)
	end

	selector.MouseButton1Click:Connect(function()
		list.Visible = not list.Visible
		arrow.Text = list.Visible and "^" or "v"
	end)

	return obj
end

local function actionButton(card, text, callback)
	local btn = makeButton(card, text, UDim2.new(1, 0, 0, 30), nil)
	btn.LayoutOrder = nextOrder(card)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- 2) MAIN HUB -----------------------------------------------------------
local FULL_SIZE = UDim2.fromOffset(720, 470)
local MINI_SIZE = UDim2.fromOffset(720, 42)
local SHIFT_Y = (470 - 42) / 2

local main = glassPanel("Main", FULL_SIZE, UDim2.fromScale(0.5, 0.5), 70)
local unlocked = false

-- Top bar
local topBar = new("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundTransparency = 1,
}, main)

local logo = new("Frame", {
	Size = UDim2.fromOffset(26, 26),
	Position = UDim2.fromOffset(12, 8),
	BackgroundColor3 = C.Accent,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
}, topBar)
onAccent(function()
	logo.BackgroundColor3 = C.Accent
end)
label(logo, "X", UDim2.fromScale(1, 1), nil, Enum.Font.GothamBlack, 16, Color3.new(0, 0, 0))

label(topBar, "XAMA", UDim2.fromOffset(70, 42), UDim2.fromOffset(46, 0),
	Enum.Font.GothamBlack, 20, C.Text, Enum.TextXAlignment.Left)
label(topBar, "v2.0", UDim2.fromOffset(40, 42), UDim2.fromOffset(112, 0),
	Enum.Font.GothamMedium, 13, C.SubText, Enum.TextXAlignment.Left)

local minBtn = makeButton(topBar, "-", UDim2.fromOffset(28, 28), UDim2.new(1, -72, 0, 7))
minBtn.TextSize = 20
local closeBtn = makeButton(topBar, "X", UDim2.fromOffset(28, 28), UDim2.new(1, -38, 0, 7), C.Bad)

local topLine = new("Frame", {
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.fromOffset(12, 42),
	BackgroundColor3 = C.Light,
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
}, main)
onAccent(function()
	topLine.BackgroundColor3 = C.Light
end)

local content = new("Frame", {
	Name = "Content",
	Size = UDim2.new(1, 0, 1, -43),
	Position = UDim2.fromOffset(0, 43),
	BackgroundTransparency = 1,
}, main)

-- Status line
local footer = label(content, "Status: Ready", UDim2.new(1, -202, 0, 18), UDim2.new(0, 192, 1, -28),
	Enum.Font.GothamMedium, 13, C.SubText, Enum.TextXAlignment.Left)

local function notify(text)
	footer.Text = "Status: " .. text
end

-- Sidebar + pages
local sidebar = new("Frame", {
	Size = UDim2.new(0, 166, 1, -20),
	Position = UDim2.fromOffset(10, 10),
	BackgroundTransparency = 1,
}, content)

local sideLine = new("Frame", {
	Size = UDim2.new(0, 1, 1, -20),
	Position = UDim2.fromOffset(181, 10),
	BackgroundColor3 = C.Light,
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
}, content)
onAccent(function()
	sideLine.BackgroundColor3 = C.Light
end)

local pageHost = new("Frame", {
	Name = "Pages",
	Position = UDim2.fromOffset(192, 10),
	Size = UDim2.new(1, -202, 1, -48),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, content)

local pages = {}
local navButtons = {}
local currentPage = nil

local function newPage(name, topInset)
	topInset = topInset or 0
	local page = new("Frame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	}, pageHost)

	local scroll = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, topInset),
		Size = UDim2.new(1, 0, 1, -topInset),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.Light,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, page)

	local function column(scaleX, offsetX)
		local col = new("Frame", {
			Size = UDim2.new(0.5, -8, 0, 0),
			Position = UDim2.new(scaleX, offsetX, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, scroll)
		new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, col)
		return col
	end

	pages[name] = page
	return page, column(0, 0), column(0.5, 2)
end

local function showPage(name)
	currentPage = name
	for pageName, page in pairs(pages) do
		page.Visible = (pageName == name)
	end
	for navName, btn in pairs(navButtons) do
		tween(btn, 0.15, { BackgroundTransparency = (navName == name) and 0.8 or 1 })
	end
end

local navDefs = {
	{ "Combat", "Combat & Visuals", "C" },
	{ "Settings", "Configs & Theming", "S" },
}

for i, def in ipairs(navDefs) do
	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.fromOffset(0, (i - 1) * 60),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
	}, sidebar)
	onAccent(function()
		btn.BackgroundColor3 = C.Accent
	end)

	local iconBox = new("Frame", {
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.fromOffset(8, 9),
		BackgroundColor3 = C.Dark,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	}, btn)
	local iconStroke = new("UIStroke", {
		Color = C.Light,
		Transparency = 0.4,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, iconBox)
	onAccent(function()
		iconStroke.Color = C.Light
	end)
	label(iconBox, def[3], UDim2.fromScale(1, 1), nil, Enum.Font.GothamBlack, 16, C.Text)

	label(btn, def[1], UDim2.new(1, -56, 0, 20), UDim2.fromOffset(52, 9),
		Enum.Font.GothamBold, 15, C.Text, Enum.TextXAlignment.Left)
	label(btn, def[2], UDim2.new(1, -56, 0, 16), UDim2.fromOffset(52, 28),
		Enum.Font.Gotham, 12, C.SubText, Enum.TextXAlignment.Left)

	navButtons[def[1]] = btn
	btn.MouseButton1Click:Connect(function()
		showPage(def[1])
	end)
end

-- Controls we need to reach from other controls (presets, headshot checkbox, ...)
local ctl = {}

-- PAGE: COMBAT ------------------------------------------------------------
local combatPage, cLeft, cRight = newPage("Combat", 40)

local tabRow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundTransparency = 1,
}, combatPage)

local presetTabs = {}
for i, name in ipairs({ "Legit", "Rage" }) do
	local b = new("TextButton", {
		Size = UDim2.fromOffset(100, 28),
		Position = UDim2.fromOffset((i - 1) * 108, 2),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.9,
		AutoButtonColor = false,
		Text = name,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = C.Text,
		BorderSizePixel = 0,
	}, tabRow)
	new("UIStroke", {
		Color = C.Light,
		Transparency = 0.5,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, b)
	onAccent(function()
		b.BackgroundColor3 = C.Accent
	end)
	presetTabs[name] = b
end

local function highlightTab(name)
	for tabName, b in pairs(presetTabs) do
		tween(b, 0.15, { BackgroundTransparency = (tabName == name) and 0.7 or 0.95 })
	end
end
highlightTab("Legit")

-- Aimbot
local aimCard = section(cLeft, "Aimbot")

ctl.enabled = checkbox(aimCard, "Enabled", false, function(v)
	Aim.SetEnabled(v)
	notify(v and "Aimbot ON (put a target in the circle, Q = lock / release)" or "Aimbot OFF")
end, "Q")

ctl.aimType = dropdown(aimCard, "Type", { "Smooth", "Snap", "Sticky" }, "Smooth", function(v)
	S.AimType = v
	notify("Aim type: " .. v)
end)

ctl.visible = checkbox(aimCard, "Visible Check", true, function(v)
	S.VisibleCheck = v
end)

ctl.lowest = checkbox(aimCard, "Lowest Health", false, function(v)
	S.LowestHealth = v
end)

ctl.distance = slider(aimCard, "Distance", 50, 2000, 150, 10, "%d studs", function(v)
	S.MaxDistance = v
end)

ctl.delay = slider(aimCard, "Aim Delay", 0, 500, 0, 10, "%dms", function(v)
	S.AimDelay = v
end)

ctl.smoothX = slider(aimCard, "Smoothing X", 0, 100, 27, 1, "%d%%", function(v)
	S.SmoothX = v / 100
end)

ctl.smoothY = slider(aimCard, "Smoothing Y", 0, 100, 50, 1, "%d%%", function(v)
	S.SmoothY = v / 100
end)

ctl.intensity = slider(aimCard, "Intensity", 0.1, 4, 1, 0.1, "%.1fx", function(v)
	S.Intensity = v
end)

-- Combat
local combatCard = section(cLeft, "Combat")

ctl.silent = checkbox(combatCard, "Silent Aim", false, function(v)
	Bridge.SilentAim = v
	notify("Silent Aim " .. (v and "ON" or "OFF") .. " (read _G.Xama.SilentAim in your gun script)")
end)

ctl.hitChance = slider(combatCard, "Hit Chance", 0, 100, 90, 1, "%d%%", function(v)
	S.HitChance = v / 100
	Bridge.HitChance = S.HitChance
	Aim.Reroll()
end)

-- Discord
local discordCard = section(cRight, "Discord")
actionButton(discordCard, "Join Discord!", function()
	notify("Discord: " .. DISCORD_LINK)
	print("Xama Discord: " .. DISCORD_LINK)
end)

-- Target
local targetCard = section(cRight, "Target")

ctl.hitPart = dropdown(targetCard, "Hit Parts", { "Random", "Head", "Torso" }, "Random", function(v)
	S.HitPart = v
	Aim.Reroll()
	notify("Hit part: " .. v .. (v == "Random" and " (40% head / 50% body)" or ""))
end)

ctl.headOnly = checkbox(targetCard, "Headshot Only", false, function(v)
	ctl.hitPart.Set(v and "Head" or "Random")
end)

ctl.fovOn = checkbox(targetCard, "FOV", true, function(v)
	S.FovOn = v
	Aim.RefreshCircle()
end)

ctl.fovFill = checkbox(targetCard, "FOV Fill", false, function(v)
	S.FovFill = v
	Aim.RefreshCircle()
end)

ctl.fovRange = slider(targetCard, "FOV Range", 40, 600, 120, 5, "%dpx", function(v)
	S.FovRadius = v
	Aim.RefreshCircle()
end)

ctl.fovMethod = dropdown(targetCard, "FOV Method", { "Center", "Mouse" }, "Center", function(v)
	S.FovMethod = v
	Aim.RefreshCircle()
end)

-- Gun Modifiers
local gunCard = section(cRight, "Gun Modifiers")

ctl.noRecoil = checkbox(gunCard, "No Recoil", false, function(v)
	Bridge.NoRecoil = v
	notify("No Recoil " .. (v and "ON" or "OFF") .. " (read _G.Xama.NoRecoil in your gun script)")
end)

ctl.noSpread = checkbox(gunCard, "No Spread", false, function(v)
	Bridge.NoSpread = v
	notify("No Spread " .. (v and "ON" or "OFF") .. " (read _G.Xama.NoSpread in your gun script)")
end)

-- Legit / Rage presets
local function applyPreset(name)
	highlightTab(name)
	if name == "Legit" then
		ctl.aimType.Set("Smooth")
		ctl.distance.Set(200)
		ctl.smoothX.Set(60)
		ctl.smoothY.Set(70)
		ctl.intensity.Set(1)
		ctl.fovRange.Set(100)
		ctl.hitChance.Set(85)
	else
		ctl.aimType.Set("Sticky")
		ctl.distance.Set(500)
		ctl.smoothX.Set(0)
		ctl.smoothY.Set(0)
		ctl.intensity.Set(2)
		ctl.fovRange.Set(250)
		ctl.hitChance.Set(100)
	end
	notify(name .. " preset loaded")
end

for name, b in pairs(presetTabs) do
	b.MouseButton1Click:Connect(function()
		applyPreset(name)
	end)
end

-- Visuals are controlled from the Combat page.
local espCard = section(cLeft, "ESP")

ctl.chams = checkbox(espCard, "Chams (nearest players)", true, function(v)
	S.Chams = v
	Visuals.Update()
	notify("Chams " .. (v and "ON" or "OFF"))
end)

ctl.nameEsp = checkbox(espCard, "Name ESP", false, function(v)
	S.NameESP = v
	Visuals.Update()
	notify("Name ESP " .. (v and "ON" or "OFF"))
end)

ctl.chamsCount = slider(espCard, "How many players", 1, 10, 3, 1, "%d", function(v)
	S.ChamsCount = v
	Visuals.Update()
end)

ctl.chamsRange = slider(espCard, "Range", 50, 1000, 300, 10, "%d studs", function(v)
	S.ChamsRange = v
	Visuals.Update()
end)

local colorCard = section(cRight, "Chams Colors")

ctl.fillColor = dropdown(colorCard, "Fill Color", COLOR_NAMES, "Red", function(v)
	S.FillColor = v
	Visuals.Update()
end)

ctl.outlineColor = dropdown(colorCard, "Outline Color", COLOR_NAMES, "Purple", function(v)
	S.OutlineColor = v
	Visuals.Update()
end)

ctl.fillTransparency = slider(colorCard, "Fill Transparency", 0, 100, 35, 1, "%d%%", function(v)
	S.FillTransparency = v / 100
	Visuals.Update()
end)
Visuals.Update()

-- Fly control lives on the Combat page; K toggles it.
local flyEnabled = false
local flyVelocity, flyGyro, flyHumanoid, flyRoot, flyConn
local flyOriginalAutoRotate

local function stopFlying()
	flyEnabled = false
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end
	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end
	if flyHumanoid and flyHumanoid.Parent and flyOriginalAutoRotate ~= nil then
		flyHumanoid.AutoRotate = flyOriginalAutoRotate
	end
	flyHumanoid, flyRoot, flyOriginalAutoRotate = nil, nil, nil
end

local function startFlying()
	stopFlying()
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not hum or not root then
		return false
	end

	flyEnabled = true
	flyHumanoid, flyRoot = hum, root
	flyOriginalAutoRotate = hum.AutoRotate
	hum.AutoRotate = false

	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.Name = "XamaFlyVelocity"
	flyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	flyVelocity.P = 1e4
	flyVelocity.Velocity = Vector3.zero
	flyVelocity.Parent = root

	flyGyro = Instance.new("BodyGyro")
	flyGyro.Name = "XamaFlyGyro"
	flyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	flyGyro.P = 1e4
	flyGyro.CFrame = root.CFrame
	flyGyro.Parent = root

	flyConn = RunService.RenderStepped:Connect(function()
		if not flyEnabled or not flyRoot or not flyRoot.Parent then
			stopFlying()
			return
		end
		local camera = workspace.CurrentCamera
		if not camera then return end
		local look = camera.CFrame.LookVector
		local direction = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += look end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= look end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			direction -= Vector3.yAxis
		end
		if direction.Magnitude > 1 then direction = direction.Unit end
		flyVelocity.Velocity = direction * 60
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude > 0.001 then
			flyGyro.CFrame = CFrame.lookAt(flyRoot.Position, flyRoot.Position + flatLook.Unit)
		end
	end)
	return true
end

keep(player.CharacterAdded:Connect(function()
	if flyEnabled then
		stopFlying()
	end
	if ctl.fly and ctl.fly.Value then
		task.wait()
		startFlying()
	end
end))

local flyCard = section(cLeft, "Movement")
ctl.fly = checkbox(flyCard, "Fly", false, function(v)
	if v then
		if not startFlying() then
			ctl.fly.Set(false, true)
			notify("Fly unavailable: character not ready")
			return
		end
		notify("Fly ON (WASD, Space/Ctrl; K to toggle)")
	else
		stopFlying()
		notify("Fly OFF")
	end
end, "K")

-- PAGE: SETTINGS ------------------------------------------------------------
local _, sLeft, sRight = newPage("Settings", 0)

-- Locally hide texture layers to reduce visual overhead; keep originals so the
-- setting can be switched off without permanently changing instances.
local TextureReducer = {
	enabled = false,
	originals = {},
	connection = nil,
}

local function reduceTexture(inst)
	local properties = nil
	if inst:IsA("Decal") or inst:IsA("Texture") then
		properties = { { "Transparency", 1 } }
	elseif inst:IsA("SpecialMesh") then
		properties = { { "TextureId", "" } }
	elseif inst:IsA("SurfaceAppearance") then
		properties = {
			{ "ColorMap", "" },
			{ "MetalnessMap", "" },
			{ "NormalMap", "" },
			{ "RoughnessMap", "" },
		}
	end

	if not properties then return end
	local saved = TextureReducer.originals[inst]
	if not saved then
		saved = {}
		TextureReducer.originals[inst] = saved
	end
	for _, entry in ipairs(properties) do
		local property, replacement = entry[1], entry[2]
		if saved[property] == nil then
			local ok, value = pcall(function() return inst[property] end)
			if ok then
				saved[property] = value
				pcall(function() inst[property] = replacement end)
			end
		end
	end
end

function TextureReducer.SetEnabled(enabled)
	if TextureReducer.enabled == enabled then return end
	TextureReducer.enabled = enabled
	if enabled then
		for _, inst in ipairs(workspace:GetDescendants()) do
			reduceTexture(inst)
		end
		TextureReducer.connection = workspace.DescendantAdded:Connect(function(inst)
			if TextureReducer.enabled then
				reduceTexture(inst)
			end
		end)
	else
		if TextureReducer.connection then
			TextureReducer.connection:Disconnect()
			TextureReducer.connection = nil
		end
		for inst, saved in pairs(TextureReducer.originals) do
			for property, value in pairs(saved) do
				pcall(function() inst[property] = value end)
			end
		end
		table.clear(TextureReducer.originals)
	end
end

local unloading = false

local function unload()
	if unloading then
		return
	end
	unloading = true
	unlocked = false
		stopFlying()
	Aim.SetEnabled(false)

		Visuals.Shutdown()
	TextureReducer.SetEnabled(false)

	for _, c in ipairs(allConns) do
		c:Disconnect()
	end
	table.clear(allConns)
	_G.Xama = nil
	closePanel(main, function()
		gui:Destroy()
		if blur then
			blur:Destroy()
		end
	end)
end

local menuCard = section(sLeft, "Menu")

ctl.accent = dropdown(menuCard, "Accent", THEME_NAMES, "White", function(v)
	applyTheme(THEMES[v])
	notify("Accent: " .. v)
end)

actionButton(menuCard, "Unload XAMA", function()
	unload()
end)

-- SAVE / LOAD SETTINGS ---------------------------------------------------
-- Saves every control (checkboxes, sliders, dropdowns) in ctl.
-- Always kept in _G.XamaSaved, so it survives Unload + re-running the script.
-- If the server-side settings RemoteFunction exists, settings also persist between sessions.
local function getRemote()
	return ReplicatedStorage:FindFirstChild("XamaSettings")
end

local function collectSettings()
	local data = {}
	for key, c in pairs(ctl) do
		local v = c.Value
		local t = type(v)
		if t == "boolean" or t == "number" or t == "string" then
			data[key] = v
		end
	end
	return data
end

local function applySettings(data)
	for key, v in pairs(data) do
		local c = ctl[key]
		-- headOnly is just a shortcut for Hit Parts = Head, so it is synced after
		if c and key ~= "headOnly" and type(v) == type(c.Value) then
			c.Set(v)
		end
	end
	if ctl.headOnly then
		ctl.headOnly.Set(ctl.hitPart.Value == "Head", true)
	end
end

local function saveSettings()
	local data = collectSettings()
	_G.XamaSaved = data

	local remote = getRemote()
	if remote then
		local ok, result = pcall(function()
			return remote:InvokeServer("Save", data)
		end)
		if ok and result then
			notify("Settings saved (permanent)")
		else
			notify("Saved for this session (server save failed)")
		end
	else
		notify("Settings saved (this session only)")
	end
end

local function loadSettings(silentIfEmpty)
	local data = nil

	local remote = getRemote()
	if remote then
		local ok, result = pcall(function()
			return remote:InvokeServer("Load")
		end)
		if ok and type(result) == "table" then
			data = result
		end
	end
	data = data or _G.XamaSaved

	if type(data) ~= "table" then
		if not silentIfEmpty then
			notify("No saved settings yet")
		end
		return
	end

	applySettings(data)
	_G.XamaSaved = data
	notify("Settings loaded")
end

local configCard = section(sLeft, "Config")
actionButton(configCard, "Save Settings", saveSettings)
actionButton(configCard, "Load Settings", function()
	loadSettings(false)
end)

local targetsCard = section(sRight, "Targets")

ctl.teamCheck = checkbox(targetsCard, "Team Check", true, function(v)
	S.TeamCheck = v
end)

ctl.includeNpcs = checkbox(targetsCard, "Include NPCs / Dummies", true, function(v)
	S.IncludeNPCs = v
	Visuals.Update()
end)

local performanceCard = section(sRight, "Performance")
ctl.textureReducer = checkbox(performanceCard, "Remove Textures", false, function(v)
	TextureReducer.SetEnabled(v)
	notify(v and "Texture layers hidden locally" or "Textures restored")
end)

local infoCard = section(sRight, "Keys")
label(infoCard, "RightShift: hide / show menu\nQ: lock on / release (aimbot)", UDim2.new(1, 0, 0, 34), nil,
	Enum.Font.Gotham, 13, C.SubText, Enum.TextXAlignment.Left).LayoutOrder = nextOrder(infoCard)

showPage("Combat")

-- Drag / minimize / close --------------------------------------------------
makeDraggable(topBar, main)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		content.Visible = false
		minBtn.Text = "+"
		tween(main, 0.3, {
			Size = MINI_SIZE,
			Position = main.Position - UDim2.fromOffset(0, SHIFT_Y),
		}, Enum.EasingStyle.Quint)
	else
		content.Visible = true
		minBtn.Text = "-"
		tween(main, 0.3, {
			Size = FULL_SIZE,
			Position = main.Position + UDim2.fromOffset(0, SHIFT_Y),
		}, Enum.EasingStyle.Quint)
	end
end)

closeBtn.MouseButton1Click:Connect(unload)

keep(UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not unlocked then
		return
	end
	if input.KeyCode == MENU_KEY then
		main.Visible = not main.Visible
	elseif input.KeyCode == Enum.KeyCode.K then
		ctl.fly.Set(not ctl.fly.Value)
	end
end))


-- START: loading sequence, then straight into the hub --------------------
task.spawn(function()
	tween(blur, 0.6, { Size = 16 })
	openPanel(loadPanel)

	local steps = {
		"Connecting Root Bypass.roblox.byfron-rivalsanticht ...",
		"Verifying Game modules...",
		"Creating the button interface...",
		"Connected to...",
	}

	for i, step in ipairs(steps) do
		loadStatus.Text = step
		tween(barFill, 0.5, { Size = UDim2.fromScale(i / #steps, 1) })
		task.wait(0.7)
	end

	task.wait(0.2)
	closePanel(loadPanel)
	task.wait(0.4)
	tween(blur, 0.5, { Size = 0 })
	unlocked = true
	openPanel(main)

		-- Restore settings after the menu's opening animation has finished.
	task.wait(0.4)
	loadSettings(true)
end)
