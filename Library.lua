--[[
    LUMINWARE UI Library v5.0 — Complete rewrite
    Layout: Sidebar (icons) | Content (tabs → subtabs → two-column cards)
    Acrylic: ViewportFrame + workspace Glass Part + DepthOfField
    
    API:
        local W   = Library:CreateWindow({ Title="X", Logo="rbxassetid://..." })
        local Tab = W:AddTab({ Name="Aimbot", Icon="crosshair" })
        local Sub = Tab:AddSubtab("Targeting")
        local Card = Sub.Left:AddCard("General")
        Card:AddToggle("id", { Label="Silent Aim", Default=false, Callback=fn })
        Card:AddSlider("id",  { Label="FOV", Min=0, Max=360, Default=90, Suffix="°" })
        Card:AddDropdown("id",{ Label="Part", Values={"Head","Neck"}, Default="Head" })
        Card:AddButton({ Label="Reset", Callback=fn })
        Card:AddInput("id", { Label="Tag", Placeholder="..." })
        Card:AddKeybind("id",{ Label="Key", Default="LeftAlt" })
        Card:AddColorPicker("id",{ Label="Color", Default=Color3.new(1,0,0) })
]]

-- ── Services ──────────────────────────────────────────────────────
local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS  = game:GetService("RunService")
local PLS = game:GetService("Players")
local CSG = game:GetService("CoreGui")
local WS  = game:GetService("Workspace")
local HS  = game:GetService("HttpService")

local LP    = PLS.LocalPlayer
local Mouse = LP:GetMouse()
local Cam   = WS.CurrentCamera

-- ── ScreenGui ─────────────────────────────────────────────────────
local Protect = (typeof(syn)=="table" and syn.protect_gui)
    or (typeof(protectgui)=="function" and protectgui)
    or function() end
local SG = Instance.new("ScreenGui")
SG.Name = "LuminwareUI"; SG.ZIndexBehavior = Enum.ZIndexBehavior.Global
SG.ResetOnSpawn = false; pcall(Protect, SG)
SG.Parent = (typeof(gethui)=="function" and pcall(gethui) and gethui()) or CSG

local _genv = {}
pcall(function() if typeof(getgenv)=="function" then _genv = getgenv() end end)

-- ── Library Object ────────────────────────────────────────────────
local L = {
    -- Theme (FROST default — cool dark blue)
    Accent     = Color3.fromRGB(90, 160, 255),
    BgDeep     = Color3.fromRGB(14, 16, 24),    -- darkest bg
    BgMid      = Color3.fromRGB(20, 23, 34),    -- card bg
    BgLight    = Color3.fromRGB(28, 32, 46),    -- input / track bg
    Sidebar    = Color3.fromRGB(16, 18, 28),    -- sidebar bg
    TextHi     = Color3.fromRGB(235, 238, 255), -- bright text
    TextMid    = Color3.fromRGB(150, 155, 180), -- muted text
    TextLow    = Color3.fromRGB(75,  80,  105), -- dim text / placeholders
    EdgeColor  = Color3.fromRGB(255, 255, 255), -- edge/stroke highlight

    Font     = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontSemi = Enum.Font.GothamSemibold,

    Toggles  = {},
    Options  = {},
    Registry = {},   -- { inst, prop, key } for theme recoloring
    Signals  = {},
    Popups   = {},   -- close-functions for open dropdowns/colorpickers
    _acleanup= {},   -- acrylic cleanup fns
    _currentTheme = "FROST",

    Themes = {
        FROST = { Accent=Color3.fromRGB(90,160,255),  BgDeep=Color3.fromRGB(14,16,24),  BgMid=Color3.fromRGB(20,23,34),  BgLight=Color3.fromRGB(28,32,46),  Sidebar=Color3.fromRGB(16,18,28)  },
        VENOM = { Accent=Color3.fromRGB(160,80,245),  BgDeep=Color3.fromRGB(14,12,22),  BgMid=Color3.fromRGB(20,16,32),  BgLight=Color3.fromRGB(28,22,44),  Sidebar=Color3.fromRGB(16,12,26)  },
        BLOOD = { Accent=Color3.fromRGB(215,55,55),   BgDeep=Color3.fromRGB(18,12,12),  BgMid=Color3.fromRGB(26,16,16),  BgLight=Color3.fromRGB(36,22,22),  Sidebar=Color3.fromRGB(20,12,12)  },
        EMBER = { Accent=Color3.fromRGB(255,140,0),   BgDeep=Color3.fromRGB(18,14,10),  BgMid=Color3.fromRGB(26,20,12),  BgLight=Color3.fromRGB(36,28,16),  Sidebar=Color3.fromRGB(20,14,10)  },
        ACID  = { Accent=Color3.fromRGB(120,215,0),   BgDeep=Color3.fromRGB(12,18,10),  BgMid=Color3.fromRGB(16,24,12),  BgLight=Color3.fromRGB(22,32,16),  Sidebar=Color3.fromRGB(12,18,10)  },
        GHOST = { Accent=Color3.fromRGB(190,195,215), BgDeep=Color3.fromRGB(16,17,22),  BgMid=Color3.fromRGB(22,24,32),  BgLight=Color3.fromRGB(30,33,44),  Sidebar=Color3.fromRGB(18,20,28)  },
    },
}
_genv.Toggles = L.Toggles
_genv.Options  = L.Options

-- ── Core Helpers ──────────────────────────────────────────────────
local function TW(inst, props, t, style, dir)
    TS:Create(inst, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint,
        dir or Enum.EasingDirection.Out), props):Play()
end

function L:New(class, props)
    local i = type(class)=="string" and Instance.new(class) or class
    for k,v in next, props do
        if k ~= "Parent" then pcall(function() i[k] = v end) end
    end
    if props.Parent then i.Parent = props.Parent end
    return i
end

function L:Corner(inst, r)
    return self:New("UICorner", { CornerRadius=UDim.new(0, r or 8), Parent=inst })
end

function L:Stroke(inst, color, thickness, transparency)
    return self:New("UIStroke", {
        Color           = color or self.EdgeColor,
        Thickness       = thickness or 1,
        Transparency    = transparency or 0.88,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent          = inst,
    })
end

function L:Reg(inst, prop, key)
    table.insert(self.Registry, { inst=inst, prop=prop, key=key })
end

function L:GS(s) table.insert(self.Signals, s) end
function L:CB(fn, ...) if type(fn)=="function" then pcall(fn, ...) end end

-- ── Theme ─────────────────────────────────────────────────────────
function L:SetTheme(name)
    local t = self.Themes[name]; if not t then return end
    self._currentTheme = name
    for k,v in next, t do self[k] = v end
    for _, r in next, self.Registry do
        if r.inst and r.inst.Parent then
            local c = self[r.key]
            if typeof(c) == "Color3" then TW(r.inst, { [r.prop]=c }, 0.35) end
        end
    end
    if self._onTheme then self._onTheme(name) end
    self:Notify({ Title="Theme: "..name, Duration=2 })
end

-- ── Notifications ─────────────────────────────────────────────────
local NArea = L:New("Frame", {
    BackgroundTransparency=1, AnchorPoint=Vector2.new(1,1),
    Position=UDim2.new(1,-16,1,-16), Size=UDim2.fromOffset(300,500),
    ZIndex=600, Parent=SG,
})
L:New("UIListLayout", {
    VerticalAlignment=Enum.VerticalAlignment.Bottom,
    HorizontalAlignment=Enum.HorizontalAlignment.Right,
    FillDirection=Enum.FillDirection.Vertical,
    Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder,
    Parent=NArea,
})

