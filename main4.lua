local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Icons from https://github.com/as6cd0/splibv2 (Icons.lua) - use key as tab/button icon name
local Icons = {
	["accessibility"] = "rbxassetid://10709751939",
	["activity"] = "rbxassetid://10709752035",
	["settings"] = "rbxassetid://10734950309",
	["user"] = "rbxassetid://10747373176",
	["users"] = "rbxassetid://10747373426",
	["target"] = "rbxassetid://10734977012",
	["crosshair"] = "rbxassetid://10709818534",
	["sword"] = "rbxassetid://10734975486",
	["gamepad"] = "rbxassetid://10723395457",
	["shield"] = "rbxassetid://10734951847",
	["circle"] = "rbxassetid://10709798174",
	["chevronright"] = "rbxassetid://10709791437",
	["play"] = "rbxassetid://10734923549",
	["toggleleft"] = "rbxassetid://10734984834",
	["toggleright"] = "rbxassetid://10734985040",
	["palette"] = "rbxassetid://10734910430",
	["list"] = "rbxassetid://10723433811",
	["folder"] = "rbxassetid://10723387563",
	["home"] = "rbxassetid://10723407389",
	["star"] = "rbxassetid://10734966248",
	["heart"] = "rbxassetid://10723406885",
	["cog"] = "rbxassetid://10709810948",
	["search"] = "rbxassetid://10734943674",
	["code"] = "rbxassetid://10709810463",
	["image"] = "rbxassetid://10723415040",
	["type"] = "rbxassetid://10747364761",
	["sliders"] = "rbxassetid://10734963400",
	["paintbrush"] = "rbxassetid://10734910187",
}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG_JELLY = {
	DAMPING = 0.25,
	STIFFNESS = 0.18,
	STRETCH_FORCE = 0.0004,
	MAX_STRETCH = 1.1,
	MIN_STRETCH = 0.92
}

local originalMainFrameSize = UDim2.new(0, 350, 0, 250)
local minimizedSize = UDim2.new(0, 220, 0, 35)

-- Resolve tab icon: full rbxassetid string or Icons key
local function resolveIcon(iconArg)
	if type(iconArg) ~= "string" or iconArg == "" then return Icons["circle"] or "rbxassetid://10709798174" end
	if iconArg:find("rbxassetid://") then return iconArg end
	return Icons[iconArg] or Icons["circle"] or "rbxassetid://10709798174"
end

