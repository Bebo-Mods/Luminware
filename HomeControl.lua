-- Luminware Home Control layout.
-- Run directly in an executor or use as a LocalScript.
--
-- Optional callback API:
-- getgenv().HomeControlCallbacks = {
--     OnChanged = function(name, value) print(name, value) end
-- }

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local guiParent = playerGui

-- Executor environments commonly expose gethui; Studio safely falls back to PlayerGui.
local hiddenGuiOk, hiddenGui = pcall(function()
	return gethui and gethui()
end)
if hiddenGuiOk and hiddenGui then
	guiParent = hiddenGui
end

local BACKGROUND_IMAGE = ""
local BLUE = Color3.fromRGB(35, 184, 241)
local WHITE = Color3.fromRGB(246, 246, 244)
local MUTED = Color3.fromRGB(190, 189, 184)
local PANEL = Color3.fromRGB(55, 53, 48)
local CARD = Color3.fromRGB(111, 109, 103)
local callbacks = {}
pcall(function()
	if typeof(getgenv) == "function" then
		callbacks = getgenv().HomeControlCallbacks or {}
	end
end)

local function emit(name, value)
	if typeof(callbacks.OnChanged) == "function" then
		task.spawn(callbacks.OnChanged, name, value)
	end
end

local old = guiParent:FindFirstChild("FrostedHomeUI")
if old then old:Destroy() end

local blur = Lighting:FindFirstChild("FrostedHomeBlur") or Instance.new("BlurEffect")
blur.Name = "FrostedHomeBlur"
blur.Size = 7
blur.Parent = Lighting

local function new(className, props, parent)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	return new("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(parent, color, transparency, thickness)
	return new("UIStroke", {
		Color = color or WHITE,
		Transparency = transparency or 0.75,
		Thickness = thickness or 1,
	}, parent)
end

local function padding(parent, left, right, top, bottom)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
	}, parent)
end

local function label(parent, text, x, y, w, h, size, color, align, font)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		Font = font or Enum.Font.Gotham,
		Text = text,
		TextColor3 = color or WHITE,
		TextSize = size or 11,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

local function tween(object, duration, props)
	TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function onClick(button, name, callback)
	assert(button and button:IsA("GuiButton"), ("FrostedHomeUI: %s is not a GuiButton"):format(name))
	return button.Activated:Connect(callback)
end

local gui = new("ScreenGui", {
	Name = "FrostedHomeUI",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local backdrop = new("ImageLabel", {
	BackgroundColor3 = Color3.fromRGB(151, 145, 133),
	BackgroundTransparency = BACKGROUND_IMAGE == "" and 1 or 0,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	Image = BACKGROUND_IMAGE,
	ScaleType = Enum.ScaleType.Crop,
}, gui)

new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(116, 111, 102)),
		ColorSequenceKeypoint.new(0.48, Color3.fromRGB(174, 168, 157)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(106, 100, 89)),
	}),
	Rotation = 12,
}, backdrop)

local dim = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(25, 23, 20),
	BackgroundTransparency = BACKGROUND_IMAGE == "" and 0.86 or 0.68,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
}, backdrop)

local canvas = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1024, 576),
}, dim)
new("UIScale", {Scale = 1}, canvas)

local function resize()
	local viewport = workspace.CurrentCamera.ViewportSize
	canvas.UIScale.Scale = math.min(viewport.X / 1024, viewport.Y / 576)
end
resize()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

local main = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.13,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(512, 288),
	Size = UDim2.fromOffset(572, 386),
}, canvas)
corner(main, 22)
stroke(main, Color3.fromRGB(150, 147, 139), 0.82, 1)

new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 98, 91)),
		ColorSequenceKeypoint.new(0.42, Color3.fromRGB(77, 74, 68)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(44, 42, 38)),
	}),
	Rotation = 8,
}, main)

local rail = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(117, 115, 108),
	BackgroundTransparency = 0.33,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(10, 10),
	Size = UDim2.fromOffset(55, 366),
}, main)
corner(rail, 16)
stroke(rail, WHITE, 0.85, 1)

local navSymbols = {"S", "P", "W", "L", "G"}
local navButtons = {}
for index, symbol in ipairs(navSymbols) do
	local button = new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(91, 89, 83),
		BackgroundTransparency = index == 1 and 0.25 or 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(11, 11 + ((index - 1) * 34)),
		Size = UDim2.fromOffset(33, 30),
		Font = Enum.Font.GothamMedium,
		Text = symbol,
		TextColor3 = WHITE,
		TextSize = 10,
	}, rail)
	corner(button, 10)
	navButtons[index] = button
	onClick(button, ("navigation button %d"):format(index), function()
		for i, item in ipairs(navButtons) do
			tween(item, 0.18, {BackgroundTransparency = i == index and 0.25 or 1})
		end
	end)
