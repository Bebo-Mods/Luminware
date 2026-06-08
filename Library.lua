--[[
    LUMINWARE UI Library v2.0
    Acrylic / Glassmorphism style
    
    Usage:
        local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
        local Window  = Library:CreateWindow({ Title = 'LUMINWARE', Logo = 'rbxassetid://...' })
        local Tab     = Window:AddTab({ Name = 'Aimbot', Icon = 'rbxassetid://...' })
        local Section = Tab:AddSection('Targeting')
        Section:AddToggle('MyToggle', { Label = 'Silent Aim', Default = false, Callback = function(v) end })
]]

-- ============================================================
-- SERVICES
-- ============================================================
local TweenService  = game:GetService("TweenService")
local UserInput     = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local Players       = game:GetService("Players")
local CoreGui       = game:GetService("CoreGui")
local HttpService   = game:GetService("HttpService")
local TextService   = game:GetService("TextService")

local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()

-- ============================================================
-- GUI PROTECTION
-- ============================================================
local ProtectGui = (typeof(syn) == "table" and syn.protect_gui)
    or (typeof(protectgui) == "function" and protectgui)
    or function() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "LuminwareUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn   = false
pcall(ProtectGui, ScreenGui)
ScreenGui.Parent = (typeof(gethui) == "function" and gethui()) or CoreGui

-- ============================================================
-- SAFE GETGENV
-- ============================================================
local _genv = {}
pcall(function() if typeof(getgenv) == "function" then _genv = getgenv() end end)

-- ============================================================
-- LIBRARY CORE
-- ============================================================
local Library = {
    -- Theme-driven color tokens
    Accent      = Color3.fromRGB(94, 158, 255);   -- blue default (FROST)
    AccentDark  = Color3.fromRGB(60, 100, 200);
    Glass       = Color3.fromRGB(30,  32,  40 );  -- acrylic panel tint
    GlassDark   = Color3.fromRGB(18,  20,  26 );  -- darker panel layer
    GlassEdge   = Color3.fromRGB(255,255,255);     -- edge highlight
    Sidebar     = Color3.fromRGB(20,  22,  30 );
    Text        = Color3.fromRGB(240, 240, 255);
    TextMuted   = Color3.fromRGB(150, 155, 175);
    TextDim     = Color3.fromRGB(90,  95,  120);
    
    Font        = Enum.Font.GothamMedium;
    FontBold    = Enum.Font.GothamBold;
    FontSemi    = Enum.Font.GothamSemibold;

    -- Internals
    Registry    = {};
    RegistryMap = {};
    Signals     = {};
    Popups      = {};
    Glows       = {};
    GlowEnabled = true;
    ScreenGui   = ScreenGui;
    Toggles     = {};
    Options     = {};

    -- Built-in themes
    Themes = {
        FROST    = { Accent = Color3.fromRGB(94,  158, 255), Glass = Color3.fromRGB(28, 32, 45),  GlassDark = Color3.fromRGB(15, 18, 28),  Sidebar = Color3.fromRGB(18, 20, 32)  };
        VENOM    = { Accent = Color3.fromRGB(168, 85,  247), Glass = Color3.fromRGB(30, 24, 44),  GlassDark = Color3.fromRGB(16, 12, 26),  Sidebar = Color3.fromRGB(20, 14, 32)  };
        BLOOD    = { Accent = Color3.fromRGB(220, 55,  55 ), Glass = Color3.fromRGB(38, 22, 22),  GlassDark = Color3.fromRGB(22, 10, 10),  Sidebar = Color3.fromRGB(28, 12, 12)  };
        EMBER    = { Accent = Color3.fromRGB(255, 140, 0  ), Glass = Color3.fromRGB(36, 28, 18),  GlassDark = Color3.fromRGB(20, 14, 8 ),  Sidebar = Color3.fromRGB(26, 18, 8 )  };
        ACID     = { Accent = Color3.fromRGB(140, 220, 0  ), Glass = Color3.fromRGB(22, 32, 18),  GlassDark = Color3.fromRGB(10, 18, 8 ),  Sidebar = Color3.fromRGB(14, 22, 10)  };
        GHOST    = { Accent = Color3.fromRGB(200, 200, 220), Glass = Color3.fromRGB(32, 34, 40),  GlassDark = Color3.fromRGB(18, 20, 24),  Sidebar = Color3.fromRGB(22, 24, 30)  };
    };
}

_genv.Toggles = Library.Toggles
_genv.Options  = Library.Options

-- ============================================================
-- HELPERS
-- ============================================================
function Library:Tween(inst, props, dur, style, dir)
    local ti = TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    TweenService:Create(inst, ti, props):Play()
end

function Library:Create(class, props)
    local inst = type(class) == "string" and Instance.new(class) or class
    for k, v in next, props do
        if k ~= "Parent" then pcall(function() inst[k] = v end) end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

function Library:Round(inst, r)
    return self:Create("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = inst })
end

function Library:Stroke(inst, col, thick, trans)
    return self:Create("UIStroke", {
        Color           = col or self.GlassEdge,
        Thickness       = thick or 1,
        Transparency    = trans or 0.88,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent          = inst,
    })
end

-- Acrylic panel: frosted glass look via layered semi-transparent frames
function Library:AcrylicFrame(props)
    -- Base dark layer
    local outer = self:Create("Frame", {
        BackgroundColor3 = props.Color or self.Glass,
        BackgroundTransparency = props.Transparency or 0.35,
        BorderSizePixel  = 0,
        Position         = props.Position or UDim2.new(0,0,0,0),
        Size             = props.Size or UDim2.new(1,0,1,0),
        ZIndex           = props.ZIndex or 1,
        ClipsDescendants = props.ClipsDescendants or false,
        Parent           = props.Parent,
    })
    if props.Radius then self:Round(outer, props.Radius) end
    -- Subtle inner highlight (top edge glow)
    local highlight = self:Create("Frame", {
        BackgroundColor3       = self.GlassEdge,
        BackgroundTransparency = 0.92,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 1),
        ZIndex                 = (props.ZIndex or 1) + 1,
        Parent                 = outer,
    })
    -- Stroke edge
    local stroke = self:Stroke(outer, self.GlassEdge, 1, 0.88)
    
    -- Register for theme updates
    table.insert(self.Registry, { inst = outer, prop = "BackgroundColor3", key = "Glass" })
    
    outer._stroke    = stroke
    outer._highlight = highlight
    return outer
end

-- ============================================================
-- REGISTRY / THEME
-- ============================================================
function Library:AddReg(inst, prop, key)
    local entry = { inst = inst, prop = prop, key = key }
    table.insert(self.Registry, entry)
    self.RegistryMap[inst] = entry
end

