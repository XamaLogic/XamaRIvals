local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
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
	Red = { Accent = Color3.fromRGB(235, 35, 50), Light = Color3.fromRGB(255, 95, 105), Dim = Color3.fromRGB(100, 16, 24) },
	Crimson = { Accent = Color3.fromRGB(190, 20, 48), Light = Color3.fromRGB(235, 75, 100), Dim = Color3.fromRGB(80, 12, 26) },
	Orange = { Accent = Color3.fromRGB(255, 110, 25), Light = Color3.fromRGB(255, 165, 85), Dim = Color3.fromRGB(105, 46, 10) },
	Pink = { Accent = Color3.fromRGB(255, 60, 140), Light = Color3.fromRGB(255, 130, 185), Dim = Color3.fromRGB(105, 24, 62) },
	White = { Accent = Color3.fromRGB(255, 255, 255), Light = Color3.fromRGB(190, 190, 190), Dim = Color3.fromRGB(80, 80, 80) },
}
local THEME_NAMES = { "Red", "Crimson", "Orange", "Pink", "White" }

local C = {
	Dark = Color3.fromRGB(9, 9, 10),
	Navy = Color3.fromRGB(16, 16, 18),
	Panel = Color3.fromRGB(17, 17, 19),
	Border = Color3.fromRGB(44, 44, 50),
	Line = Color3.fromRGB(30, 30, 34),
	Accent = THEMES.Red.Accent,
	Light = THEMES.Red.Light,
	Dim = THEMES.Red.Dim,
	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(150, 150, 156),
	Good = Color3.fromRGB(90, 255, 140),
	Bad = Color3.fromRGB(70, 16, 22),
	Off = Color3.fromRGB(34, 34, 38),
	Btn = Color3.fromRGB(22, 22, 25),
	BtnHover = Color3.fromRGB(40, 40, 46),
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

-- Slightly rounded corners (3px) on everything
local function corner(obj, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 3) }, obj)
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
	C.Dim = theme.Dim or C.Dim
	for _, fn in ipairs(accentUpdaters) do
		pcall(fn)
	end
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

-- Window: dark body, thin red border, soft red glow behind it ----------------
-- Returns (wrapper, body). The wrapper is what gets moved / scaled / shown;
-- everything you put inside the window goes into body.
local function makeWindow(name, size, position)
	local wrap = new("Frame", {
		Name = name,
		Size = size,
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)

	-- subtle glow: a few faint, slightly larger red layers behind the body
	local glowAlpha = { 0.88, 0.92, 0.95, 0.975 }
	for i, alpha in ipairs(glowAlpha) do
		local pad = i * 3
		local glow = new("Frame", {
			Name = "Glow" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, pad * 2, 1, pad * 2),
			BackgroundColor3 = C.Accent,
			BackgroundTransparency = alpha,
			BorderSizePixel = 0,
			ZIndex = 0,
		}, wrap)
		corner(glow, 4 + pad)
		onAccent(function()
			glow.BackgroundColor3 = C.Accent
		end)
	end

	local body = new("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	}, wrap)
	corner(body, 4)
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 22)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 9)),
		}),
		Rotation = 90,
	}, body)

	local stroke = new("UIStroke", {
		Color = C.Accent,
		Thickness = 1,
		Transparency = 0.1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, body)
	onAccent(function()
		stroke.Color = C.Accent
	end)

	new("UIScale", { Scale = 1 }, wrap)
	return wrap, body
end

local function openPanel(panel)
	local scale = panel:FindFirstChildOfClass("UIScale")
	local base = panel:GetAttribute("BaseScale") or 1
	scale.Scale = base * 0.92
	panel.Visible = true
	tween(scale, 0.25, { Scale = base }, Enum.EasingStyle.Back)
end

local function closePanel(panel, callback)
	local scale = panel:FindFirstChildOfClass("UIScale")
	local base = panel:GetAttribute("BaseScale") or 1
	tween(scale, 0.18, { Scale = base * 0.94 })
	task.delay(0.2, function()
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
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.Text,
		BorderSizePixel = 0,
	}, parent)
	corner(btn, 3)

	local stroke = new("UIStroke", {
		Color = C.Dim,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, btn)
	onAccent(function()
		stroke.Color = C.Dim
	end)

	btn.MouseEnter:Connect(function()
		tween(btn, 0.12, { BackgroundColor3 = C.BtnHover })
		tween(stroke, 0.12, { Color = C.Accent })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.12, { BackgroundColor3 = base })
		tween(stroke, 0.12, { Color = C.Dim })
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, 0.06, { BackgroundColor3 = C.Dim })
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, 0.1, { BackgroundColor3 = C.BtnHover })
	end)

	return btn
end

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