end

local power = new("TextButton", {
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(11, 325),
	Size = UDim2.fromOffset(33, 30),
	Font = Enum.Font.GothamMedium,
	Text = "O",
	TextColor3 = WHITE,
	TextSize = 13,
}, rail)

local content = new("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(76, 16),
	Size = UDim2.fromOffset(484, 354),
}, main)

local tabOne = new("TextButton", {
	AutoButtonColor = false, BackgroundTransparency = 1,
	Position = UDim2.fromOffset(14, 4), Size = UDim2.fromOffset(56, 30),
	Font = Enum.Font.GothamMedium, Text = "Subtab 1", TextColor3 = WHITE, TextSize = 11,
}, content)
local tabTwo = new("TextButton", {
	AutoButtonColor = false, BackgroundTransparency = 1,
	Position = UDim2.fromOffset(80, 4), Size = UDim2.fromOffset(56, 30),
	Font = Enum.Font.Gotham, Text = "Subtab 2", TextColor3 = MUTED, TextSize = 11,
}, content)
local tabLine = new("Frame", {
	BackgroundColor3 = WHITE, BorderSizePixel = 0,
	Position = UDim2.fromOffset(14, 34), Size = UDim2.fromOffset(56, 1),
}, content)

local search = new("TextBox", {
	BackgroundColor3 = Color3.fromRGB(25, 24, 21),
	BackgroundTransparency = 0.52,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(304, 4),
	Size = UDim2.fromOffset(112, 28),
	ClearTextOnFocus = false,
	Font = Enum.Font.Gotham,
	PlaceholderColor3 = MUTED,
	PlaceholderText = "Q  Search",
	Text = "",
	TextColor3 = WHITE,
	TextSize = 9,
	TextXAlignment = Enum.TextXAlignment.Left,
}, content)
corner(search, 11)
padding(search, 12, 8, 0, 0)

label(content, "D", 423, 4, 20, 28, 10, WHITE, Enum.TextXAlignment.Center, Enum.Font.GothamMedium)
local avatar = new("ImageLabel", {
	BackgroundColor3 = Color3.fromRGB(212, 221, 220),
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(449, 6),
	Size = UDim2.fromOffset(24, 24),
	Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(player.UserId),
}, content)
corner(avatar, 12)
stroke(avatar, WHITE, 0.2, 1)

local pageOne = new("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 48),
	Size = UDim2.fromOffset(484, 306),
}, content)

local pageTwo = new("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 48),
	Size = UDim2.fromOffset(484, 306),
	Visible = false,
}, content)
label(pageTwo, "Subtab 2", 14, 12, 200, 24, 16, WHITE, Enum.TextXAlignment.Left, Enum.Font.GothamMedium)
label(pageTwo, "A quiet second page, ready for your content.", 14, 40, 300, 18, 10, MUTED)

local function setTab(first)
	pageOne.Visible = first
	pageTwo.Visible = not first
	tween(tabLine, 0.25, {Position = UDim2.fromOffset(first and 14 or 80, 34)})
	tween(tabOne, 0.2, {TextColor3 = first and WHITE or MUTED})
	tween(tabTwo, 0.2, {TextColor3 = first and MUTED or WHITE})
end
onClick(tabOne, "Subtab 1", function() setTab(true) end)
onClick(tabTwo, "Subtab 2", function() setTab(false) end)

local function card(parent, x, y, w, h, radius)
	local frame = new("Frame", {
		BackgroundColor3 = CARD,
		BackgroundTransparency = 0.28,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
	}, parent)
	corner(frame, radius or 13)
	stroke(frame, WHITE, 0.78, 1)
	return frame
end

local function toggle(parent, x, y, initial, name)
	local state = initial
	local track = new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = state and BLUE or Color3.fromRGB(138, 137, 132),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(23, 13),
		Text = "",
	}, parent)
	corner(track, 7)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(state and 16.5 or 6.5, 6.5),
		Size = UDim2.fromOffset(10, 10),
	}, track)
	corner(knob, 5)
	onClick(track, "toggle", function()
		state = not state
		tween(track, 0.18, {BackgroundColor3 = state and BLUE or Color3.fromRGB(138, 137, 132)})
		tween(knob, 0.18, {Position = UDim2.fromOffset(state and 16.5 or 6.5, 6.5)})
		emit(name or "Toggle", state)
	end)
	return track
end

local left = card(pageOne, 0, 0, 158, 230, 14)
local miniA = card(left, 8, 7, 68, 68, 12)
local miniB = card(left, 81, 7, 68, 68, 12)
label(miniA, "/", 10, 7, 20, 20, 12, WHITE, Enum.TextXAlignment.Center, Enum.Font.GothamMedium)
label(miniA, "Thing 1", 10, 48, 50, 14, 9, WHITE)
toggle(miniA, 38, 12, true, "Thing 1")
label(miniB, "O", 10, 7, 20, 20, 10, WHITE, Enum.TextXAlignment.Center, Enum.Font.GothamMedium)
label(miniB, "Thing 2", 10, 48, 50, 14, 9, WHITE)
toggle(miniB, 38, 12, false, "Thing 2")

