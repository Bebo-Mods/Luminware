--[[
    LUMINWARE UI Library v4.0
    Concept: sidebar nav + subtab horizontal tabs + two-column card grid
    Acrylic: ViewportFrame camera-follow blur (Fluent/7kayoh technique)
    
    USAGE:
        local L = loadstring(game:HttpGet(repo.."Library.lua"))()
        local Win = L:CreateWindow({ Title="LUMINWARE", Acrylic=true })
        local Tab = Win:AddTab({ Name="Aimbot", Icon="crosshair" })
        local Sub = Tab:AddSubtab("Targeting")   -- subtab = horizontal tab inside a tab
        local Card = Sub.Left:AddCard("Settings")
        Card:AddToggle("id", { Label="Silent Aim", Default=false })
        Card:AddSlider("id",  { Label="FOV",   Min=0, Max=360, Default=90 })
]]

local TS   = game:GetService("TweenService")
local UIS  = game:GetService("UserInputService")
local RS   = game:GetService("RunService")
local PLS  = game:GetService("Players")
local CSG  = game:GetService("CoreGui")
local HS   = game:GetService("HttpService")
local WS   = game:GetService("Workspace")

local LP    = PLS.LocalPlayer
local Cam   = WS.CurrentCamera
local Mouse = LP:GetMouse()

-- GUI protection
local Protect = (typeof(syn)=="table" and syn.protect_gui)
    or (typeof(protectgui)=="function" and protectgui) or function() end

local SG = Instance.new("ScreenGui")
SG.Name="LuminwareV4"; SG.ZIndexBehavior=Enum.ZIndexBehavior.Global
SG.ResetOnSpawn=false; pcall(Protect,SG)
SG.Parent=(typeof(gethui)=="function" and gethui()) or CSG

local _genv={}; pcall(function() if typeof(getgenv)=="function" then _genv=getgenv() end end)

-- ================================================================
-- ACRYLIC BLUR (ViewportFrame technique, same as Fluent/7kayoh)
-- ================================================================
local function CreateAcrylic(parent, zindex)
    -- Correct 7kayoh/Fluent acrylic technique:
    -- Glass Part lives in workspace so it sees the 3D world.
    -- A clone goes inside the ViewportFrame for rendering.
    -- DepthOfField on the VP camera creates the frosted blur.

    local vp = Instance.new("ViewportFrame")
    vp.BackgroundTransparency = 1
    vp.Size                   = UDim2.fromScale(1, 1)
    vp.ZIndex                 = zindex or 1
    vp.Ambient                = Color3.fromRGB(20, 22, 32)
    vp.LightColor             = Color3.fromRGB(255, 255, 255)
    vp.LightDirection         = Vector3.new(-1, -2, -3)
    vp.Parent                 = parent

    local vpCam = Instance.new("Camera")
    vpCam.FieldOfView  = Cam.FieldOfView
    vp.CurrentCamera   = vpCam
    vpCam.Parent       = vp

    -- DepthOfField creates the frosted blur on the viewport
    local dof = Instance.new("DepthOfFieldEffect")
    dof.FocusDistance = 0
    dof.InFocusRadius = 0.1
    dof.NearIntensity = 1
    dof.FarIntensity  = 0
    dof.Enabled       = true
    dof.Parent        = vpCam

    -- Glass part in workspace (so it sees the actual 3D world)
    local folder = Instance.new("Folder")
    folder.Name   = "_LuminwareAcrylic"
    folder.Parent = WS

    local function makePart()
        local p = Instance.new("Part")
        p.Material     = Enum.Material.Glass
        p.Color        = Color3.fromRGB(25, 27, 38)
        p.Transparency = 0.82
        p.Reflectance  = 0
        p.Anchored     = true
        p.CanCollide   = false
        p.CastShadow   = false
        p.TopSurface   = Enum.SurfaceType.Smooth
        p.BottomSurface= Enum.SurfaceType.Smooth
        return p
    end

    local wsPart = makePart(); wsPart.Parent = folder
    local vpPart = makePart(); vpPart.Parent = vp  -- clone inside viewport

    -- Overlay tint on top of the viewport
    local overlay = Instance.new("Frame")
    overlay.BackgroundColor3       = Color3.fromRGB(18, 20, 30)
    overlay.BackgroundTransparency = 0.38
    overlay.BorderSizePixel        = 0
    overlay.Size                   = UDim2.fromScale(1, 1)
    overlay.ZIndex                 = (zindex or 1) + 1
    overlay.Parent                 = parent

    -- Sync camera + dynamically size the glass part every frame
    local conn = RS.RenderStepped:Connect(function()
        local cf  = Cam.CFrame
        local fov = Cam.FieldOfView

        -- Place glass 2 studs ahead of the camera
        local dist  = 2
        local posCF = cf * CFrame.new(0, 0, -dist)
        wsPart.CFrame = posCF
        vpPart.CFrame = posCF

        -- Scale to fill the viewport
        local abs  = vp.AbsoluteSize
        local asp  = (abs.X > 0 and abs.Y > 0) and (abs.X / abs.Y) or (16/9)
        local halfH= math.tan(math.rad(fov * 0.5)) * dist
        local halfW= halfH * asp
        local sz   = Vector3.new(halfW * 2 + 0.5, halfH * 2 + 0.5, 0.05)
        wsPart.Size = sz
        vpPart.Size = sz

        vpCam.CFrame      = cf
        vpCam.FieldOfView = fov
    end)

    local function cleanup()
        conn:Disconnect()
        pcall(function() folder:Destroy() end)
    end

    return vp, overlay, cleanup