local function playersAreTeammates(a, b)
	if not a or not b then return false end
	-- Prefer Roblox Team instances. TeamColor is a fallback for games that
	-- assign teams by color instead of assigning the Team property.
	if a.Team ~= nil and b.Team ~= nil then
		return a.Team == b.Team
	end
	if not a.Neutral and not b.Neutral then
		return a.TeamColor == b.TeamColor
	end
	return false
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
		if not ignoreTeam and S.TeamCheck and playersAreTeammates(owner, player) then
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

-- UI CONTROLS (compact) -------------------------------------------------
local orderCounters = setmetatable({}, { __mode = "k" })

local function nextOrder(parent)
	orderCounters[parent] = (orderCounters[parent] or 0) + 1
	return orderCounters[parent]
end

-- tween (or instantly set) a few properties
local function apply(obj, props, instant)
	if instant then
		for k, v in pairs(props) do
			obj[k] = v
		end
	else
		tween(obj, 0.15, props)
	end
end

-- thin separator along the bottom of a row
local function rowLine(row)
	new("Frame", {
		Name = "Sep",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.Line,
		BorderSizePixel = 0,
	}, row)
end

-- A compact boxed group with a small red title
local function section(column, title)
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(column),
	}, column)
	corner(card, 3)
	new("UIStroke", {
		Color = C.Border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, card)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 3),
	}, card)
	new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, card)

	local head = new("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
	}, card)
	local titleLabel = label(head, string.upper(title), UDim2.new(1, 0, 1, 0), nil,
		Enum.Font.GothamBold, 11, C.Accent, Enum.TextXAlignment.Left)
	local headLine = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
	}, head)
	onAccent(function()
		titleLabel.TextColor3 = C.Accent
		headLine.BackgroundColor3 = C.Accent
	end)
	return card
end

-- Checkbox with a red checkmark
local function checkbox(card, text, default, callback, keyText)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(card),
	}, card)
	rowLine(row)

	local box = new("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(0, 6),
		BackgroundColor3 = C.Off,
		BorderSizePixel = 0,
	}, row)
	corner(box, 2)
	local boxStroke = new("UIStroke", {
		Color = C.Border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, box)

	-- the checkmark is two small rotated bars
	local checkShort = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(3.5, 7.5),
		Size = UDim2.fromOffset(2, 5),
		Rotation = -45,
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, box)
	local checkLong = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(7.5, 6),
		Size = UDim2.fromOffset(2, 8),
		Rotation = 45,
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, box)

	label(row, text, UDim2.new(1, -60, 1, -1), UDim2.fromOffset(20, 0),
		Enum.Font.GothamMedium, 12, C.Text, Enum.TextXAlignment.Left)
	if keyText then
		label(row, "[" .. keyText .. "]", UDim2.fromOffset(34, 23), UDim2.new(1, -34, 0, 0),
			Enum.Font.GothamMedium, 11, C.SubText, Enum.TextXAlignment.Right)
	end

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
	}, row)

	local obj = { Value = default }

	local function render(instant)
		local on = obj.Value
		apply(boxStroke, { Color = on and C.Accent or C.Border }, instant)
		apply(checkShort, { BackgroundTransparency = on and 0 or 1, BackgroundColor3 = C.Accent }, instant)
		apply(checkLong, { BackgroundTransparency = on and 0 or 1, BackgroundColor3 = C.Accent }, instant)
	end

	function obj.Set(v, silent)
		obj.Value = v
		render(false)
		if callback and not silent then
			callback(v)
		end
	end

	hit.MouseButton1Click:Connect(function()
		obj.Set(not obj.Value)
	end)

	onAccent(function()
		render(true)
	end)

	return obj
end

-- Red toggle switch (same arguments as checkbox)
local function toggle(card, text, default, callback, keyText)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(card),
	}, card)
	rowLine(row)

	label(row, text, UDim2.new(1, -70, 1, -1), UDim2.fromOffset(0, 0),
		Enum.Font.GothamMedium, 12, C.Text, Enum.TextXAlignment.Left)
	if keyText then
		label(row, "[" .. keyText .. "]", UDim2.fromOffset(34, 23), UDim2.new(1, -66, 0, 0),
			Enum.Font.GothamMedium, 11, C.SubText, Enum.TextXAlignment.Right)
	end

	local track = new("Frame", {
		Size = UDim2.fromOffset(26, 12),
		Position = UDim2.new(1, -26, 0, 5),
		BackgroundColor3 = C.Off,
		BorderSizePixel = 0,
	}, row)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
	local trackStroke = new("UIStroke", {
		Color = C.Border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, track)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = C.SubText,
		BorderSizePixel = 0,
	}, track)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
	}, row)

	local obj = { Value = default }

	local function render(instant)
		local on = obj.Value
		apply(track, { BackgroundColor3 = on and C.Accent or C.Off }, instant)
		apply(trackStroke, { Color = on and C.Accent or C.Border }, instant)
		apply(knob, {
			Position = UDim2.fromOffset(on and 16 or 2, 2),
			BackgroundColor3 = on and Color3.new(1, 1, 1) or C.SubText,
		}, instant)
	end

	function obj.Set(v, silent)
		obj.Value = v
		render(false)
		if callback and not silent then
			callback(v)
		end
	end

	hit.MouseButton1Click:Connect(function()
		obj.Set(not obj.Value)
	end)

	onAccent(function()
		render(true)
	end)

	return obj
