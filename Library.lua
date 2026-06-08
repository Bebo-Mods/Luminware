--[[
    LUMINWARE UI Library v3.0
    Exact acrylic panel design — sidebar + subtabs + two-column card grid
    
    API:
        local Window  = Library:CreateWindow({ Title='LUMINWARE', Logo='rbxassetid://...' })
        local Tab     = Window:AddTab({ Name='Aimbot', Icon='rbxassetid://...' })
        -- Each tab returns {Left, Right} panes (two columns)
        local Card    = Tab.Left:AddCard({ Title='Targeting', Width=1 })
        Card:AddToggle('id', { Label='Silent Aim', Default=false, Callback=fn })
        Card:AddSlider('id', { Label='FOV', Min=0, Max=360, Default=90, Suffix='°' })
        Card:AddDropdown('id', { Label='Part', Values={...}, Default='Head' })
        Card:AddButton({ Label='Reset', Callback=fn })
        Card:AddInput('id', { Label='Name', Placeholder='...' })
        Card:AddColorPicker('id', { Label='Color', Default=Color3.new(1,0,0) })
        Card:AddKeybind('id', { Label='Aim Key', Default='LeftAlt' })
]]

local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local HttpService  = game:GetService("HttpService")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

local ProtectGui = (typeof(syn)=="table" and syn.protect_gui)
    or (typeof(protectgui)=="function" and protectgui)
    or function() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "LuminwareV3"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn   = false
pcall(ProtectGui, ScreenGui)
ScreenGui.Parent = (typeof(gethui)=="function" and gethui()) or CoreGui

local _genv = {}
pcall(function() if typeof(getgenv)=="function" then _genv = getgenv() end end)

-- ================================================================
-- LIBRARY OBJECT
-- ================================================================
local L = {
    -- Colors (FROST theme default)
    Accent      = Color3.fromRGB(99, 165, 255);
    Glass       = Color3.fromRGB(28, 32, 44);
    GlassLight  = Color3.fromRGB(38, 43, 58);
    GlassDark   = Color3.fromRGB(18, 20, 30);
    SidebarBg   = Color3.fromRGB(20, 22, 32);
    EdgeColor   = Color3.fromRGB(255,255,255);
    TextPrimary = Color3.fromRGB(240, 242, 255);
    TextSec     = Color3.fromRGB(160, 165, 190);
    TextDim     = Color3.fromRGB(90,  95,  120);

    Font     = Enum.Font.GothamMedium;
    FontBold = Enum.Font.GothamBold;
    FontSemi = Enum.Font.GothamSemibold;

    Registry = {};
    Signals  = {};
    Popups   = {};
    Toggles  = {};
    Options  = {};

    Themes = {
        FROST  = { Accent=Color3.fromRGB(99,165,255),  Glass=Color3.fromRGB(28,32,44),   GlassLight=Color3.fromRGB(38,43,58),  GlassDark=Color3.fromRGB(18,20,30),  SidebarBg=Color3.fromRGB(20,22,32)  };
        VENOM  = { Accent=Color3.fromRGB(168,85,247),  Glass=Color3.fromRGB(30,24,44),   GlassLight=Color3.fromRGB(40,32,58),  GlassDark=Color3.fromRGB(16,12,26),  SidebarBg=Color3.fromRGB(20,14,32)  };
        BLOOD  = { Accent=Color3.fromRGB(220,60,60),   Glass=Color3.fromRGB(36,22,22),   GlassLight=Color3.fromRGB(48,30,30),  GlassDark=Color3.fromRGB(20,10,10),  SidebarBg=Color3.fromRGB(26,12,12)  };
        EMBER  = { Accent=Color3.fromRGB(255,145,0),   Glass=Color3.fromRGB(36,28,18),   GlassLight=Color3.fromRGB(48,38,24),  GlassDark=Color3.fromRGB(20,14,8),   SidebarBg=Color3.fromRGB(26,18,8)   };
        ACID   = { Accent=Color3.fromRGB(140,220,0),   Glass=Color3.fromRGB(22,32,18),   GlassLight=Color3.fromRGB(30,44,24),  GlassDark=Color3.fromRGB(10,18,8),   SidebarBg=Color3.fromRGB(14,22,10)  };
        GHOST  = { Accent=Color3.fromRGB(200,200,220), Glass=Color3.fromRGB(32,34,42),   GlassLight=Color3.fromRGB(44,46,58),  GlassDark=Color3.fromRGB(20,22,28),  SidebarBg=Color3.fromRGB(22,24,32)  };
    };
    _currentTheme = "FROST";
}

_genv.Toggles = L.Toggles
_genv.Options  = L.Options