function Library:SetTheme(name)
    local t = self.Themes[name]
    if not t then return end
    
    -- Tween the accent and glass colors
    self.Accent     = t.Accent
    self.AccentDark = Color3.fromHSV((function()
        local h,s,v = Color3.toHSV(t.Accent); return h,s,v*0.65
    end)())
    self.Glass      = t.Glass
    self.GlassDark  = t.GlassDark
    self.Sidebar    = t.Sidebar
    self._currentTheme = name

    -- Update all registered instances with smooth tween
    for _, entry in next, self.Registry do
        if entry.inst and entry.inst.Parent then
            local col = self[entry.key]
            if typeof(col) == "Color3" then
                self:Tween(entry.inst, { [entry.prop] = col }, 0.4)
            end
        end
    end
    
    -- Flash effect
    if self._flashFrame then
        self._flashFrame.Visible = true
        self:Tween(self._flashFrame, { BackgroundTransparency = 1 }, 0.5)
        task.delay(0.5, function()
            if self._flashFrame then self._flashFrame.Visible = false; self._flashFrame.BackgroundTransparency = 0.88 end
        end)
    end
end

-- ============================================================
-- NOTIFICATIONS — bottom right toasts
-- ============================================================
local NotifArea = Library:Create("Frame", {
    BackgroundTransparency = 1,
    AnchorPoint            = Vector2.new(1,1),
    Position               = UDim2.new(1,-18,1,-18),
    Size                   = UDim2.new(0,280,0,400),
    ZIndex                 = 500,
    Parent                 = ScreenGui,
})
Library:Create("UIListLayout", {
    VerticalAlignment   = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    FillDirection       = Enum.FillDirection.Vertical,
    Padding             = UDim.new(0, 8),
    SortOrder           = Enum.SortOrder.LayoutOrder,
    Parent              = NotifArea,
})

function Library:Notify(opts)
    if type(opts) == "string" then opts = { Title = opts, Duration = 4 } end
    local title    = opts.Title or "Notification"
    local body     = opts.Body  or ""
    local duration = opts.Duration or 4

    local card = self:Create("Frame", {
        BackgroundColor3       = self.GlassDark,
        BackgroundTransparency = 0.15,
        Size                   = UDim2.new(1,0,0, body~="" and 66 or 44),
        ZIndex                 = 501,
        ClipsDescendants       = true,
        Parent                 = NotifArea,
    })
    self:Round(card, 10)
    self:Stroke(card, self.GlassEdge, 1, 0.84)

    -- Accent left bar
    local bar = self:Create("Frame", {
        BackgroundColor3 = self.Accent,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0,3,1,0),
        ZIndex           = 502,
        Parent           = card,
    })
    self:Round(bar, 2)
    self:AddReg(bar, "BackgroundColor3", "Accent")

    self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font                   = self.FontBold,
        Text                   = title,
        TextColor3             = self.Text,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Position               = UDim2.new(0,14,0,8),
        Size                   = UDim2.new(1,-18,0,18),
        ZIndex                 = 502,
        Parent                 = card,
    })

    if body ~= "" then
        self:Create("TextLabel", {
            BackgroundTransparency = 1,
            Font                   = self.Font,
            Text                   = body,
            TextColor3             = self.TextMuted,
            TextSize               = 12,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextWrapped            = true,
            Position               = UDim2.new(0,14,0,28),
            Size                   = UDim2.new(1,-18,0,30),
            ZIndex                 = 502,
            Parent                 = card,
        })
    end

    -- Progress bar
    local prog = self:Create("Frame", {
        BackgroundColor3 = self.Accent,
        BackgroundTransparency = 0.5,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0,1),
        Position         = UDim2.new(0,0,1,0),
        Size             = UDim2.new(1,0,0,2),
        ZIndex           = 503,
        Parent           = card,
    })
    self:AddReg(prog, "BackgroundColor3", "Accent")

    -- Fade in
    card.BackgroundTransparency = 1
    self:Tween(card, { BackgroundTransparency = 0.15 }, 0.25)
    self:Tween(prog, { Size = UDim2.new(0,0,0,2) }, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

    task.delay(duration, function()
        self:Tween(card, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.35)
        pcall(function() card:Destroy() end)
    end)
end

-- ============================================================
-- DRAGGABLE
-- ============================================================
function Library:MakeDraggable(handle, target, cutoffY)
    handle.Active = true
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local rel = handle.AbsolutePosition
        if cutoffY and (Mouse.Y - rel.Y) > cutoffY then return end
        dragging  = true
        dragStart = Vector2.new(Mouse.X, Mouse.Y)
        startPos  = target.Position
    end)
    UserInput.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = Vector2.new(Mouse.X, Mouse.Y) - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInput.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- ============================================================