end

-- Slider: label + value on top, thin track with a red fill underneath
local function slider(card, text, min, max, default, step, fmt, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(card),
	}, card)
	rowLine(row)

	label(row, text, UDim2.new(0.6, 0, 0, 14), UDim2.fromOffset(0, 3),
		Enum.Font.GothamMedium, 12, C.Text, Enum.TextXAlignment.Left)
	local valueLabel = label(row, "", UDim2.new(0.4, 0, 0, 14), UDim2.new(0.6, 0, 0, 3),
		Enum.Font.GothamMedium, 11, C.Light, Enum.TextXAlignment.Right)

	local track = new("Frame", {
		Size = UDim2.new(1, -6, 0, 4),
		Position = UDim2.fromOffset(3, 21),
		BackgroundColor3 = C.Off,
		BorderSizePixel = 0,
	}, row)
	corner(track, 2)

	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
	}, track)
	corner(fill, 2)

	local knob = new("Frame", {
		Size = UDim2.fromOffset(6, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, track)
	corner(knob, 2)

	local hit = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 15),
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

	onAccent(function()
		fill.BackgroundColor3 = C.Accent
		valueLabel.TextColor3 = C.Light
	end)

	obj.Set(default, true)
	return obj
end

-- Dropdown: label on the left, small selector on the right
local function dropdown(card, text, options, default, callback)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(card),
	}, card)
	new("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, holder)

	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, holder)
	rowLine(row)

	label(row, text, UDim2.new(1, -104, 1, -1), UDim2.fromOffset(0, 0),
		Enum.Font.GothamMedium, 12, C.Text, Enum.TextXAlignment.Left)

	local selector = new("TextButton", {
		Size = UDim2.fromOffset(98, 18),
		Position = UDim2.new(1, -98, 0, 3),
		BackgroundColor3 = C.Off,
		AutoButtonColor = false,
		Text = default,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
	}, row)
	corner(selector, 3)
	new("UIPadding", { PaddingLeft = UDim.new(0, 6) }, selector)
	local selStroke = new("UIStroke", {
		Color = C.Border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, selector)
	local arrow = label(selector, "v", UDim2.fromOffset(16, 18), UDim2.new(1, -18, 0, 0),
		Enum.Font.GothamBold, 10, C.Accent, Enum.TextXAlignment.Center)
	onAccent(function()
		arrow.TextColor3 = C.Accent
	end)

	local list = new("Frame", {
		Size = UDim2.new(0, 98, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Dark,
		BorderSizePixel = 0,
		Visible = false,
		LayoutOrder = 2,
	}, holder)
	corner(list, 3)
	local listStroke = new("UIStroke", {
		Color = C.Dim,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, list)
	onAccent(function()
		listStroke.Color = C.Dim
	end)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local obj = { Value = default }

	function obj.Set(v, silent)
		obj.Value = v
		selector.Text = v
		list.Visible = false
		arrow.Text = "v"
		tween(selStroke, 0.12, { Color = C.Border })
		if callback and not silent then
			callback(v)
		end
	end

	for i, option in ipairs(options) do
		local opt = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundColor3 = C.Dim,
			BackgroundTransparency = 1,
			Text = option,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = i,
		}, list)
		new("UIPadding", { PaddingLeft = UDim.new(0, 6) }, opt)
		opt.MouseEnter:Connect(function()
			opt.BackgroundColor3 = C.Dim
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
		tween(selStroke, 0.12, { Color = list.Visible and C.Accent or C.Border })
	end)

	return obj
end

local function actionButton(card, text, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(card),
	}, card)
	local btn = makeButton(row, text, UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 4))
	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- 2) MAIN HUB -----------------------------------------------------------
local FULL_SIZE = UDim2.fromOffset(680, 420)
local MINI_SIZE = UDim2.fromOffset(680, 26)
local SHIFT_Y = (420 - 26) / 2

local main, mainBody = makeWindow("Main", FULL_SIZE, UDim2.fromScale(0.5, 0.5))
local unlocked = false

-- Pick a comfortable size for this screen (changeable in Settings > UI Size)
local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
local defaultScale = math.clamp(math.min(viewport.X / 760, viewport.Y / 480), 0.6, 1.45)
main:SetAttribute("BaseScale", defaultScale)

local function setUiScale(s)
	main:SetAttribute("BaseScale", s)
	local sc = main:FindFirstChildOfClass("UIScale")
	if sc and main.Visible then
		tween(sc, 0.15, { Scale = s })
	end
end

-- Top bar
local topBar = new("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundTransparency = 1,
}, mainBody)