end
-- ================================================================
-- LIBRARY
-- ================================================================
local L = {
    Accent      = Color3.fromRGB(99,165,255);
    Glass       = Color3.fromRGB(26,28,38);
    GlassLight  = Color3.fromRGB(36,39,52);
    GlassDark   = Color3.fromRGB(18,20,28);
    SidebarBg   = Color3.fromRGB(18,20,30);
    EdgeHi      = Color3.fromRGB(255,255,255);
    Text        = Color3.fromRGB(238,240,255);
    TextMid     = Color3.fromRGB(155,160,185);
    TextDim     = Color3.fromRGB(80,85,110);

    Font     = Enum.Font.GothamMedium;
    FontBold = Enum.Font.GothamBold;
    FontSemi = Enum.Font.GothamSemibold;

    Registry = {};
    Signals  = {};
    Popups   = {};
    Toggles  = {};
    Options  = {};
    _acrylicConns = {};

    Themes = {
        FROST = { Accent=Color3.fromRGB(99,165,255),  GlassLight=Color3.fromRGB(36,39,52),   GlassDark=Color3.fromRGB(18,20,28),   SidebarBg=Color3.fromRGB(18,20,30)  };
        VENOM = { Accent=Color3.fromRGB(168,85,247),  GlassLight=Color3.fromRGB(38,30,52),   GlassDark=Color3.fromRGB(20,14,30),   SidebarBg=Color3.fromRGB(18,14,28)  };
        BLOOD = { Accent=Color3.fromRGB(220,60,60),   GlassLight=Color3.fromRGB(46,28,28),   GlassDark=Color3.fromRGB(24,12,12),   SidebarBg=Color3.fromRGB(22,10,10)  };
        EMBER = { Accent=Color3.fromRGB(255,145,0),   GlassLight=Color3.fromRGB(44,34,22),   GlassDark=Color3.fromRGB(24,16,8),    SidebarBg=Color3.fromRGB(22,14,8)   };
        ACID  = { Accent=Color3.fromRGB(140,220,0),   GlassLight=Color3.fromRGB(28,40,22),   GlassDark=Color3.fromRGB(12,22,8),    SidebarBg=Color3.fromRGB(12,20,8)   };
        GHOST = { Accent=Color3.fromRGB(195,200,220), GlassLight=Color3.fromRGB(40,42,54),   GlassDark=Color3.fromRGB(22,24,32),   SidebarBg=Color3.fromRGB(20,22,30)  };
    };
    _currentTheme = "FROST";
}
_genv.Toggles = L.Toggles; _genv.Options = L.Options

-- Lucide icon IDs (subset — add more as needed)
-- These are rbxassetid image IDs from the Fluent/remote-spy asset sheet
L.Icons = {
    crosshair   = "rbxassetid://14478026738",
    eye         = "rbxassetid://14478026262",
    move        = "rbxassetid://14478028604",
    sliders     = "rbxassetid://14478030628",
    settings    = "rbxassetid://14478030418",
    power       = "rbxassetid://14478028890",
    minus       = "rbxassetid://14478028222",
    x           = "rbxassetid://14478031618",
    chevrondown = "rbxassetid://14478025774",
    check       = "rbxassetid://14478025578",
    zap         = "rbxassetid://14478031878",
    user        = "rbxassetid://14478031378",
    shield      = "rbxassetid://14478030238",
    target      = "rbxassetid://14478030818",
    wind        = "rbxassetid://14478031498",
    package     = "rbxassetid://14478028750",
    info        = "rbxassetid://14478027278",
    paint       = "rbxassetid://14478028678",
}

function L:Icon(name)
    return self.Icons[name] or self.Icons.package
end

function L:T(i,p,d,s) TweenService_Create_helper(i,p,d,s) end

local function TW(inst,props,dur,sty)
    TS:Create(inst, TweenInfo.new(dur or 0.2, sty or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

function L:N(c,p)
    local i=type(c)=="string" and Instance.new(c) or c
    for k,v in next,p do if k~="Parent" then pcall(function()i[k]=v end) end end
    if p.Parent then i.Parent=p.Parent end
    return i
end
function L:Corner(i,r) return self:N("UICorner",{CornerRadius=UDim.new(0,r or 8),Parent=i}) end
function L:Stroke(i,col,thick,t)
    return self:N("UIStroke",{Color=col or self.EdgeHi,Thickness=thick or 1,
        Transparency=t or 0.86,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=i})
end
function L:Reg(i,p,k) table.insert(self.Registry,{inst=i,prop=p,key=k}) end
function L:Sig(s) table.insert(self.Signals,s) end
function L:Call(f,...) if type(f)=="function" then pcall(f,...) end end

function L:SetTheme(name)
    local t=self.Themes[name]; if not t then return end
    self._currentTheme=name
    for k,v in next,t do self[k]=v end
    for _,r in next,self.Registry do
        if r.inst and r.inst.Parent then
            local c=self[r.key]
            if typeof(c)=="Color3" then TW(r.inst,{[r.prop]=c},0.35) end
        end
    end
    self:Notify({Title="Theme: "..name,Duration=2})
end

-- ================================================================
-- NOTIFICATIONS
-- ================================================================
local NArea=L:N("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,1),
    Position=UDim2.new(1,-16,1,-16),Size=UDim2.fromOffset(300,500),ZIndex=600,Parent=SG})
L:N("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,
    HorizontalAlignment=Enum.HorizontalAlignment.Right,
    FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,8),
    SortOrder=Enum.SortOrder.LayoutOrder,Parent=NArea})

function L:Notify(opts)
    opts=type(opts)=="string" and {Title=opts,Duration=4} or opts
    local dur=opts.Duration or 4
    local card=self:N("Frame",{BackgroundColor3=self.GlassDark,BackgroundTransparency=0.08,
        Size=UDim2.new(1,0,0,opts.Content and 70 or 48),ZIndex=601,ClipsDescendants=true,Parent=NArea})
    self:Corner(card,10); self:Stroke(card,self.EdgeHi,1,0.8)
    local bar=self:N("Frame",{BackgroundColor3=self.Accent,BorderSizePixel=0,
        Size=UDim2.fromOffset(3,48),ZIndex=602,Parent=card})
    self:Reg(bar,"BackgroundColor3","Accent")
    self:N("TextLabel",{BackgroundTransparency=1,Font=self.FontBold,Text=opts.Title or "",
        TextColor3=self.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(14,8),Size=UDim2.new(1,-18,0,18),ZIndex=602,Parent=card})
    if opts.Content then
        self:N("TextLabel",{BackgroundTransparency=1,Font=self.Font,Text=opts.Content,
            TextColor3=self.TextMid,TextSize=12,TextWrapped=true,
            TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(14,28),Size=UDim2.new(1,-18,0,32),ZIndex=602,Parent=card})
    end
    local prog=self:N("Frame",{BackgroundColor3=self.Accent,BackgroundTransparency=0.5,
        BorderSizePixel=0,AnchorPoint=Vector2.new(0,1),
        Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,2),ZIndex=603,Parent=card})
    self:Reg(prog,"BackgroundColor3","Accent")
    card.BackgroundTransparency=1; TW(card,{BackgroundTransparency=0.08},0.22)
    TW(prog,{Size=UDim2.fromOffset(0,2)},dur,Enum.EasingStyle.Linear)
    task.delay(dur,function() TW(card,{BackgroundTransparency=1},0.25) task.wait(0.3) pcall(function()card:Destroy()end) end)
end

-- ================================================================
-- DRAGGABLE
-- ================================================================
function L:Drag(handle,target,cutY)
    local d,s0,p0=false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if cutY and (Mouse.Y-handle.AbsolutePosition.Y)>cutY then return end
        d=true; s0=Vector2.new(Mouse.X,Mouse.Y); p0=target.Position
    end)
    UIS.InputChanged:Connect(function(i)
        if not d or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local v=Vector2.new(Mouse.X,Mouse.Y)-s0
        target.Position=UDim2.new(p0.X.Scale,p0.X.Offset+v.X,p0.Y.Scale,p0.Y.Offset+v.Y)
    end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)