function L:Notify(opts)
    opts = type(opts)=="string" and {Title=opts,Duration=4} or opts
    local dur = opts.Duration or 4
    local h   = opts.Body and 68 or 46

    local card = self:New("Frame", {
        BackgroundColor3=self.BgMid, BackgroundTransparency=0.08,
        Size=UDim2.new(1,0,0,h), ClipsDescendants=true,
        ZIndex=601, Parent=NArea,
    })
    self:Corner(card, 10)
    self:Stroke(card, self.EdgeColor, 1, 0.82)

    -- accent left bar
    local bar = self:New("Frame", {
        BackgroundColor3=self.Accent, BorderSizePixel=0,
        Size=UDim2.fromOffset(3,h), ZIndex=602, Parent=card,
    })
    self:Reg(bar, "BackgroundColor3", "Accent")

    self:New("TextLabel", {
        BackgroundTransparency=1, Font=self.FontBold,
        Text=opts.Title or "", TextColor3=self.TextHi, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(14,opts.Body and 8 or 14),
        Size=UDim2.new(1,-18,0,18), ZIndex=602, Parent=card,
    })
    if opts.Body then
        self:New("TextLabel", {
            BackgroundTransparency=1, Font=self.Font,
            Text=opts.Body, TextColor3=self.TextMid, TextSize=12,
            TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(14,28), Size=UDim2.new(1,-18,0,32),
            ZIndex=602, Parent=card,
        })
    end

    -- drain bar
    local prog = self:New("Frame", {
        BackgroundColor3=self.Accent, BackgroundTransparency=0.6,
        BorderSizePixel=0, AnchorPoint=Vector2.new(0,1),
        Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,2),
        ZIndex=603, Parent=card,
    })
    self:Reg(prog, "BackgroundColor3", "Accent")

    card.BackgroundTransparency = 1
    TW(card, {BackgroundTransparency=0.08}, 0.22)
    TW(prog, {Size=UDim2.fromOffset(0,2)}, dur, Enum.EasingStyle.Linear)
    task.delay(dur, function()
        TW(card, {BackgroundTransparency=1}, 0.25)
        task.wait(0.3)
        pcall(function() card:Destroy() end)
    end)
end

-- ── Drag ──────────────────────────────────────────────────────────
function L:Drag(handle, target, maxY)
    local dragging, s0, p0 = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if maxY and (Mouse.Y - handle.AbsolutePosition.Y) > maxY then return end
        dragging=true; s0=Vector2.new(Mouse.X,Mouse.Y); p0=target.Position
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d = Vector2.new(Mouse.X,Mouse.Y) - s0
        target.Position = UDim2.new(p0.X.Scale,p0.X.Offset+d.X,p0.Y.Scale,p0.Y.Offset+d.Y)
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
end

-- ── Acrylic blur (correct 7kayoh technique) ───────────────────────
local function MakeAcrylic(parent, bgColor, bgTrans)
    -- ViewportFrame behind all content
    local vp = Instance.new("ViewportFrame")
    vp.BackgroundTransparency = 1
    vp.Size = UDim2.fromScale(1,1)
    vp.ZIndex = 1
    vp.Ambient = Color3.fromRGB(18,20,30)
    vp.LightColor = Color3.fromRGB(220,225,255)
    vp.LightDirection = Vector3.new(-1,-2,-1)
    vp.Parent = parent

    local vpCam = Instance.new("Camera")
    vpCam.FieldOfView = Cam.FieldOfView
    vp.CurrentCamera = vpCam
    vpCam.Parent = vp

    -- DepthOfField on the viewport camera = frosted blur
    local dof = Instance.new("DepthOfFieldEffect")
    dof.FocusDistance = 0
    dof.InFocusRadius = 0.1
    dof.NearIntensity = 1
    dof.FarIntensity  = 0
    dof.Enabled = true
    dof.Parent = vpCam

    -- Glass part lives in Workspace (sees the real 3D world)
    local folder = Instance.new("Folder")
    folder.Name = "_LWAcrylic"
    folder.Parent = WS

    local function makePart()
        local p = Instance.new("Part")
        p.Material      = Enum.Material.Glass
        p.Color         = Color3.fromRGB(22, 25, 38)
        p.Transparency  = 0.82
        p.Reflectance   = 0
        p.Anchored      = true
        p.CanCollide    = false
        p.CastShadow    = false
        p.TopSurface    = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        return p
    end
    local wsPart = makePart(); wsPart.Parent = folder
    local vpPart = makePart(); vpPart.Parent = vp

    -- Dark tint overlay on top of acrylic
    local overlay = Instance.new("Frame")
    overlay.BackgroundColor3       = bgColor or Color3.fromRGB(16,18,28)
    overlay.BackgroundTransparency = bgTrans or 0.35
    overlay.BorderSizePixel        = 0
    overlay.Size                   = UDim2.fromScale(1,1)
    overlay.ZIndex                 = 2
    overlay.Parent                 = parent

    -- Per-frame: sync camera + scale glass part to fill viewport exactly
    local conn = RS.RenderStepped:Connect(function()
        local cf  = Cam.CFrame
        local fov = Cam.FieldOfView
        local dist = 2

        local posCF = cf * CFrame.new(0, 0, -dist)
        wsPart.CFrame = posCF
        vpPart.CFrame = posCF

        local abs = vp.AbsoluteSize
        if abs.X > 0 and abs.Y > 0 then
            local halfH = math.tan(math.rad(fov * 0.5)) * dist
            local halfW = halfH * (abs.X / abs.Y)
            local sz = Vector3.new(halfW*2+0.5, halfH*2+0.5, 0.05)
            wsPart.Size = sz
            vpPart.Size = sz
        end

        vpCam.CFrame      = cf
        vpCam.FieldOfView = fov
    end)

    return overlay, function()
        conn:Disconnect()
        pcall(function() folder:Destroy() end)
    end
end