-- CREATE WINDOW
-- ============================================================
function Library:CreateWindow(config)
    config = config or {}
    local title    = config.Title    or "LUMINWARE"
    local logoId   = config.Logo     or ""
    local size     = config.Size     or Vector2.new(860, 540)
    local centerIt = config.Center ~= false

    local Window = { Tabs = {}, _tabOrder = {} }

    -- ── OUTER SHELL ────────────────────────────────────────
    local Root = self:Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint            = centerIt and Vector2.new(0.5,0.5) or Vector2.zero,
        Position               = centerIt and UDim2.fromScale(0.5,0.5) or UDim2.fromOffset(60,60),
        Size                   = UDim2.fromOffset(size.X, size.Y),
        ZIndex                 = 2,
        Parent                 = ScreenGui,
    })

    -- Drop shadow
    local shadow = self:Create("ImageLabel", {
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://5028857084",
        ImageColor3            = Color3.new(0,0,0),
        ImageTransparency      = 0.55,
        ScaleType              = Enum.ScaleType.Slice,
        SliceCenter            = Rect.new(24,24,276,276),
        AnchorPoint            = Vector2.new(0.5,0.5),
        Position               = UDim2.new(0.5,0,0.5,6),
        Size                   = UDim2.new(1,48,1,48),
        ZIndex                 = 1,
        Parent                 = Root,
    })

    -- Main container (acrylic background)
    local Main = self:Create("Frame", {
        BackgroundColor3       = self.GlassDark,
        BackgroundTransparency = 0.08,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,1,0),
        ZIndex                 = 2,
        Parent                 = Root,
    })
    self:Round(Main, 14)
    self:Stroke(Main, self.GlassEdge, 1, 0.82)
    self:AddReg(Main, "BackgroundColor3", "GlassDark")

    -- Drag handle (title bar strip)
    self:MakeDraggable(Main, Root, 52)

    -- Flash effect frame (theme transition)
    self._flashFrame = self:Create("Frame", {
        BackgroundColor3       = Color3.new(1,1,1),
        BackgroundTransparency = 0.88,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,1,0),
        ZIndex                 = 200,
        Visible                = false,
        Parent                 = Main,
    })
    self:Round(self._flashFrame, 14)

    -- ── SIDEBAR ────────────────────────────────────────────
    local Sidebar = self:Create("Frame", {
        BackgroundColor3       = self.Sidebar,
        BackgroundTransparency = 0.12,
        BorderSizePixel        = 0,
        Size                   = UDim2.fromOffset(64, size.Y),
        ZIndex                 = 3,
        Parent                 = Main,
    })
    self:Create("UICorner", { CornerRadius = UDim.new(0,14), Parent = Sidebar })
    -- Clip right corners (only left side rounds)
    self:Create("Frame", {
        BackgroundColor3 = self.Sidebar,
        BackgroundTransparency = 0.12,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5,0,0,0),
        Size             = UDim2.new(0.5,0,1,0),
        ZIndex           = 3,
        Parent           = Sidebar,
    })
    self:AddReg(Sidebar, "BackgroundColor3", "Sidebar")

    -- Logo/icon at top of sidebar
    local logoArea = self:Create("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.fromOffset(64, 64),
        ZIndex                 = 4,
        Parent                 = Sidebar,
    })
    if logoId ~= "" then
        self:Create("ImageLabel", {
            BackgroundTransparency = 1,
            AnchorPoint            = Vector2.new(0.5,0.5),
            Position               = UDim2.fromScale(0.5,0.5),
            Size                   = UDim2.fromOffset(36,36),
            Image                  = logoId,
            ScaleType              = Enum.ScaleType.Fit,
            ZIndex                 = 5,
            Parent                 = logoArea,
        })
    else
        -- Default diamond logo mark
        local diamond = self:Create("Frame", {
            AnchorPoint      = Vector2.new(0.5,0.5),
            Position         = UDim2.fromScale(0.5,0.5),
            Size             = UDim2.fromOffset(22,22),
            BackgroundColor3 = self.Accent,
            Rotation         = 45,
            ZIndex           = 5,
            Parent           = logoArea,
        })
        self:Round(diamond, 4)
        self:AddReg(diamond, "BackgroundColor3", "Accent")
    end

    -- Nav icon list
    local NavList = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position               = UDim2.fromOffset(0, 72),
        Size                   = UDim2.new(1,0,1,-120),
        ZIndex                 = 4,
        Parent                 = Sidebar,
    })
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding       = UDim.new(0,4),
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Parent        = NavList,
    })

    -- Power button at bottom
    local powerBtn = self:Create("TextButton", {
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(0.5,1),
        Position               = UDim2.new(0.5,0,1,-14),
        Size                   = UDim2.fromOffset(40,40),
        Text                   = "",
        ZIndex                 = 4,
        Parent                 = Sidebar,
    })
    self:Create("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(0.5,0.5),
        Position               = UDim2.fromScale(0.5,0.5),
        Size                   = UDim2.fromOffset(18,18),
        Image                  = "rbxassetid://7059364814",
        ImageColor3            = self.TextDim,
        ZIndex                 = 5,
        Parent                 = powerBtn,
    })
    powerBtn.MouseButton1Click:Connect(function()
        self:Notify({ Title = "Closing...", Duration = 1 })
        task.delay(0.8, function() self:Unload() end)
    end)
    powerBtn.MouseEnter:Connect(function()
        self:Tween(powerBtn:FindFirstChildOfClass("ImageLabel"), { ImageColor3 = Color3.fromRGB(220,60,60) }, 0.15)
    end)
    powerBtn.MouseLeave:Connect(function()
        self:Tween(powerBtn:FindFirstChildOfClass("ImageLabel"), { ImageColor3 = self.TextDim }, 0.15)
    end)

    -- ── CONTENT AREA ────────────────────────────────────────
    local Content = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position               = UDim2.fromOffset(72,0),
        Size                   = UDim2.new(1,-72,1,0),
        ZIndex                 = 3,
        Parent                 = Main,
    })

    -- Content top bar (title + theme indicator)
    local TopBar = self:Create("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1,0,0,52),
        ZIndex                 = 4,
        Parent                 = Content,
    })
    self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font                   = self.FontBold,
        Text                   = string.upper(title),
        TextColor3             = self.Text,
        TextSize               = 16,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Position               = UDim2.new(0,14,0,0),
        Size                   = UDim2.new(0.5,0,1,0),
        ZIndex                 = 5,
        Parent                 = TopBar,
    })

    -- Theme dots in top right
    local themeRow = self:Create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(1,0.5),
        Position               = UDim2.new(1,-14,0.5,0),
        Size                   = UDim2.fromOffset(110,16),
        ZIndex                 = 5,
        Parent                 = TopBar,
    })
    self:Create("UIListLayout", {
        FillDirection       = Enum.FillDirection.Horizontal,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding             = UDim.new(0,6),
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Parent              = themeRow,
    })

    local themeOrder = { "FROST","VENOM","BLOOD","EMBER","ACID","GHOST" }
    for _, tname in ipairs(themeOrder) do
        local tdata = self.Themes[tname]
        local dot = self:Create("TextButton", {
            BackgroundColor3 = tdata.Accent,
            Size             = UDim2.fromOffset(10,10),
            Text             = "",
            ZIndex           = 6,
            Parent           = themeRow,
        })
        self:Round(dot, 5)
        local tn = tname
        dot.MouseButton1Click:Connect(function()
            self:SetTheme(tn)
        end)
        dot.MouseEnter:Connect(function()
            self:Tween(dot, { Size = UDim2.fromOffset(13,13) }, 0.12)
        end)
        dot.MouseLeave:Connect(function()
            self:Tween(dot, { Size = UDim2.fromOffset(10,10) }, 0.12)
        end)
    end

    -- Divider under top bar
    self:Create("Frame", {
        BackgroundColor3       = self.GlassEdge,
        BackgroundTransparency = 0.88,
        BorderSizePixel        = 0,
        Position               = UDim2.fromOffset(0,51),
        Size                   = UDim2.new(1,0,0,1),
        ZIndex                 = 4,
        Parent                 = Content,
    })

    -- Tab content container
    local TabContainer = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position               = UDim2.fromOffset(0,52),
        Size                   = UDim2.new(1,0,1,-52),
        ZIndex                 = 3,
        Parent                 = Content,
    })

    -- Active nav indicator (accent bar left of active icon)
    local NavIndicator = self:Create("Frame", {
        BackgroundColor3 = self.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.fromOffset(0, 80),
        Size             = UDim2.fromOffset(3, 32),
        ZIndex           = 10,
        Parent           = Sidebar,
    })
    self:Round(NavIndicator, 2)
    self:AddReg(NavIndicator, "BackgroundColor3", "Accent")

    -- ── ADD TAB ─────────────────────────────────────────────
    function Window:AddTab(opts)
        opts = type(opts) == "string" and { Name = opts } or opts
        local tabName = opts.Name or "Tab"
        local iconId  = opts.Icon or ""

        local Tab = { Sections = {}, _name = tabName }

        -- Nav icon button
        local navBtn = Library:Create("TextButton", {
            BackgroundColor3       = Library.Accent,
            BackgroundTransparency = 1,
            Size                   = UDim2.fromOffset(48, 48),
            Text                   = "",
            ZIndex                 = 5,
            Parent                 = NavList,
        })
        Library:Round(navBtn, 10)

        -- Icon image (using Roblox icon IDs for common tabs)
        local iconMap = {
            Aimbot   = "rbxassetid://7506870928",
            ESP      = "rbxassetid://7506869530",
            Movement = "rbxassetid://7507030703",
            Misc     = "rbxassetid://7506870548",
            Settings = "rbxassetid://7507016059",
        }
        local iconImg = Library:Create("ImageLabel", {
            BackgroundTransparency = 1,
            AnchorPoint            = Vector2.new(0.5,0.5),
            Position               = UDim2.fromScale(0.5,0.5),
            Size                   = UDim2.fromOffset(20,20),
            Image                  = iconId ~= "" and iconId or (iconMap[tabName] or "rbxassetid://7505493267"),
            ImageColor3            = Library.TextDim,
            ZIndex                 = 6,
            Parent                 = navBtn,
        })

        -- Tooltip label
        local tooltip = Library:Create("TextLabel", {
            BackgroundColor3       = Library.GlassDark,
            BackgroundTransparency = 0.1,
            Font                   = Library.FontSemi,
            Text                   = tabName,
            TextColor3             = Library.Text,
            TextSize               = 12,
            Position               = UDim2.new(1,8,0.5,0),
            AnchorPoint            = Vector2.new(0,0.5),
            Size                   = UDim2.fromOffset(70,24),
            ZIndex                 = 50,
            Visible                = false,
            Parent                 = navBtn,
        })
        Library:Round(tooltip, 6)
        Library:Stroke(tooltip, Library.GlassEdge, 1, 0.82)

        navBtn.MouseEnter:Connect(function()
            tooltip.Visible = true
        end)
        navBtn.MouseLeave:Connect(function()
            tooltip.Visible = false
        end)

        -- Tab content frame
        local TabFrame = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1,0,1,0),
            Visible                = false,
            ZIndex                 = 3,
            Parent                 = TabContainer,
        })

        -- Scrollable content inside tab
        local Scroll = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1,-16,1,-16),
            Position               = UDim2.fromOffset(8,8),
            CanvasSize             = UDim2.new(0,0,0,0),
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = Library.Accent,
            ScrollBarImageTransparency = 0.4,
            TopImage               = "",
            BottomImage            = "",
            ZIndex                 = 3,
            Parent                 = TabFrame,
        })
        Library:AddReg(Scroll, "ScrollBarImageColor3", "Accent")

        Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder     = Enum.SortOrder.LayoutOrder,
            Padding       = UDim.new(0,10),
            Parent        = Scroll,
        })

        Scroll:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.fromOffset(0, Scroll:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y + 16)
        end)

        function Tab:ShowTab()
            for _, t in next, Window.Tabs do t:HideTab() end
            TabFrame.Visible = true
            Library:Tween(navBtn, { BackgroundTransparency = 0.84 }, 0.2)
            Library:Tween(iconImg, { ImageColor3 = Library.Accent }, 0.2)
            -- Slide nav indicator to this button
            Library:Tween(NavIndicator, {
                Position = UDim2.fromOffset(0, navBtn.AbsolutePosition.Y - NavList.AbsolutePosition.Y + 72 + 8),
                Size     = UDim2.fromOffset(3,32),
            }, 0.25)
            Tab._active = true
        end

        function Tab:HideTab()
            TabFrame.Visible = false
            Library:Tween(navBtn, { BackgroundTransparency = 1 }, 0.2)
            Library:Tween(iconImg, { ImageColor3 = Library.TextDim }, 0.2)
            Tab._active = false
        end

        navBtn.MouseButton1Click:Connect(function()
            Tab:ShowTab()
        end)

        -- ── ADD SECTION ───────────────────────────────────────
        function Tab:AddSection(sectionName, opts)
            opts = opts or {}
            local Section = {}

            -- Acrylic section card
            local card = Library:Create("Frame", {
                BackgroundColor3       = Library.Glass,
                BackgroundTransparency = 0.42,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(opts.Width or 1, opts.WidthOffset or -0, 0, 0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                ZIndex                 = 4,
                Parent                 = Scroll,
            })
            Library:Round(card, 10)
            Library:Stroke(card, Library.GlassEdge, 1, 0.86)
            Library:AddReg(card, "BackgroundColor3", "Glass")

            -- Section header
            local header = Library:Create("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1,0,0,36),
                ZIndex                 = 5,
                Parent                 = card,
            })
            Library:Create("TextLabel", {
                BackgroundTransparency = 1,
                Font                   = Library.FontSemi,
                Text                   = string.upper(sectionName or ""),
                TextColor3             = Library.TextMuted,
                TextSize               = 11,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Position               = UDim2.fromOffset(14,0),
                Size                   = UDim2.new(1,-28,1,0),
                LetterSpacing          = 2,
                ZIndex                 = 6,
                Parent                 = header,
            })
            -- Header divider
            Library:Create("Frame", {
                BackgroundColor3       = Library.GlassEdge,
                BackgroundTransparency = 0.88,
                BorderSizePixel        = 0,
                AnchorPoint            = Vector2.new(0,1),
                Position               = UDim2.new(0,0,1,0),
                Size                   = UDim2.new(1,0,0,1),
                ZIndex                 = 6,
                Parent                 = header,
            })

            -- Item container
            local itemList = Library:Create("Frame", {
                BackgroundTransparency = 1,
                Position               = UDim2.fromOffset(0,36),
                Size                   = UDim2.new(1,0,0,0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                ZIndex                 = 5,
                Parent                 = card,
            })
            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder     = Enum.SortOrder.LayoutOrder,
                Parent        = itemList,
            })
            Library:Create("UIPadding", {
                PaddingLeft   = UDim.new(0,14),
                PaddingRight  = UDim.new(0,14),
                PaddingBottom = UDim.new(0,12),
                Parent        = itemList,
            })

            Section._list = itemList
            Section._card = card

            -- ── ROW HELPER ─────────────────────────────────────
            local function MakeRow(label, heightOffset)
                local row = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1,0,0,heightOffset or 38),
                    ZIndex                 = 6,
                    Parent                 = itemList,
                })
                local lbl = Library:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font                   = Library.Font,
                    Text                   = label or "",
                    TextColor3             = Library.Text,
                    TextSize               = 13,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Size                   = UDim2.new(0.55,0,1,0),
                    ZIndex                 = 7,
                    Parent                 = row,
                })
                return row, lbl
            end

            -- ── TOGGLE ─────────────────────────────────────────
            function Section:AddToggle(idx, info)
                info = info or {}
                local row, lbl = MakeRow(info.Label or info.Text or idx)

                local track = Library:Create("Frame", {
                    AnchorPoint      = Vector2.new(1,0.5),
                    Position         = UDim2.new(1,0,0.5,0),
                    Size             = UDim2.fromOffset(40,20),
                    BackgroundColor3 = Library.Glass,
                    ZIndex           = 7,
                    Parent           = row,
                })
                Library:Round(track, 10)
                Library:AddReg(track, "BackgroundColor3", "Glass")

                local knob = Library:Create("Frame", {
                    AnchorPoint      = Vector2.new(0,0.5),
                    Position         = UDim2.new(0,2,0.5,0),
                    Size             = UDim2.fromOffset(16,16),
                    BackgroundColor3 = Library.TextMuted,
                    ZIndex           = 8,
                    Parent           = track,
                })
                Library:Round(knob, 8)

                local Toggle = {
                    Value    = not not info.Default,
                    Type     = "Toggle",
                    Callback = info.Callback or function() end,
                    Addons   = {},
                }

                function Toggle:Render(animate)
                    local onPos  = UDim2.new(1,-18,0.5,0)
                    local offPos = UDim2.new(0,2,0.5,0)
                    local pos    = self.Value and onPos or offPos
                    local trackC = self.Value and Library.Accent or Library.Glass
                    local knobC  = self.Value and Color3.new(1,1,1) or Library.TextMuted
                    if animate then
                        Library:Tween(track, { BackgroundColor3 = trackC }, 0.18)
                        Library:Tween(knob, { Position = pos, BackgroundColor3 = knobC }, 0.18)
                    else
                        track.BackgroundColor3 = trackC
                        knob.Position = pos
                        knob.BackgroundColor3 = knobC
                    end
                    -- Keep registry correct
                    local reg = Library.RegistryMap[track]
                    if reg then reg.key = self.Value and "Accent" or "Glass" end
                end

                function Toggle:SetValue(v)
                    self.Value = not not v
                    self:Render(true)
                    Library:SafeCall(self.Callback, self.Value)
                    Library:SafeCall(self.Changed, self.Value)
                end

                function Toggle:OnChanged(fn) self.Changed = fn; fn(self.Value) end

                local hitBtn = Library:Create("TextButton", {
                    BackgroundTransparency = 1,
                    Text                   = "",
                    Size                   = UDim2.new(1,0,1,0),
                    ZIndex                 = 9,
                    Parent                 = row,
                })
                hitBtn.MouseButton1Click:Connect(function()
                    Toggle:SetValue(not Toggle.Value)
                end)
                hitBtn.MouseEnter:Connect(function()
                    Library:Tween(lbl, { TextColor3 = Library.Accent }, 0.15)
                end)
                hitBtn.MouseLeave:Connect(function()
                    Library:Tween(lbl, { TextColor3 = Library.Text }, 0.15)
                end)

                Toggle:Render(false)
                Library.Toggles[idx] = Toggle
                return Toggle
            end

            -- ── SLIDER ─────────────────────────────────────────
            function Section:AddSlider(idx, info)
                info = info or {}
                local min  = info.Min or 0
                local max  = info.Max or 100
                local def  = info.Default or min
                local suf  = info.Suffix or ""

                local container = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1,0,0,52),
                    ZIndex                 = 6,
                    Parent                 = itemList,
                })
                -- Top row: label + value
                local labelLbl = Library:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font                   = Library.Font,
                    Text                   = info.Label or info.Text or idx,
                    TextColor3             = Library.Text,
                    TextSize               = 13,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Size                   = UDim2.new(0.6,0,0,22),
                    ZIndex                 = 7,
                    Parent                 = container,
                })
                local valueLbl = Library:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font                   = Library.FontSemi,
                    Text                   = tostring(def)..suf,
                    TextColor3             = Library.Accent,
                    TextSize               = 13,
                    TextXAlignment         = Enum.TextXAlignment.Right,
                    AnchorPoint            = Vector2.new(1,0),
                    Position               = UDim2.new(1,0,0,0),
                    Size                   = UDim2.new(0.4,0,0,22),
                    ZIndex                 = 7,
                    Parent                 = container,
                })
                Library:AddReg(valueLbl, "TextColor3", "Accent")

                -- Track
                local trackBg = Library:Create("Frame", {
                    AnchorPoint      = Vector2.new(0,0),
                    Position         = UDim2.fromOffset(0,26),
                    BackgroundColor3 = Library.GlassDark,
                    BorderSizePixel  = 0,
                    Size             = UDim2.new(1,0,0,6),
                    ZIndex           = 7,
                    Parent           = container,
                })
                Library:Round(trackBg, 3)
                Library:AddReg(trackBg, "BackgroundColor3", "GlassDark")

                local fill = Library:Create("Frame", {
                    BackgroundColor3 = Library.Accent,
                    BorderSizePixel  = 0,
                    Size             = UDim2.new(0,0,1,0),
                    ZIndex           = 8,
                    Parent           = trackBg,
                })
                Library:Round(fill, 3)
                Library:AddReg(fill, "BackgroundColor3", "Accent")

                local knob = Library:Create("Frame", {
                    AnchorPoint      = Vector2.new(0.5,0.5),
                    Position         = UDim2.new(0,0,0.5,0),
                    Size             = UDim2.fromOffset(14,14),
                    BackgroundColor3 = Library.Accent,
                    ZIndex           = 9,
                    Parent           = trackBg,
                })
                Library:Round(knob, 7)
                Library:AddReg(knob, "BackgroundColor3", "Accent")
                Library:Create("UIStroke", {
                    Color            = Color3.new(1,1,1),
                    Thickness        = 2,
                    Transparency     = 0.7,
                    ApplyStrokeMode  = Enum.ApplyStrokeMode.Border,
                    Parent           = knob,
                })

                local Slider = {
                    Value    = def,
                    Min      = min,
                    Max      = max,
                    Rounding = info.Rounding or 0,
                    Type     = "Slider",
                    Callback = info.Callback or function() end,
                }

                local function round(v)
                    if Slider.Rounding == 0 then return math.floor(v + 0.5) end
                    return tonumber(string.format("%."..Slider.Rounding.."f", v))
                end

                function Slider:Render()
                    local pct = math.clamp((self.Value - min)/(max - min), 0, 1)
                    fill.Size     = UDim2.new(pct,0,1,0)
                    knob.Position = UDim2.new(pct,0,0.5,0)
                    valueLbl.Text = tostring(self.Value)..suf
                end

                function Slider:SetValue(v)
                    local n = tonumber(v)
                    if not n then return end
                    self.Value = round(math.clamp(n, min, max))
                    self:Render()
                    Library:SafeCall(self.Callback, self.Value)
                    Library:SafeCall(self.Changed, self.Value)
                end

                function Slider:OnChanged(fn) self.Changed = fn; fn(self.Value) end

                trackBg.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local function update()
                        local mx  = Mouse.X
                        local abs = trackBg.AbsolutePosition.X
                        local w   = trackBg.AbsoluteSize.X
                        local pct = math.clamp((mx - abs)/w, 0, 1)
                        Slider:SetValue(min + pct*(max-min))
                    end
                    update()
                    local conn; conn = RunService.Heartbeat:Connect(function()
                        if not UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                            conn:Disconnect()
                        else
                            update()
                        end
                    end)
                end)

                Slider:Render()
                Library.Options[idx] = Slider
                return Slider
            end

            -- ── BUTTON ─────────────────────────────────────────
            function Section:AddButton(info)
                info = type(info) == "string" and { Label = info } or info
                local row, lbl = MakeRow(info.Label or info.Text or "Button", 38)
                lbl.Size = UDim2.new(0.5,0,1,0)

                local btn = Library:Create("TextButton", {
                    AnchorPoint      = Vector2.new(1,0.5),
                    Position         = UDim2.new(1,0,0.5,0),
                    BackgroundColor3 = Library.Glass,
                    BackgroundTransparency = 0.4,
                    Font             = Library.FontSemi,
                    Text             = info.Action or "Execute",
                    TextColor3       = Library.Text,
                    TextSize         = 12,
                    Size             = UDim2.fromOffset(80,28),
                    ZIndex           = 7,
                    Parent           = row,
                })
                Library:Round(btn, 7)
                Library:Stroke(btn, Library.GlassEdge, 1, 0.82)

                btn.MouseButton1Click:Connect(function()
                    Library:SafeCall(info.Callback or info.Func)
                    Library:Tween(btn, { BackgroundColor3 = Library.Accent }, 0.08)
                    Library:Tween(btn, { BackgroundColor3 = Library.Glass }, 0.25)
                end)
                btn.MouseEnter:Connect(function()
                    Library:Tween(btn, { BackgroundTransparency = 0.2 }, 0.15)
                end)
                btn.MouseLeave:Connect(function()
                    Library:Tween(btn, { BackgroundTransparency = 0.4 }, 0.15)
                end)
                return btn
            end

            -- ── DROPDOWN ───────────────────────────────────────
            function Section:AddDropdown(idx, info)
                info = info or {}
                local container = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1,0,0,58),
                    ZIndex                 = 6,
                    Parent                 = itemList,
                })
                Library:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font                   = Library.Font,
                    Text                   = info.Label or info.Text or idx,
                    TextColor3             = Library.Text,
                    TextSize               = 13,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Size                   = UDim2.new(1,0,0,20),
                    ZIndex                 = 7,
                    Parent                 = container,
                })
                local dropBtn = Library:Create("TextButton", {
                    BackgroundColor3       = Library.GlassDark,
                    BackgroundTransparency = 0.2,
                    Font                   = Library.FontSemi,
                    Text                   = info.Default or "--",
                    TextColor3             = Library.Text,
                    TextSize               = 13,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Position               = UDim2.fromOffset(0,22),
                    Size                   = UDim2.new(1,0,0,30),
                    ZIndex                 = 7,
                    Parent                 = container,
                })
                Library:Round(dropBtn, 6)
                Library:Stroke(dropBtn, Library.GlassEdge, 1, 0.82)
                Library:Create("UIPadding", { PaddingLeft = UDim.new(0,10), Parent = dropBtn })

                -- Arrow
                local arrow = Library:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint            = Vector2.new(1,0.5),
                    Position               = UDim2.new(1,-10,0.5,0),
                    Size                   = UDim2.fromOffset(16,16),
                    Font                   = Library.FontBold,
                    Text                   = "▾",
                    TextColor3             = Library.TextMuted,
                    TextSize               = 14,
                    ZIndex                 = 8,
                    Parent                 = dropBtn,
                })

                local Dropdown = {
                    Value    = info.Default,
                    Values   = info.Values or {},
                    Type     = "Dropdown",
                    Callback = info.Callback or function() end,
                }

                -- Dropdown list popup
                local listFrame = Library:Create("Frame", {
                    BackgroundColor3       = Library.GlassDark,
                    BackgroundTransparency = 0.08,
                    BorderSizePixel        = 0,
                    ZIndex                 = 30,
                    Visible                = false,
                    Parent                 = ScreenGui,
                })
                Library:Round(listFrame, 8)
                Library:Stroke(listFrame, Library.GlassEdge, 1, 0.78)
                Library:AddReg(listFrame, "BackgroundColor3", "GlassDark")

                local listLayout = Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder     = Enum.SortOrder.LayoutOrder,
                    Parent        = listFrame,
                })
                Library:Create("UIPadding", {
                    PaddingTop    = UDim.new(0,4),
                    PaddingBottom = UDim.new(0,4),
                    Parent        = listFrame,
                })

                table.insert(Library.Popups, function()
                    if listFrame.Visible then
                        listFrame.Visible = false
                        Library:Tween(arrow, { Rotation = 0 }, 0.15)
                    end
                end)

                local function buildList()
                    for _, c in next, listFrame:GetChildren() do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, val in next, Dropdown.Values do
                        local item = Library:Create("TextButton", {
                            BackgroundColor3       = val == Dropdown.Value and Library.Accent or Library.Glass,
                            BackgroundTransparency = val == Dropdown.Value and 0.7 or 0.95,
                            Font                   = Library.FontSemi,
                            Text                   = tostring(val),
                            TextColor3             = val == Dropdown.Value and Library.Accent or Library.TextMuted,
                            TextSize               = 13,
                            TextXAlignment         = Enum.TextXAlignment.Left,
                            Size                   = UDim2.new(1,0,0,30),
                            ZIndex                 = 31,
                            Parent                 = listFrame,
                        })
                        Library:Create("UIPadding", { PaddingLeft = UDim.new(0,12), Parent = item })
                        local v = val
                        item.MouseButton1Click:Connect(function()
                            Dropdown.Value = v
                            dropBtn.Text   = tostring(v)
                            listFrame.Visible = false
                            Library:Tween(arrow, { Rotation = 0 }, 0.15)
                            buildList()
                            Library:SafeCall(Dropdown.Callback, v)
                            Library:SafeCall(Dropdown.Changed, v)
                        end)
                        item.MouseEnter:Connect(function()
                            if v ~= Dropdown.Value then
                                Library:Tween(item, { BackgroundTransparency = 0.75, TextColor3 = Library.Text }, 0.1)
                            end
                        end)
                        item.MouseLeave:Connect(function()
                            if v ~= Dropdown.Value then
                                Library:Tween(item, { BackgroundTransparency = 0.95, TextColor3 = Library.TextMuted }, 0.1)
                            end
                        end)
                    end
                    -- resize list
                    local h = math.min(#Dropdown.Values, 6) * 30 + 8
                    listFrame.Size = UDim2.fromOffset(dropBtn.AbsoluteSize.X, h)
                    listFrame.Position = UDim2.fromOffset(
                        dropBtn.AbsolutePosition.X,
                        dropBtn.AbsolutePosition.Y + 34
                    )
                end

                dropBtn.MouseButton1Click:Connect(function()
                    if listFrame.Visible then
                        listFrame.Visible = false
                        Library:Tween(arrow, { Rotation = 0 }, 0.15)
                    else
                        for _, fn in next, Library.Popups do fn() end
                        buildList()
                        listFrame.Visible = true
                        Library:Tween(arrow, { Rotation = 180 }, 0.15)
                    end
                end)

                function Dropdown:SetValue(v)
                    self.Value = v; dropBtn.Text = tostring(v); buildList()
                    Library:SafeCall(self.Callback, v); Library:SafeCall(self.Changed, v)
                end
                function Dropdown:SetValues(vals) self.Values = vals; buildList() end
                function Dropdown:OnChanged(fn) self.Changed = fn; fn(self.Value) end

                Library.Options[idx] = Dropdown
                return Dropdown
            end

            -- ── INPUT ──────────────────────────────────────────
            function Section:AddInput(idx, info)
                info = info or {}
                local container = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1,0,0,58),
                    ZIndex                 = 6,
                    Parent                 = itemList,
                })
                Library:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font                   = Library.Font,
                    Text                   = info.Label or info.Text or idx,
                    TextColor3             = Library.Text,
                    TextSize               = 13,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Size                   = UDim2.new(1,0,0,20),
                    ZIndex                 = 7,
                    Parent                 = container,
                })
                local box = Library:Create("TextBox", {
                    BackgroundColor3       = Library.GlassDark,
                    BackgroundTransparency = 0.2,
                    Font                   = Library.Font,
                    Text                   = info.Default or "",
                    PlaceholderText        = info.Placeholder or "",
                    PlaceholderColor3      = Library.TextDim,
                    TextColor3             = Library.Text,
                    TextSize               = 13,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ClearTextOnFocus       = false,
                    Position               = UDim2.fromOffset(0,22),
                    Size                   = UDim2.new(1,0,0,30),
                    ZIndex                 = 7,
                    Parent                 = container,
                })
                Library:Round(box, 6)
                Library:Stroke(box, Library.GlassEdge, 1, 0.82)
                Library:Create("UIPadding", { PaddingLeft = UDim.new(0,10), Parent = box })

                local Input = {
                    Value    = info.Default or "",
                    Type     = "Input",
                    Callback = info.Callback or function() end,
                }

                box:GetPropertyChangedSignal("Text"):Connect(function()
                    if info.Numeric and not tonumber(box.Text) and #box.Text > 0 then
                        box.Text = Input.Value; return
                    end
                    Input.Value = box.Text
                    if not info.Finished then Library:SafeCall(Input.Callback, Input.Value) end
                end)
                box.FocusLost:Connect(function(enter)
                    if info.Finished and enter then Library:SafeCall(Input.Callback, Input.Value) end
                    Library:SafeCall(Input.Changed, Input.Value)
                end)
                function Input:SetValue(v) box.Text = tostring(v); self.Value = tostring(v) end
                function Input:OnChanged(fn) self.Changed = fn; fn(self.Value) end

                Library.Options[idx] = Input
                return Input
            end

            -- ── KEYBIND ────────────────────────────────────────
            function Section:AddKeybind(idx, info)
                info = info or {}
                local row, lbl = MakeRow(info.Label or info.Text or idx)

                local kbBtn = Library:Create("TextButton", {
                    AnchorPoint            = Vector2.new(1,0.5),
                    Position               = UDim2.new(1,0,0.5,0),
                    BackgroundColor3       = Library.GlassDark,
                    BackgroundTransparency = 0.2,
                    Font                   = Library.FontSemi,
                    Text                   = info.Default or "None",
                    TextColor3             = Library.Accent,
                    TextSize               = 12,
                    Size                   = UDim2.fromOffset(72,26),
                    ZIndex                 = 7,
                    Parent                 = row,
                })
                Library:Round(kbBtn, 6)
                Library:Stroke(kbBtn, Library.GlassEdge, 1, 0.82)
                Library:AddReg(kbBtn, "TextColor3", "Accent")

                local KeyPicker = {
                    Value    = info.Default or "None",
                    Mode     = info.Mode or "Toggle",
                    Toggled  = false,
                    Type     = "KeyPicker",
                    Callback = info.Callback or function() end,
                }

                local picking = false
                kbBtn.MouseButton1Click:Connect(function()
                    if picking then return end
                    picking = true
                    kbBtn.Text = "..."
                    local conn; conn = UserInput.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            KeyPicker.Value = inp.KeyCode.Name
                            kbBtn.Text = inp.KeyCode.Name
                            picking = false; conn:Disconnect()
                            Library:SafeCall(KeyPicker.ChangedCallback, inp.KeyCode)
                        elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
                            picking = false; conn:Disconnect(); kbBtn.Text = KeyPicker.Value
                        end
                    end)
                end)

                UserInput.InputBegan:Connect(function(inp)
                    if picking then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name == KeyPicker.Value then
                        if KeyPicker.Mode == "Toggle" then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            Library:SafeCall(KeyPicker.Callback, KeyPicker.Toggled)
                        end
                    end
                end)

                function KeyPicker:GetState() return self.Toggled end
                function KeyPicker:SetValue(d) self.Value = d[1]; self.Mode = d[2]; kbBtn.Text = d[1] end
                function KeyPicker:OnChanged(fn) self.Changed = fn end

                Library.Options[idx] = KeyPicker
                return KeyPicker
            end

            -- ── COLOR PICKER ───────────────────────────────────
            function Section:AddColorPicker(idx, info)
                info = info or {}
                local row, lbl = MakeRow(info.Label or info.Title or idx)

                local swatch = Library:Create("TextButton", {
                    AnchorPoint      = Vector2.new(1,0.5),
                    Position         = UDim2.new(1,0,0.5,0),
                    BackgroundColor3 = info.Default or Library.Accent,
                    Size             = UDim2.fromOffset(36,20),
                    Text             = "",
                    ZIndex           = 7,
                    Parent           = row,
                })
                Library:Round(swatch, 5)
                Library:Stroke(swatch, Library.GlassEdge, 1, 0.82)

                local ColorPicker = {
                    Value        = info.Default or Library.Accent,
                    Transparency = info.Transparency or 0,
                    Type         = "ColorPicker",
                    Callback     = info.Callback or function() end,
                }
                function ColorPicker:SetHSVFromRGB(c)
                    self.Hue, self.Sat, self.Vib = Color3.toHSV(c)
                end
                ColorPicker:SetHSVFromRGB(ColorPicker.Value)

                -- Simple picker popup
                local popup = Library:Create("Frame", {
                    BackgroundColor3       = Library.GlassDark,
                    BackgroundTransparency = 0.08,
                    Size                   = UDim2.fromOffset(220,240),
                    Visible                = false,
                    ZIndex                 = 40,
                    Parent                 = ScreenGui,
                })
                Library:Round(popup, 10)
                Library:Stroke(popup, Library.GlassEdge, 1, 0.78)
                Library:AddReg(popup, "BackgroundColor3", "GlassDark")

                Library:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font                   = Library.FontSemi,
                    Text                   = info.Title or "Color",
                    TextColor3             = Library.Text,
                    TextSize               = 13,
                    Position               = UDim2.fromOffset(12,8),
                    Size                   = UDim2.new(1,-24,0,20),
                    ZIndex                 = 41,
                    Parent                 = popup,
                })

                -- SV map
                local svMap = Library:Create("ImageLabel", {
                    BorderSizePixel = 0,
                    Position        = UDim2.fromOffset(10,34),
                    Size            = UDim2.fromOffset(160,160),
                    Image           = "rbxassetid://4155801252",
                    ZIndex          = 41,
                    Parent          = popup,
                })
                Library:Round(svMap, 4)

                local svCursor = Library:Create("Frame", {
                    AnchorPoint      = Vector2.new(0.5,0.5),
                    Size             = UDim2.fromOffset(10,10),
                    BackgroundColor3 = Color3.new(1,1,1),
                    ZIndex           = 42,
                    Parent           = svMap,
                })
                Library:Round(svCursor, 5)
                Library:Create("UIStroke", { Color=Color3.new(0,0,0), Thickness=1.5, Parent=svCursor })

                -- Hue bar
                local hueBar = Library:Create("Frame", {
                    BorderSizePixel  = 0,
                    Position         = UDim2.fromOffset(178,34),
                    Size             = UDim2.fromOffset(14,160),
                    ZIndex           = 41,
                    Parent           = popup,
                })
                Library:Round(hueBar, 4)
                Library:Create("UIGradient", {
                    Color    = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,   Color3.fromHSV(0,1,1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
                        ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5,1,1)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1,1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
                        ColorSequenceKeypoint.new(1,   Color3.fromHSV(1,1,1)),
                    }),
                    Rotation = 90,
                    Parent   = hueBar,
                })
                local hueCursor = Library:Create("Frame", {
                    AnchorPoint      = Vector2.new(0.5,0.5),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel  = 0,
                    Size             = UDim2.fromOffset(14,4),
                    ZIndex           = 42,
                    Parent           = hueBar,
                })

                -- Hex input
                local hexBox = Library:Create("TextBox", {
                    BackgroundColor3       = Library.Glass,
                    BackgroundTransparency = 0.6,
                    Font                   = Library.Font,
                    Text                   = "#" .. ColorPicker.Value:ToHex():upper(),
                    PlaceholderText        = "#FFFFFF",
                    TextColor3             = Library.Text,
                    TextSize               = 12,
                    ClearTextOnFocus       = false,
                    Position               = UDim2.fromOffset(10,200),
                    Size                   = UDim2.fromOffset(100,26),
                    ZIndex                 = 41,
                    Parent                 = popup,
                })
                Library:Round(hexBox, 5)
                Library:Create("UIPadding", { PaddingLeft = UDim.new(0,8), Parent = hexBox })

                function ColorPicker:Display()
                    self.Value = Color3.fromHSV(self.Hue, self.Sat, self.Vib)
                    svMap.BackgroundColor3 = Color3.fromHSV(self.Hue,1,1)
                    swatch.BackgroundColor3 = self.Value
                    svCursor.Position  = UDim2.new(self.Sat,0,1-self.Vib,0)
                    hueCursor.Position = UDim2.new(0,0,self.Hue,0)
                    hexBox.Text = "#"..self.Value:ToHex():upper()
                    Library:SafeCall(self.Callback, self.Value)
                    Library:SafeCall(self.Changed,  self.Value)
                end

                svMap.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local conn; conn = RunService.Heartbeat:Connect(function()
                        if not UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then conn:Disconnect(); return end
                        local ax,ay = svMap.AbsolutePosition.X, svMap.AbsolutePosition.Y
                        local aw,ah = svMap.AbsoluteSize.X, svMap.AbsoluteSize.Y
                        ColorPicker.Sat = math.clamp((Mouse.X-ax)/aw,0,1)
                        ColorPicker.Vib = 1-math.clamp((Mouse.Y-ay)/ah,0,1)
                        ColorPicker:Display()
                    end)
                end)

                hueBar.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local conn; conn = RunService.Heartbeat:Connect(function()
                        if not UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then conn:Disconnect(); return end
                        local ay,ah = hueBar.AbsolutePosition.Y, hueBar.AbsoluteSize.Y
                        ColorPicker.Hue = math.clamp((Mouse.Y-ay)/ah,0,1)
                        ColorPicker:Display()
                    end)
                end)

                hexBox.FocusLost:Connect(function(enter)
                    if not enter then return end
                    local ok,col = pcall(Color3.fromHex, hexBox.Text)
                    if ok then ColorPicker:SetHSVFromRGB(col); ColorPicker:Display() end
                end)

                local popupOpen = false
                swatch.MouseButton1Click:Connect(function()
                    popupOpen = not popupOpen
                    if popupOpen then
                        for _,fn in next, Library.Popups do fn() end
                        popup.Position = UDim2.fromOffset(
                            swatch.AbsolutePosition.X - 220,
                            swatch.AbsolutePosition.Y
                        )
                        popup.Visible  = true
                    else
                        popup.Visible = false
                    end
                end)
                table.insert(Library.Popups, function() popup.Visible = false; popupOpen = false end)

                function ColorPicker:SetValueRGB(c,t)
                    self.Transparency = t or 0
                    self:SetHSVFromRGB(c)
                    self:Display()
                end
                function ColorPicker:SetValue(hsv,t)
                    self.Transparency = t or 0
                    self:SetHSVFromRGB(Color3.fromHSV(hsv[1],hsv[2],hsv[3]))
                    self:Display()
                end
                function ColorPicker:OnChanged(fn) self.Changed = fn; fn(self.Value) end

                ColorPicker:Display()
                Library.Options[idx] = ColorPicker
                return ColorPicker
            end

            return Section
        end -- AddSection

        Window.Tabs[tabName] = Tab
        table.insert(Window._tabOrder, Tab)

        -- Auto-show first tab
        if #Window._tabOrder == 1 then
            task.defer(function() Tab:ShowTab() end)
        end

        return Tab
    end -- AddTab

    -- Minimize / close helpers
    function Window:Toggle()
        Root.Visible = not Root.Visible
    end

    Library.Window = Window
    Root.Visible = true

    -- Global keybind (RightShift)
    Library:GiveSignal(UserInput.InputBegan:Connect(function(inp, proc)
        if inp.KeyCode == Enum.KeyCode.RightShift and not proc then
            Window:Toggle()
        end
    end))

    -- Close popups on outside click
    Library:GiveSignal(UserInput.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            for _, fn in next, Library.Popups do fn() end
        end
    end))

    return Window
end

-- ============================================================
-- SIGNAL MANAGEMENT
-- ============================================================
function Library:GiveSignal(s) table.insert(self.Signals, s) end
function Library:SafeCall(fn, ...) if type(fn)=="function" then pcall(fn,...) end end

function Library:Unload()
    for _, s in next, self.Signals do pcall(function() s:Disconnect() end) end
    ScreenGui:Destroy()
    _genv.Toggles = nil
    _genv.Options  = nil
end

return Library