local logo = new("Frame", {
	Size = UDim2.fromOffset(14, 14),
	Position = UDim2.fromOffset(8, 6),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
}, topBar)
corner(logo, 3)
onAccent(function()
	logo.BackgroundColor3 = C.Accent
end)
label(logo, "X", UDim2.fromScale(1, 1), nil, Enum.Font.GothamBlack, 10, Color3.new(0, 0, 0))

label(topBar, "XAMA", UDim2.fromOffset(44, 26), UDim2.fromOffset(28, 0),
	Enum.Font.GothamBlack, 12, C.Text, Enum.TextXAlignment.Left)
label(topBar, "v2.0", UDim2.fromOffset(30, 26), UDim2.fromOffset(72, 0),
	Enum.Font.GothamMedium, 10, C.SubText, Enum.TextXAlignment.Left)

local minBtn = makeButton(topBar, "-", UDim2.fromOffset(18, 18), UDim2.new(1, -46, 0, 4))
local closeBtn = makeButton(topBar, "x", UDim2.fromOffset(18, 18), UDim2.new(1, -24, 0, 4), C.Bad)

local topLine = new("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.fromOffset(0, 26),
	BackgroundColor3 = C.Accent,
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
}, mainBody)
onAccent(function()
	topLine.BackgroundColor3 = C.Accent
end)

local content = new("Frame", {
	Name = "Content",
	Size = UDim2.new(1, 0, 1, -27),
	Position = UDim2.fromOffset(0, 27),
	BackgroundTransparency = 1,
}, mainBody)

-- Status line along the bottom
local footerBar = new("Frame", {
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 1, -20),
	BackgroundTransparency = 1,
}, content)
new("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = C.Line,
	BorderSizePixel = 0,
}, footerBar)
local footer = label(footerBar, "Status: Ready", UDim2.new(1, -16, 1, 0), UDim2.fromOffset(8, 0),
	Enum.Font.GothamMedium, 11, C.SubText, Enum.TextXAlignment.Left)

local function notify(text)
	footer.Text = "Status: " .. text
end

-- Sidebar + pages
local sidebar = new("Frame", {
	Size = UDim2.new(0, 128, 1, -32),
	Position = UDim2.fromOffset(6, 6),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
}, content)
corner(sidebar, 3)
new("UIStroke", {
	Color = C.Border,
	Thickness = 1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, sidebar)
new("UIPadding", {
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 4),
	PaddingRight = UDim.new(0, 4),
}, sidebar)
new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)