-- ── Loading Screen ────────────────────────────────────────────────
function L:ShowLoading(onDone)
    local ov = self:New("Frame", {
        BackgroundColor3=self.BgDeep, BackgroundTransparency=0,
        Size=UDim2.fromScale(1,1), ZIndex=2000, Parent=SG,
    })
    local diamond = self:New("Frame", {
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.44,0),
        Size=UDim2.fromOffset(0,0),
        BackgroundColor3=self.Accent, Rotation=45,
        BorderSizePixel=0, ZIndex=2001, Parent=ov,
    })
    self:Corner(diamond, 8)
    self:Reg(diamond, "BackgroundColor3", "Accent")

    local title = self:New("TextLabel", {
        BackgroundTransparency=1, Font=self.FontBold,
        Text="LUMINWARE", TextColor3=self.TextHi, TextSize=24,
        TextTransparency=1, AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.new(0.5,0,0.52,0),
        Size=UDim2.new(1,0,0,30),
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=2001, Parent=ov,
    })
    local sub = self:New("TextLabel", {
        BackgroundTransparency=1, Font=self.Font,
        Text="INITIALIZING...", TextColor3=self.TextLow, TextSize=11,
        AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.new(0.5,0,0.585,0),
        Size=UDim2.new(1,0,0,18),
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=2001, Parent=ov,
    })
    local barBg = self:New("Frame", {
        AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.new(0.5,0,0.625,0),
        Size=UDim2.fromOffset(180,3),
        BackgroundColor3=self.BgLight, BorderSizePixel=0,
        ZIndex=2001, Parent=ov,
    })
    self:Corner(barBg, 2)
    local barFill = self:New("Frame", {
        BackgroundColor3=self.Accent, BorderSizePixel=0,
        Size=UDim2.new(0,0,1,0), ZIndex=2002, Parent=barBg,
    })
    self:Corner(barFill, 2)
    self:Reg(barFill, "BackgroundColor3", "Accent")

    TW(diamond, {Size=UDim2.fromOffset(52,52)}, 0.4, Enum.EasingStyle.Back)
    task.wait(0.3)
    TW(title, {TextTransparency=0}, 0.3)

    local steps = {"LOADING MODULES...","APPLYING PATCHES...","READY"}
    for n, msg in ipairs(steps) do
        sub.Text = msg
        TW(barFill, {Size=UDim2.new(n/#steps,0,1,0)}, 0.35, Enum.EasingStyle.Quint)
        task.wait(0.42)
    end
    task.wait(0.1)
    TW(ov, {BackgroundTransparency=1}, 0.4)
    task.wait(0.45)
    pcall(function() ov:Destroy() end)
    if onDone then onDone() end
end

-- ── Card Components ───────────────────────────────────────────────
-- Returns a Card object with Add* methods, parented into a scroll column
local function BuildCard(L, scrollCol, titleText)
    -- Card frame — auto-sizes vertically
    local card = L:New("Frame", {
        BackgroundColor3=L.BgMid, BackgroundTransparency=0.18,
        BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=5, Parent=scrollCol,
    })
    L:Corner(card, 10)
    L:Stroke(card, L.EdgeColor, 1, 0.90)
    L:Reg(card, "BackgroundColor3", "BgMid")

    -- thin top edge highlight
    L:New("Frame", {
        BackgroundColor3=L.EdgeColor, BackgroundTransparency=0.88,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,1), ZIndex=6, Parent=card,
    })

    -- Header (optional title)
    local headerH = 0
    if titleText and titleText ~= "" then
        headerH = 32
        local hdr = L:New("Frame", {
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,32), ZIndex=6, Parent=card,
        })
        L:New("TextLabel", {
            BackgroundTransparency=1, Font=L.FontSemi,
            Text=string.upper(titleText), TextColor3=L.TextLow, TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(14,0), Size=UDim2.new(1,-28,1,0),
            ZIndex=7, Parent=hdr,
        })
        L:New("Frame", {
            BackgroundColor3=L.EdgeColor, BackgroundTransparency=0.90,
            BorderSizePixel=0, AnchorPoint=Vector2.new(0,1),
            Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,1),
            ZIndex=7, Parent=hdr,
        })
    end

    -- Content container
    local content = L:New("Frame", {
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(0, headerH),
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=6, Parent=card,
    })
    L:New("UIListLayout", {
        FillDirection=Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=content,
    })
    L:New("UIPadding", {
        PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
        PaddingBottom=UDim.new(0,10),
        Parent=content,
    })

    -- ── helper: row ──────────────────────────────────────────────
    local function Row(h)
        return L:New("Frame", {
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,h or 40),
            ZIndex=7, Parent=content,
        })
    end
    local function RowLabel(parent, text)
        return L:New("TextLabel", {
            BackgroundTransparency=1, Font=L.Font,
            Text=text or "", TextColor3=L.TextHi, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(0.6,0,1,0), ZIndex=8, Parent=parent,
        })
    end

    local Card = {}

    -- ── Toggle ───────────────────────────────────────────────────
    function Card:AddToggle(idx, info)
        info = info or {}
        local row = Row(40)
        local lbl = RowLabel(row, info.Label or info.Text or idx)

        local track = L:New("Frame", {
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
            Size=UDim2.fromOffset(40,22),
            BackgroundColor3=L.BgLight, ZIndex=8, Parent=row,
        })
        L:Corner(track, 11)
        L:Reg(track, "BackgroundColor3", "BgLight")

        local knob = L:New("Frame", {
            AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,2,0.5,0),
            Size=UDim2.fromOffset(18,18),
            BackgroundColor3=L.TextMid, ZIndex=9, Parent=track,
        })
        L:Corner(knob, 9)

        local Tog = {
            Value=not not info.Default, Type="Toggle",
            Callback=info.Callback or function()end, Addons={},
        }

        function Tog:Render(animate)
            local tc = self.Value and L.Accent or L.BgLight
            local kc = self.Value and Color3.new(1,1,1) or L.TextMid
            local kp = self.Value and UDim2.new(1,-20,0.5,0) or UDim2.new(0,2,0.5,0)
            if animate then
                TW(track, {BackgroundColor3=tc}, 0.18)
                TW(knob,  {BackgroundColor3=kc, Position=kp}, 0.18)
            else
                track.BackgroundColor3=tc; knob.BackgroundColor3=kc; knob.Position=kp
            end
            for _,r in next,L.Registry do
                if r.inst==track then r.key=self.Value and "Accent" or "BgLight" end
            end
        end

        function Tog:SetValue(v)
            self.Value = not not v
            self:Render(true)
            L:CB(self.Callback, self.Value)
            L:CB(self.Changed,  self.Value)
        end
        function Tog:OnChanged(fn) self.Changed=fn; fn(self.Value) end

        local hit = L:New("TextButton", {
            BackgroundTransparency=1, Text="",
            Size=UDim2.fromScale(1,1), ZIndex=10, Parent=row,
        })
        hit.MouseButton1Click:Connect(function() Tog:SetValue(not Tog.Value) end)
        hit.MouseEnter:Connect(function() TW(lbl,{TextColor3=L.Accent},0.12) end)
        hit.MouseLeave:Connect(function() TW(lbl,{TextColor3=L.TextHi},0.12) end)

        Tog:Render(false)
        L.Toggles[idx] = Tog
        return Tog
    end

    -- ── Slider ───────────────────────────────────────────────────
    function Card:AddSlider(idx, info)
        info = info or {}
        local min = info.Min or 0; local max = info.Max or 100
        local def = info.Default or min; local suf = info.Suffix or ""

        local wrap = L:New("Frame", {
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,50), ZIndex=7, Parent=content,
        })
        L:New("TextLabel", {
            BackgroundTransparency=1, Font=L.Font,
            Text=info.Label or info.Text or idx,
            TextColor3=L.TextHi, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(0.65,0,0,22), ZIndex=8, Parent=wrap,
        })
        local valLbl = L:New("TextLabel", {
            BackgroundTransparency=1, Font=L.FontSemi,
            Text=tostring(def)..suf, TextColor3=L.Accent, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Right,
            AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0),
            Size=UDim2.new(0.35,0,0,22), ZIndex=8, Parent=wrap,
        })
        L:Reg(valLbl, "TextColor3", "Accent")

        -- track
        local track = L:New("Frame", {
            BorderSizePixel=0, Position=UDim2.fromOffset(0,28),
            BackgroundColor3=L.BgLight, Size=UDim2.new(1,0,0,4),
            ZIndex=8, Parent=wrap,
        })
        L:Corner(track, 2)
        L:Reg(track, "BackgroundColor3", "BgLight")

        local fill = L:New("Frame", {
            BackgroundColor3=L.Accent, BorderSizePixel=0,
            Size=UDim2.new(0,0,1,0), ZIndex=9, Parent=track,
        })
        L:Corner(fill, 2)
        L:Reg(fill, "BackgroundColor3", "Accent")

        local knob = L:New("Frame", {
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0,0,0.5,0),
            Size=UDim2.fromOffset(14,14), BackgroundColor3=L.Accent,
            ZIndex=10, Parent=track,
        })
        L:Corner(knob, 7)
        L:Reg(knob, "BackgroundColor3", "Accent")
        L:New("UIStroke", {
            Color=Color3.new(1,1,1), Thickness=2, Transparency=0.75,
            ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=knob,
        })

        local Sli = {
            Value=def, Min=min, Max=max, Rounding=info.Rounding or 0,
            Type="Slider", Callback=info.Callback or function()end,
        }
        local function rnd(v)
            if Sli.Rounding==0 then return math.floor(v+0.5) end
            return tonumber(string.format("%."..Sli.Rounding.."f",v))
        end
        function Sli:Render()
            local p = math.clamp((self.Value-min)/(max-min),0,1)
            fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,0)
            valLbl.Text=tostring(self.Value)..suf
        end
        function Sli:SetValue(v)
            local n=tonumber(v); if not n then return end
            self.Value=rnd(math.clamp(n,min,max)); self:Render()
            L:CB(self.Callback,self.Value); L:CB(self.Changed,self.Value)
        end
        function Sli:OnChanged(fn) self.Changed=fn; fn(self.Value) end

        -- drag
        local function startDrag()
            local c; c=RS.Heartbeat:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                local p=math.clamp((Mouse.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                Sli:SetValue(min+p*(max-min))
            end)
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then startDrag() end
        end)
        knob.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then startDrag() end
        end)

        Sli:Render()
        L.Options[idx] = Sli
        return Sli
    end

    -- ── Button ───────────────────────────────────────────────────
    function Card:AddButton(info)
        info = type(info)=="string" and {Label=info} or info
        local row = Row(40)
        RowLabel(row, info.Label or info.Text or "")

        local btn = L:New("TextButton", {
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
            BackgroundColor3=L.BgLight, BackgroundTransparency=0.25,
            Font=L.FontSemi, Text=info.Action or "Execute",
            TextColor3=L.TextHi, TextSize=12,
            Size=UDim2.fromOffset(84,28), ZIndex=8, Parent=row,
        })
        L:Corner(btn, 7)
        L:Stroke(btn, L.EdgeColor, 1, 0.84)

        btn.MouseButton1Click:Connect(function()
            TW(btn,{BackgroundColor3=L.Accent},0.07)
            task.delay(0.14,function() TW(btn,{BackgroundColor3=L.BgLight},0.22) end)
            L:CB(info.Callback or info.Func)
        end)
        btn.MouseEnter:Connect(function() TW(btn,{BackgroundTransparency=0.05},0.12) end)
        btn.MouseLeave:Connect(function() TW(btn,{BackgroundTransparency=0.25},0.12) end)
        return btn
    end

    -- ── Dropdown ─────────────────────────────────────────────────
    function Card:AddDropdown(idx, info)
        info = info or {}
        local wrap = L:New("Frame", {
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,60), ZIndex=7, Parent=content,
        })
        L:New("TextLabel", {
            BackgroundTransparency=1, Font=L.Font,
            Text=info.Label or info.Text or idx,
            TextColor3=L.TextHi, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,0,0,20), ZIndex=8, Parent=wrap,
        })

        -- the visible button
        local dbtn = L:New("Frame", {
            BackgroundColor3=L.BgLight, BackgroundTransparency=0.15,
            BorderSizePixel=0,
            Position=UDim2.fromOffset(0,22), Size=UDim2.new(1,0,0,32),
            ZIndex=8, Parent=wrap,
        })
        L:Corner(dbtn, 7)
        L:Stroke(dbtn, L.EdgeColor, 1, 0.82)
        L:Reg(dbtn, "BackgroundColor3", "BgLight")

        local selLbl = L:New("TextLabel", {
            BackgroundTransparency=1, Font=L.FontSemi,
            Text=tostring(info.Default or "--"),
            TextColor3=L.TextHi, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(10,0), Size=UDim2.new(1,-36,1,0),
            ZIndex=9, Parent=dbtn,
        })
        local arrow = L:New("TextLabel", {
            BackgroundTransparency=1, Font=L.FontBold,
            Text="▾", TextColor3=L.TextMid, TextSize=14,
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
            Size=UDim2.fromOffset(16,16), ZIndex=9, Parent=dbtn,
        })

        local DD = {
            Value=info.Default, Values=info.Values or {},
            Type="Dropdown", Callback=info.Callback or function()end,
        }

        -- popup frame — parented to SG so it floats above everything
        local popup = L:New("Frame", {
            BackgroundColor3=L.BgMid, BackgroundTransparency=0.05,
            BorderSizePixel=0, ZIndex=500, Visible=false, Parent=SG,
        })
        L:Corner(popup, 8)
        L:Stroke(popup, L.EdgeColor, 1, 0.78)
        L:Reg(popup, "BackgroundColor3", "BgMid")

        local popLayout = L:New("UIListLayout", {
            FillDirection=Enum.FillDirection.Vertical,
            SortOrder=Enum.SortOrder.LayoutOrder, Parent=popup,
        })
        L:New("UIPadding", {
            PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4), Parent=popup,
        })

        local function closeDD()
            if not popup.Visible then return end
            popup.Visible = false
            TW(arrow, {Rotation=0}, 0.14)
        end
        table.insert(L.Popups, closeDD)

        local function buildList()
            -- clear old items
            for _,c in next, popup:GetChildren() do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, val in next, DD.Values do
                local isSel = (val == DD.Value)
                local item = L:New("TextButton", {
                    BackgroundColor3 = isSel and L.Accent or L.BgLight,
                    BackgroundTransparency = isSel and 0.7 or 0.9,
                    Font=L.FontSemi, Text="",
                    Size=UDim2.new(1,0,0,32), ZIndex=501, Parent=popup,
                })
                L:New("TextLabel", {
                    BackgroundTransparency=1, Font=L.FontSemi,
                    Text=tostring(val),
                    TextColor3=isSel and L.TextHi or L.TextMid,
                    TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
                    Position=UDim2.fromOffset(12,0), Size=UDim2.new(1,-12,1,0),
                    ZIndex=502, Parent=item,
                })
                local v = val
                item.MouseButton1Click:Connect(function()
                    DD.Value = v
                    selLbl.Text = tostring(v)
                    buildList()
                    closeDD()
                    L:CB(DD.Callback, v)
                    L:CB(DD.Changed,  v)
                end)
                item.MouseEnter:Connect(function()
                    if v~=DD.Value then TW(item,{BackgroundTransparency=0.72},0.08) end
                end)
                item.MouseLeave:Connect(function()
                    if v~=DD.Value then TW(item,{BackgroundTransparency=0.9},0.08) end
                end)
            end

            -- position + size popup
            local count = math.min(#DD.Values, 7)
            local h = count * 32 + 8
            popup.Size = UDim2.fromOffset(dbtn.AbsoluteSize.X, h)
            popup.Position = UDim2.fromOffset(
                dbtn.AbsolutePosition.X,
                dbtn.AbsolutePosition.Y + dbtn.AbsoluteSize.Y + 2
            )
        end

        -- clickable hit area over the whole dbtn frame
        local hit = L:New("TextButton", {
            BackgroundTransparency=1, Text="",
            Size=UDim2.fromScale(1,1), ZIndex=10, Parent=dbtn,
        })
        hit.MouseButton1Click:Connect(function()
            if popup.Visible then
                closeDD()
            else
                for _,fn in next, L.Popups do fn() end
                buildList()
                popup.Visible = true
                TW(arrow, {Rotation=180}, 0.14)
            end
        end)

        function DD:SetValue(v)
            self.Value=v; selLbl.Text=tostring(v); buildList()
            L:CB(self.Callback,v); L:CB(self.Changed,v)
        end
        function DD:SetValues(vals)
            self.Values=vals; buildList()
        end
        function DD:OnChanged(fn) self.Changed=fn; fn(self.Value) end

        L.Options[idx] = DD
        return DD
    end

    -- ── Input ─────────────────────────────────────────────────────
    function Card:AddInput(idx, info)
        info = info or {}
        local wrap = L:New("Frame", {
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,60), ZIndex=7, Parent=content,
        })
        L:New("TextLabel", {
            BackgroundTransparency=1, Font=L.Font,
            Text=info.Label or info.Text or idx,
            TextColor3=L.TextHi, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,0,0,20), ZIndex=8, Parent=wrap,
        })
        local box = L:New("TextBox", {
            BackgroundColor3=L.BgLight, BackgroundTransparency=0.15,
            Font=L.Font, Text=info.Default or "",
            PlaceholderText=info.Placeholder or "",
            PlaceholderColor3=L.TextLow,
            TextColor3=L.TextHi, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            ClearTextOnFocus=false,
            Position=UDim2.fromOffset(0,24), Size=UDim2.new(1,0,0,30),
            ZIndex=8, Parent=wrap,
        })
        L:Corner(box, 7)
        L:Stroke(box, L.EdgeColor, 1, 0.82)
        L:New("UIPadding", {PaddingLeft=UDim.new(0,10), Parent=box})

        local Inp = { Value=info.Default or "", Type="Input", Callback=info.Callback or function()end }
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if info.Numeric and not tonumber(box.Text) and #box.Text>0 then box.Text=Inp.Value;return end
            Inp.Value = box.Text
            if not info.Finished then L:CB(Inp.Callback, Inp.Value) end
        end)
        box.FocusLost:Connect(function(enter)
            if info.Finished and enter then L:CB(Inp.Callback, Inp.Value) end
            L:CB(Inp.Changed, Inp.Value)
        end)
        function Inp:SetValue(v) box.Text=tostring(v); self.Value=tostring(v) end
        function Inp:OnChanged(fn) self.Changed=fn; fn(self.Value) end

        L.Options[idx] = Inp
        return Inp
    end

    -- ── Keybind ──────────────────────────────────────────────────
    function Card:AddKeybind(idx, info)
        info = info or {}
        local row = Row(40)
        RowLabel(row, info.Label or info.Text or idx)

        local kbtn = L:New("TextButton", {
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
            BackgroundColor3=L.BgLight, BackgroundTransparency=0.15,
            Font=L.FontSemi, Text=info.Default or "None",
            TextColor3=L.Accent, TextSize=12,
            Size=UDim2.fromOffset(72,26), ZIndex=8, Parent=row,
        })
        L:Corner(kbtn, 6)
        L:Stroke(kbtn, L.EdgeColor, 1, 0.82)
        L:Reg(kbtn, "TextColor3", "Accent")

        local KP = {
            Value=info.Default or "None", Mode=info.Mode or "Toggle",
            Toggled=false, Type="KeyPicker", Callback=info.Callback or function()end,
        }
        local picking = false
        kbtn.MouseButton1Click:Connect(function()
            if picking then return end
            picking = true; kbtn.Text = "..."
            local c; c = UIS.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    KP.Value = inp.KeyCode.Name; kbtn.Text = inp.KeyCode.Name
                    picking = false; c:Disconnect()
                    L:CB(KP.ChangedCallback, inp.KeyCode)
                elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
                    picking = false; c:Disconnect(); kbtn.Text = KP.Value
                end
            end)
        end)
        UIS.InputBegan:Connect(function(inp)
            if picking then return end
            if inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode.Name==KP.Value then
                if KP.Mode=="Toggle" then KP.Toggled=not KP.Toggled; L:CB(KP.Callback,KP.Toggled) end
            end
        end)
        function KP:GetState() return self.Toggled end
        function KP:SetValue(d) self.Value=d[1];self.Mode=d[2];kbtn.Text=d[1] end
        function KP:OnChanged(fn) self.Changed=fn end
        L.Options[idx] = KP
        return KP
    end

    -- ── ColorPicker ──────────────────────────────────────────────
    function Card:AddColorPicker(idx, info)
        info = info or {}
        local row = Row(40)
        RowLabel(row, info.Label or info.Title or idx)

        local swatch = L:New("TextButton", {
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
            BackgroundColor3=info.Default or L.Accent,
            Size=UDim2.fromOffset(38,20), Text="", ZIndex=8, Parent=row,
        })
        L:Corner(swatch, 5)
        L:Stroke(swatch, L.EdgeColor, 1, 0.82)

        local CP = {
            Value=info.Default or L.Accent, Transparency=info.Transparency or 0,
            Type="ColorPicker", Callback=info.Callback or function()end,
        }
        function CP:SetHSV(c) self.Hue,self.Sat,self.Vib=Color3.toHSV(c) end
        CP:SetHSV(CP.Value)

        local popup = L:New("Frame", {
            BackgroundColor3=L.BgMid, BackgroundTransparency=0.05,
            BorderSizePixel=0, Size=UDim2.fromOffset(224,252),
            Visible=false, ZIndex=500, Parent=SG,
        })
        L:Corner(popup, 10)
        L:Stroke(popup, L.EdgeColor, 1, 0.78)
        L:Reg(popup, "BackgroundColor3", "BgMid")

        L:New("TextLabel", {
            BackgroundTransparency=1, Font=L.FontSemi,
            Text=info.Title or "Color", TextColor3=L.TextHi, TextSize=13,
            Position=UDim2.fromOffset(12,8), Size=UDim2.new(1,-24,0,20),
            ZIndex=501, Parent=popup,
        })

        local svM = L:New("ImageLabel", {
            BorderSizePixel=0, Position=UDim2.fromOffset(10,32),
            Size=UDim2.fromOffset(164,164),
            Image="rbxassetid://4155801252", ZIndex=501, Parent=popup,
        })
        L:Corner(svM, 5)

        local svC = L:New("Frame", {
            AnchorPoint=Vector2.new(0.5,0.5),
            Size=UDim2.fromOffset(10,10),
            BackgroundColor3=Color3.new(1,1,1), ZIndex=502, Parent=svM,
        })
        L:Corner(svC, 5)
        L:New("UIStroke",{Color=Color3.new(0,0,0),Thickness=1.5,Parent=svC})

        local hBar = L:New("Frame", {
            BorderSizePixel=0, Position=UDim2.fromOffset(180,32),
            Size=UDim2.fromOffset(14,164), ZIndex=501, Parent=popup,
        })
        L:Corner(hBar, 4)
        local hSeq = {}
        for i=0,10 do hSeq[#hSeq+1]=ColorSequenceKeypoint.new(i/10,Color3.fromHSV(i/10,1,1)) end
        L:New("UIGradient",{Color=ColorSequence.new(hSeq),Rotation=90,Parent=hBar})
        local hC = L:New("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=Color3.new(1,1,1),
            BorderSizePixel=0, Size=UDim2.fromOffset(14,4), ZIndex=502, Parent=hBar,
        })

        local hexBox = L:New("TextBox", {
            BackgroundColor3=L.BgLight, BackgroundTransparency=0.5,
            Font=L.Font, Text="#"..CP.Value:ToHex():upper(),
            PlaceholderText="#FFFFFF", TextColor3=L.TextHi, TextSize=12,
            ClearTextOnFocus=false,
            Position=UDim2.fromOffset(10,204), Size=UDim2.fromOffset(100,28),
            ZIndex=501, Parent=popup,
        })
        L:Corner(hexBox, 5)
        L:New("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=hexBox})

        function CP:Display()
            self.Value = Color3.fromHSV(self.Hue,self.Sat,self.Vib)
            svM.BackgroundColor3 = Color3.fromHSV(self.Hue,1,1)
            swatch.BackgroundColor3 = self.Value
            svC.Position = UDim2.new(self.Sat,0,1-self.Vib,0)
            hC.Position  = UDim2.new(0,0,self.Hue,0)
            hexBox.Text  = "#"..self.Value:ToHex():upper()
            L:CB(self.Callback,self.Value); L:CB(self.Changed,self.Value)
        end

        svM.InputBegan:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local c; c=RS.Heartbeat:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                CP.Sat = math.clamp((Mouse.X-svM.AbsolutePosition.X)/svM.AbsoluteSize.X,0,1)
                CP.Vib = 1-math.clamp((Mouse.Y-svM.AbsolutePosition.Y)/svM.AbsoluteSize.Y,0,1)
                CP:Display()
            end)
        end)
        hBar.InputBegan:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local c; c=RS.Heartbeat:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                CP.Hue = math.clamp((Mouse.Y-hBar.AbsolutePosition.Y)/hBar.AbsoluteSize.Y,0,1)
                CP:Display()
            end)
        end)
        hexBox.FocusLost:Connect(function(enter)
            if not enter then return end
            local ok,col=pcall(Color3.fromHex,hexBox.Text)
            if ok then CP:SetHSV(col); CP:Display() end
        end)

        local popOpen = false
        swatch.MouseButton1Click:Connect(function()
            popOpen = not popOpen
            if popOpen then
                for _,fn in next, L.Popups do fn() end
                popup.Position = UDim2.fromOffset(
                    math.max(4, swatch.AbsolutePosition.X - 224),
                    swatch.AbsolutePosition.Y + 4
                )
                popup.Visible = true
            else
                popup.Visible = false
            end
        end)
        table.insert(L.Popups, function() popup.Visible=false; popOpen=false end)

        function CP:SetValueRGB(c,t) self.Transparency=t or 0; self:SetHSV(c); self:Display() end
        function CP:SetValue(h,t) self.Transparency=t or 0; self:SetHSV(Color3.fromHSV(h[1],h[2],h[3])); self:Display() end
        function CP:OnChanged(fn) self.Changed=fn; fn(self.Value) end

        CP:Display()
        L.Options[idx] = CP
        return CP
    end

    return Card