local large = card(left, 8, 81, 141, 141, 12)
label(large, "Z", 10, 7, 20, 20, 11, WHITE, Enum.TextXAlignment.Center, Enum.Font.GothamMedium)
label(large, "Thing 3", 10, 117, 70, 14, 9, WHITE)
toggle(large, 108, 11, false, "Thing 3")

local controls = card(pageOne, 165, 0, 158, 105, 13)
label(controls, "Toggle", 12, 8, 70, 16, 9, WHITE)
toggle(controls, 124, 11, true, "Toggle")
label(controls, "Slider", 12, 40, 70, 16, 9, WHITE)
local sliderTrack = new("Frame", {
	BackgroundColor3 = Color3.fromRGB(144, 143, 137),
	BorderSizePixel = 0, Position = UDim2.fromOffset(64, 45), Size = UDim2.fromOffset(80, 8),
}, controls)
corner(sliderTrack, 4)
local sliderFill = new("Frame", {
	BackgroundColor3 = BLUE, BorderSizePixel = 0, Size = UDim2.fromScale(0.72, 1),
}, sliderTrack)
corner(sliderFill, 4)
local sliderKnob = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0,
	Position = UDim2.fromScale(0.72, 0.5), Size = UDim2.fromOffset(9, 9),
}, sliderTrack)
corner(sliderKnob, 5)

local dragging = false
local function updateSlider(input)
	local value = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
	sliderFill.Size = UDim2.fromScale(value, 1)
	sliderKnob.Position = UDim2.fromScale(value, 0.5)
	emit("Slider", value)
end
sliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		updateSlider(input)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateSlider(input)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

label(controls, "Button", 12, 72, 70, 16, 9, WHITE)
local action = new("TextButton", {
	AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(145, 144, 138),
	BackgroundTransparency = 0.35, BorderSizePixel = 0,
	Position = UDim2.fromOffset(104, 70), Size = UDim2.fromOffset(40, 20),
	Font = Enum.Font.Gotham, Text = "Action", TextColor3 = WHITE, TextSize = 8,
}, controls)
corner(action, 10)
stroke(action, WHITE, 0.76, 1)
onClick(action, "action button", function()
	tween(action, 0.1, {BackgroundColor3 = BLUE})
	task.delay(0.2, function() tween(action, 0.25, {BackgroundColor3 = Color3.fromRGB(145, 144, 138)}) end)
	emit("Action", true)
end)

local function module(parent, x, y, title, initial, enabled)
	local box = card(parent, x, y, 158, 102, 13)
	label(box, title, 12, 8, 92, 14, 9, WHITE, Enum.TextXAlignment.Left, Enum.Font.GothamMedium)
	label(box, "Lorem ipsum nibh quisque", 12, 21, 110, 12, 6, MUTED)
	toggle(box, 124, 10, enabled, title .. " Enabled")
	label(box, "Actions", 12, 35, 80, 12, 6, MUTED)
	local choices = {"One", "Two", "Three", "Four"}
	local buttons = {}
	for i, choice in ipairs(choices) do
		local selected = i == initial
		local button = new("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = selected and WHITE or Color3.fromRGB(137, 136, 130),
			BackgroundTransparency = selected and 0 or 0.32,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(12 + ((i - 1) * 37), 55),
			Size = UDim2.fromOffset(24, 24),
			Font = Enum.Font.GothamMedium,
			Text = "O",
			TextColor3 = selected and Color3.fromRGB(75, 74, 70) or WHITE,
			TextSize = 8,
		}, box)
		corner(button, 12)
		stroke(button, WHITE, 0.65, 1)
		label(box, choice, 7 + ((i - 1) * 37), 80, 34, 12, 6, WHITE, Enum.TextXAlignment.Center)
		buttons[i] = button
		onClick(button, ("%s option %s"):format(title, choice), function()
			for index, item in ipairs(buttons) do
				local active = index == i
				tween(item, 0.16, {
					BackgroundColor3 = active and WHITE or Color3.fromRGB(137, 136, 130),
					BackgroundTransparency = active and 0 or 0.32,
					TextColor3 = active and Color3.fromRGB(75, 74, 70) or WHITE,
				})
			end
			emit(title, choice)
		end)
	end
	return box
end

module(pageOne, 330, 0, "Module One", 2, true)
module(pageOne, 330, 111, "Module Two", 4, false)

onClick(power, "power button", function()
	emit("Power", false)
	gui.Enabled = false
	blur.Size = 0
end)