local pageHost = new("Frame", {
	Name = "Pages",
	Position = UDim2.fromOffset(142, 6),
	Size = UDim2.new(1, -148, 1, -32),
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
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = C.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, page)
	onAccent(function()
		scroll.ScrollBarImageColor3 = C.Accent
	end)

	local function column(scaleX, offsetX, widthOffset)
		local col = new("Frame", {
			Size = UDim2.new(0.5, widthOffset, 0, 0),
			Position = UDim2.new(scaleX, offsetX, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, scroll)
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, col)
		return col
	end

	pages[name] = page
	return page, column(0, 0, -4), column(0.5, 4, -8)
end

-- Tiny vector icons built from frames / strokes (no image ids needed)
local function paintIcon(icon, color)
	for _, d in ipairs(icon:GetDescendants()) do
		if d:IsA("UIStroke") then
			d.Color = color
		elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = color
		end
	end
end

local function buildIcon(kind, parent)
	local icon = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, parent)

	local function rect(x, y, w, h, round)
		local f = new("Frame", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = C.SubText,
			BorderSizePixel = 0,
		}, icon)
		if round then
			new("UICorner", { CornerRadius = UDim.new(round, 0) }, f)
		end
		return f
	end

	local function ring(x, y, w, h)
		local f = new("Frame", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, h),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, icon)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
		new("UIStroke", {
			Color = C.SubText,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, f)
		return f
	end

	if kind == "main" then
		rect(0, 0, 6, 6)
		rect(8, 0, 6, 6)
		rect(0, 8, 6, 6)
		rect(8, 8, 6, 6)
	elseif kind == "combat" then
		ring(1, 1, 12, 12)
		rect(6, 6, 2, 2)
		rect(6, 0, 2, 3)
		rect(6, 11, 2, 3)
		rect(0, 6, 3, 2)
		rect(11, 6, 3, 2)
	elseif kind == "visuals" then
		ring(0, 3, 14, 8)
		rect(5, 5, 4, 4, 1)
	elseif kind == "movement" then
		rect(0, 2, 10, 2)
		rect(4, 6, 10, 2)
		rect(1, 10, 8, 2)
	elseif kind == "players" then
		rect(4, 0, 6, 6, 1)
		rect(1, 8, 12, 6, 0.5)
	else -- settings: three little sliders
		rect(2, 0, 2, 14)
		rect(6, 0, 2, 14)
		rect(10, 0, 2, 14)
		rect(0, 3, 6, 3)
		rect(4, 8, 6, 3)
		rect(8, 5, 6, 3)
	end

	paintIcon(icon, C.SubText)
	return icon
end

local function showPage(name)
	local previous = currentPage
	currentPage = name
	for pageName, page in pairs(pages) do
		if pageName == name then
			page.Visible = true
			if previous ~= name then
				-- small slide-in when switching tabs
				page.Position = UDim2.fromOffset(12, 0)
				tween(page, 0.2, { Position = UDim2.fromOffset(0, 0) })
			end
		else
			page.Visible = false
		end
	end
	for navName, nav in pairs(navButtons) do
		local on = (navName == name)
		tween(nav.Button, 0.15, { BackgroundTransparency = on and 0.6 or 1 })
		tween(nav.Bar, 0.15, { BackgroundTransparency = on and 0 or 1 })
		tween(nav.Label, 0.15, { TextColor3 = on and C.Text or C.SubText })
		paintIcon(nav.Icon, on and C.Accent or C.SubText)
	end
end

local navDefs = {
	{ "Main", "main" },
	{ "Combat", "combat" },
	{ "Visuals", "visuals" },
	{ "Movement", "movement" },
	{ "Players", "players" },
	{ "Settings", "settings" },
}

for i, def in ipairs(navDefs) do
	local name, iconKind = def[1], def[2]

	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		LayoutOrder = i * 2,
	}, sidebar)
	corner(btn, 3)

	local bar = new("Frame", {
		Size = UDim2.new(0, 2, 1, -8),
		Position = UDim2.fromOffset(0, 4),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, btn)

	local icon = buildIcon(iconKind, btn)
	local text = label(btn, name, UDim2.new(1, -30, 1, 0), UDim2.fromOffset(30, 0),
		Enum.Font.GothamMedium, 12, C.SubText, Enum.TextXAlignment.Left)

	navButtons[name] = { Button = btn, Bar = bar, Label = text, Icon = icon }

	-- keep the selected tab red after an accent change
	onAccent(function()
		local on = (currentPage == name)
		btn.BackgroundColor3 = C.Accent
		bar.BackgroundColor3 = C.Accent
		paintIcon(icon, on and C.Accent or C.SubText)
	end)

	btn.MouseEnter:Connect(function()
		if currentPage ~= name then
			tween(btn, 0.1, { BackgroundTransparency = 0.88 })
		end
	end)
	btn.MouseLeave:Connect(function()
		if currentPage ~= name then
			tween(btn, 0.1, { BackgroundTransparency = 1 })
		end
	end)
	btn.MouseButton1Click:Connect(function()
		showPage(name)
	end)

	if i < #navDefs then
		new("Frame", {
			Size = UDim2.new(1, -8, 0, 1),
			BackgroundColor3 = C.Line,
			BorderSizePixel = 0,
			LayoutOrder = i * 2 + 1,
		}, sidebar)
	end
end

-- Controls we need to reach from other controls (presets, headshot checkbox, ...)
local ctl = {}

-- Extra tabs (Main / Visuals / Movement / Players); Combat and Settings are created below
local _, mnLeft, mnRight = newPage("Main", 0)
local _, vLeft, vRight = newPage("Visuals", 0)
local _, mvLeft, mvRight = newPage("Movement", 0)
local _, plLeft, plRight = newPage("Players", 0)

-- PAGE: COMBAT ------------------------------------------------------------
local combatPage, cLeft, cRight = newPage("Combat", 26)

local tabRow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundTransparency = 1,
}, combatPage)