end

-- ================================================================
-- LOADING SCREEN
-- ================================================================
function L:ShowLoading(done)
    local ov=self:N("Frame",{BackgroundColor3=self.GlassDark,BackgroundTransparency=0,
        Size=UDim2.fromScale(1,1),ZIndex=1000,Parent=SG})
    local diamond=self:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.42,0),Size=UDim2.fromOffset(0,0),
        BackgroundColor3=self.Accent,Rotation=45,BorderSizePixel=0,ZIndex=1001,Parent=ov})
    self:Corner(diamond,8); self:Reg(diamond,"BackgroundColor3","Accent")
    local title=self:N("TextLabel",{BackgroundTransparency=1,Font=self.FontBold,
        Text="LUMINWARE",TextColor3=self.Text,TextSize=24,TextTransparency=1,
        AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0.52,0),
        Size=UDim2.new(1,0,0,28),TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=1001,Parent=ov})
    local sub=self:N("TextLabel",{BackgroundTransparency=1,Font=self.Font,
        Text="INITIALIZING...",TextColor3=self.TextDim,TextSize=11,
        AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0.585,0),
        Size=UDim2.new(1,0,0,18),TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=1001,Parent=ov})
    local barBg=self:N("Frame",{AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.new(0.5,0,0.625,0),Size=UDim2.fromOffset(180,3),
        BackgroundColor3=self.GlassLight,BorderSizePixel=0,ZIndex=1001,Parent=ov})
    self:Corner(barBg,2)
    local barF=self:N("Frame",{BackgroundColor3=self.Accent,BorderSizePixel=0,
        Size=UDim2.new(0,0,1,0),ZIndex=1002,Parent=barBg})
    self:Corner(barF,2); self:Reg(barF,"BackgroundColor3","Accent")

    TW(diamond,{Size=UDim2.fromOffset(52,52)},0.4,Enum.EasingStyle.Back)
    task.wait(0.3)
    TW(title,{TextTransparency=0},0.3)
    local steps={"LOADING MODULES...","PATCHING MEMORY...","READY"}
    for n,msg in ipairs(steps) do
        sub.Text=msg
        TW(barF,{Size=UDim2.new(n/#steps,0,1,0)},0.35,Enum.EasingStyle.Quint)
        task.wait(0.42)
    end
    task.wait(0.1)
    TW(ov,{BackgroundTransparency=1},0.4)
    task.wait(0.45)
    ov:Destroy()
    if done then done() end
end

-- ================================================================
-- CARD COMPONENTS (shared between tabs and subtabs)
-- ================================================================
local function MakeCard(L, parentScroll, titleText)
    local card=L:N("Frame",{BackgroundColor3=L.GlassLight,BackgroundTransparency=0.25,
        BorderSizePixel=0,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=5,Parent=parentScroll})
    L:Corner(card,12); L:Stroke(card,L.EdgeHi,1,0.84)
    L:Reg(card,"BackgroundColor3","GlassLight")
    -- top edge highlight
    L:N("Frame",{BackgroundColor3=L.EdgeHi,BackgroundTransparency=0.9,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,1),ZIndex=6,Parent=card})

    if titleText and titleText~="" then
        local hdr=L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,32),ZIndex=6,Parent=card})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=string.upper(titleText),TextColor3=L.TextDim,TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-28,1,0),
            ZIndex=7,Parent=hdr})
        L:N("Frame",{BackgroundColor3=L.EdgeHi,BackgroundTransparency=0.9,
            BorderSizePixel=0,AnchorPoint=Vector2.new(0,1),
            Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),ZIndex=7,Parent=hdr})
    end

    local items=L:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,titleText~="" and 32 or 0),
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=6,Parent=card})
    L:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,Parent=items})
    L:N("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),
        PaddingBottom=UDim.new(0,12),Parent=items})

    local Card={}

    local function Row(h)
        return L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h or 40),ZIndex=7,Parent=items})
    end
    local function Lbl(par,txt)
        return L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,Text=txt or "",
            TextColor3=L.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(0.55,0,1,0),ZIndex=8,Parent=par})
    end

    function Card:AddToggle(idx,info)
        info=info or {}
        local row=Row(40); local lbl=Lbl(row,info.Label or info.Text or idx)
        local track=L:N("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
            Size=UDim2.fromOffset(44,24),BackgroundColor3=L.GlassLight,ZIndex=8,Parent=row})
        L:Corner(track,12); L:Reg(track,"BackgroundColor3","GlassLight")
        local knob=L:N("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,3,0.5,0),
            Size=UDim2.fromOffset(18,18),BackgroundColor3=L.TextMid,ZIndex=9,Parent=track})
        L:Corner(knob,9)
        local Tog={Value=not not info.Default,Type="Toggle",
            Callback=info.Callback or function()end,Addons={}}
        function Tog:Render(anim)
            local tC=self.Value and L.Accent or L.GlassLight
            local kC=self.Value and Color3.new(1,1,1) or L.TextMid
            local kP=self.Value and UDim2.new(1,-21,0.5,0) or UDim2.new(0,3,0.5,0)
            if anim then TW(track,{BackgroundColor3=tC},0.18);TW(knob,{BackgroundColor3=kC,Position=kP},0.18)
            else track.BackgroundColor3=tC;knob.BackgroundColor3=kC;knob.Position=kP end
            for _,r in next,L.Registry do if r.inst==track then r.key=self.Value and "Accent" or "GlassLight" end end
        end
        function Tog:SetValue(v) self.Value=not not v;self:Render(true);L:Call(self.Callback,self.Value);L:Call(self.Changed,self.Value) end
        function Tog:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        local hit=L:N("TextButton",{BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1),ZIndex=10,Parent=row})
        hit.MouseButton1Click:Connect(function() Tog:SetValue(not Tog.Value) end)
        hit.MouseEnter:Connect(function() TW(lbl,{TextColor3=L.Accent},0.15) end)
        hit.MouseLeave:Connect(function() TW(lbl,{TextColor3=L.Text},0.15) end)
        Tog:Render(false); L.Toggles[idx]=Tog; return Tog
    end

    function Card:AddSlider(idx,info)
        info=info or {}
        local min=info.Min or 0;local max=info.Max or 100;local def=info.Default or min;local suf=info.Suffix or ""
        local wrap=L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,52),ZIndex=7,Parent=items})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,Text=info.Label or info.Text or idx,
            TextColor3=L.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(0.65,0,0,22),ZIndex=8,Parent=wrap})
        local valL=L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=tostring(def)..suf,TextColor3=L.Accent,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Right,AnchorPoint=Vector2.new(1,0),
            Position=UDim2.new(1,0,0,0),Size=UDim2.new(0.35,0,0,22),ZIndex=8,Parent=wrap})
        L:Reg(valL,"TextColor3","Accent")
        local trk=L:N("Frame",{BorderSizePixel=0,Position=UDim2.fromOffset(0,27),
            BackgroundColor3=L.GlassDark,Size=UDim2.new(1,0,0,5),ZIndex=8,Parent=wrap})
        L:Corner(trk,3); L:Reg(trk,"BackgroundColor3","GlassDark")
        local fill=L:N("Frame",{BackgroundColor3=L.Accent,BorderSizePixel=0,
            Size=UDim2.new(0,0,1,0),ZIndex=9,Parent=trk})
        L:Corner(fill,3); L:Reg(fill,"BackgroundColor3","Accent")
        local knob=L:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,0,0.5,0),
            Size=UDim2.fromOffset(16,16),BackgroundColor3=L.Accent,ZIndex=10,Parent=trk})
        L:Corner(knob,8); L:Reg(knob,"BackgroundColor3","Accent")
        L:N("UIStroke",{Color=Color3.new(1,1,1),Thickness=2,Transparency=0.7,
            ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=knob})
        local Sli={Value=def,Min=min,Max=max,Rounding=info.Rounding or 0,Type="Slider",
            Callback=info.Callback or function()end}
        local function rnd(v) if Sli.Rounding==0 then return math.floor(v+0.5) end
            return tonumber(string.format("%."..Sli.Rounding.."f",v)) end
        function Sli:Render()
            local p=math.clamp((self.Value-min)/(max-min),0,1)
            fill.Size=UDim2.new(p,0,1,0);knob.Position=UDim2.new(p,0,0.5,0)
            valL.Text=tostring(self.Value)..suf
        end
        function Sli:SetValue(v) local n=tonumber(v);if not n then return end
            self.Value=rnd(math.clamp(n,min,max));self:Render()
            L:Call(self.Callback,self.Value);L:Call(self.Changed,self.Value) end
        function Sli:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        trk.InputBegan:Connect(function(inp)
            if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local c;c=RS.Heartbeat:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                local p=math.clamp((Mouse.X-trk.AbsolutePosition.X)/trk.AbsoluteSize.X,0,1)
                Sli:SetValue(min+p*(max-min))
            end)
        end)
        Sli:Render(); L.Options[idx]=Sli; return Sli
    end

    function Card:AddButton(info)
        info=type(info)=="string" and {Label=info} or info
        local row=Row(40); Lbl(row,info.Label or info.Text or "Button")
        local btn=L:N("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
            BackgroundColor3=L.GlassLight,BackgroundTransparency=0.3,
            Font=L.FontSemi,Text=info.Action or "Execute",TextColor3=L.Text,TextSize=12,
            Size=UDim2.fromOffset(86,28),ZIndex=8,Parent=row})
        L:Corner(btn,7); L:Stroke(btn)
        btn.MouseButton1Click:Connect(function()
            TW(btn,{BackgroundColor3=L.Accent},0.08)
            task.delay(0.15,function() TW(btn,{BackgroundColor3=L.GlassLight},0.25) end)
            L:Call(info.Callback or info.Func)
        end)
        btn.MouseEnter:Connect(function() TW(btn,{BackgroundTransparency=0.1},0.15) end)
        btn.MouseLeave:Connect(function() TW(btn,{BackgroundTransparency=0.3},0.15) end)
        return btn
    end

    function Card:AddDropdown(idx,info)
        info=info or {}
        local wrap=L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,62),ZIndex=7,Parent=items})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,Text=info.Label or info.Text or idx,
            TextColor3=L.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,0,0,22),ZIndex=8,Parent=wrap})
        local dbtn=L:N("TextButton",{BackgroundColor3=L.GlassDark,BackgroundTransparency=0.12,
            Font=L.Font,Text="",TextColor3=L.Text,TextSize=13,
            Position=UDim2.fromOffset(0,24),Size=UDim2.new(1,0,0,32),ZIndex=8,Parent=wrap})
        L:Corner(dbtn,8); L:Stroke(dbtn,L.EdgeHi,1,0.8)
        local sel=L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=tostring(info.Default or "--"),TextColor3=L.Text,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-36,1,0),ZIndex=9,Parent=dbtn})
        local arrow=L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontBold,
            Text="▾",TextColor3=L.TextDim,TextSize=15,
            AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),
            Size=UDim2.fromOffset(18,18),ZIndex=9,Parent=dbtn})
        local DD={Value=info.Default,Values=info.Values or {},Type="Dropdown",
            Callback=info.Callback or function()end}
        local popup=L:N("Frame",{BackgroundColor3=L.GlassDark,BackgroundTransparency=0.05,
            BorderSizePixel=0,ZIndex=120,Visible=false,Parent=SG})
        L:Corner(popup,8); L:Stroke(popup,L.EdgeHi,1,0.75); L:Reg(popup,"BackgroundColor3","GlassDark")
        L:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
            SortOrder=Enum.SortOrder.LayoutOrder,Parent=popup})
        L:N("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=popup})
        local function closeDD() if not popup.Visible then return end
            popup.Visible=false; TW(arrow,{Rotation=0},0.15) end
        table.insert(L.Popups,closeDD)
        local function buildList()
            for _,c in next,popup:GetChildren() do if c:IsA("TextButton") then c:Destroy() end end
            for _,v in next,DD.Values do
                local isSel=(DD.Value==v)
                local it=L:N("TextButton",{BackgroundColor3=isSel and L.Accent or L.GlassLight,
                    BackgroundTransparency=isSel and 0.7 or 0.9,Font=L.FontSemi,Text="",
                    Size=UDim2.new(1,0,0,32),ZIndex=121,Parent=popup})
                L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,Text=tostring(v),
                    TextColor3=isSel and L.Text or L.TextMid,TextSize=13,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-12,1,0),ZIndex=122,Parent=it})
                local vv=v
                it.MouseButton1Click:Connect(function()
                    DD.Value=vv; sel.Text=tostring(vv); closeDD(); buildList()
                    L:Call(DD.Callback,vv); L:Call(DD.Changed,vv)
                end)
                it.MouseEnter:Connect(function() if vv~=DD.Value then TW(it,{BackgroundTransparency=0.75},0.1) end end)
                it.MouseLeave:Connect(function() if vv~=DD.Value then TW(it,{BackgroundTransparency=0.9},0.1) end end)
            end
            local cnt=math.min(#DD.Values,7)
            popup.Size=UDim2.fromOffset(dbtn.AbsoluteSize.X,cnt*32+8)
            popup.Position=UDim2.fromOffset(dbtn.AbsolutePosition.X,dbtn.AbsolutePosition.Y+36)
        end
        dbtn.MouseButton1Click:Connect(function()
            if popup.Visible then closeDD()
            else for _,fn in next,L.Popups do fn() end; buildList(); popup.Visible=true; TW(arrow,{Rotation=180},0.15) end
        end)
        function DD:SetValue(v) self.Value=v;sel.Text=tostring(v);buildList();L:Call(self.Callback,v);L:Call(self.Changed,v) end
        function DD:SetValues(vals) self.Values=vals;buildList() end
        function DD:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        L.Options[idx]=DD; return DD
    end

    function Card:AddInput(idx,info)
        info=info or {}
        local wrap=L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,62),ZIndex=7,Parent=items})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,Text=info.Label or info.Text or idx,
            TextColor3=L.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,0,0,22),ZIndex=8,Parent=wrap})
        local box=L:N("TextBox",{BackgroundColor3=L.GlassDark,BackgroundTransparency=0.12,
            Font=L.Font,Text=info.Default or "",PlaceholderText=info.Placeholder or "",
            PlaceholderColor3=L.TextDim,TextColor3=L.Text,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,
            Position=UDim2.fromOffset(0,24),Size=UDim2.new(1,0,0,32),ZIndex=8,Parent=wrap})
        L:Corner(box,8); L:Stroke(box,L.EdgeHi,1,0.8)
        L:N("UIPadding",{PaddingLeft=UDim.new(0,10),Parent=box})
        local Inp={Value=info.Default or "",Type="Input",Callback=info.Callback or function()end}
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if info.Numeric and not tonumber(box.Text) and #box.Text>0 then box.Text=Inp.Value;return end
            Inp.Value=box.Text; if not info.Finished then L:Call(Inp.Callback,Inp.Value) end
        end)
        box.FocusLost:Connect(function(enter)
            if info.Finished and enter then L:Call(Inp.Callback,Inp.Value) end
            L:Call(Inp.Changed,Inp.Value)
        end)
        function Inp:SetValue(v) box.Text=tostring(v);self.Value=tostring(v) end
        function Inp:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        L.Options[idx]=Inp; return Inp
    end

    function Card:AddKeybind(idx,info)
        info=info or {}
        local row=Row(40); local lbl=Lbl(row,info.Label or info.Text or idx)
        local kbBtn=L:N("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
            BackgroundColor3=L.GlassDark,BackgroundTransparency=0.12,
            Font=L.FontSemi,Text=info.Default or "None",TextColor3=L.Accent,TextSize=12,
            Size=UDim2.fromOffset(76,28),ZIndex=8,Parent=row})
        L:Corner(kbBtn,7); L:Stroke(kbBtn); L:Reg(kbBtn,"TextColor3","Accent")
        local KP={Value=info.Default or "None",Mode=info.Mode or "Toggle",
            Toggled=false,Type="KeyPicker",Callback=info.Callback or function()end}
        local picking=false
        kbBtn.MouseButton1Click:Connect(function()
            if picking then return end; picking=true; kbBtn.Text="..."
            local c; c=UIS.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.Keyboard then
                    KP.Value=inp.KeyCode.Name; kbBtn.Text=inp.KeyCode.Name; picking=false; c:Disconnect()
                    L:Call(KP.ChangedCallback,inp.KeyCode)
                elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then
                    picking=false; c:Disconnect(); kbBtn.Text=KP.Value
                end
            end)
        end)
        UIS.InputBegan:Connect(function(inp)
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

    function Card:AddColorPicker(idx,info)
        info=info or {}
        local row=Row(40); Lbl(row,info.Label or info.Title or idx)
        local swatch=L:N("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
            BackgroundColor3=info.Default or L.Accent,Size=UDim2.fromOffset(40,22),
            Text="",ZIndex=8,Parent=row})
        L:Corner(swatch,5); L:Stroke(swatch)
        local CP={Value=info.Default or L.Accent,Transparency=info.Transparency or 0,
            Type="ColorPicker",Callback=info.Callback or function()end}
        function CP:SetHSV(c) self.Hue,self.Sat,self.Vib=Color3.toHSV(c) end
        CP:SetHSV(CP.Value)
        local popup=L:N("Frame",{BackgroundColor3=L.GlassDark,BackgroundTransparency=0.05,
            Size=UDim2.fromOffset(224,248),Visible=false,ZIndex=130,Parent=SG})
        L:Corner(popup,10); L:Stroke(popup,L.EdgeHi,1,0.78); L:Reg(popup,"BackgroundColor3","GlassDark")
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,Text=info.Title or "Color",
            TextColor3=L.Text,TextSize=13,Position=UDim2.fromOffset(12,8),
            Size=UDim2.new(1,-24,0,20),ZIndex=131,Parent=popup})
        local svM=L:N("ImageLabel",{BorderSizePixel=0,Position=UDim2.fromOffset(10,32),
            Size=UDim2.fromOffset(164,164),Image="rbxassetid://4155801252",ZIndex=131,Parent=popup})
        L:Corner(svM,4)
        local svC=L:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(10,10),
            BackgroundColor3=Color3.new(1,1,1),ZIndex=132,Parent=svM})
        L:Corner(svC,5); L:N("UIStroke",{Color=Color3.new(0,0,0),Thickness=1.5,Parent=svC})
        local hBar=L:N("Frame",{BorderSizePixel=0,Position=UDim2.fromOffset(180,32),
            Size=UDim2.fromOffset(14,164),ZIndex=131,Parent=popup})
        L:Corner(hBar,4)
        local hSeq={}; for i=0,10 do hSeq[#hSeq+1]=ColorSequenceKeypoint.new(i/10,Color3.fromHSV(i/10,1,1)) end
        L:N("UIGradient",{Color=ColorSequence.new(hSeq),Rotation=90,Parent=hBar})
        local hC=L:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),
            BorderSizePixel=0,Size=UDim2.fromOffset(14,4),ZIndex=132,Parent=hBar})
        local hexB=L:N("TextBox",{BackgroundColor3=L.GlassLight,BackgroundTransparency=0.5,
            Font=L.Font,Text="#"..CP.Value:ToHex():upper(),PlaceholderText="#FFFFFF",
            TextColor3=L.Text,TextSize=12,ClearTextOnFocus=false,
            Position=UDim2.fromOffset(10,204),Size=UDim2.fromOffset(100,28),ZIndex=131,Parent=popup})
        L:Corner(hexB,5); L:N("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=hexB})
        function CP:Display()
            self.Value=Color3.fromHSV(self.Hue,self.Sat,self.Vib)
            svM.BackgroundColor3=Color3.fromHSV(self.Hue,1,1)
            swatch.BackgroundColor3=self.Value
            svC.Position=UDim2.new(self.Sat,0,1-self.Vib,0)
            hC.Position=UDim2.new(0,0,self.Hue,0)
            hexB.Text="#"..self.Value:ToHex():upper()
            L:Call(self.Callback,self.Value); L:Call(self.Changed,self.Value)
        end
        svM.InputBegan:Connect(function(inp)
            if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local c; c=RS.Heartbeat:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                CP.Sat=math.clamp((Mouse.X-svM.AbsolutePosition.X)/svM.AbsoluteSize.X,0,1)
                CP.Vib=1-math.clamp((Mouse.Y-svM.AbsolutePosition.Y)/svM.AbsoluteSize.Y,0,1)
                CP:Display()
            end)
        end)
        hBar.InputBegan:Connect(function(inp)
            if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local c; c=RS.Heartbeat:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                CP.Hue=math.clamp((Mouse.Y-hBar.AbsolutePosition.Y)/hBar.AbsoluteSize.Y,0,1)
                CP:Display()
            end)
        end)
        hexB.FocusLost:Connect(function(enter)
            if not enter then return end
            local ok,col=pcall(Color3.fromHex,hexB.Text)
            if ok then CP:SetHSV(col);CP:Display() end
        end)
        local open=false
        swatch.MouseButton1Click:Connect(function()
            open=not open
            if open then for _,fn in next,L.Popups do fn() end
                popup.Position=UDim2.fromOffset(swatch.AbsolutePosition.X-224,swatch.AbsolutePosition.Y)
                popup.Visible=true
            else popup.Visible=false end
        end)
        table.insert(L.Popups,function() popup.Visible=false;open=false end)
        function CP:SetValueRGB(c,t) self.Transparency=t or 0;self:SetHSV(c);self:Display() end
        function CP:SetValue(h,t) self.Transparency=t or 0;self:SetHSV(Color3.fromHSV(h[1],h[2],h[3]));self:Display() end
        function CP:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        CP:Display(); L.Options[idx]=CP; return CP
    end

    return Card