end

-- ── Scroll Column Helper ──────────────────────────────────────────
local function MakeScrollCol(L, parent, xScale, xOffset, xSizeScale, xSizeOffset, yOffset)
    local col = L:New("ScrollingFrame", {
        BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.new(xScale, xOffset+6, 0, yOffset or 6),
        Size=UDim2.new(xSizeScale, xSizeOffset-12, 1, -(yOffset or 6)-6),
        CanvasSize=UDim2.fromOffset(0,0),
        ScrollBarThickness=3,
        ScrollBarImageColor3=L.Accent,
        ScrollBarImageTransparency=0.5,
        TopImage="", BottomImage="",
        ZIndex=4, Parent=parent,
    })
    L:Reg(col, "ScrollBarImageColor3", "Accent")
    local layout = L:New("UIListLayout", {
        FillDirection=Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,8), Parent=col,
    })
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        col.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
    end)
    return col
end

-- ── CreateWindow ──────────────────────────────────────────────────
function L:CreateWindow(cfg)
    cfg = cfg or {}
    local W_SIZE   = cfg.Size or Vector2.new(900, 560)
    local logoId   = cfg.Logo or ""
    local useAcr   = cfg.Acrylic ~= false

    local Window = { Tabs={}, _tabOrder={} }

    -- ─── Root (positioning anchor, transparent) ─────────────────
    local Root = self:New("Frame", {
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(W_SIZE.X, W_SIZE.Y),
        ZIndex=2, Visible=false, Parent=SG,
    })

    -- ─── Minimize icon ──────────────────────────────────────────
    local MinIcon = self:New("Frame", {
        BackgroundColor3=self.BgMid, BackgroundTransparency=0.1,
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.fromScale(0.1,0.9),
        Size=UDim2.fromOffset(56,56),
        Visible=false, ZIndex=500, Parent=SG,
    })
    self:Corner(MinIcon, 14)
    self:Stroke(MinIcon, self.EdgeColor, 1, 0.78)
    self:Drag(MinIcon, MinIcon)
    if logoId ~= "" then
        self:New("ImageLabel", {
            BackgroundTransparency=1, Image=logoId,
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(36,36), ScaleType=Enum.ScaleType.Fit,
            ZIndex=501, Parent=MinIcon,
        })
    else
        local d = self:New("Frame", {
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(20,20), BackgroundColor3=self.Accent,
            Rotation=45, BorderSizePixel=0, ZIndex=501, Parent=MinIcon,
        })
        self:Corner(d, 4); self:Reg(d,"BackgroundColor3","Accent")
    end
    self:New("TextButton", {
        BackgroundTransparency=1, Text="",
        Size=UDim2.fromScale(1,1), ZIndex=502, Parent=MinIcon,
    }).MouseButton1Click:Connect(function()
        MinIcon.Visible=false; Root.Visible=true
    end)

    -- ─── Main panel ─────────────────────────────────────────────
    -- ClipsDescendants so acrylic doesn't bleed outside rounded corners
    local Main = self:New("Frame", {
        BackgroundColor3=self.BgDeep, BackgroundTransparency=0.05,
        BorderSizePixel=0, Size=UDim2.fromScale(1,1),
        ClipsDescendants=true, ZIndex=2, Parent=Root,
    })
    self:Corner(Main, 14)
    self:Stroke(Main, self.EdgeColor, 1, 0.82)
    self:Reg(Main, "BackgroundColor3", "BgDeep")

    -- Acrylic layer (ZIndex=1 so it's behind everything else in Main)
    if useAcr then
        local acrFrame = self:New("Frame", {
            BackgroundTransparency=1, Size=UDim2.fromScale(1,1),
            ZIndex=1, Parent=Main,
        })
        local _overlay, cleanup = MakeAcrylic(acrFrame, self.BgDeep, 0.32)
        self:Reg(_overlay, "BackgroundColor3", "BgDeep")
        table.insert(self._acleanup, cleanup)
    end

    -- ─── SIDEBAR (fixed 62px width) ─────────────────────────────
    local SW = 62   -- sidebar width

    local Sidebar = self:New("Frame", {
        BackgroundColor3=self.Sidebar, BackgroundTransparency=0.05,
        BorderSizePixel=0,
        Size=UDim2.fromOffset(SW, W_SIZE.Y),
        ZIndex=10, Parent=Main,  -- ZIndex 10 so it's above acrylic overlay
    })
    -- UICorner on the sidebar rounds all 4 corners.
    -- To only round the left side, layer a square frame over the right half.
    self:New("UICorner", {CornerRadius=UDim.new(0,14), Parent=Sidebar})
    self:New("Frame", {
        BackgroundColor3=self.Sidebar, BackgroundTransparency=0.05,
        BorderSizePixel=0,
        Position=UDim2.fromOffset(SW/2,0), Size=UDim2.fromOffset(SW/2, W_SIZE.Y),
        ZIndex=10, Parent=Sidebar,
    })
    self:Reg(Sidebar, "BackgroundColor3", "Sidebar")

    -- right-edge subtle separator
    self:New("Frame", {
        BackgroundColor3=self.EdgeColor, BackgroundTransparency=0.88,
        BorderSizePixel=0,
        Position=UDim2.fromOffset(SW-1,0), Size=UDim2.fromOffset(1,W_SIZE.Y),
        ZIndex=11, Parent=Main,
    })

    -- Logo area (top of sidebar)
    local logoArea = self:New("Frame", {
        BackgroundTransparency=1, Size=UDim2.fromOffset(SW,60),
        ZIndex=11, Parent=Sidebar,
    })
    if logoId ~= "" then
        self:New("ImageLabel",{
            BackgroundTransparency=1, Image=logoId,
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(30,30), ScaleType=Enum.ScaleType.Fit,
            ZIndex=12, Parent=logoArea,
        })
    else
        local d = self:New("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(18,18), BackgroundColor3=self.Accent,
            Rotation=45, BorderSizePixel=0, ZIndex=12, Parent=logoArea,
        })
        self:Corner(d,4); self:Reg(d,"BackgroundColor3","Accent")
    end

    -- Nav icon list
    local NavList = self:New("Frame", {
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,64),
        Size=UDim2.new(1,0,1,-130),
        ZIndex=11, Parent=Sidebar,
    })
    self:New("UIListLayout",{
        FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=NavList,
    })

    -- Active nav indicator bar
    local NavIndicator = self:New("Frame",{
        BackgroundColor3=self.Accent, BorderSizePixel=0,
        Position=UDim2.fromOffset(SW-3,80), Size=UDim2.fromOffset(3,30),
        ZIndex=15, Parent=Main,
    })
    self:Corner(NavIndicator,2); self:Reg(NavIndicator,"BackgroundColor3","Accent")

    -- Bottom sidebar buttons (minimize + close)
    local BotArea = self:New("Frame",{
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,1), Position=UDim2.new(0.5,0,1,-10),
        Size=UDim2.fromOffset(SW,92), ZIndex=11, Parent=Sidebar,
    })
    self:New("UIListLayout",{
        FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=BotArea,
    })

    local function SideIconBtn(iconId, baseColor, fn)
        local bg = self:New("TextButton",{
            BackgroundColor3=baseColor or self.BgLight,
            BackgroundTransparency=0.6,
            Size=UDim2.fromOffset(38,38), Text="", ZIndex=12, Parent=BotArea,
        })
        self:Corner(bg,9)
        if iconId and iconId~="" then
            local img=self:New("ImageLabel",{
                BackgroundTransparency=1, Image=iconId,
                ImageColor3=self.TextLow,
                AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
                Size=UDim2.fromOffset(17,17), ZIndex=13, Parent=bg,
            })
            bg.MouseEnter:Connect(function()
                TW(bg,{BackgroundTransparency=0.3},0.12)
                TW(img,{ImageColor3=self.TextHi},0.12)
            end)
            bg.MouseLeave:Connect(function()
                TW(bg,{BackgroundTransparency=0.6},0.12)
                TW(img,{ImageColor3=self.TextLow},0.12)
            end)
        end
        bg.MouseButton1Click:Connect(fn)
        return bg
    end

    -- Minimize
    SideIconBtn("rbxassetid://7072717857", nil, function()
        Root.Visible=false; MinIcon.Visible=true
    end)
    -- Close/Unload
    SideIconBtn("rbxassetid://7059364814", Color3.fromRGB(48,16,16), function()
        self:Notify({Title="Unloading...", Duration=0.8})
        task.delay(0.7, function() self:Unload() end)
    end)

    -- ─── Content area (to the right of sidebar) ─────────────────
    local Content = self:New("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(SW,0),
        Size=UDim2.new(1,-SW,1,0),
        ZIndex=10, Parent=Main,
    })

    -- Top bar (title + dots)
    local TopBar = self:New("Frame",{
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,48), ZIndex=11, Parent=Content,
    })
    self:Drag(TopBar, Root, 48)

    self:New("TextLabel",{
        BackgroundTransparency=1, Font=self.FontBold,
        Text=string.upper(cfg.Title or "LUMINWARE"),
        TextColor3=self.TextHi, TextSize=15,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(16,0), Size=UDim2.new(0.6,0,1,0),
        ZIndex=12, Parent=TopBar,
    })

    -- Yellow + Red dots top-right
    local dotRow = self:New("Frame",{
        BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0), Size=UDim2.fromOffset(42,14),
        ZIndex=12, Parent=TopBar,
    })
    self:New("UIListLayout",{
        FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Right,
        VerticalAlignment=Enum.VerticalAlignment.Center,
        Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=dotRow,
    })
    local function Dot(col, fn)
        local d = self:New("TextButton",{
            BackgroundColor3=col, Size=UDim2.fromOffset(13,13),
            Text="", ZIndex=13, Parent=dotRow,
        })
        self:Corner(d,7)
        d.MouseEnter:Connect(function() TW(d,{Size=UDim2.fromOffset(15,15)},0.1) end)
        d.MouseLeave:Connect(function() TW(d,{Size=UDim2.fromOffset(13,13)},0.1) end)
        d.MouseButton1Click:Connect(fn)
    end
    Dot(Color3.fromRGB(255,188,44), function() Root.Visible=false; MinIcon.Visible=true end)
    Dot(Color3.fromRGB(254,95,87),  function()
        self:Notify({Title="Closing...",Duration=0.8})
        task.delay(0.7,function() self:Unload() end)
    end)

    -- Divider under topbar
    self:New("Frame",{
        BackgroundColor3=self.EdgeColor, BackgroundTransparency=0.88,
        BorderSizePixel=0, Position=UDim2.fromOffset(0,47),
        Size=UDim2.new(1,0,0,1), ZIndex=11, Parent=Content,
    })

    -- ─── Main tab row (horizontal, scrolls to show active) ──────
    -- Height: 34px, positioned just below topbar
    local TabRowH = 34
    local TabRowY = 50

    local TabRowBg = self:New("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,TabRowY), Size=UDim2.new(1,0,0,TabRowH),
        ZIndex=11, Parent=Content,
    })
    local TabRowInner = self:New("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(16,0), Size=UDim2.new(1,-32,1,0),
        ZIndex=11, Parent=TabRowBg,
    })
    self:New("UIListLayout",{
        FillDirection=Enum.FillDirection.Horizontal,
        VerticalAlignment=Enum.VerticalAlignment.Center,
        Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=TabRowInner,
    })

    -- underline for main tabs
    local TabUnderline = self:New("Frame",{
        BackgroundColor3=self.Accent, BorderSizePixel=0,
        AnchorPoint=Vector2.new(0,1),
        Position=UDim2.fromOffset(0,TabRowH), Size=UDim2.fromOffset(0,2),
        ZIndex=13, Parent=TabRowInner,
    })
    self:Corner(TabUnderline,1); self:Reg(TabUnderline,"BackgroundColor3","Accent")
    -- base line
    self:New("Frame",{
        BackgroundColor3=self.EdgeColor, BackgroundTransparency=0.88,
        BorderSizePixel=0, AnchorPoint=Vector2.new(0,1),
        Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,1),
        ZIndex=12, Parent=TabRowInner,
    })

    -- divider under tab row
    self:New("Frame",{
        BackgroundColor3=self.EdgeColor, BackgroundTransparency=0.90,
        BorderSizePixel=0,
        Position=UDim2.fromOffset(0, TabRowY+TabRowH+1),
        Size=UDim2.new(1,0,0,1), ZIndex=11, Parent=Content,
    })

    -- Tab content host
    local TabHostY = TabRowY + TabRowH + 4
    local TabHost = self:New("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(0, TabHostY),
        Size=UDim2.new(1,0,1,-TabHostY),
        ZIndex=10, Parent=Content,
    })

    -- ─── AddTab ─────────────────────────────────────────────────
    local ICON_MAP = {
        Aimbot="rbxassetid://7506870928", ESP="rbxassetid://7506869530",
        Movement="rbxassetid://7507030703", Misc="rbxassetid://7506870548",
        Settings="rbxassetid://7507016059",
    }

    function Window:AddTab(opts)
        opts = type(opts)=="string" and {Name=opts} or opts
        local name    = opts.Name or "Tab"
        local iconKey = opts.Icon or name

        local Tab = { _name=name, Subtabs={}, _subtabOrder={} }

        -- Sidebar nav icon button
        local navBg = L:New("TextButton",{
            BackgroundColor3=L.BgLight, BackgroundTransparency=1,
            Size=UDim2.fromOffset(46,46), Text="", ZIndex=12, Parent=NavList,
        })
        L:Corner(navBg,10)
        local navImg = L:New("ImageLabel",{
            BackgroundTransparency=1,
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(19,19),
            Image=ICON_MAP[name] or ICON_MAP[iconKey] or "rbxassetid://7505493267",
            ImageColor3=L.TextLow, ZIndex=13, Parent=navBg,
        })
        -- hover tooltip
        local tip = L:New("TextLabel",{
            BackgroundColor3=L.BgMid, BackgroundTransparency=0.05,
            Font=L.FontSemi, Text=name, TextColor3=L.TextHi, TextSize=12,
            AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(1,6,0.5,0),
            Size=UDim2.fromOffset(72,24), Visible=false, ZIndex=60, Parent=navBg,
        })
        L:Corner(tip,6); L:Stroke(tip)
        navBg.MouseEnter:Connect(function() tip.Visible=true end)
        navBg.MouseLeave:Connect(function() tip.Visible=false end)

        -- Main tab text button
        local TAB_BTN_W = 76
        local tabBtn = L:New("TextButton",{
            BackgroundTransparency=1, Font=L.FontSemi,
            Text=name, TextColor3=L.TextLow, TextSize=13,
            Size=UDim2.fromOffset(TAB_BTN_W, TabRowH),
            ZIndex=12, Parent=TabRowInner,
        })

        -- Tab frame (holds subtab row + subtab content)
        local tabFrame = L:New("Frame",{
            BackgroundTransparency=1, Size=UDim2.fromScale(1,1),
            Visible=false, ZIndex=10, Parent=TabHost,
        })

        -- Subtab row inside this tab frame
        local SubRowH = 30
        local subRowBg = L:New("Frame",{
            BackgroundTransparency=1,
            Position=UDim2.fromOffset(12,0), Size=UDim2.new(1,-24,0,SubRowH),
            ZIndex=11, Parent=tabFrame,
        })
        L:New("UIListLayout",{
            FillDirection=Enum.FillDirection.Horizontal,
            VerticalAlignment=Enum.VerticalAlignment.Center,
            Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder,
            Parent=subRowBg,
        })
        -- subtab underline
        local SubLine = L:New("Frame",{
            BackgroundColor3=L.Accent, BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,1),
            Position=UDim2.fromOffset(0,SubRowH), Size=UDim2.fromOffset(0,2),
            ZIndex=13, Parent=subRowBg,
        })
        L:Corner(SubLine,1); L:Reg(SubLine,"BackgroundColor3","Accent")
        L:New("Frame",{
            BackgroundColor3=L.EdgeColor, BackgroundTransparency=0.88,
            BorderSizePixel=0, AnchorPoint=Vector2.new(0,1),
            Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,1),
            ZIndex=12, Parent=subRowBg,
        })

        -- Subtab content host
        local subHostY = SubRowH + 6
        local SubHost = L:New("Frame",{
            BackgroundTransparency=1,
            Position=UDim2.fromOffset(0,subHostY),
            Size=UDim2.new(1,0,1,-subHostY),
            ZIndex=10, Parent=tabFrame,
        })

        -- ─── AddSubtab ──────────────────────────────────────────
        function Tab:AddSubtab(subName)
            local Sub = { _name=subName }
            local SUB_W = 72

            local sBg = L:New("TextButton",{
                BackgroundTransparency=1, Font=L.FontSemi,
                Text=subName, TextColor3=L.TextLow, TextSize=13,
                Size=UDim2.fromOffset(SUB_W, SubRowH),
                ZIndex=12, Parent=subRowBg,
            })

            local sFrame = L:New("Frame",{
                BackgroundTransparency=1, Size=UDim2.fromScale(1,1),
                Visible=false, ZIndex=10, Parent=SubHost,
            })

            -- Two scroll columns inside sFrame
            local leftCol  = MakeScrollCol(L, sFrame, 0,   0,    0.5, 0, 4)
            local rightCol = MakeScrollCol(L, sFrame, 0.5, 0,    0.5, 0, 4)

            -- Pane API
            local function PaneAPI(col)
                local P = {}
                function P:AddCard(title)
                    return BuildCard(L, col, title or "")
                end
                return P
            end
            Sub.Left  = PaneAPI(leftCol)
            Sub.Right = PaneAPI(rightCol)

            function Sub:Show()
                for _,s in next, Tab.Subtabs do s:Hide() end
                sFrame.Visible=true; Sub._active=true
                TW(sBg,{TextColor3=L.TextHi},0.15)
                -- slide subtab underline
                L:New("UICorner",{CornerRadius=UDim.new(0,1),Parent=SubLine})  -- noop if already exists
                TW(SubLine,{
                    Position=UDim2.fromOffset(sBg.AbsolutePosition.X - subRowBg.AbsolutePosition.X, SubRowH),
                    Size=UDim2.fromOffset(SUB_W,2),
                },0.2)
            end
            function Sub:Hide()
                sFrame.Visible=false; Sub._active=false
                TW(sBg,{TextColor3=L.TextLow},0.15)
            end
            sBg.MouseButton1Click:Connect(function() Sub:Show() end)

            Tab.Subtabs[subName]=Sub
            table.insert(Tab._subtabOrder,Sub)
            if #Tab._subtabOrder==1 then task.defer(function() Sub:Show() end) end
            return Sub
        end

        -- Show/Hide this tab
        function Tab:ShowTab()
            for _,t in next, Window.Tabs do t:HideTab() end
            tabFrame.Visible=true; Tab._active=true
            TW(navBg,{BackgroundTransparency=0.78},0.15)
            TW(navImg,{ImageColor3=L.Accent},0.15)
            TW(tabBtn,{TextColor3=L.TextHi},0.15)
            -- slide main underline
            TW(TabUnderline,{
                Position=UDim2.fromOffset(tabBtn.AbsolutePosition.X - TabRowInner.AbsolutePosition.X, TabRowH),
                Size=UDim2.fromOffset(TAB_BTN_W,2),
            },0.2)
            -- slide nav indicator
            TW(NavIndicator,{
                Position=UDim2.fromOffset(SW-3,
                    navBg.AbsolutePosition.Y - NavList.AbsolutePosition.Y + 64 + 8)
            },0.22)
        end
        function Tab:HideTab()
            tabFrame.Visible=false; Tab._active=false
            TW(navBg,{BackgroundTransparency=1},0.15)
            TW(navImg,{ImageColor3=L.TextLow},0.15)
            TW(tabBtn,{TextColor3=L.TextLow},0.15)
        end

        navBg.MouseButton1Click:Connect(function() Tab:ShowTab() end)
        tabBtn.MouseButton1Click:Connect(function() Tab:ShowTab() end)

        Window.Tabs[name]=Tab
        table.insert(Window._tabOrder,Tab)
        if #Window._tabOrder==1 then task.defer(function() Tab:ShowTab() end) end
        return Tab
    end

    -- close popups on outside click
    L:GS(UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            for _,fn in next,L.Popups do fn() end
        end
    end))

    -- RightShift toggle
    L:GS(UIS.InputBegan:Connect(function(inp,proc)
        if inp.KeyCode==Enum.KeyCode.RightShift and not proc then
            Root.Visible=not Root.Visible
        end
    end))

    function Window:Toggle() Root.Visible=not Root.Visible end

    -- Show loading then reveal
    L:ShowLoading(function() Root.Visible=true end)
    L.Window=Window
    return Window
end

-- ── Unload ────────────────────────────────────────────────────────
function L:Unload()
    for _,fn in next,self._acleanup do pcall(fn) end
    for _,s  in next,self.Signals   do pcall(function()s:Disconnect()end) end
    pcall(function() SG:Destroy() end)
    _genv.Toggles=nil; _genv.Options=nil
end

return L