local presetTabs = {}
for i, name in ipairs({ "Legit", "Rage" }) do
	local b = new("TextButton", {
		Size = UDim2.fromOffset(72, 20),
		Position = UDim2.fromOffset((i - 1) * 78, 0),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.92,
		AutoButtonColor = false,
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = C.Text,
		BorderSizePixel = 0,
	}, tabRow)
	corner(b, 3)
	new("UIStroke", {
		Color = C.Border,
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
		local on = (tabName == name)
		tween(b, 0.15, { BackgroundTransparency = on and 0.55 or 0.92 })
		local st = b:FindFirstChildOfClass("UIStroke")
		if st then
			tween(st, 0.15, { Color = on and C.Accent or C.Border })
		end
	end
end
highlightTab("Legit")

-- Aimbot
local aimCard = section(cLeft, "Aimbot")

ctl.enabled = toggle(aimCard, "Enabled", false, function(v)
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

ctl.silent = toggle(combatCard, "Silent Aim", false, function(v)
	Bridge.SilentAim = v
	notify("Silent Aim " .. (v and "ON" or "OFF") .. " (read _G.Xama.SilentAim in your gun script)")
end)

ctl.hitChance = slider(combatCard, "Hit Chance", 0, 100, 90, 1, "%d%%", function(v)
	S.HitChance = v / 100
	Bridge.HitChance = S.HitChance
	Aim.Reroll()
end)

-- Discord
local discordCard = section(mnRight, "Discord")
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

ctl.noRecoil = toggle(gunCard, "No Recoil", false, function(v)
	Bridge.NoRecoil = v
	notify("No Recoil " .. (v and "ON" or "OFF") .. " (read _G.Xama.NoRecoil in your gun script)")
end)

ctl.noSpread = toggle(gunCard, "No Spread", false, function(v)
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
local espCard = section(vLeft, "ESP")

ctl.chams = toggle(espCard, "Chams (nearest players)", true, function(v)
	S.Chams = v
	Visuals.Update()
	notify("Chams " .. (v and "ON" or "OFF"))
end)

ctl.nameEsp = toggle(espCard, "Name ESP", false, function(v)
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

local colorCard = section(vRight, "Chams Colors")

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

-- Noclip is tied to the existing Fly toggle (K / Combat > Movement > Fly).
-- Save each part's original collision setting so it can be restored exactly.
local flyNoclipOriginals = {}
local flyNoclipConnection

local function setFlyNoclip(enabled, character)
	if enabled then
		if not character then return end
		for _, inst in ipairs(character:GetDescendants()) do
			if inst:IsA("BasePart") then
				if flyNoclipOriginals[inst] == nil then
					flyNoclipOriginals[inst] = inst.CanCollide
				end
				inst.CanCollide = false
			end
		end
		if flyNoclipConnection then
			flyNoclipConnection:Disconnect()
		end
		flyNoclipConnection = character.DescendantAdded:Connect(function(inst)
			if inst:IsA("BasePart") then
				if flyNoclipOriginals[inst] == nil then
					flyNoclipOriginals[inst] = inst.CanCollide
				end
				inst.CanCollide = false
			end
		end)
	else
		if flyNoclipConnection then
			flyNoclipConnection:Disconnect()
			flyNoclipConnection = nil
		end
		for part, originalValue in pairs(flyNoclipOriginals) do
			if part and part.Parent then
				part.CanCollide = originalValue
			end
		end
		table.clear(flyNoclipOriginals)
	end
end

local function stopFlying()
	flyEnabled = false
	setFlyNoclip(false)
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
	setFlyNoclip(true, character)
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

local flyCard = section(mvLeft, "Movement")
ctl.fly = toggle(flyCard, "Fly", false, function(v)
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

-- O key: tween above the nearest other player, then float there for 5 seconds.
-- Intended for use in your own Roblox Studio experience.
local hopTween, hopForce, hopConn
local hopToken = 0
local hopHumanoid, hopOriginalAutoRotate

local function cancelPlayerHop()
	hopToken += 1
	if hopTween then
		hopTween:Cancel()
		hopTween = nil
	end
	if hopConn then
		hopConn:Disconnect()
		hopConn = nil
	end
	if hopForce then
		hopForce:Destroy()
		hopForce = nil
	end
	if hopHumanoid and hopHumanoid.Parent and hopOriginalAutoRotate ~= nil then
		hopHumanoid.AutoRotate = hopOriginalAutoRotate
	end
	hopHumanoid, hopOriginalAutoRotate = nil, nil
end

local function getClosestOtherPlayer()
	local character = player.Character
	local myRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local closestCharacter, closestHead
	local closestDistance = math.huge
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		-- The O-key hop uses the same Team Check setting as the aimbot.
		if otherPlayer ~= player and (not S.TeamCheck or not playersAreTeammates(otherPlayer, player)) then
			local otherCharacter = otherPlayer.Character
			local otherHumanoid = otherCharacter and otherCharacter:FindFirstChildOfClass("Humanoid")
			local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
			local otherHead = otherCharacter and (otherCharacter:FindFirstChild("Head") or otherRoot)
			if otherHumanoid and otherHumanoid.Health > 0 and otherRoot and otherHead then
				local distance = (otherRoot.Position - myRoot.Position).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closestCharacter, closestHead = otherCharacter, otherHead
				end
			end
		end
	end
	return closestCharacter, closestHead
end

local function tweenAboveClosestPlayer()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		notify("Tween unavailable: character not ready")
		return
	end
	if flyEnabled then
		notify("Turn Fly off before using the O tween")
		return
	end

	local targetCharacter, targetHead = getClosestOtherPlayer()
	if not targetCharacter or not targetHead then
		notify("No other living player found")
		return
	end

	cancelPlayerHop()
	local thisHop = hopToken
	hopHumanoid = humanoid
	hopOriginalAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false

	local hoverOffset = Vector3.new(0, 4.5, 0)
	local destination = targetHead.Position + hoverOffset
	local distance = (destination - root.Position).Magnitude
	local duration = math.clamp(distance / 70, 0.4, 1.8)
	local facing = root.CFrame.LookVector
	local targetCFrame = CFrame.lookAt(destination, destination + Vector3.new(facing.X, 0, facing.Z))
	hopTween = TweenService:Create(
		root,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = targetCFrame }
	)
	hopTween:Play()
	local playbackState = hopTween.Completed:Wait()
	if thisHop ~= hopToken or playbackState ~= Enum.PlaybackState.Completed then
		return
	end
	hopTween = nil

	if not targetCharacter.Parent or not targetHead.Parent then
		cancelPlayerHop()
		notify("Target left; tween cancelled")
		return
	end

	hopForce = Instance.new("BodyPosition")
	hopForce.Name = "XamaPlayerHover"
	hopForce.MaxForce = Vector3.new(9e6, 9e6, 9e6)
	hopForce.P = 30000
	hopForce.D = 1500
	hopForce.Position = targetHead.Position + hoverOffset
	hopForce.Parent = root

	local startedAt = os.clock()
	hopConn = RunService.Heartbeat:Connect(function()
		if thisHop ~= hopToken then return end
		if not root.Parent or not targetCharacter.Parent or not targetHead.Parent then
			cancelPlayerHop()
			notify("Target unavailable; hover ended")
			return
		end
		hopForce.Position = targetHead.Position + hoverOffset
		if os.clock() - startedAt >= 5 then
			cancelPlayerHop()
			notify("Finished floating for 5 seconds")
		end
	end)
	notify("Floating above " .. targetCharacter.Name .. " for 5 seconds")
end

keep(player.CharacterAdded:Connect(function()
	cancelPlayerHop()
end))

local floatCard = section(mvRight, "Player Float")
actionButton(floatCard, "Float above nearest player", function()
	task.spawn(tweenAboveClosestPlayer)
end)
label(floatCard, "Key [O]  -  floats for 5 seconds", UDim2.new(1, 0, 0, 18), nil,
	Enum.Font.Gotham, 11, C.SubText, Enum.TextXAlignment.Left).LayoutOrder = nextOrder(floatCard)

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
	cancelPlayerHop()
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

ctl.accent = dropdown(menuCard, "Accent", THEME_NAMES, "Red", function(v)
	applyTheme(THEMES[v] or THEMES.Red)
	notify("Accent: " .. v)
end)

ctl.uiSize = slider(menuCard, "UI Size", 60, 180, math.floor(defaultScale * 20 + 0.5) * 5, 5, "%d%%", function(v)
	setUiScale(v / 100)
end)

actionButton(menuCard, "Unload XAMA", function()
	unload()
end)

-- SAVE / LOAD SETTINGS ---------------------------------------------------
-- Saves every control (toggles, checkboxes, sliders, dropdowns) in ctl.
-- It writes to every place that is available:
--   session : _G.XamaSaved (survives Unload + re-running the script)
--   file    : XAMA_config.json, if writefile / readfile / isfile exist in your environment
--   game    : DataStore, if the Script half is in ServerScriptService
-- Load reads file -> game -> session, whichever it finds first.
local CONFIG_FILE = "XAMA_config.json"

local function fileApi()
	local ok, w, r, e = pcall(function()
		return writefile, readfile, isfile
	end)
	if ok and type(w) == "function" and type(r) == "function" and type(e) == "function" then
		return w, r, e
	end
	return nil
end

local function getRemote(wait)
	local r = ReplicatedStorage:FindFirstChild("XamaSettings")
	if not r and wait then
		r = ReplicatedStorage:WaitForChild("XamaSettings", 2)
	end
	return r
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
	local applied = 0
	for key, v in pairs(data) do
		local c = ctl[key]
		-- headOnly is just a shortcut for Hit Parts = Head, so it is synced after
		if c and key ~= "headOnly" and type(v) == type(c.Value) then
			c.Set(v)
			applied += 1
		end
	end
	if ctl.headOnly and ctl.hitPart then
		ctl.headOnly.Set(ctl.hitPart.Value == "Head", true)
	end
	return applied
end

local configCard = section(mnLeft, "Config")
local configInfo = label(configCard, "No saved config yet", UDim2.new(1, 0, 0, 30), nil,
	Enum.Font.Gotham, 11, C.SubText, Enum.TextXAlignment.Left)
configInfo.TextWrapped = true
configInfo.LayoutOrder = nextOrder(configCard)

local function setConfigInfo(text)
	configInfo.Text = text
end

local function saveSettings()
	local data = collectSettings()
	_G.XamaSaved = data
	local where = { "session" }

	local w = fileApi()
	if w then
		local ok = pcall(function()
			w(CONFIG_FILE, HttpService:JSONEncode(data))
		end)
		if ok then
			table.insert(where, "file")
		end
	end

	local remote = getRemote(false)
	if remote then
		local ok, result = pcall(function()
			return remote:InvokeServer("Save", data)
		end)
		if ok and result then
			table.insert(where, "game")
		end
	end

	local where_ = table.concat(where, " + ")
	setConfigInfo("Saved " .. os.date("%H:%M:%S") .. " -> " .. where_)
	notify("Settings saved (" .. where_ .. ")")
end

local function readSaved(waitForServer)
	local _, r, e = fileApi()
	if r then
		local ok, data = pcall(function()
			if e(CONFIG_FILE) then
				return HttpService:JSONDecode(r(CONFIG_FILE))
			end
			return nil
		end)
		if ok and type(data) == "table" then
			return data, "file"
		end
	end

	local remote = getRemote(waitForServer)
	if remote then
		local ok, result = pcall(function()
			return remote:InvokeServer("Load")
		end)
		if ok and type(result) == "table" then
			return result, "game"
		end
	end

	if type(_G.XamaSaved) == "table" then
		return _G.XamaSaved, "session"
	end
	return nil
end

local function loadSettings(isAuto)
	local data, from = readSaved(isAuto)
	if not data then
		setConfigInfo("No saved config found")
		if not isAuto then
			notify("No saved settings yet - press Save Settings first")
		end
		return
	end

	local count = applySettings(data)
	_G.XamaSaved = data
	setConfigInfo("Loaded " .. count .. " settings from " .. from .. " at " .. os.date("%H:%M:%S"))
	notify("Settings loaded from " .. from)
end

actionButton(configCard, "Save Settings", saveSettings)
actionButton(configCard, "Load Settings", function()
	loadSettings(false)
end)

local targetsCard = section(plLeft, "Targets")

ctl.teamCheck = checkbox(targetsCard, "Team Check", true, function(v)
	S.TeamCheck = v
end)

ctl.includeNpcs = checkbox(targetsCard, "Include NPCs / Dummies", true, function(v)
	S.IncludeNPCs = v
	Visuals.Update()
end)

local performanceCard = section(sRight, "Performance")
ctl.textureReducer = toggle(performanceCard, "Remove Textures", false, function(v)
	TextureReducer.SetEnabled(v)
	notify(v and "Texture layers hidden locally" or "Textures restored")
end)

local infoCard = section(mnRight, "Keys")
local keysLabel = label(infoCard, "RightShift  -  hide / show menu\nQ  -  lock on / release aimbot\nK  -  toggle fly\nO  -  float above nearest player (5s)",
	UDim2.new(1, 0, 0, 62), nil, Enum.Font.Gotham, 11, C.SubText, Enum.TextXAlignment.Left)
keysLabel.LayoutOrder = nextOrder(infoCard)

showPage("Main")

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
			Position = main.Position - UDim2.fromOffset(0, SHIFT_Y * (main:GetAttribute("BaseScale") or 1)),
		}, Enum.EasingStyle.Quint)
	else
		content.Visible = true
		minBtn.Text = "-"
		tween(main, 0.3, {
			Size = FULL_SIZE,
			Position = main.Position + UDim2.fromOffset(0, SHIFT_Y * (main:GetAttribute("BaseScale") or 1)),
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
	elseif input.KeyCode == Enum.KeyCode.O then
		tweenAboveClosestPlayer()
	end
end))


-- START: no loader, the hub just plays an intro animation -------------------
local function playIntro()
	local scale = main:FindFirstChildOfClass("UIScale")
	local base = main:GetAttribute("BaseScale") or 1
	local center = main.Position

	scale.Scale = base * 0.8
	main.Position = center + UDim2.fromOffset(0, 30)
	main.Visible = true

	-- glow and border fade in
	for _, child in ipairs(main:GetChildren()) do
		if string.sub(child.Name, 1, 4) == "Glow" then
			local target = child.BackgroundTransparency
			child.BackgroundTransparency = 1
			tween(child, 0.9, { BackgroundTransparency = target })
		end
	end
	local stroke = mainBody:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 1
		tween(stroke, 0.6, { Transparency = 0.1 })
	end

	-- window pops up and settles
	tween(scale, 0.55, { Scale = base }, Enum.EasingStyle.Back)
	tween(main, 0.5, { Position = center }, Enum.EasingStyle.Quint)

	-- tabs slide in one after another
	for i, def in ipairs(navDefs) do
		local nav = navButtons[def[1]]
		if nav then
			local iconPos = nav.Icon.Position
			local textPos = nav.Label.Position
			nav.Icon.Position = iconPos - UDim2.fromOffset(18, 0)
			nav.Label.Position = textPos - UDim2.fromOffset(18, 0)
			nav.Label.TextTransparency = 1
			task.delay(0.15 + i * 0.06, function()
				tween(nav.Icon, 0.3, { Position = iconPos }, Enum.EasingStyle.Quint)
				tween(nav.Label, 0.3, { Position = textPos, TextTransparency = 0 }, Enum.EasingStyle.Quint)
			end)
		end
	end
end

task.spawn(function()
	unlocked = true
	playIntro()

	-- bring back the saved config once the intro has played
	task.wait(0.8)
	loadSettings(true)
end)