end

-- ================================================================
-- PANE — left or right column in a subtab
-- ================================================================
local function MakePaneAPI(L, col)
    local Pane={}
    function Pane:AddCard(title)
        return MakeCard(L, col, title or "")
    end
    return Pane
end

-- ================================================================
-- MAKE SCROLLABLE COLUMN
-- ================================================================
local function MakeColumn(L, parent, xPos, xSz, yOff)
    local col=L:N("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.new(xPos,xPos==0 and 10 or 6,0,yOff or 0),
        Size=UDim2.new(xSz,-16,1,-(yOff or 0)-8),
        CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,
        ScrollBarImageColor3=L.Accent,ScrollBarImageTransparency=0.5,
        TopImage="",BottomImage="",ZIndex=4,Parent=parent})
    L:Reg(col,"ScrollBarImageColor3","Accent")
    L:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,10),Parent=col})
    col:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        col.CanvasSize=UDim2.fromOffset(0,col:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y+10)
    end)
    return col
end

-- ================================================================
-- CREATE WINDOW
-- ================================================================
function L:CreateWindow(cfg)
    cfg=cfg or {}
    local W=cfg.Size or Vector2.new(900,560)
    local logoId=cfg.Logo or ""
    local useAcrylic=cfg.Acrylic~=false  -- default ON

    local Window={Tabs={},_tabOrder={}}

    -- Root (just for positioning)
    local Root=self:N("Frame",{BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(W.X,W.Y),ZIndex=2,Visible=false,Parent=SG})

    -- Minimize icon (visible when minimized)
    local MinIcon=self:N("Frame",{BackgroundColor3=self.GlassDark,BackgroundTransparency=0.1,
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(58,58),Visible=false,ZIndex=500,Parent=SG})
    self:Corner(MinIcon,14); self:Stroke(MinIcon,self.EdgeHi,1,0.78)
    self:Drag(MinIcon,MinIcon)
    if logoId~="" then
        self:N("ImageLabel",{BackgroundTransparency=1,Image=logoId,
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(38,38),ScaleType=Enum.ScaleType.Fit,ZIndex=501,Parent=MinIcon})
    else
        local d=self:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(22,22),BackgroundColor3=self.Accent,Rotation=45,BorderSizePixel=0,ZIndex=501,Parent=MinIcon})
        self:Corner(d,4); self:Reg(d,"BackgroundColor3","Accent")
    end
    self:N("TextButton",{BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1),ZIndex=502,Parent=MinIcon}).MouseButton1Click:Connect(function()
        MinIcon.Visible=false; Root.Visible=true
    end)

    -- Main glass panel
    local Main=self:N("Frame",{BackgroundColor3=self.Glass,BackgroundTransparency=0.1,
        BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=2,Parent=Root})
    self:Corner(Main,16); self:Stroke(Main,self.EdgeHi,1,0.80)
    self:Reg(Main,"BackgroundColor3","Glass")

    -- Acrylic blur layer (behind everything)
    if useAcrylic then
        local acrylicFrame=self:N("Frame",{BackgroundTransparency=1,
            Size=UDim2.fromScale(1,1),ZIndex=1,Parent=Root})
        self:Corner(acrylicFrame,16)
        acrylicFrame.ClipsDescendants=true
        local _,overlay,cleanup=CreateAcrylic(acrylicFrame,1)
        self:Reg(overlay,"BackgroundColor3","GlassDark")
        table.insert(self._acrylicConns,cleanup)
    end

    -- top edge highlight
    self:N("Frame",{BackgroundColor3=self.EdgeHi,BackgroundTransparency=0.88,
        BorderSizePixel=0,Size=UDim2.new(1,0,0,1),ZIndex=10,Parent=Main})

    -- SIDEBAR (64px)
    local SW=64
    local Sidebar=self:N("Frame",{BackgroundColor3=self.SidebarBg,BackgroundTransparency=0.05,
        BorderSizePixel=0,Size=UDim2.fromOffset(SW,W.Y),ZIndex=3,Parent=Main})
    -- Square off right half (keep only left corners rounded)
    self:N("Frame",{BackgroundColor3=self.SidebarBg,BackgroundTransparency=0.05,
        BorderSizePixel=0,Position=UDim2.fromOffset(SW/2,0),
        Size=UDim2.fromOffset(SW/2,W.Y),ZIndex=3,Parent=Sidebar})
    self:N("UICorner",{CornerRadius=UDim.new(0,16),Parent=Sidebar})
    self:Reg(Sidebar,"BackgroundColor3","SidebarBg")
    -- Right divider
    self:N("Frame",{BackgroundColor3=self.EdgeHi,BackgroundTransparency=0.88,
        BorderSizePixel=0,AnchorPoint=Vector2.new(1,0),Position=UDim2.fromOffset(SW,0),
        Size=UDim2.fromOffset(1,W.Y),ZIndex=4,Parent=Main})

    -- Logo in sidebar
    local logoArea=self:N("Frame",{BackgroundTransparency=1,Size=UDim2.fromOffset(SW,64),ZIndex=4,Parent=Sidebar})
    if logoId~="" then
        self:N("ImageLabel",{BackgroundTransparency=1,Image=logoId,
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(32,32),ScaleType=Enum.ScaleType.Fit,ZIndex=5,Parent=logoArea})
    else
        local d=self:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(20,20),BackgroundColor3=self.Accent,Rotation=45,
            BorderSizePixel=0,ZIndex=5,Parent=logoArea})
        self:Corner(d,4); self:Reg(d,"BackgroundColor3","Accent")
    end

    -- Nav list
    local NavList=self:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,70),Size=UDim2.new(1,0,1,-140),
        ZIndex=4,Parent=Sidebar})
    self:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=NavList})

    -- Active nav indicator
    local NavBar=self:N("Frame",{BackgroundColor3=self.Accent,BorderSizePixel=0,
        Position=UDim2.fromOffset(SW-3,90),Size=UDim2.fromOffset(3,32),ZIndex=6,Parent=Main})
    self:Corner(NavBar,2); self:Reg(NavBar,"BackgroundColor3","Accent")

    -- Bottom sidebar buttons
    local BotBtns=self:N("Frame",{BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-10),
        Size=UDim2.fromOffset(SW,96),ZIndex=4,Parent=Sidebar})
    self:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=BotBtns})

    local function SBtn(iconName,col,fn)
        local bg=self:N("TextButton",{BackgroundColor3=col or self.GlassLight,
            BackgroundTransparency=0.6,Size=UDim2.fromOffset(40,40),Text="",ZIndex=5,Parent=BotBtns})
        self:Corner(bg,10)
        -- Use icon image
        local iconId=self:Icon(iconName)
        if iconId~="" then
            local img=self:N("ImageLabel",{BackgroundTransparency=1,Image=iconId,
                ImageColor3=self.TextDim,AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(18,18),ZIndex=6,Parent=bg})
            bg.MouseEnter:Connect(function() TW(bg,{BackgroundTransparency=0.3},0.15);TW(img,{ImageColor3=self.Text},0.15) end)
            bg.MouseLeave:Connect(function() TW(bg,{BackgroundTransparency=0.6},0.15);TW(img,{ImageColor3=self.TextDim},0.15) end)
        end
        bg.MouseButton1Click:Connect(fn)
        return bg
    end

    SBtn("minus",nil,function()
        Root.Visible=false; MinIcon.Visible=true
    end)
    SBtn("x",Color3.fromRGB(50,18,18),function()
        self:Notify({Title="Closing...",Duration=0.8})
        task.delay(0.7,function() self:Unload() end)
    end)

    -- CONTENT AREA
    local Content=self:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(SW,0),Size=UDim2.new(1,-SW,1,0),ZIndex=3,Parent=Main})

    -- Top bar
    local TopBar=self:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,50),ZIndex=4,Parent=Content})
    self:Drag(TopBar,Root,50)
    self:N("TextLabel",{BackgroundTransparency=1,Font=self.FontBold,
        Text=string.upper(cfg.Title or "LUMINWARE"),TextColor3=self.Text,TextSize=16,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(16,0),Size=UDim2.new(0.5,0,1,0),ZIndex=5,Parent=TopBar})

    -- Top-right: minimize + close dots
    local TRRow=self:N("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0),Size=UDim2.fromOffset(46,16),ZIndex=5,Parent=TopBar})
    self:N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Right,
        VerticalAlignment=Enum.VerticalAlignment.Center,
        Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,Parent=TRRow})
    local function Dot(col,fn)
        local d=self:N("TextButton",{BackgroundColor3=col,Size=UDim2.fromOffset(14,14),
            Text="",ZIndex=6,Parent=TRRow})
        self:Corner(d,7)
        d.MouseEnter:Connect(function() TW(d,{Size=UDim2.fromOffset(16,16)},0.1) end)
        d.MouseLeave:Connect(function() TW(d,{Size=UDim2.fromOffset(14,14)},0.1) end)
        d.MouseButton1Click:Connect(fn); return d
    end
    Dot(Color3.fromRGB(255,189,46),function() Root.Visible=false; MinIcon.Visible=true end)
    Dot(Color3.fromRGB(255,95,86),function()
        self:Notify({Title="Closing...",Duration=0.8})
        task.delay(0.7,function() self:Unload() end)
    end)

    -- Divider under topbar
    self:N("Frame",{BackgroundColor3=self.EdgeHi,BackgroundTransparency=0.88,
        BorderSizePixel=0,Position=UDim2.fromOffset(0,49),Size=UDim2.new(1,0,0,1),ZIndex=4,Parent=Content})

    -- Tab row (main horizontal tabs)
    local TabRow=self:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(16,54),Size=UDim2.new(1,-32,0,28),ZIndex=4,Parent=Content})
    self:N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
        VerticalAlignment=Enum.VerticalAlignment.Center,
        Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder,Parent=TabRow})
    -- Underline for main tabs
    local TabLine=self:N("Frame",{BackgroundColor3=self.Accent,BorderSizePixel=0,
        AnchorPoint=Vector2.new(0,1),Position=UDim2.fromOffset(0,28),
        Size=UDim2.fromOffset(0,2),ZIndex=6,Parent=TabRow})
    self:Corner(TabLine,1); self:Reg(TabLine,"BackgroundColor3","Accent")
    -- Base line
    self:N("Frame",{BackgroundColor3=self.EdgeHi,BackgroundTransparency=0.9,BorderSizePixel=0,
        AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),ZIndex=5,Parent=TabRow})
    -- Divider under tab row
    self:N("Frame",{BackgroundColor3=self.EdgeHi,BackgroundTransparency=0.88,
        BorderSizePixel=0,Position=UDim2.fromOffset(0,83),Size=UDim2.new(1,0,0,1),ZIndex=4,Parent=Content})

    local TabHost=self:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,86),Size=UDim2.new(1,0,1,-86),ZIndex=3,Parent=Content})

    -- ── ADD TAB ─────────────────────────────────────────────
    function Window:AddTab(opts)
        opts=type(opts)=="string" and {Name=opts} or opts
        local name=opts.Name or "Tab"
        local iconName=opts.Icon or "package"

        local Tab={_name=name,Subtabs={},_subtabOrder={}}

        -- Sidebar nav button
        local navBtn=L:N("TextButton",{BackgroundColor3=L.GlassLight,BackgroundTransparency=1,
            Size=UDim2.fromOffset(48,48),Text="",ZIndex=5,Parent=NavList})
        L:Corner(navBtn,10)
        local navIco=L:N("ImageLabel",{BackgroundTransparency=1,
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(20,20),Image=L:Icon(iconName),
            ImageColor3=L.TextDim,ZIndex=6,Parent=navBtn})
        local tip=L:N("TextLabel",{BackgroundColor3=L.GlassDark,BackgroundTransparency=0.05,
            Font=L.FontSemi,Text=name,TextColor3=L.Text,TextSize=12,
            AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(1,6,0.5,0),
            Size=UDim2.fromOffset(80,26),Visible=false,ZIndex=60,Parent=navBtn})
        L:Corner(tip,6); L:Stroke(tip)
        navBtn.MouseEnter:Connect(function() tip.Visible=true end)
        navBtn.MouseLeave:Connect(function() tip.Visible=false end)

        -- Main tab text button in tab row
        local tabBtnW=82
        local tBtn=L:N("TextButton",{BackgroundTransparency=1,
            Font=L.FontSemi,Text=name,TextColor3=L.TextDim,TextSize=13,
            Size=UDim2.fromOffset(tabBtnW,28),ZIndex=5,Parent=TabRow})

        -- Tab host frame
        local tabFrame=L:N("Frame",{BackgroundTransparency=1,
            Size=UDim2.fromScale(1,1),Visible=false,ZIndex=3,Parent=TabHost})

        -- Subtab row inside this tab frame (horizontal, at top)
        local SubRow=L:N("Frame",{BackgroundTransparency=1,
            Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-20,0,34),ZIndex=4,Parent=tabFrame})
        L:N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
            VerticalAlignment=Enum.VerticalAlignment.Center,
            Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,Parent=SubRow})
        -- Subtab underline
        local SubLine=L:N("Frame",{BackgroundColor3=L.Accent,BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,1),Position=UDim2.fromOffset(0,34),
            Size=UDim2.fromOffset(0,2),ZIndex=6,Parent=SubRow})
        L:Corner(SubLine,1); L:Reg(SubLine,"BackgroundColor3","Accent")
        -- Subtab base line
        L:N("Frame",{BackgroundColor3=L.EdgeHi,BackgroundTransparency=0.9,BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
            Size=UDim2.new(1,0,0,1),ZIndex=5,Parent=SubRow})

        -- Subtab content host
        local SubHost=L:N("Frame",{BackgroundTransparency=1,
            Position=UDim2.fromOffset(0,38),Size=UDim2.new(1,0,1,-38),
            ZIndex=3,Parent=tabFrame})

        -- ── ADD SUBTAB ──────────────────────────────────────
        function Tab:AddSubtab(subName)
            local Sub={_name=subName}

            -- Subtab button
            local sBtnW=80
            local sBtn=L:N("TextButton",{BackgroundTransparency=1,
                Font=L.FontSemi,Text=subName,TextColor3=L.TextDim,TextSize=13,
                Size=UDim2.fromOffset(sBtnW,34),ZIndex=5,Parent=SubRow})

            -- Subtab frame (two columns)
            local sFrame=L:N("Frame",{BackgroundTransparency=1,
                Size=UDim2.fromScale(1,1),Visible=false,ZIndex=3,Parent=SubHost})

            local leftCol=MakeColumn(L,sFrame,0,0.5,8)
            local rightCol=MakeColumn(L,sFrame,0.5,0.5,8)

            Sub.Left=MakePaneAPI(L,leftCol)
            Sub.Right=MakePaneAPI(L,rightCol)

            function Sub:Show()
                for _,s in next,Tab.Subtabs do s:Hide() end
                sFrame.Visible=true; Sub._active=true
                TW(sBtn,{TextColor3=L.Text},0.2)
                TW(SubLine,{
                    Position=UDim2.fromOffset(sBtn.AbsolutePosition.X-SubRow.AbsolutePosition.X,34),
                    Size=UDim2.fromOffset(sBtnW,2)
                },0.22)
            end
            function Sub:Hide()
                sFrame.Visible=false; Sub._active=false
                TW(sBtn,{TextColor3=L.TextDim},0.2)
            end
            sBtn.MouseButton1Click:Connect(function() Sub:Show() end)

            Tab.Subtabs[subName]=Sub
            table.insert(Tab._subtabOrder,Sub)
            -- auto-show first subtab
            if #Tab._subtabOrder==1 then task.defer(function() Sub:Show() end) end
            return Sub
        end

        function Tab:ShowTab()
            for _,t in next,Window.Tabs do t:HideTab() end
            tabFrame.Visible=true; Tab._active=true
            TW(navBtn,{BackgroundTransparency=0.82},0.2)
            TW(navIco,{ImageColor3=L.Accent},0.2)
            TW(tBtn,{TextColor3=L.Text},0.2)
            TW(TabLine,{
                Position=UDim2.fromOffset(tBtn.AbsolutePosition.X-TabRow.AbsolutePosition.X,28),
                Size=UDim2.fromOffset(tabBtnW,2)
            },0.22)
            TW(NavBar,{Position=UDim2.fromOffset(SW-3,navBtn.AbsolutePosition.Y-NavList.AbsolutePosition.Y+70+8)},0.25)
        end
        function Tab:HideTab()
            tabFrame.Visible=false; Tab._active=false
            TW(navBtn,{BackgroundTransparency=1},0.2)
            TW(navIco,{ImageColor3=L.TextDim},0.2)
            TW(tBtn,{TextColor3=L.TextDim},0.2)
        end
        navBtn.MouseButton1Click:Connect(function() Tab:ShowTab() end)
        tBtn.MouseButton1Click:Connect(function() Tab:ShowTab() end)

        Window.Tabs[name]=Tab; table.insert(Window._tabOrder,Tab)
        if #Window._tabOrder==1 then task.defer(function() Tab:ShowTab() end) end
        return Tab
    end

    -- Close popups on outside click
    L:Sig(UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            for _,fn in next,L.Popups do fn() end
        end
    end))
    -- RightShift toggle
    L:Sig(UIS.InputBegan:Connect(function(inp,proc)
        if inp.KeyCode==Enum.KeyCode.RightShift and not proc then
            Root.Visible=not Root.Visible
        end
    end))

    function Window:Toggle() Root.Visible=not Root.Visible end

    L:ShowLoading(function() Root.Visible=true end)
    L.Window=Window; return Window
end

-- ================================================================
-- UNLOAD
-- ================================================================
function L:Unload()
    for _,c in next,self._acrylicConns do pcall(c) end
    for _,s in next,self.Signals do pcall(function()s:Disconnect()end) end
    SG:Destroy()
    _genv.Toggles=nil; _genv.Options=nil
end

return L