-- ================================================================
-- UTILS
-- ================================================================
function L:T(inst, props, t, sty, dir)
    TweenService:Create(inst, TweenInfo.new(t or 0.2, sty or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
end

function L:N(class, props)
    local i = type(class)=="string" and Instance.new(class) or class
    for k,v in next, props do if k~="Parent" then pcall(function() i[k]=v end) end end
    if props.Parent then i.Parent = props.Parent end
    return i
end

function L:Corner(i, r) return self:N("UICorner",{CornerRadius=UDim.new(0,r or 8),Parent=i}) end

function L:Stroke(i, col, thick, trans)
    return self:N("UIStroke",{
        Color=col or self.EdgeColor, Thickness=thick or 1,
        Transparency=trans or 0.84, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=i
    })
end

function L:Glass(parent, col, trans, radius, zindex)
    local f = self:N("Frame",{
        BackgroundColor3=col or self.GlassLight,
        BackgroundTransparency=trans or 0.3,
        BorderSizePixel=0, ZIndex=zindex or 2, Parent=parent
    })
    if radius then self:Corner(f, radius) end
    self:Stroke(f)
    return f
end

function L:Reg(inst, prop, key)
    table.insert(self.Registry, {inst=inst, prop=prop, key=key})
end

function L:Signal(s) table.insert(self.Signals, s) end
function L:Call(fn,...) if type(fn)=="function" then pcall(fn,...) end end

function L:SetTheme(name)
    local t = self.Themes[name]; if not t then return end
    self._currentTheme = name
    for k,v in next,t do self[k]=v end
    for _,r in next,self.Registry do
        if r.inst and r.inst.Parent then
            local col = self[r.key]
            if typeof(col)=="Color3" then self:T(r.inst,{[r.prop]=col},0.4) end
        end
    end
    if self._onTheme then self._onTheme() end
    self:Notify({Title="Theme: "..name, Duration=2})
end

function L:GetDarker(c, f)
    local h,s,v = Color3.toHSV(c)
    return Color3.fromHSV(h,s,v*(f or 0.6))
end

-- ================================================================
-- NOTIFICATIONS — bottom-right toasts
-- ================================================================
local NotifArea = L:N("Frame",{
    BackgroundTransparency=1,
    AnchorPoint=Vector2.new(1,1),
    Position=UDim2.new(1,-16,1,-16),
    Size=UDim2.fromOffset(300,500),
    ZIndex=600, Parent=ScreenGui,
})
L:N("UIListLayout",{
    VerticalAlignment=Enum.VerticalAlignment.Bottom,
    HorizontalAlignment=Enum.HorizontalAlignment.Right,
    FillDirection=Enum.FillDirection.Vertical,
    Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder,
    Parent=NotifArea
})

function L:Notify(opts)
    opts = type(opts)=="string" and {Title=opts,Duration=4} or opts
    local dur = opts.Duration or 4
    local card = self:N("Frame",{
        BackgroundColor3=self.GlassDark, BackgroundTransparency=0.05,
        Size=UDim2.new(1,0,0,opts.Body and 66 or 46),
        ZIndex=601, ClipsDescendants=true, Parent=NotifArea
    })
    self:Corner(card,10)
    self:Stroke(card,self.EdgeColor,1,0.8)
    local bar = self:N("Frame",{
        BackgroundColor3=self.Accent, BorderSizePixel=0,
        Size=UDim2.fromOffset(3,46), ZIndex=602, Parent=card
    })
    self:Reg(bar,"BackgroundColor3","Accent")
    self:N("TextLabel",{
        BackgroundTransparency=1, Font=self.FontBold,
        Text=opts.Title or "", TextColor3=self.TextPrimary,
        TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(14,8), Size=UDim2.new(1,-18,0,18),
        ZIndex=602, Parent=card
    })
    if opts.Body then
        self:N("TextLabel",{
            BackgroundTransparency=1, Font=self.Font,
            Text=opts.Body, TextColor3=self.TextSec,
            TextSize=12, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(14,28), Size=UDim2.new(1,-18,0,30),
            ZIndex=602, Parent=card
        })
    end
    local prog = self:N("Frame",{
        BackgroundColor3=self.Accent, BackgroundTransparency=0.5,
        BorderSizePixel=0, AnchorPoint=Vector2.new(0,1),
        Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,2),
        ZIndex=603, Parent=card
    })
    self:Reg(prog,"BackgroundColor3","Accent")
    card.BackgroundTransparency=1
    self:T(card,{BackgroundTransparency=0.05},0.25)
    self:T(prog,{Size=UDim2.fromOffset(0,2)},dur,Enum.EasingStyle.Linear)
    task.delay(dur, function()
        self:T(card,{BackgroundTransparency=1},0.3)
        task.wait(0.35)
        pcall(function() card:Destroy() end)
    end)
end

-- ================================================================
-- DRAGGABLE
-- ================================================================
function L:Drag(handle, target, cutoff)
    local drag,s0,p0 = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if cutoff and (Mouse.Y-handle.AbsolutePosition.Y)>cutoff then return end
        drag=true; s0=Vector2.new(Mouse.X,Mouse.Y); p0=target.Position
    end)
    UserInput.InputChanged:Connect(function(i)
        if not drag or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d=Vector2.new(Mouse.X,Mouse.Y)-s0
        target.Position=UDim2.new(p0.X.Scale,p0.X.Offset+d.X,p0.Y.Scale,p0.Y.Offset+d.Y)
    end)
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ================================================================
-- LOADING SCREEN
-- ================================================================
function L:ShowLoading(onDone)
    local overlay = self:N("Frame",{
        BackgroundColor3=self.GlassDark, BackgroundTransparency=0,
        Size=UDim2.fromScale(1,1), ZIndex=1000, Parent=ScreenGui
    })
    local logo = self:N("Frame",{
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.fromScale(0.5,0.44),
        Size=UDim2.fromOffset(60,60),
        BackgroundColor3=self.Accent,
        Rotation=45, BorderSizePixel=0, ZIndex=1001, Parent=overlay
    })
    self:Corner(logo,10)
    self:Reg(logo,"BackgroundColor3","Accent")

    local title = self:N("TextLabel",{
        BackgroundTransparency=1, Font=self.FontBold,
        Text="LUMINWARE", TextColor3=self.TextPrimary,
        TextSize=26, AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.new(0.5,0,0.54,0), Size=UDim2.new(1,0,0,32),
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=1001, Parent=overlay
    })
    local sub = self:N("TextLabel",{
        BackgroundTransparency=1, Font=self.Font,
        Text="INITIALIZING...", TextColor3=self.TextDim,
        TextSize=11, AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.new(0.5,0,0.6,0), Size=UDim2.new(1,0,0,20),
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=1001, Parent=overlay
    })

    -- progress bar
    local barBg = self:N("Frame",{
        AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.new(0.5,0,0.66,0),
        Size=UDim2.fromOffset(200,3),
        BackgroundColor3=self.GlassLight, BorderSizePixel=0, ZIndex=1001, Parent=overlay
    })
    self:Corner(barBg,2)
    local barFill = self:N("Frame",{
        BackgroundColor3=self.Accent, BorderSizePixel=0,
        Size=UDim2.new(0,0,1,0), ZIndex=1002, Parent=barBg
    })
    self:Corner(barFill,2)
    self:Reg(barFill,"BackgroundColor3","Accent")

    -- Animate logo pulse + bar fill
    logo.Size = UDim2.fromOffset(0,0)
    self:T(logo,{Size=UDim2.fromOffset(60,60)},0.4,Enum.EasingStyle.Back)
    task.wait(0.3)
    local msgs = {"LOADING MODULES...","APPLYING PATCHES...","READY"}
    for i,m in ipairs(msgs) do
        sub.Text = m
        self:T(barFill,{Size=UDim2.new(i/#msgs,0,1,0)},0.35,Enum.EasingStyle.Quint)
        task.wait(0.4)
    end
    task.wait(0.1)
    self:T(overlay,{BackgroundTransparency=1},0.4)
    task.wait(0.45)
    overlay:Destroy()
    if onDone then onDone() end
end

-- ================================================================
-- MINIMIZE ICON (draggable, shows when minimized)
-- ================================================================
function L:_MakeMinIcon(root, logoId)
    local icon = self:N("Frame",{
        BackgroundColor3=self.GlassDark, BackgroundTransparency=0.1,
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(56,56),
        Visible=false, ZIndex=500, Parent=ScreenGui
    })
    self:Corner(icon,14)
    self:Stroke(icon,self.EdgeColor,1,0.75)
    self:Drag(icon,icon)

    if logoId and logoId~="" then
        self:N("ImageLabel",{
            BackgroundTransparency=1, Image=logoId,
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(38,38), ScaleType=Enum.ScaleType.Fit,
            ZIndex=501, Parent=icon
        })
    else
        local d = self:N("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(24,24),
            BackgroundColor3=self.Accent,
            Rotation=45, BorderSizePixel=0, ZIndex=501, Parent=icon
        })
        self:Corner(d,5)
        self:Reg(d,"BackgroundColor3","Accent")
    end

    -- Click to restore
    local btn = self:N("TextButton",{
        BackgroundTransparency=1, Text="", Size=UDim2.fromScale(1,1),
        ZIndex=502, Parent=icon
    })
    btn.MouseButton1Click:Connect(function()
        icon.Visible = false
        root.Visible = true
    end)
    return icon
end

-- ================================================================
-- CREATE WINDOW
-- ================================================================
function L:CreateWindow(cfg)
    cfg = cfg or {}
    local W_SIZE = cfg.Size or Vector2.new(880,540)
    local logoId = cfg.Logo or ""

    local Window = { Tabs={}, _tabOrder={}, _activeTab=nil }

    -- Root (invisible, just for positioning)
    local Root = self:N("Frame",{
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(W_SIZE.X,W_SIZE.Y),
        ZIndex=2, Visible=false, Parent=ScreenGui
    })

    local MinIcon = self:_MakeMinIcon(Root, logoId)

    -- ── MAIN PANEL ──────────────────────────────────────────
    local Main = self:N("Frame",{
        BackgroundColor3=self.Glass,
        BackgroundTransparency=0.08,
        BorderSizePixel=0,
        Size=UDim2.fromScale(1,1),
        ZIndex=2, Parent=Root
    })
    self:Corner(Main,16)
    self:Stroke(Main,self.EdgeColor,1,0.78)
    self:Reg(Main,"BackgroundColor3","Glass")

    -- top edge highlight
    self:N("Frame",{
        BackgroundColor3=self.EdgeColor, BackgroundTransparency=0.88,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,1), ZIndex=3, Parent=Main
    })

    -- ── SIDEBAR ─────────────────────────────────────────────
    local SIDEBAR_W = 62
    local Sidebar = self:N("Frame",{
        BackgroundColor3=self.SidebarBg,
        BackgroundTransparency=0.05,
        BorderSizePixel=0,
        Size=UDim2.fromOffset(SIDEBAR_W, W_SIZE.Y),
        ZIndex=3, Parent=Main
    })
    -- square-off right edge (only left corners round)
    self:N("Frame",{
        BackgroundColor3=self.SidebarBg, BackgroundTransparency=0.05,
        BorderSizePixel=0, Position=UDim2.fromOffset(SIDEBAR_W/2,0),
        Size=UDim2.fromOffset(SIDEBAR_W/2,W_SIZE.Y), ZIndex=3, Parent=Sidebar
    })
    self:N("UICorner",{CornerRadius=UDim.new(0,16),Parent=Sidebar})
    self:Reg(Sidebar,"BackgroundColor3","SidebarBg")

    -- right separator line on sidebar
    self:N("Frame",{
        BackgroundColor3=self.EdgeColor, BackgroundTransparency=0.86,
        BorderSizePixel=0, AnchorPoint=Vector2.new(1,0),
        Position=UDim2.fromOffset(SIDEBAR_W,0),
        Size=UDim2.fromOffset(1,W_SIZE.Y), ZIndex=4, Parent=Main
    })

    -- Logo area
    local logoArea = self:N("Frame",{
        BackgroundTransparency=1,
        Size=UDim2.fromOffset(SIDEBAR_W,64),
        ZIndex=4, Parent=Sidebar
    })
    if logoId~="" then
        self:N("ImageLabel",{
            BackgroundTransparency=1, Image=logoId,
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(34,34), ScaleType=Enum.ScaleType.Fit,
            ZIndex=5, Parent=logoArea
        })
    else
        local d = self:N("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(20,20),
            BackgroundColor3=self.Accent, Rotation=45,
            BorderSizePixel=0, ZIndex=5, Parent=logoArea
        })
        self:Corner(d,4)
        self:Reg(d,"BackgroundColor3","Accent")
    end

    -- Nav list
    local NavList = self:N("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,68),
        Size=UDim2.new(1,0,1,-120),
        ZIndex=4, Parent=Sidebar
    })
    self:N("UIListLayout",{
        FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=NavList
    })

    -- Active indicator bar
    local NavBar = self:N("Frame",{
        BackgroundColor3=self.Accent, BorderSizePixel=0,
        Position=UDim2.fromOffset(SIDEBAR_W-3,90),
        Size=UDim2.fromOffset(3,32), ZIndex=6, Parent=Main
    })
    self:Corner(NavBar,2)
    self:Reg(NavBar,"BackgroundColor3","Accent")

    -- Power + Hide buttons at bottom of sidebar
    local BtnArea = self:N("Frame",{
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,1),
        Position=UDim2.new(0.5,0,1,-10),
        Size=UDim2.fromOffset(SIDEBAR_W,88),
        ZIndex=4, Parent=Sidebar
    })
    self:N("UIListLayout",{
        FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=BtnArea
    })

    local function SideBtn(icon, col, onClick)
        local btn = self:N("TextButton",{
            BackgroundColor3=col or self.GlassLight,
            BackgroundTransparency=0.6,
            Size=UDim2.fromOffset(40,40), Text="", ZIndex=5, Parent=BtnArea
        })
        self:Corner(btn,10)
        local img = self:N("ImageLabel",{
            BackgroundTransparency=1,
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(18,18),
            Image=icon, ImageColor3=self.TextDim,
            ZIndex=6, Parent=btn
        })
        btn.MouseEnter:Connect(function()
            self:T(btn,{BackgroundTransparency=0.3},0.15)
            self:T(img,{ImageColor3=self.TextPrimary},0.15)
        end)
        btn.MouseLeave:Connect(function()
            self:T(btn,{BackgroundTransparency=0.6},0.15)
            self:T(img,{ImageColor3=self.TextDim},0.15)
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- Minimize button (dash icon)
    SideBtn("rbxassetid://7072717857", nil, function()
        Root.Visible = false
        MinIcon.Visible = true
        -- animate minimize
        self:T(Root,{Size=UDim2.fromOffset(56,56)},0.25,Enum.EasingStyle.Back,Enum.EasingDirection.In)
        task.wait(0.25)
        Root.Visible = false
        Root.Size = UDim2.fromOffset(W_SIZE.X,W_SIZE.Y)
        MinIcon.Visible = true
    end)

    -- Hide / toggle button (eye icon)
    SideBtn("rbxassetid://7506902703", nil, function()
        Root.Visible = false
    end)

    -- Power / unload
    SideBtn("rbxassetid://7059364814", Color3.fromRGB(50,20,20), function()
        self:Notify({Title="Unloading LUMINWARE...", Duration=1})
        task.delay(0.9, function() self:Unload() end)
    end)

    -- ── CONTENT AREA ────────────────────────────────────────
    local ContentArea = self:N("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(SIDEBAR_W,0),
        Size=UDim2.new(1,-SIDEBAR_W,1,0),
        ZIndex=3, Parent=Main
    })

    -- Top bar: title + hide/minimize buttons
    local TopBar = self:N("Frame",{
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,52),
        ZIndex=4, Parent=ContentArea
    })
    self:Drag(TopBar, Root, 52)

    self:N("TextLabel",{
        BackgroundTransparency=1, Font=self.FontBold,
        Text=string.upper(cfg.Title or "LUMINWARE"),
        TextColor3=self.TextPrimary, TextSize=16,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(16,0),
        Size=UDim2.new(0.5,0,1,0),
        ZIndex=5, Parent=TopBar
    })

    -- Top-right: just minimize and close (not theme dots)
    local TRBtns = self:N("Frame",{
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0),
        Size=UDim2.fromOffset(56,24),
        ZIndex=5, Parent=TopBar
    })
    self:N("UIListLayout",{
        FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Right,
        VerticalAlignment=Enum.VerticalAlignment.Center,
        Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=TRBtns
    })

    -- Minimize dot
    local minDot = self:N("TextButton",{
        BackgroundColor3=Color3.fromRGB(255,189,46),
        Size=UDim2.fromOffset(14,14), Text="", ZIndex=6, Parent=TRBtns
    })
    self:Corner(minDot,7)
    minDot.MouseButton1Click:Connect(function()
        Root.Visible = false; MinIcon.Visible = true
    end)
    -- Close dot
    local clsDot = self:N("TextButton",{
        BackgroundColor3=Color3.fromRGB(255,95,86),
        Size=UDim2.fromOffset(14,14), Text="", ZIndex=6, Parent=TRBtns
    })
    self:Corner(clsDot,7)
    clsDot.MouseButton1Click:Connect(function()
        self:Notify({Title="Closing...",Duration=0.8})
        task.delay(0.7,function() self:Unload() end)
    end)

    -- Divider under topbar
    self:N("Frame",{
        BackgroundColor3=self.EdgeColor, BackgroundTransparency=0.86,
        BorderSizePixel=0, Position=UDim2.fromOffset(0,51),
        Size=UDim2.new(1,0,0,1), ZIndex=4, Parent=ContentArea
    })

    -- Tab switcher row (horizontal text tabs like the concept)
    local TabRow = self:N("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(16,56),
        Size=UDim2.new(1,-32,0,32),
        ZIndex=4, Parent=ContentArea
    })
    self:N("UIListLayout",{
        FillDirection=Enum.FillDirection.Horizontal,
        VerticalAlignment=Enum.VerticalAlignment.Center,
        Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=TabRow
    })

    -- Active underline for tab row
    local TabUnderline = self:N("Frame",{
        BackgroundColor3=self.Accent, BorderSizePixel=0,
        AnchorPoint=Vector2.new(0,1),
        Position=UDim2.fromOffset(0,32),
        Size=UDim2.fromOffset(0,2), ZIndex=6, Parent=TabRow
    })
    self:Corner(TabUnderline,1)
    self:Reg(TabUnderline,"BackgroundColor3","Accent")

    -- Divider under tab row
    self:N("Frame",{
        BackgroundColor3=self.EdgeColor, BackgroundTransparency=0.88,
        BorderSizePixel=0, Position=UDim2.fromOffset(0,88),
        Size=UDim2.new(1,0,0,1), ZIndex=4, Parent=ContentArea
    })

    -- Tab content host
    local TabHost = self:N("Frame",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,92),
        Size=UDim2.new(1,0,1,-92),
        ZIndex=3, Parent=ContentArea
    })

    -- ── ADD TAB ─────────────────────────────────────────────
    function Window:AddTab(opts)
        opts = type(opts)=="string" and {Name=opts} or opts
        local name   = opts.Name or "Tab"
        local iconId = opts.Icon or ""

        local Tab = { _name=name, Left=nil, Right=nil }

        -- Nav icon button in sidebar
        local iconMap = {
            Aimbot="rbxassetid://7506870928", ESP="rbxassetid://7506869530",
            Movement="rbxassetid://7507030703", Misc="rbxassetid://7506870548",
            Settings="rbxassetid://7507016059",
        }
        local navBtn = L:N("TextButton",{
            BackgroundColor3=L.GlassLight, BackgroundTransparency=1,
            Size=UDim2.fromOffset(48,48), Text="", ZIndex=5, Parent=NavList
        })
        L:Corner(navBtn,10)
        local navIco = L:N("ImageLabel",{
            BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(20,20),
            Image=iconId~="" and iconId or (iconMap[name] or "rbxassetid://7505493267"),
            ImageColor3=L.TextDim, ZIndex=6, Parent=navBtn
        })
        -- Tooltip
        local tip = L:N("TextLabel",{
            BackgroundColor3=L.GlassDark, BackgroundTransparency=0.05,
            Font=L.FontSemi, Text=name, TextColor3=L.TextPrimary,
            TextSize=12, AnchorPoint=Vector2.new(0,0.5),
            Position=UDim2.new(1,6,0.5,0), Size=UDim2.fromOffset(76,24),
            Visible=false, ZIndex=60, Parent=navBtn
        })
        L:Corner(tip,6); L:Stroke(tip)
        navBtn.MouseEnter:Connect(function() tip.Visible=true end)
        navBtn.MouseLeave:Connect(function() tip.Visible=false end)

        -- Horizontal text tab button
        local tabBtnW = 80
        local tabBtn = L:N("TextButton",{
            BackgroundTransparency=1,
            Font=L.FontSemi, Text=name,
            TextColor3=L.TextDim, TextSize=13,
            Size=UDim2.fromOffset(tabBtnW,32),
            ZIndex=5, Parent=TabRow
        })

        -- Tab frame (two-column grid)
        local tabFrame = L:N("Frame",{
            BackgroundTransparency=1,
            Size=UDim2.fromScale(1,1),
            Visible=false, ZIndex=3, Parent=TabHost
        })

        -- Two scrollable columns
        local function MakeCol(xPos, xSz)
            local col = L:N("ScrollingFrame",{
                BackgroundTransparency=1, BorderSizePixel=0,
                Position=UDim2.new(xPos,xPos==0 and 12 or 6,0,10),
                Size=UDim2.new(xSz,-18,1,-20),
                CanvasSize=UDim2.fromOffset(0,0),
                ScrollBarThickness=3,
                ScrollBarImageColor3=L.Accent,
                ScrollBarImageTransparency=0.5,
                TopImage="", BottomImage="",
                ZIndex=3, Parent=tabFrame
            })
            L:Reg(col,"ScrollBarImageColor3","Accent")
            L:N("UIListLayout",{
                FillDirection=Enum.FillDirection.Vertical,
                SortOrder=Enum.SortOrder.LayoutOrder,
                Padding=UDim.new(0,10), Parent=col
            })
            col:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                col.CanvasSize=UDim2.fromOffset(0,col:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y+10)
            end)
            return col
        end

        local leftCol  = MakeCol(0,   0.5)
        local rightCol = MakeCol(0.5, 0.5)

        -- Pane wrappers (expose AddCard)
        local function MakePaneAPI(col)
            local Pane = {}
            function Pane:AddCard(cardOpts)
                return Window:_AddCard(col, cardOpts)
            end
            return Pane
        end
        Tab.Left  = MakePaneAPI(leftCol)
        Tab.Right = MakePaneAPI(rightCol)

        function Tab:ShowTab()
            for _,t in next,Window.Tabs do t:HideTab() end
            tabFrame.Visible = true
            Tab._active = true
            L:T(navBtn,{BackgroundTransparency=0.82},0.2)
            L:T(navIco,{ImageColor3=L.Accent},0.2)
            L:T(tabBtn,{TextColor3=L.TextPrimary},0.2)
            -- Slide underline to this tab
            L:T(TabUnderline,{
                Position=UDim2.fromOffset(tabBtn.AbsolutePosition.X-TabRow.AbsolutePosition.X,32),
                Size=UDim2.fromOffset(tabBtnW,2),
            },0.22)
            -- Slide nav indicator
            L:T(NavBar,{
                Position=UDim2.fromOffset(SIDEBAR_W-3, navBtn.AbsolutePosition.Y-NavList.AbsolutePosition.Y+68+10)
            },0.25)
        end
        function Tab:HideTab()
            tabFrame.Visible=false; Tab._active=false
            L:T(navBtn,{BackgroundTransparency=1},0.2)
            L:T(navIco,{ImageColor3=L.TextDim},0.2)
            L:T(tabBtn,{TextColor3=L.TextDim},0.2)
        end

        navBtn.MouseButton1Click:Connect(function() Tab:ShowTab() end)
        tabBtn.MouseButton1Click:Connect(function() Tab:ShowTab() end)

        Window.Tabs[name] = Tab
        table.insert(Window._tabOrder, Tab)
        if #Window._tabOrder==1 then task.defer(function() Tab:ShowTab() end) end
        return Tab
    end

    -- ── ADD CARD ────────────────────────────────────────────
    function Window:_AddCard(parentCol, opts)
        opts = opts or {}
        local Card = {}

        local card = L:N("Frame",{
            BackgroundColor3=L.GlassLight,
            BackgroundTransparency=0.28,
            BorderSizePixel=0,
            Size=UDim2.new(1,0,0,0),
            AutomaticSize=Enum.AutomaticSize.Y,
            ZIndex=4, Parent=parentCol
        })
        L:Corner(card,12)
        L:Stroke(card,L.EdgeColor,1,0.84)
        L:Reg(card,"BackgroundColor3","GlassLight")

        -- Card header
        local header = L:N("Frame",{
            BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,38),
            ZIndex=5, Parent=card
        })
        L:N("TextLabel",{
            BackgroundTransparency=1, Font=L.FontSemi,
            Text=string.upper(opts.Title or ""),
            TextColor3=L.TextDim, TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(14,0),
            Size=UDim2.new(1,-28,1,0),
            ZIndex=6, Parent=header
        })
        -- Bottom separator
        L:N("Frame",{
            BackgroundColor3=L.EdgeColor, BackgroundTransparency=0.88,
            BorderSizePixel=0, AnchorPoint=Vector2.new(0,1),
            Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,1),
            ZIndex=6, Parent=header
        })

        -- Items container
        local items = L:N("Frame",{
            BackgroundTransparency=1,
            Position=UDim2.fromOffset(0,38),
            Size=UDim2.new(1,0,0,0),
            AutomaticSize=Enum.AutomaticSize.Y,
            ZIndex=5, Parent=card
        })
        L:N("UIListLayout",{
            FillDirection=Enum.FillDirection.Vertical,
            SortOrder=Enum.SortOrder.LayoutOrder,
            Parent=items
        })
        L:N("UIPadding",{
            PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
            PaddingBottom=UDim.new(0,10),
            Parent=items
        })

        -- ── ROW ───────────────────────────────────────────
        local function Row(h)
            local r = L:N("Frame",{
                BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,h or 40),
                ZIndex=6, Parent=items
            })
            return r
        end

        local function RowLabel(parent, txt)
            return L:N("TextLabel",{
                BackgroundTransparency=1, Font=L.Font,
                Text=txt or "", TextColor3=L.TextPrimary,
                TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(0.55,0,1,0), ZIndex=7, Parent=parent
            })
        end

        -- ── TOGGLE ────────────────────────────────────────
        function Card:AddToggle(idx, info)
            info = info or {}
            local row = Row(40)
            RowLabel(row, info.Label or info.Text or idx)

            local track = L:N("Frame",{
                AnchorPoint=Vector2.new(1,0.5),
                Position=UDim2.new(1,0,0.5,0),
                Size=UDim2.fromOffset(44,24),
                BackgroundColor3=L.GlassLight,
                ZIndex=7, Parent=row
            })
            L:Corner(track,12)
            L:Reg(track,"BackgroundColor3","GlassLight")

            local knob = L:N("Frame",{
                AnchorPoint=Vector2.new(0,0.5),
                Position=UDim2.new(0,3,0.5,0),
                Size=UDim2.fromOffset(18,18),
                BackgroundColor3=L.TextDim,
                ZIndex=8, Parent=track
            })
            L:Corner(knob,9)

            local Toggle = {
                Value=not not info.Default, Type="Toggle",
                Callback=info.Callback or function() end, Addons={}
            }

            function Toggle:Render(anim)
                local on=self.Value
                local tC = on and L.Accent or L.GlassLight
                local kC = on and Color3.new(1,1,1) or L.TextDim
                local kP = on and UDim2.new(1,-21,0.5,0) or UDim2.new(0,3,0.5,0)
                if anim then
                    L:T(track,{BackgroundColor3=tC},0.2)
                    L:T(knob,{BackgroundColor3=kC,Position=kP},0.2)
                else
                    track.BackgroundColor3=tC; knob.BackgroundColor3=kC; knob.Position=kP
                end
                local r=L.Registry
                for _,e in next,r do
                    if e.inst==track then e.key=on and "Accent" or "GlassLight" end
                end
            end

            function Toggle:SetValue(v)
                self.Value=not not v; self:Render(true)
                L:Call(self.Callback,self.Value); L:Call(self.Changed,self.Value)
            end
            function Toggle:OnChanged(fn) self.Changed=fn; fn(self.Value) end

            local hit = L:N("TextButton",{
                BackgroundTransparency=1, Text="",
                Size=UDim2.fromScale(1,1), ZIndex=9, Parent=row
            })
            hit.MouseButton1Click:Connect(function() Toggle:SetValue(not Toggle.Value) end)
            hit.MouseEnter:Connect(function()
                if not Toggle.Value then L:T(track,{BackgroundTransparency=0.5},0.15) end
            end)
            hit.MouseLeave:Connect(function()
                if not Toggle.Value then L:T(track,{BackgroundTransparency=0},0.15) end
            end)
            Toggle:Render(false)
            L.Toggles[idx]=Toggle
            return Toggle
        end

        -- ── SLIDER ────────────────────────────────────────
        function Card:AddSlider(idx, info)
            info = info or {}
            local min=info.Min or 0; local max=info.Max or 100
            local def=info.Default or min; local suf=info.Suffix or ""

            local wrap = L:N("Frame",{
                BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,54), ZIndex=6, Parent=items
            })
            -- top row
            L:N("TextLabel",{
                BackgroundTransparency=1, Font=L.Font,
                Text=info.Label or info.Text or idx, TextColor3=L.TextPrimary,
                TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(0.65,0,0,22), ZIndex=7, Parent=wrap
            })
            local valLbl = L:N("TextLabel",{
                BackgroundTransparency=1, Font=L.FontSemi,
                Text=tostring(def)..suf, TextColor3=L.Accent,
                TextSize=13, TextXAlignment=Enum.TextXAlignment.Right,
                AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0),
                Size=UDim2.new(0.35,0,0,22), ZIndex=7, Parent=wrap
            })
            L:Reg(valLbl,"TextColor3","Accent")

            local track = L:N("Frame",{
                BorderSizePixel=0, Position=UDim2.fromOffset(0,28),
                BackgroundColor3=L.GlassDark,
                Size=UDim2.new(1,0,0,5), ZIndex=7, Parent=wrap
            })
            L:Corner(track,3)
            L:Reg(track,"BackgroundColor3","GlassDark")

            local fill = L:N("Frame",{
                BackgroundColor3=L.Accent, BorderSizePixel=0,
                Size=UDim2.new(0,0,1,0), ZIndex=8, Parent=track
            })
            L:Corner(fill,3)
            L:Reg(fill,"BackgroundColor3","Accent")

            local knob = L:N("Frame",{
                AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(0,0,0.5,0),
                Size=UDim2.fromOffset(16,16),
                BackgroundColor3=L.Accent, ZIndex=9, Parent=track
            })
            L:Corner(knob,8)
            L:Reg(knob,"BackgroundColor3","Accent")
            L:N("UIStroke",{Color=Color3.new(1,1,1),Thickness=2,Transparency=0.72,
                ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=knob})

            local Slider={Value=def,Min=min,Max=max,Rounding=info.Rounding or 0,
                Type="Slider",Callback=info.Callback or function()end}

            local function rnd(v)
                if Slider.Rounding==0 then return math.floor(v+0.5) end
                return tonumber(string.format("%."..Slider.Rounding.."f",v))
            end

            function Slider:Render()
                local p=math.clamp((self.Value-min)/(max-min),0,1)
                fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,0)
                valLbl.Text=tostring(self.Value)..suf
            end

            function Slider:SetValue(v)
                local n=tonumber(v); if not n then return end
                self.Value=rnd(math.clamp(n,min,max)); self:Render()
                L:Call(self.Callback,self.Value); L:Call(self.Changed,self.Value)
            end
            function Slider:OnChanged(fn) self.Changed=fn; fn(self.Value) end

            track.InputBegan:Connect(function(inp)
                if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                local conn; conn=RunService.Heartbeat:Connect(function()
                    if not UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        conn:Disconnect(); return
                    end
                    local p=math.clamp((Mouse.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                    Slider:SetValue(min+p*(max-min))
                end)
            end)

            Slider:Render()
            L.Options[idx]=Slider
            return Slider
        end

        -- ── BUTTON ────────────────────────────────────────
        function Card:AddButton(info)
            info = type(info)=="string" and {Label=info} or info
            local row = Row(40)
            local lbl = RowLabel(row, info.Label or info.Text or "Button")

            local btn = L:N("TextButton",{
                AnchorPoint=Vector2.new(1,0.5),
                Position=UDim2.new(1,0,0.5,0),
                BackgroundColor3=L.GlassLight,
                BackgroundTransparency=0.35,
                Font=L.FontSemi,
                Text=info.Action or "Execute",
                TextColor3=L.TextPrimary, TextSize=12,
                Size=UDim2.fromOffset(86,28), ZIndex=7, Parent=row
            })
            L:Corner(btn,7)
            L:Stroke(btn)

            btn.MouseButton1Click:Connect(function()
                L:T(btn,{BackgroundColor3=L.Accent},0.08)
                task.delay(0.12,function()
                    L:T(btn,{BackgroundColor3=L.GlassLight},0.25)
                end)
                L:Call(info.Callback or info.Func)
            end)
            btn.MouseEnter:Connect(function() L:T(btn,{BackgroundTransparency=0.1},0.15) end)
            btn.MouseLeave:Connect(function() L:T(btn,{BackgroundTransparency=0.35},0.15) end)
            return btn
        end

        -- ── DROPDOWN ──────────────────────────────────────
        function Card:AddDropdown(idx, info)
            info = info or {}
            local wrap = L:N("Frame",{
                BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,62), ZIndex=6, Parent=items
            })
            L:N("TextLabel",{
                BackgroundTransparency=1, Font=L.Font,
                Text=info.Label or info.Text or idx, TextColor3=L.TextPrimary,
                TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(1,0,0,22), ZIndex=7, Parent=wrap
            })

            local dropBtn = L:N("TextButton",{
                BackgroundColor3=L.GlassDark,
                BackgroundTransparency=0.15,
                Font=L.Font,
                Text="",
                TextColor3=L.TextPrimary, TextSize=13,
                Position=UDim2.fromOffset(0,24),
                Size=UDim2.new(1,0,0,32),
                ZIndex=7, Parent=wrap
            })
            L:Corner(dropBtn,8)
            L:Stroke(dropBtn,L.EdgeColor,1,0.8)

            local selLbl = L:N("TextLabel",{
                BackgroundTransparency=1, Font=L.FontSemi,
                Text=tostring(info.Default or "--"),
                TextColor3=L.TextPrimary, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left,
                Position=UDim2.fromOffset(12,0),
                Size=UDim2.new(1,-36,1,0),
                ZIndex=8, Parent=dropBtn
            })

            local arrow = L:N("TextLabel",{
                BackgroundTransparency=1, Font=L.FontBold,
                Text="▾", TextColor3=L.TextDim, TextSize=15,
                AnchorPoint=Vector2.new(1,0.5),
                Position=UDim2.new(1,-10,0.5,0),
                Size=UDim2.fromOffset(18,18),
                ZIndex=8, Parent=dropBtn
            })

            local DD={Value=info.Default, Values=info.Values or {}, Type="Dropdown",
                Callback=info.Callback or function()end}

            -- Popup list (parented to ScreenGui to float above everything)
            local popup = L:N("Frame",{
                BackgroundColor3=L.GlassDark, BackgroundTransparency=0.05,
                BorderSizePixel=0, ZIndex=100, Visible=false, Parent=ScreenGui
            })
            L:Corner(popup,8)
            L:Stroke(popup,L.EdgeColor,1,0.72)
            L:Reg(popup,"BackgroundColor3","GlassDark")
            L:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
                SortOrder=Enum.SortOrder.LayoutOrder,Parent=popup})
            L:N("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=popup})

            local function closePopup()
                if not popup.Visible then return end
                popup.Visible=false; L:T(arrow,{Rotation=0},0.15)
            end

            local function buildList()
                for _,c in next,popup:GetChildren() do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _,val in next,DD.Values do
                    local isSelected = (DD.Value == val)
                    local item = L:N("TextButton",{
                        BackgroundColor3= isSelected and L.Accent or L.GlassLight,
                        BackgroundTransparency= isSelected and 0.65 or 0.9,
                        Font=L.FontSemi, Text="",
                        TextColor3= isSelected and L.Accent or L.TextSec,
                        TextSize=13,
                        Size=UDim2.new(1,0,0,32),
                        ZIndex=101, Parent=popup
                    })
                    L:N("TextLabel",{
                        BackgroundTransparency=1, Font=L.FontSemi,
                        Text=tostring(val),
                        TextColor3= isSelected and L.TextPrimary or L.TextSec,
                        TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
                        Position=UDim2.fromOffset(12,0),
                        Size=UDim2.new(1,-12,1,0), ZIndex=102, Parent=item
                    })
                    local v=val
                    item.MouseButton1Click:Connect(function()
                        DD.Value=v; selLbl.Text=tostring(v)
                        closePopup(); buildList()
                        L:Call(DD.Callback,v); L:Call(DD.Changed,v)
                    end)
                    item.MouseEnter:Connect(function()
                        if v~=DD.Value then L:T(item,{BackgroundTransparency=0.7},0.1) end
                    end)
                    item.MouseLeave:Connect(function()
                        if v~=DD.Value then L:T(item,{BackgroundTransparency=0.9},0.1) end
                    end)
                end
                local count=math.min(#DD.Values,7)
                local h=count*32+8
                popup.Size=UDim2.fromOffset(dropBtn.AbsoluteSize.X, h)
                popup.Position=UDim2.fromOffset(
                    dropBtn.AbsolutePosition.X,
                    dropBtn.AbsolutePosition.Y+34
                )
            end

            dropBtn.MouseButton1Click:Connect(function()
                if popup.Visible then closePopup()
                else
                    for _,fn in next,L.Popups do fn() end
                    buildList(); popup.Visible=true
                    L:T(arrow,{Rotation=180},0.15)
                end
            end)
            table.insert(L.Popups, closePopup)

            function DD:SetValue(v)
                self.Value=v; selLbl.Text=tostring(v); buildList()
                L:Call(self.Callback,v); L:Call(self.Changed,v)
            end
            function DD:SetValues(vals) self.Values=vals; buildList() end
            function DD:OnChanged(fn) self.Changed=fn; fn(self.Value) end

            L.Options[idx]=DD
            return DD
        end

        -- ── INPUT ─────────────────────────────────────────
        function Card:AddInput(idx, info)
            info=info or {}
            local wrap=L:N("Frame",{BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,62),ZIndex=6,Parent=items})
            L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,
                Text=info.Label or info.Text or idx,TextColor3=L.TextPrimary,
                TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(1,0,0,22),ZIndex=7,Parent=wrap})
            local box=L:N("TextBox",{
                BackgroundColor3=L.GlassDark,BackgroundTransparency=0.15,
                Font=L.Font,Text=info.Default or "",
                PlaceholderText=info.Placeholder or "",
                PlaceholderColor3=L.TextDim,
                TextColor3=L.TextPrimary,TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left,
                ClearTextOnFocus=false,
                Position=UDim2.fromOffset(0,24),Size=UDim2.new(1,0,0,32),
                ZIndex=7,Parent=wrap})
            L:Corner(box,8); L:Stroke(box,L.EdgeColor,1,0.8)
            L:N("UIPadding",{PaddingLeft=UDim.new(0,10),Parent=box})
            local Input={Value=info.Default or "",Type="Input",Callback=info.Callback or function()end}
            box:GetPropertyChangedSignal("Text"):Connect(function()
                Input.Value=box.Text
                if not info.Finished then L:Call(Input.Callback,Input.Value) end
            end)
            box.FocusLost:Connect(function(enter)
                if info.Finished and enter then L:Call(Input.Callback,Input.Value) end
                L:Call(Input.Changed,Input.Value)
            end)
            function Input:SetValue(v) box.Text=tostring(v);self.Value=tostring(v) end
            function Input:OnChanged(fn) self.Changed=fn;fn(self.Value) end
            L.Options[idx]=Input; return Input
        end

        -- ── KEYBIND ───────────────────────────────────────
        function Card:AddKeybind(idx, info)
            info=info or {}
            local row=Row(40)
            RowLabel(row, info.Label or info.Text or idx)
            local kbBtn=L:N("TextButton",{
                AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
                BackgroundColor3=L.GlassDark,BackgroundTransparency=0.15,
                Font=L.FontSemi,Text=info.Default or "None",
                TextColor3=L.Accent,TextSize=12,
                Size=UDim2.fromOffset(76,28),ZIndex=7,Parent=row})
            L:Corner(kbBtn,7); L:Stroke(kbBtn)
            L:Reg(kbBtn,"TextColor3","Accent")
            local KP={Value=info.Default or "None",Mode=info.Mode or "Toggle",
                Toggled=false,Type="KeyPicker",Callback=info.Callback or function()end}
            local picking=false
            kbBtn.MouseButton1Click:Connect(function()
                if picking then return end; picking=true; kbBtn.Text="..."
                local c; c=UserInput.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Keyboard then
                        KP.Value=inp.KeyCode.Name; kbBtn.Text=inp.KeyCode.Name
                        picking=false; c:Disconnect()
                        L:Call(KP.ChangedCallback,inp.KeyCode)
                    elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then
                        picking=false; c:Disconnect(); kbBtn.Text=KP.Value
                    end
                end)
            end)
            UserInput.InputBegan:Connect(function(inp)
                if picking then return end
                if inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode.Name==KP.Value then
                    if KP.Mode=="Toggle" then KP.Toggled=not KP.Toggled; L:Call(KP.Callback,KP.Toggled) end
                end
            end)
            function KP:GetState() return self.Toggled end
            function KP:SetValue(d) self.Value=d[1];self.Mode=d[2];kbBtn.Text=d[1] end
            function KP:OnChanged(fn) self.Changed=fn end
            L.Options[idx]=KP; return KP
        end

        -- ── COLOR PICKER ──────────────────────────────────
        function Card:AddColorPicker(idx, info)
            info=info or {}
            local row=Row(40)
            RowLabel(row, info.Label or info.Title or idx)
            local swatch=L:N("TextButton",{
                AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
                BackgroundColor3=info.Default or L.Accent,
                Size=UDim2.fromOffset(40,22),Text="",ZIndex=7,Parent=row})
            L:Corner(swatch,5); L:Stroke(swatch)
            local CP={Value=info.Default or L.Accent,Transparency=info.Transparency or 0,
                Type="ColorPicker",Callback=info.Callback or function()end}
            function CP:SetHSVFromRGB(c) self.Hue,self.Sat,self.Vib=Color3.toHSV(c) end
            CP:SetHSVFromRGB(CP.Value)

            local popup=L:N("Frame",{BackgroundColor3=L.GlassDark,BackgroundTransparency=0.05,
                Size=UDim2.fromOffset(224,248),Visible=false,ZIndex=110,Parent=ScreenGui})
            L:Corner(popup,10); L:Stroke(popup,L.EdgeColor,1,0.75)
            L:Reg(popup,"BackgroundColor3","GlassDark")
            L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
                Text=info.Title or "Color",TextColor3=L.TextPrimary,TextSize=13,
                Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,20),ZIndex=111,Parent=popup})
            local svMap=L:N("ImageLabel",{BorderSizePixel=0,Position=UDim2.fromOffset(10,32),
                Size=UDim2.fromOffset(164,164),Image="rbxassetid://4155801252",ZIndex=111,Parent=popup})
            L:Corner(svMap,4)
            local svC=L:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
                Size=UDim2.fromOffset(10,10),BackgroundColor3=Color3.new(1,1,1),
                ZIndex=112,Parent=svMap})
            L:Corner(svC,5)
            L:N("UIStroke",{Color=Color3.new(0,0,0),Thickness=1.5,Parent=svC})
            local hBar=L:N("Frame",{BorderSizePixel=0,Position=UDim2.fromOffset(180,32),
                Size=UDim2.fromOffset(14,164),ZIndex=111,Parent=popup})
            L:Corner(hBar,4)
            local hSeq={}
            for i=0,10 do hSeq[#hSeq+1]=ColorSequenceKeypoint.new(i/10,Color3.fromHSV(i/10,1,1)) end
            L:N("UIGradient",{Color=ColorSequence.new(hSeq),Rotation=90,Parent=hBar})
            local hC=L:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
                BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,
                Size=UDim2.fromOffset(14,4),ZIndex=112,Parent=hBar})
            local hexBox=L:N("TextBox",{BackgroundColor3=L.GlassLight,BackgroundTransparency=0.5,
                Font=L.Font,Text="#"..CP.Value:ToHex():upper(),PlaceholderText="#FFFFFF",
                TextColor3=L.TextPrimary,TextSize=12,ClearTextOnFocus=false,
                Position=UDim2.fromOffset(10,204),Size=UDim2.fromOffset(100,28),
                ZIndex=111,Parent=popup})
            L:Corner(hexBox,5); L:N("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=hexBox})

            function CP:Display()
                self.Value=Color3.fromHSV(self.Hue,self.Sat,self.Vib)
                svMap.BackgroundColor3=Color3.fromHSV(self.Hue,1,1)
                swatch.BackgroundColor3=self.Value
                svC.Position=UDim2.new(self.Sat,0,1-self.Vib,0)
                hC.Position=UDim2.new(0,0,self.Hue,0)
                hexBox.Text="#"..self.Value:ToHex():upper()
                L:Call(self.Callback,self.Value); L:Call(self.Changed,self.Value)
            end

            svMap.InputBegan:Connect(function(inp)
                if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                local c; c=RunService.Heartbeat:Connect(function()
                    if not UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                    CP.Sat=math.clamp((Mouse.X-svMap.AbsolutePosition.X)/svMap.AbsoluteSize.X,0,1)
                    CP.Vib=1-math.clamp((Mouse.Y-svMap.AbsolutePosition.Y)/svMap.AbsoluteSize.Y,0,1)
                    CP:Display()
                end)
            end)
            hBar.InputBegan:Connect(function(inp)
                if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                local c; c=RunService.Heartbeat:Connect(function()
                    if not UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                    CP.Hue=math.clamp((Mouse.Y-hBar.AbsolutePosition.Y)/hBar.AbsoluteSize.Y,0,1)
                    CP:Display()
                end)
            end)
            hexBox.FocusLost:Connect(function(enter)
                if not enter then return end
                local ok,col=pcall(Color3.fromHex,hexBox.Text)
                if ok then CP:SetHSVFromRGB(col);CP:Display() end
            end)
            local open=false
            swatch.MouseButton1Click:Connect(function()
                open=not open
                if open then
                    for _,fn in next,L.Popups do fn() end
                    popup.Position=UDim2.fromOffset(
                        swatch.AbsolutePosition.X-224,
                        swatch.AbsolutePosition.Y)
                    popup.Visible=true
                else popup.Visible=false end
            end)
            table.insert(L.Popups,function() popup.Visible=false;open=false end)
            function CP:SetValueRGB(c,t) self.Transparency=t or 0;self:SetHSVFromRGB(c);self:Display() end
            function CP:SetValue(h,t) self.Transparency=t or 0;self:SetHSVFromRGB(Color3.fromHSV(h[1],h[2],h[3]));self:Display() end
            function CP:OnChanged(fn) self.Changed=fn;fn(self.Value) end
            CP:Display()
            L.Options[idx]=CP; return CP
        end

        return Card
    end -- _AddCard

    -- Close popups on outside click
    L:Signal(UserInput.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            for _,fn in next,L.Popups do fn() end
        end
    end))

    -- RightShift toggles visibility
    L:Signal(UserInput.InputBegan:Connect(function(inp,proc)
        if inp.KeyCode==Enum.KeyCode.RightShift and not proc then
            Root.Visible=not Root.Visible
        end
    end))

    function Window:Toggle() Root.Visible=not Root.Visible end

    -- Show loading then reveal
    L:ShowLoading(function()
        Root.Visible=true
    end)

    L.Window=Window
    return Window
end

-- ================================================================
-- UNLOAD
-- ================================================================
function L:Unload()
    for _,s in next,self.Signals do pcall(function()s:Disconnect()end) end
    ScreenGui:Destroy()
    _genv.Toggles=nil; _genv.Options=nil
end

return L