local function makeWindow(options)
	options = options or {}
	local winName = options.Name or "Voidlib"
	local subTitle = options.SubTitle or "by void"
	local iconUrl = options.Icon or "rbxassetid://110661788517806"
	local showToggle = options.Toggle ~= false
	local closeCallback = options.CloseCallback ~= false
	local minW = options.MinWidth or 280
	local minH = options.MinHeight or 200
	local maxW = options.MaxWidth or 600
	local maxH = options.MaxHeight or 500

	local sc = Instance.new("ScreenGui")
	sc.Name = "VoidlibScreenGui"
	sc.ResetOnSpawn = false
	sc.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sc.DisplayOrder = 10
	sc.Parent = PlayerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Parent = sc
	mainFrame.Size = originalMainFrameSize
	mainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
	mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	mainFrame.BackgroundTransparency = 0.15
	mainFrame.Active = true
	mainFrame.ZIndex = 5
	mainFrame.ClipsDescendants = true
	local currentMainFrameSize = originalMainFrameSize
	local resizing = false

	local mainFrameCorner = Instance.new("UICorner")
	mainFrameCorner.CornerRadius = UDim.new(0, 12)
	mainFrameCorner.Parent = mainFrame

	local MenuStroke = Instance.new("UIStroke")
	MenuStroke.Parent = mainFrame
	MenuStroke.Thickness = 2.5
	MenuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	MenuStroke.Color = Color3.fromRGB(100, 100, 108)

	local StrokeGradient = Instance.new("UIGradient")
	StrokeGradient.Parent = MenuStroke
	StrokeGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 68)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 160, 170)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 68))
	})
	StrokeGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1)
	})

	local rotation = 0
	RunService.RenderStepped:Connect(function(delta)
		rotation = rotation + (delta * 150)
		if rotation >= 360 then rotation = 0 end
		StrokeGradient.Rotation = rotation
	end)

	-- Start sound plays when window opens. Click sound for buttons/toggles/etc.
	-- Start = window open (1626996526). Click = buttons/toggles (different ID so not every button plays the same).
	-- Custom click: upload MP3 to Roblox, get rbxassetid, set options.ClickSoundId = "rbxassetid://YOUR_ID"
	local startSoundId = options.StartSoundId or "rbxassetid://1626996526"
	local clickSoundId = options.ClickSoundId or "rbxassetid://134702285895289"
	local StartSound = Instance.new("Sound", sc)
	StartSound.SoundId = startSoundId
	StartSound.Volume = 1
	local ClickSound = Instance.new("Sound", sc)
	ClickSound.SoundId = clickSoundId
	ClickSound.Volume = 1

	local function PlaySound()
		ClickSound:Play()
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Parent = mainFrame
	titleLabel.Size = UDim2.new(1, 0, 0, 35)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.Text = "                 " .. winName
	titleLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	titleLabel.BackgroundTransparency = 0.8
	titleLabel.Font = Enum.Font.Michroma
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 6

	local titleLabelcor = Instance.new("UICorner")
	titleLabelcor.CornerRadius = UDim.new(0, 10)
	titleLabelcor.Parent = titleLabel

	local image = Instance.new("ImageLabel")
	image.Name = "TitleImage"
	image.Parent = titleLabel
	image.Size = UDim2.new(0, 25, 0, 25)
	image.Position = UDim2.new(0, 10, 0.5, -12.5)
	image.Image = iconUrl
	image.BackgroundTransparency = 1
	image.ZIndex = 7

	local g = Instance.new("UICorner")
	g.CornerRadius = UDim.new(1, 0)
	g.Parent = image

	local byVoidLabel = Instance.new("TextLabel")
	byVoidLabel.Name = "ByVoidLabel"
	byVoidLabel.Parent = titleLabel
	byVoidLabel.Size = UDim2.new(0, 60, 1, 0)
	byVoidLabel.Position = UDim2.new(0, 130, 0, 0)
	byVoidLabel.Text = subTitle
	byVoidLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	byVoidLabel.BackgroundTransparency = 1
	byVoidLabel.Font = Enum.Font.Michroma
	byVoidLabel.TextSize = 9
	byVoidLabel.TextXAlignment = Enum.TextXAlignment.Left
	byVoidLabel.ZIndex = 7

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Parent = mainFrame
	closeButton.Size = UDim2.new(0, 20, 0, 20)
	closeButton.Position = UDim2.new(1, -25, 0, 7)
	closeButton.Text = "X"
	closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
	closeButton.BackgroundTransparency = 0.5
	closeButton.TextColor3 = Color3.fromRGB(200, 200, 210)
	closeButton.TextSize = 14
	closeButton.Font = Enum.Font.Michroma
	closeButton.ZIndex = 10

	local closeButtonCorner = Instance.new("UICorner")
	closeButtonCorner.CornerRadius = UDim.new(0, 6)
	closeButtonCorner.Parent = closeButton

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "MinimizeButton"
	minimizeButton.Parent = mainFrame
	minimizeButton.Size = UDim2.new(0, 20, 0, 20)
	minimizeButton.Position = UDim2.new(1, -50, 0, 7)
	minimizeButton.Text = "—"
	minimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
	minimizeButton.BackgroundTransparency = 0.5
	minimizeButton.TextColor3 = Color3.fromRGB(200, 200, 210)
	minimizeButton.TextSize = 14
	minimizeButton.Font = Enum.Font.Michroma
	minimizeButton.ZIndex = 10
	minimizeButton.Visible = showToggle

	local minimizeButtonCorner = Instance.new("UICorner")
	minimizeButtonCorner.CornerRadius = UDim.new(0, 6)
	minimizeButtonCorner.Parent = minimizeButton

	local tabHolder = Instance.new("ScrollingFrame")
	tabHolder.Name = "TabHolder"
	tabHolder.Parent = mainFrame
	tabHolder.Size = UDim2.new(0, 45, 1, -45)
	tabHolder.Position = UDim2.new(0, 5, 0, 50)
	tabHolder.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	tabHolder.BackgroundTransparency = 0.8
	tabHolder.BorderSizePixel = 0
	tabHolder.ScrollBarThickness = 2
	tabHolder.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 130)
	tabHolder.ZIndex = 6

	local tabHolderCorner = Instance.new("UICorner")
	tabHolderCorner.CornerRadius = UDim.new(0, 8)
	tabHolderCorner.Parent = tabHolder

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Parent = tabHolder
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local pageHolder = Instance.new("Frame")
	pageHolder.Name = "PageHolder"
	pageHolder.Parent = mainFrame
	pageHolder.Size = UDim2.new(1, -55, 1, -45)
	pageHolder.Position = UDim2.new(0, 55, 0, 50)
	pageHolder.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	pageHolder.BackgroundTransparency = 0.8
	pageHolder.ZIndex = 6

	local pageHolderCorner = Instance.new("UICorner")
	pageHolderCorner.CornerRadius = UDim.new(0, 8)
	pageHolderCorner.Parent = pageHolder

	local tabs = {}
	local activeTab = nil
	local pageLayoutOrders = {}
	local isMinimized = false
	local isAnimating = false

	local function getNextLayoutOrder(page)
		local n = pageLayoutOrders[page] or 0
		pageLayoutOrders[page] = n + 1
		return n
	end

	local function CreateTab(tabName, iconArg)
		local iconId = resolveIcon(iconArg)

		local tabButton = Instance.new("ImageButton")
		tabButton.Name = tabName .. "Tab"
		tabButton.Parent = tabHolder
	tabButton.Size = UDim2.new(0, 30, 0, 30)
	tabButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	tabButton.BackgroundTransparency = 0.5
	tabButton.Image = iconId
	tabButton.ImageColor3 = Color3.fromRGB(140, 140, 150)
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 1
	aspectRatio.Parent = tabButton
	tabButton.ZIndex = 7

	local tabBtnCorner = Instance.new("UICorner")
	tabBtnCorner.CornerRadius = UDim.new(0, 6)
	tabBtnCorner.Parent = tabButton

		local page = Instance.new("ScrollingFrame")
		page.Name = tabName .. "Page"
		page.Parent = pageHolder
	page.Size = UDim2.new(1, -10, 1, -10)
	page.Position = UDim2.new(0, 5, 0, 5)
	page.Visible = false
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 130)
	page.ZIndex = 7

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.Parent = page
	pageLayout.Padding = UDim.new(0, 8)
	pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder

	pageLayoutOrders[page] = 0

	tabButton.MouseButton1Click:Connect(function()
		PlaySound()
		for _, t in pairs(tabs) do
			t.Page.Visible = false
			t.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			t.Button.ImageColor3 = Color3.fromRGB(140, 140, 150)
		end
		page.Visible = true
		tabButton.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
		tabButton.ImageColor3 = Color3.fromRGB(220, 220, 230)
		activeTab = tabName
	end)

		tabs[tabName] = { Button = tabButton, Page = page }

		if not activeTab then
			page.Visible = true
			tabButton.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
			tabButton.ImageColor3 = Color3.fromRGB(220, 220, 230)
			activeTab = tabName
		end

		return page
	end

	local function AddSection(parentPage, title, bio)
		local order = getNextLayoutOrder(parentPage)
		local wrap = Instance.new("Frame")
		wrap.Name = "SectionWrap"
		wrap.Size = UDim2.new(0.9, 0, 0, bio and 44 or 28)
		wrap.BackgroundTransparency = 1
		wrap.Parent = parentPage
		wrap.LayoutOrder = order
		wrap.ZIndex = 8

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 22)
		label.Position = UDim2.new(0, 0, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = title
		label.TextColor3 = Color3.fromRGB(200, 200, 210)
		label.Font = Enum.Font.Michroma
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = wrap
		label.ZIndex = 8

		if bio and #bio > 0 then
			local bioLabel = Instance.new("TextLabel")
			bioLabel.Size = UDim2.new(1, 0, 0, 18)
			bioLabel.Position = UDim2.new(0, 0, 0, 22)
			bioLabel.BackgroundTransparency = 1
			bioLabel.Text = bio
			bioLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
			bioLabel.Font = Enum.Font.Gotham
			bioLabel.TextSize = 11
			bioLabel.TextXAlignment = Enum.TextXAlignment.Left
			bioLabel.TextWrapped = true
			bioLabel.Parent = wrap
			bioLabel.ZIndex = 8
		end
		return wrap
	end

	local function AddButton(parentPage, text, callback, options)
		options = options or {}
		local bio = options.bio or options.Bio
		local iconAssetId = options.icon or options.Icon or "rbxassetid://10709791437"
		local order = getNextLayoutOrder(parentPage)

		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(0.9, 0, 0, bio and 58 or 35)
		wrap.BackgroundTransparency = 1
		wrap.Parent = parentPage
		wrap.LayoutOrder = order
		wrap.ZIndex = 8

		local yOff = 0
		if bio and #bio > 0 then
			local bioLabel = Instance.new("TextLabel")
			bioLabel.Size = UDim2.new(1, 0, 0, 16)
			bioLabel.Position = UDim2.new(0, 0, 0, 0)
			bioLabel.BackgroundTransparency = 1
			bioLabel.Text = bio
			bioLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
			bioLabel.Font = Enum.Font.Gotham
			bioLabel.TextSize = 10
			bioLabel.TextXAlignment = Enum.TextXAlignment.Left
			bioLabel.TextWrapped = true
			bioLabel.Parent = wrap
			bioLabel.ZIndex = 8
			yOff = 20
		end

		local btn = Instance.new("TextButton")
		btn.Parent = wrap
		btn.Size = UDim2.new(1, 0, 0, 35)
		btn.Position = UDim2.new(0, 0, 0, yOff)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		btn.BackgroundTransparency = 0.3
		btn.Text = "  " .. text
		btn.TextColor3 = Color3.fromRGB(220, 220, 230)
		btn.Font = Enum.Font.Michroma
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.ZIndex = 8

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Parent = btn
		btnStroke.Color = Color3.fromRGB(80, 80, 90)
		btnStroke.Thickness = 1

		local img = Instance.new("ImageLabel")
		img.Size = UDim2.new(0, 18, 0, 18)
		img.Position = UDim2.new(1, -24, 0.5, -9)
		img.BackgroundTransparency = 1
		img.Image = type(iconAssetId) == "string" and iconAssetId or "rbxassetid://10709791437"
		img.ImageColor3 = Color3.fromRGB(200, 200, 210)
		img.Parent = btn
		img.ZIndex = 9

		btn.MouseButton1Click:Connect(function()
			PlaySound()
			callback()
		end)

		return btn
	end

	local function AddToggle(parentPage, text, default, callback, options)
		options = options or {}
		local bio = options.bio or options.Bio
		local order = getNextLayoutOrder(parentPage)
		local state = default == true

		local ON_COLOR = Color3.fromRGB(0, 122, 255)
		local OFF_COLOR = Color3.fromRGB(140, 140, 140)
		local THUMB_OFF = 3
		local THUMB_ON = 22
		local trackW, trackH = 48, 26

		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(0.9, 0, 0, bio and 52 or 34)
		wrap.BackgroundTransparency = 1
		wrap.Parent = parentPage
		wrap.LayoutOrder = order
		wrap.ZIndex = 8

		local yOff = 0
		if bio and #bio > 0 then
			local bioLabel = Instance.new("TextLabel")
			bioLabel.Size = UDim2.new(1, 0, 0, 14)
			bioLabel.Position = UDim2.new(0, 0, 0, 0)
			bioLabel.BackgroundTransparency = 1
			bioLabel.Text = bio
			bioLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
			bioLabel.Font = Enum.Font.Gotham
			bioLabel.TextSize = 10
			bioLabel.TextXAlignment = Enum.TextXAlignment.Left
			bioLabel.Parent = wrap
			bioLabel.ZIndex = 8
			yOff = 18
		end

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 26)
		row.Position = UDim2.new(0, 0, 0, yOff)
		row.BackgroundTransparency = 1
		row.Parent = wrap
		row.ZIndex = 8

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -60, 1, 0)
		label.Position = UDim2.new(0, 0, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.Font = Enum.Font.Michroma
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
		label.ZIndex = 8

		local track = Instance.new("Frame")
		track.Name = "Track"
		track.Size = UDim2.new(0, trackW, 0, trackH)
		track.Position = UDim2.new(1, -trackW, 0.5, -trackH/2)
		track.BackgroundColor3 = state and ON_COLOR or OFF_COLOR
		track.BackgroundTransparency = 0.25
		track.Parent = row
		track.ZIndex = 8

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(1, 0)
		trackCorner.Parent = track

		local trackStroke = Instance.new("UIStroke")
		trackStroke.Thickness = 1
		trackStroke.Transparency = 0.6
		trackStroke.Color = Color3.fromRGB(255, 255, 255)
		trackStroke.Parent = track

		local thumb = Instance.new("Frame")
		thumb.Name = "Thumb"
		thumb.Size = UDim2.new(0, trackH - 4, 0, trackH - 4)
		thumb.Position = UDim2.new(0, state and THUMB_ON or THUMB_OFF, 0.5, -thumb.Size.Y.Offset/2)
		thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		thumb.BackgroundTransparency = 0.1
		thumb.Parent = track
		thumb.ZIndex = 9

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = UDim.new(1, 0)
		thumbCorner.Parent = thumb

		local thumbStroke = Instance.new("UIStroke")
		thumbStroke.Thickness = 0.5
		thumbStroke.Transparency = 0.7
		thumbStroke.Parent = thumb

		local function updateVisuals(on)
			state = on
			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(track, tweenInfo, { BackgroundColor3 = on and ON_COLOR or OFF_COLOR }):Play()
			TweenService:Create(thumb, tweenInfo, { Position = UDim2.new(0, on and THUMB_ON or THUMB_OFF, 0.5, -thumb.Size.Y.Offset/2) }):Play()
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				PlaySound()
				state = not state
				updateVisuals(state)
				callback(state)
			end
		end)

		updateVisuals(state)
		return { toggle = track, set = updateVisuals, get = function() return state end }
	end

	local function AddParagraph(parentPage, text, options)
		options = options or {}
		local bio = options.bio or options.Bio
		local order = getNextLayoutOrder(parentPage)

		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(0.9, 0, 0, 0)
		wrap.AutomaticSize = Enum.AutomaticSize.Y
		wrap.BackgroundTransparency = 1
		wrap.Parent = parentPage
		wrap.LayoutOrder = order
		wrap.ZIndex = 8

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 4)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = wrap

		if bio and #bio > 0 then
			local bioLabel = Instance.new("TextLabel")
			bioLabel.Size = UDim2.new(1, 0, 0, 16)
			bioLabel.BackgroundTransparency = 1
			bioLabel.Text = bio
			bioLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
			bioLabel.Font = Enum.Font.Gotham
			bioLabel.TextSize = 10
			bioLabel.TextXAlignment = Enum.TextXAlignment.Left
			bioLabel.TextWrapped = true
			bioLabel.AutomaticSize = Enum.AutomaticSize.Y
			bioLabel.LayoutOrder = 0
			bioLabel.Parent = wrap
			bioLabel.ZIndex = 8
		end

		local p = Instance.new("TextLabel")
		p.Size = UDim2.new(1, 0, 0, 0)
		p.AutomaticSize = Enum.AutomaticSize.Y
		p.BackgroundTransparency = 1
		p.Text = text
		p.TextColor3 = Color3.fromRGB(200, 200, 200)
		p.Font = Enum.Font.Gotham
		p.TextSize = 12
		p.TextXAlignment = Enum.TextXAlignment.Left
		p.TextWrapped = true
		p.LayoutOrder = 1
		p.Parent = wrap
		p.ZIndex = 8

		return wrap
	end

	local function AddDropdown(parentPage, text, optionsList, defaultIndex, callback, options)
		options = options or {}
		local bio = options.bio or options.Bio
		local order = getNextLayoutOrder(parentPage)
		local selected = math.clamp(defaultIndex or 1, 1, #optionsList)
		local open = false

		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(0.9, 0, 0, bio and 52 or 34)
		wrap.BackgroundTransparency = 1
		wrap.Parent = parentPage
		wrap.LayoutOrder = order
		wrap.ZIndex = 8

		local yOff = 0
		if bio and #bio > 0 then
			local bioLabel = Instance.new("TextLabel")
			bioLabel.Size = UDim2.new(1, 0, 0, 14)
			bioLabel.Position = UDim2.new(0, 0, 0, 0)
			bioLabel.BackgroundTransparency = 1
			bioLabel.Text = bio
			bioLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
			bioLabel.Font = Enum.Font.Gotham
			bioLabel.TextSize = 10
			bioLabel.TextXAlignment = Enum.TextXAlignment.Left
			bioLabel.Parent = wrap
			bioLabel.ZIndex = 8
			yOff = 18
		end

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.Position = UDim2.new(0, 0, 0, yOff)
		btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		btn.BackgroundTransparency = 0.2
		btn.Text = ""
		btn.Parent = wrap
		btn.ZIndex = 9

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		local btnLabel = Instance.new("TextLabel")
		btnLabel.Size = UDim2.new(1, -50, 1, 0)
		btnLabel.Position = UDim2.new(0, 8, 0, 0)
		btnLabel.BackgroundTransparency = 1
		btnLabel.Text = text
		btnLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
		btnLabel.Font = Enum.Font.Michroma
		btnLabel.TextSize = 11
		btnLabel.TextXAlignment = Enum.TextXAlignment.Left
		btnLabel.Parent = btn
		btnLabel.ZIndex = 10

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0, 28, 1, 0)
		valueLabel.Position = UDim2.new(1, -38, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(optionsList[selected] or selected)
		valueLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
		valueLabel.Font = Enum.Font.Gotham
		valueLabel.TextSize = 11
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = btn
		valueLabel.ZIndex = 10

		local chevron = Instance.new("TextLabel")
		chevron.Size = UDim2.new(0, 16, 1, 0)
		chevron.Position = UDim2.new(1, -20, 0, 0)
		chevron.BackgroundTransparency = 1
		chevron.Text = open and "▾" or "▴"
		chevron.TextColor3 = Color3.fromRGB(120, 120, 130)
		chevron.Font = Enum.Font.Gotham
		chevron.TextSize = 12
		chevron.Parent = btn
		chevron.ZIndex = 10

		local listFrame = Instance.new("Frame")
		listFrame.Size = UDim2.new(1, 0, 0, 0)
		listFrame.Position = UDim2.new(0, 0, 0, yOff + 34)
		listFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		listFrame.BackgroundTransparency = 0.2
		listFrame.Visible = false
		listFrame.Parent = wrap
		listFrame.ZIndex = 12

		local listCorner = Instance.new("UICorner")
		listCorner.CornerRadius = UDim.new(0, 6)
		listCorner.Parent = listFrame

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 2)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = listFrame

		for i, opt in ipairs(optionsList) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1, -8, 0, 26)
			optBtn.Position = UDim2.new(0, 4, 0, (i-1)*28)
			optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			optBtn.BackgroundTransparency = 0.5
			optBtn.Text = opt
			optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
			optBtn.Font = Enum.Font.Gotham
			optBtn.TextSize = 11
			optBtn.LayoutOrder = i
			optBtn.Parent = listFrame
			optBtn.ZIndex = 13
			optBtn.MouseButton1Click:Connect(function()
				PlaySound()
				selected = i
				valueLabel.Text = tostring(optionsList[selected] or selected)
				chevron.Text = "▴"
				listFrame.Visible = false
				listFrame.Size = UDim2.new(1, 0, 0, 0)
				callback(optionsList[selected], i)
			end)
		end

		btn.MouseButton1Click:Connect(function()
			PlaySound()
			open = not open
			chevron.Text = open and "▾" or "▴"
			listFrame.Visible = open
			if open then
				listFrame.Size = UDim2.new(1, 0, 0, math.min(#optionsList * 28 + 8, 140))
			else
				listFrame.Size = UDim2.new(1, 0, 0, 0)
			end
		end)
		return { set = function(i) selected = math.clamp(i, 1, #optionsList); valueLabel.Text = tostring(optionsList[selected] or selected) end, get = function() return selected end }
	end

	-- Helpers for colorpicker (hex/rgb <-> Color3)
	local function rgbToHex(c)
		local r, g, b = math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)
		return string.format("#%02X%02X%02X", r, g, b)
	end
	local function rgbToRGBString(color)
		local r = math.floor(color.R * 255)
		local g = math.floor(color.G * 255)
		local b = math.floor(color.B * 255)
		return string.format("(%d, %d, %d)", r, g, b)
	end
	local function hexToColor3(hex)
		if hex:sub(1, 1) == "#" then hex = hex:sub(2) end
		if #hex ~= 6 then return nil end
		local r = tonumber(hex:sub(1, 2), 16)
		local g = tonumber(hex:sub(3, 4), 16)
		local b = tonumber(hex:sub(5, 6), 16)
		if not (r and g and b) then return nil end
		return Color3.fromRGB(r, g, b)
	end
	local function rgbStringToColor3(text)
		local r, g, b = text:match("%(?%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)?")
		r, g, b = tonumber(r), tonumber(g), tonumber(b)
		if not (r and g and b) then return nil end
		if r > 255 or g > 255 or b > 255 then return nil end
		return Color3.fromRGB(r, g, b)
	end

	local function AddColorPicker(parentPage, text, defaultColor, callback, options)
		options = options or {}
		local bio = options.bio or options.Bio
		local order = getNextLayoutOrder(parentPage)
		local current = defaultColor or Color3.fromRGB(255, 255, 255)
		local ColorH, ColorS, ColorV = current:ToHSV()

		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(0.9, 0, 0, bio and 52 or 34)
		wrap.BackgroundTransparency = 1
		wrap.Parent = parentPage
		wrap.LayoutOrder = order
		wrap.ZIndex = 8

		local yOff = 0
		if bio and #bio > 0 then
			local bioLabel = Instance.new("TextLabel")
			bioLabel.Size = UDim2.new(1, 0, 0, 14)
			bioLabel.Position = UDim2.new(0, 0, 0, 0)
			bioLabel.BackgroundTransparency = 1
			bioLabel.Text = bio
			bioLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
			bioLabel.Font = Enum.Font.Gotham
			bioLabel.TextSize = 10
			bioLabel.TextXAlignment = Enum.TextXAlignment.Left
			bioLabel.Parent = wrap
			bioLabel.ZIndex = 8
			yOff = 18
		end

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 26)
		row.Position = UDim2.new(0, 0, 0, yOff)
		row.BackgroundTransparency = 1
		row.Parent = wrap
		row.ZIndex = 8

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -50, 1, 0)
		label.Position = UDim2.new(0, 0, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.Font = Enum.Font.Michroma
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
		label.ZIndex = 8

		local preview = Instance.new("Frame")
		preview.Size = UDim2.new(0, 40, 0, 18)
		preview.Position = UDim2.new(1, -48, 0.5, -9)
		preview.BackgroundColor3 = current
		preview.Parent = row
		preview.ZIndex = 8
		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 4)
		previewCorner.Parent = preview
		local previewStroke = Instance.new("UIStroke")
		previewStroke.Color = Color3.fromRGB(70, 70, 78)
		previewStroke.Thickness = 1
		previewStroke.Parent = preview

		local arrowIcon = Instance.new("ImageLabel")
		arrowIcon.Size = UDim2.new(0, 12, 0, 12)
		arrowIcon.Position = UDim2.new(0, 4, 0.5, -6)
		arrowIcon.AnchorPoint = Vector2.new(0, 0.5)
		arrowIcon.Image = "rbxassetid://10709791523"
		arrowIcon.Rotation = -90
		arrowIcon.BackgroundTransparency = 1
		arrowIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		arrowIcon.Parent = preview
		arrowIcon.ZIndex = 9

		local colorPickerBtn = Instance.new("TextButton")
		colorPickerBtn.Size = UDim2.new(1, 0, 1, 0)
		colorPickerBtn.BackgroundTransparency = 1
		colorPickerBtn.Text = ""
		colorPickerBtn.Parent = row
		colorPickerBtn.ZIndex = 9

		colorPickerBtn.MouseButton1Click:Connect(function()
			PlaySound()
			local pickerFrame = Instance.new("Frame")
			pickerFrame.Size = UDim2.new(0, 260, 0, 200)
			pickerFrame.Position = UDim2.new(0.5, -130, 0.5, -100)
			pickerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			pickerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
			pickerFrame.BorderSizePixel = 0
			pickerFrame.Parent = sc
			pickerFrame.ZIndex = 100
			local pickerStroke = Instance.new("UIStroke")
			pickerStroke.Color = Color3.fromRGB(70, 70, 78)
			pickerStroke.Thickness = 1.5
			pickerStroke.Transparency = 0.3
			pickerStroke.Parent = pickerFrame
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = pickerFrame

			local topBar = Instance.new("Frame")
			topBar.Size = UDim2.new(1, 0, 0, 25)
			topBar.Position = UDim2.new(0, 0, 0, 0)
			topBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
			topBar.BorderSizePixel = 0
			topBar.Parent = pickerFrame
			topBar.ZIndex = 101
			local topBarCorner = Instance.new("UICorner")
			topBarCorner.CornerRadius = UDim.new(0, 6)
			topBarCorner.Parent = topBar

			local titleLabel = Instance.new("TextLabel")
			titleLabel.Size = UDim2.new(1, -70, 1, 0)
			titleLabel.Position = UDim2.new(0, 10, 0, 0)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Text = "Custom Color"
			titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
			titleLabel.Font = Enum.Font.Gotham
			titleLabel.TextSize = 12
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.Parent = topBar
			titleLabel.ZIndex = 102

			local randomBtn = Instance.new("ImageButton")
			randomBtn.Size = UDim2.new(0, 20, 0, 20)
			randomBtn.Position = UDim2.new(1, -50, 0.5, -10)
			randomBtn.AnchorPoint = Vector2.new(1, 0.5)
			randomBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			randomBtn.Image = "rbxassetid://7484765651"
			randomBtn.ScaleType = Enum.ScaleType.Fit
			randomBtn.Parent = topBar
			randomBtn.ZIndex = 102
			local randomCorner = Instance.new("UICorner")
			randomCorner.CornerRadius = UDim.new(0, 3)
			randomCorner.Parent = randomBtn

			local closeBtn = Instance.new("TextButton")
			closeBtn.Size = UDim2.new(0, 22, 0, 22)
			closeBtn.Position = UDim2.new(1, -26, 0.5, -11)
			closeBtn.AnchorPoint = Vector2.new(1, 0.5)
			closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
			closeBtn.Text = "X"
			closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			closeBtn.Font = Enum.Font.GothamBold
			closeBtn.TextSize = 12
			closeBtn.Parent = topBar
			closeBtn.ZIndex = 102
			closeBtn.AutoButtonColor = false
			local closeCorner = Instance.new("UICorner")
			closeCorner.CornerRadius = UDim.new(0, 4)
			closeCorner.Parent = closeBtn

			local colorPreview = Instance.new("Frame")
			colorPreview.Size = UDim2.new(0, 40, 0, 40)
			colorPreview.Position = UDim2.new(0, 15, 0, 35)
			colorPreview.BackgroundColor3 = current
			colorPreview.Parent = pickerFrame
			colorPreview.ZIndex = 101
			local colorPreviewCorner = Instance.new("UICorner")
			colorPreviewCorner.CornerRadius = UDim.new(0, 4)
			colorPreviewCorner.Parent = colorPreview
			local colorPreviewStroke = Instance.new("UIStroke")
			colorPreviewStroke.Color = Color3.fromRGB(90, 90, 95)
			colorPreviewStroke.Thickness = 1
			colorPreviewStroke.Parent = colorPreview

			local colorCodeBox = Instance.new("TextBox")
			colorCodeBox.Size = UDim2.new(0, 120, 0, 22)
			colorCodeBox.Position = UDim2.new(0, 65, 0, 35)
			colorCodeBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
			colorCodeBox.TextColor3 = Color3.fromRGB(230, 230, 230)
			colorCodeBox.Font = Enum.Font.Gotham
			colorCodeBox.TextSize = 12
			colorCodeBox.TextXAlignment = Enum.TextXAlignment.Left
			colorCodeBox.ClearTextOnFocus = false
			colorCodeBox.PlaceholderText = "HEX Color Code"
			colorCodeBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
			colorCodeBox.Text = rgbToHex(current)
			colorCodeBox.Parent = pickerFrame
			colorCodeBox.ZIndex = 101
			local codeBoxCorner = Instance.new("UICorner")
			codeBoxCorner.CornerRadius = UDim.new(0, 4)
			codeBoxCorner.Parent = colorCodeBox
			local codeBoxStroke = Instance.new("UIStroke")
			codeBoxStroke.Color = Color3.fromRGB(70, 70, 75)
			codeBoxStroke.Parent = colorCodeBox

			local colorCodeBoxUD = Instance.new("TextBox")
			colorCodeBoxUD.Size = UDim2.new(0, 120, 0, 22)
			colorCodeBoxUD.Position = UDim2.new(0, 65, 0, 62)
			colorCodeBoxUD.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
			colorCodeBoxUD.TextColor3 = Color3.fromRGB(230, 230, 230)
			colorCodeBoxUD.Font = Enum.Font.Gotham
			colorCodeBoxUD.TextSize = 12
			colorCodeBoxUD.TextXAlignment = Enum.TextXAlignment.Left
			colorCodeBoxUD.ClearTextOnFocus = false
			colorCodeBoxUD.PlaceholderText = "RGB Values"
			colorCodeBoxUD.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
			colorCodeBoxUD.Text = rgbToRGBString(current)
			colorCodeBoxUD.Parent = pickerFrame
			colorCodeBoxUD.ZIndex = 101
			local udCorner = Instance.new("UICorner")
			udCorner.CornerRadius = UDim.new(0, 4)
			udCorner.Parent = colorCodeBoxUD
			local udStroke = Instance.new("UIStroke")
			udStroke.Color = Color3.fromRGB(70, 70, 75)
			udStroke.Parent = colorCodeBoxUD

			-- Saturation/Value canvas (reference: ColorCanvas + satImage + ColorSelection)
			local colorCanvas = Instance.new("Frame")
			colorCanvas.Size = UDim2.new(0, 150, 0, 100)
			colorCanvas.Position = UDim2.new(0, 15, 0, 92)
			colorCanvas.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
			colorCanvas.Parent = pickerFrame
			colorCanvas.ZIndex = 101
			local canvasCorner = Instance.new("UICorner")
			canvasCorner.CornerRadius = UDim.new(0, 4)
			canvasCorner.Parent = colorCanvas
			local canvasStroke = Instance.new("UIStroke")
			canvasStroke.Color = Color3.fromRGB(70, 70, 75)
			canvasStroke.Parent = colorCanvas

			local satImage = Instance.new("ImageLabel")
			satImage.Size = UDim2.new(1, 0, 1, 0)
			satImage.AnchorPoint = Vector2.new(0.5, 0.5)
			satImage.Position = UDim2.new(0.5, 0, 0.5, 0)
			satImage.BackgroundTransparency = 1
			satImage.Image = "rbxassetid://4155801252"
			satImage.ScaleType = Enum.ScaleType.Stretch
			satImage.Parent = colorCanvas
			satImage.ZIndex = 102
			local satImageCorner = Instance.new("UICorner")
			satImageCorner.CornerRadius = UDim.new(0, 4)
			satImageCorner.Parent = satImage

			local colorSelection = Instance.new("ImageLabel")
			colorSelection.Size = UDim2.new(0, 14, 0, 14)
			colorSelection.AnchorPoint = Vector2.new(0.5, 0.5)
			colorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
			colorSelection.BackgroundTransparency = 1
			colorSelection.Image = "rbxassetid://4805639000"
			colorSelection.ImageColor3 = Color3.fromRGB(255, 255, 255)
			colorSelection.Parent = colorCanvas
			colorSelection.ZIndex = 103

			-- Vertical hue bar
			local hueBar = Instance.new("Frame")
			hueBar.Size = UDim2.new(0, 18, 0, 100)
			hueBar.Position = UDim2.new(1, -33, 0, 92)
			hueBar.BackgroundTransparency = 0
			hueBar.Parent = pickerFrame
			hueBar.ZIndex = 101
			local hueBarCorner = Instance.new("UICorner")
			hueBarCorner.CornerRadius = UDim.new(0, 4)
			hueBarCorner.Parent = hueBar
			local hueBarStroke = Instance.new("UIStroke")
			hueBarStroke.Color = Color3.fromRGB(70, 70, 75)
			hueBarStroke.Parent = hueBar

			local hueGrad = Instance.new("UIGradient")
			hueGrad.Rotation = 270
			hueGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 4)),
				ColorSequenceKeypoint.new(0.2, Color3.fromRGB(234, 255, 0)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(21, 255, 0)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 17, 255)),
				ColorSequenceKeypoint.new(0.9, Color3.fromRGB(255, 0, 251)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 4)),
			})
			hueGrad.Parent = hueBar

			local hueSelection = Instance.new("ImageLabel")
			hueSelection.Size = UDim2.new(0, 16, 0, 16)
			hueSelection.AnchorPoint = Vector2.new(0.5, 0.5)
			hueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
			hueSelection.BackgroundTransparency = 1
			hueSelection.Image = "rbxassetid://4805639000"
			hueSelection.ImageColor3 = Color3.fromRGB(255, 255, 255)
			hueSelection.Parent = hueBar
			hueSelection.ZIndex = 103

			local canvasConn, hueConn, canvasEndConn, hueEndConn
			local function updateColor()
				current = Color3.fromHSV(ColorH, ColorS, ColorV)
				preview.BackgroundColor3 = current
				colorPreview.BackgroundColor3 = current
				colorCanvas.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
				colorCodeBox.Text = rgbToHex(current)
				colorCodeBoxUD.Text = rgbToRGBString(current)
				colorSelection.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
				hueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
				callback(current)
			end

			colorCodeBox.FocusLost:Connect(function()
				local newColor = hexToColor3(colorCodeBox.Text)
				if newColor then
					local h, s, v = newColor:ToHSV()
					ColorH, ColorS, ColorV = h, s, v
					updateColor()
				end
			end)
			colorCodeBoxUD.FocusLost:Connect(function()
				local newColor = rgbStringToColor3(colorCodeBoxUD.Text)
				if newColor then
					local h, s, v = newColor:ToHSV()
					ColorH, ColorS, ColorV = h, s, v
					updateColor()
				end
			end)

			-- Canvas drag
			colorCanvas.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				local function doUpdate()
					local pos = input.Position or UserInputService:GetMouseLocation()
					local ax, ay = colorCanvas.AbsoluteSize.X, colorCanvas.AbsoluteSize.Y
					if ax <= 0 or ay <= 0 then return end
					local relX = (pos.X - colorCanvas.AbsolutePosition.X) / ax
					local relY = (pos.Y - colorCanvas.AbsolutePosition.Y) / ay
					local x = math.clamp(relX, 0, 1)
					local y = math.clamp(relY, 0, 1)
					colorSelection.Position = UDim2.new(x, 0, y, 0)
					ColorS = x
					ColorV = 1 - y
					updateColor()
				end
				doUpdate()
				if canvasConn then canvasConn:Disconnect() end
				if canvasEndConn then canvasEndConn:Disconnect() end
				canvasConn = UserInputService.InputChanged:Connect(function(changedInput)
					if (changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch) and
						(UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsTouchPressed()) then
						local pos = changedInput.Position or UserInputService:GetMouseLocation()
						local ax, ay = colorCanvas.AbsoluteSize.X, colorCanvas.AbsoluteSize.Y
						if ax > 0 and ay > 0 then
							local relX = (pos.X - colorCanvas.AbsolutePosition.X) / ax
							local relY = (pos.Y - colorCanvas.AbsolutePosition.Y) / ay
							local x = math.clamp(relX, 0, 1)
							local y = math.clamp(relY, 0, 1)
							colorSelection.Position = UDim2.new(x, 0, y, 0)
							ColorS = x
							ColorV = 1 - y
							updateColor()
						end
					end
				end)
				canvasEndConn = UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
						if canvasConn then canvasConn:Disconnect() canvasConn = nil end
						if canvasEndConn then canvasEndConn:Disconnect() canvasEndConn = nil end
					end
				end)
			end)

			-- Hue bar drag (vertical: Y 0 = top = hue 1, Y 1 = bottom = hue 0)
			hueBar.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				local function doUpdate()
					local pos = input.Position or UserInputService:GetMouseLocation()
					local ay = hueBar.AbsoluteSize.Y
					if ay <= 0 then return end
					local relY = (pos.Y - hueBar.AbsolutePosition.Y) / ay
					local y = math.clamp(relY, 0, 1)
					hueSelection.Position = UDim2.new(0.5, 0, y, 0)
					ColorH = 1 - y
					updateColor()
				end
				doUpdate()
				if hueConn then hueConn:Disconnect() end
				if hueEndConn then hueEndConn:Disconnect() end
				hueConn = UserInputService.InputChanged:Connect(function(changedInput)
					if (changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch) and
						(UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsTouchPressed()) then
						local pos = changedInput.Position or UserInputService:GetMouseLocation()
						local ay = hueBar.AbsoluteSize.Y
						if ay > 0 then
							local relY = (pos.Y - hueBar.AbsolutePosition.Y) / ay
							local y = math.clamp(relY, 0, 1)
							hueSelection.Position = UDim2.new(0.5, 0, y, 0)
							ColorH = 1 - y
							updateColor()
						end
					end
				end)
				hueEndConn = UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
						if hueConn then hueConn:Disconnect() hueConn = nil end
						if hueEndConn then hueEndConn:Disconnect() hueEndConn = nil end
					end
				end)
			end)

			randomBtn.MouseButton1Click:Connect(function()
				PlaySound()
				local rnd = Color3.new(math.random(), math.random(), math.random())
				local h, s, v = rnd:ToHSV()
				ColorH, ColorS, ColorV = h, s, v
				updateColor()
			end)

			closeBtn.MouseButton1Click:Connect(function()
				PlaySound()
				if canvasConn then canvasConn:Disconnect() end
				if hueConn then hueConn:Disconnect() end
				if canvasEndConn then canvasEndConn:Disconnect() end
				if hueEndConn then hueEndConn:Disconnect() end
				pickerFrame:Destroy()
			end)
		end)

		return {
			set = function(c)
				current = c
				local h, s, v = c:ToHSV()
				ColorH, ColorS, ColorV = h, s, v
				preview.BackgroundColor3 = c
				callback(c)
			end,
			get = function() return current end
		}
	end

	local function AddSlider(parentPage, text, minVal, maxVal, defaultVal, callback, options)
		options = options or {}
		local bio = options.bio or options.Bio
		local order = getNextLayoutOrder(parentPage)
		local value = math.clamp(defaultVal or minVal, minVal, maxVal)
		local trackW, trackH = 120, 6

		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(0.9, 0, 0, bio and 52 or 38)
		wrap.BackgroundTransparency = 1
		wrap.Parent = parentPage
		wrap.LayoutOrder = order
		wrap.ZIndex = 8

		local yOff = 0
		if bio and #bio > 0 then
			local bioLabel = Instance.new("TextLabel")
			bioLabel.Size = UDim2.new(1, 0, 0, 14)
			bioLabel.Position = UDim2.new(0, 0, 0, 0)
			bioLabel.BackgroundTransparency = 1
			bioLabel.Text = bio
			bioLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
			bioLabel.Font = Enum.Font.Gotham
			bioLabel.TextSize = 10
			bioLabel.TextXAlignment = Enum.TextXAlignment.Left
			bioLabel.Parent = wrap
			bioLabel.ZIndex = 8
			yOff = 18
		end

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 28)
		row.Position = UDim2.new(0, 0, 0, yOff)
		row.BackgroundTransparency = 1
		row.Parent = wrap
		row.ZIndex = 8

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -140, 1, 0)
		label.Position = UDim2.new(0, 0, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(220, 220, 230)
		label.Font = Enum.Font.Michroma
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
		label.ZIndex = 8

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0, 44, 1, 0)
		valueLabel.Position = UDim2.new(1, -130, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = string.format("%.1f", value)
		valueLabel.TextColor3 = Color3.fromRGB(0, 122, 255)
		valueLabel.Font = Enum.Font.Gotham
		valueLabel.TextSize = 11
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = row
		valueLabel.ZIndex = 8

		local range = math.max(maxVal - minVal, 0.001)
		local function tFromValue(v) return math.clamp((v - minVal) / range, 0, 1) end

		local track = Instance.new("Frame")
		track.Size = UDim2.new(0, trackW, 0, trackH)
		track.Position = UDim2.new(1, -trackW, 0.5, -trackH/2)
		track.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		track.Parent = row
		track.ZIndex = 8
		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(1, 0)
		trackCorner.Parent = track

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(tFromValue(value), 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
		fill.Parent = track
		fill.ZIndex = 9
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = fill

		local thumb = Instance.new("Frame")
		thumb.Size = UDim2.new(0, 10, 0, 14)
		thumb.Position = UDim2.new(tFromValue(value), -5, 0.5, -7)
		thumb.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
		thumb.Parent = track
		thumb.ZIndex = 10
		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = UDim.new(0, 2)
		thumbCorner.Parent = thumb

		local function setValue(v)
			value = math.clamp(v, minVal, maxVal)
			local t = tFromValue(value)
			fill.Size = UDim2.new(t, 0, 1, 0)
			thumb.Position = UDim2.new(t, -5, 0.5, -7)
			valueLabel.Text = string.format("%.1f", value)
			callback(value)
		end

		local dragging = false
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				PlaySound()
				dragging = true
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
				setValue(minVal + rel * (maxVal - minVal))
			end
		end)
		return { set = setValue, get = function() return value end }
	end

	local function AddTextbox(parentPage, text, placeholder, defaultText, callback, options)
		options = options or {}
		local bio = options.bio or options.Bio
		local order = getNextLayoutOrder(parentPage)
		local currentText = defaultText or ""

		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(0.9, 0, 0, bio and 52 or 34)
		wrap.BackgroundTransparency = 1
		wrap.Parent = parentPage
		wrap.LayoutOrder = order
		wrap.ZIndex = 8

		local yOff = 0
		if bio and #bio > 0 then
			local bioLabel = Instance.new("TextLabel")
			bioLabel.Size = UDim2.new(1, 0, 0, 14)
			bioLabel.Position = UDim2.new(0, 0, 0, 0)
			bioLabel.BackgroundTransparency = 1
			bioLabel.Text = bio
			bioLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
			bioLabel.Font = Enum.Font.Gotham
			bioLabel.TextSize = 10
			bioLabel.TextXAlignment = Enum.TextXAlignment.Left
			bioLabel.Parent = wrap
			bioLabel.ZIndex = 8
			yOff = 18
		end

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 28)
		row.Position = UDim2.new(0, 0, 0, yOff)
		row.BackgroundTransparency = 1
		row.Parent = wrap
		row.ZIndex = 8

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0, 0, 1, 0)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Position = UDim2.new(0, 0, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(220, 220, 230)
		label.Font = Enum.Font.Michroma
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
		label.ZIndex = 8

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -80, 1, 0)
		box.Position = UDim2.new(0, 0, 0, 0)
		box.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		box.BorderSizePixel = 0
		box.PlaceholderText = placeholder or "Type here..."
		box.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
		box.Text = currentText
		box.TextColor3 = Color3.fromRGB(220, 220, 230)
		box.Font = Enum.Font.Gotham
		box.TextSize = 11
		box.ClearTextOnFocus = false
		box.Parent = row
		box.ZIndex = 9
		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = UDim.new(0, 5)
		boxCorner.Parent = box
		box.FocusLost:Connect(function(enter)
			PlaySound()
			currentText = box.Text
			callback(box.Text, enter)
		end)
		local editIcon = Instance.new("ImageLabel")
		editIcon.Size = UDim2.new(0, 18, 0, 18)
		editIcon.Position = UDim2.new(1, -24, 0.5, -9)
		editIcon.BackgroundTransparency = 1
		editIcon.Image = "rbxassetid://10723344885"
		editIcon.ImageColor3 = Color3.fromRGB(140, 140, 150)
		editIcon.Parent = row
		editIcon.ZIndex = 9
		return { set = function(t) currentText = t; box.Text = t end, get = function() return box.Text end }
	end

	local function toggleMinimize()
		if isAnimating then return end
		isAnimating = true
		if not isMinimized then
			PlaySound()
			minimizeButton.Text = "+"
			tabHolder.Visible = false
			pageHolder.Visible = false
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(mainFrame, tweenInfo, {Size = minimizedSize}):Play()
			task.wait(0.5)
			isMinimized = true
		else
			PlaySound()
			minimizeButton.Text = "—"
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(mainFrame, tweenInfo, {Size = currentMainFrameSize}):Play()
			task.wait(0.5)
			tabHolder.Visible = true
			pageHolder.Visible = true
			isMinimized = false
		end
		isAnimating = false
	end

	minimizeButton.MouseButton1Click:Connect(toggleMinimize)

	closeButton.MouseButton1Click:Connect(function()
		PlaySound()
		if isAnimating then return end
		isAnimating = true
		local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()
		task.wait(0.4)
		if closeCallback then sc:Destroy() end
	end)

	local toggleIconUrl = options.ToggleIcon or options.Icon or "rbxassetid://110661788517806"
	local mainFrameHideShowButton = Instance.new("ImageButton")
	mainFrameHideShowButton.Name = "HideShowButton"
	mainFrameHideShowButton.Parent = sc
	mainFrameHideShowButton.Size = UDim2.new(0, 45, 0, 45)
	mainFrameHideShowButton.Position = UDim2.new(0, 20, 0, 20)
	mainFrameHideShowButton.Image = toggleIconUrl
	mainFrameHideShowButton.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
	mainFrameHideShowButton.BackgroundTransparency = 0.2
	mainFrameHideShowButton.ZIndex = 20
	mainFrameHideShowButton.Active = true
	mainFrameHideShowButton.Draggable = true

	local hideShowButtonCorner = Instance.new("UICorner")
	hideShowButtonCorner.CornerRadius = UDim.new(0.5, 0)
	hideShowButtonCorner.Parent = mainFrameHideShowButton

	local isMainFrameVisible = true
	mainFrameHideShowButton.MouseButton1Click:Connect(function()
		if isAnimating then return end
		isMainFrameVisible = not isMainFrameVisible
		mainFrame.Visible = isMainFrameVisible
	end)

	local function applyCalmJelly(ui, dragPart)
		local dragging = false
		local dragInput
		local dragStartPos
		local startPos
		local targetPos = ui.Position
		local currentVel = Vector2.new(0, 0)
		dragPart.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStartPos = input.Position
				startPos = ui.Position
				local connection
				connection = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						connection:Disconnect()
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				dragInput = input
			end
		end)
		RunService.RenderStepped:Connect(function()
			if isAnimating then return end
			if resizing then
				mainFrame.Size = currentMainFrameSize
				return
			end
			local currentOffset = Vector2.new(ui.Position.X.Offset, ui.Position.Y.Offset)
			if dragging and dragInput then
				local delta = dragInput.Position - dragStartPos
				targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
			local goalPos = Vector2.new(targetPos.X.Offset, targetPos.Y.Offset)
			local dist = goalPos - currentOffset
			local force = dist * CONFIG_JELLY.STIFFNESS
			currentVel = currentVel * (1 - CONFIG_JELLY.DAMPING) + force
			local newOffset = currentOffset + currentVel
			ui.Position = UDim2.new(targetPos.X.Scale, newOffset.X, targetPos.Y.Scale, newOffset.Y)
			local velX = math.abs(currentVel.X)
			local velY = math.abs(currentVel.Y)
			local stretchX = 1
			local stretchY = 1
			if dragging or currentVel.Magnitude > 0.5 then
				stretchX = math.clamp(1 + (velX * CONFIG_JELLY.STRETCH_FORCE) - (velY * CONFIG_JELLY.STRETCH_FORCE/2), CONFIG_JELLY.MIN_STRETCH, CONFIG_JELLY.MAX_STRETCH)
				stretchY = math.clamp(1 + (velY * CONFIG_JELLY.STRETCH_FORCE) - (velX * CONFIG_JELLY.STRETCH_FORCE/2), CONFIG_JELLY.MIN_STRETCH, CONFIG_JELLY.MAX_STRETCH)
			end
			local currentBaseSize = isMinimized and minimizedSize or currentMainFrameSize
			ui.Size = ui.Size:Lerp(UDim2.new(currentBaseSize.X.Scale, currentBaseSize.X.Offset * stretchX, currentBaseSize.Y.Scale, currentBaseSize.Y.Offset * stretchY), 0.1)
		end)
	end

	applyCalmJelly(mainFrame, titleLabel)

	-- Resize handle: drag bottom-right edge to make window bigger or smaller (min/max applied)
	local resizeHandle = Instance.new("Frame")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.new(0, 24, 0, 24)
	resizeHandle.Position = UDim2.new(1, -24, 1, -24)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.Parent = mainFrame
	resizeHandle.ZIndex = 15
	local resizeCorner = Instance.new("UICorner")
	resizeCorner.CornerRadius = UDim.new(0, 4)
	resizeCorner.Parent = resizeHandle
	local resizeIcon = Instance.new("TextLabel")
	resizeIcon.Size = UDim2.new(1, 0, 1, 0)
	resizeIcon.BackgroundTransparency = 1
	resizeIcon.Text = "⤡"
	resizeIcon.TextColor3 = Color3.fromRGB(120, 120, 130)
	resizeIcon.TextSize = 14
	resizeIcon.Parent = resizeHandle
	resizeIcon.ZIndex = 16
	resizeHandle.InputBegan:Connect(function(input)
		if isMinimized or isAnimating then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not resizing then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local topLeft = mainFrame.AbsolutePosition
			local newW = math.clamp(input.Position.X - topLeft.X, minW, maxW)
			local newH = math.clamp(input.Position.Y - topLeft.Y, minH, maxH)
			currentMainFrameSize = UDim2.new(0, newW, 0, newH)
			mainFrame.Size = currentMainFrameSize
		end
	end)

	for i = 1, 40 do
		local dot = Instance.new("Frame", mainFrame)
		dot.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
		dot.Position = UDim2.new(0, math.random(0, 450), 0, math.random(0, 300))
		dot.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
		dot.BorderSizePixel = 0
		dot.BackgroundTransparency = math.random() * 0.7
		dot.ZIndex = 5
		task.spawn(function()
			while true do
				local newPos = UDim2.new(0, math.random(0, 450), 0, math.random(0, 300))
				local tween = TweenService:Create(dot, TweenInfo.new(math.random(2, 5), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = newPos})
				tween:Play()
				tween.Completed:Wait()
			end
		end)
	end

	task.spawn(function()
		isAnimating = true
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(mainFrame, tweenInfo, {
			Size = originalMainFrameSize,
			Position = UDim2.new(0.5, -225, 0.5, -150)
		}):Play()
		task.wait(0.6)
		isAnimating = false
		StartSound:Play()
	end)

	return {
		MakeTab = function(self, tabOpts)
			tabOpts = tabOpts or {}
			local page = CreateTab(tabOpts.Name or "Tab", tabOpts.Icon)
			return {
				AddSection = function(_, title, bio) return AddSection(page, title, bio) end,
				AddButton = function(_, text, callback, opt) return AddButton(page, text, callback, opt) end,
				AddToggle = function(_, text, default, callback, opt) return AddToggle(page, text, default, callback, opt) end,
				AddParagraph = function(_, text, opt) return AddParagraph(page, text, opt) end,
				AddTextbox = function(_, text, placeholder, defaultText, callback, opt) return AddTextbox(page, text, placeholder, defaultText, callback, opt) end,
				AddSlider = function(_, text, minV, maxV, defaultV, callback, opt) return AddSlider(page, text, minV, maxV, defaultV, callback, opt) end,
				AddDropdown = function(_, text, list, defaultIndex, callback, opt) return AddDropdown(page, text, list, defaultIndex, callback, opt) end,
				AddColorPicker = function(_, text, defaultColor, callback, opt) return AddColorPicker(page, text, defaultColor, callback, opt) end,
			}
		end
	}
end

return {
	MakeWindow = function(self, options)
		return makeWindow(options)
	end
}
