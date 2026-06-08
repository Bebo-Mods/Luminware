--[[
    LUMINWARE UI Library v6.0
    Complete rewrite fixing all layout and rendering bugs.

    Root causes fixed:
    - Sidebar corners: use ClipsDescendants on main panel + don't round sidebar at all
    - AbsolutePosition timing: track cumulative tab widths manually, never use AbsolutePosition
    - Right column empty: explicit pixel sizes not scale-based
    - Icons: text abbreviation always visible, image overlay optional
    - Dropdown: popup repositioned every open via AbsolutePosition (safe since popup is always open)
    - Slider label: separate header row properly sized
    - ZIndex: acrylic=1-3, main=4, sidebar=5, content=6, cards=7-10, popups=20+
]]

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

-- ScreenGui
local Protect = (typeof(syn)=="table" and syn.protect_gui)
    or (typeof(protectgui)=="function" and protectgui)
    or function() end
local SG = Instance.new("ScreenGui")
SG.Name="LuminwareUI"; SG.ZIndexBehavior=Enum.ZIndexBehavior.Global
SG.ResetOnSpawn=false; pcall(Protect,SG)
SG.IgnoreGuiInset=true
SG.Parent=(typeof(gethui)=="function" and pcall(gethui) and gethui()) or CSG

local _genv={}
pcall(function() if typeof(getgenv)=="function" then _genv=getgenv() end end)

-- ================================================================
-- THEME / COLORS
-- ================================================================
local L = {
    Version  = "1.0.0",
    -- FROST (default)
    Accent   = Color3.fromRGB(35, 184, 241),
    BgDeep   = Color3.fromRGB(24, 23, 21),
    BgMid    = Color3.fromRGB(91, 89, 83),
    BgLight  = Color3.fromRGB(126, 124, 117),
    SideCol  = Color3.fromRGB(99, 97, 91),
    TextHi   = Color3.fromRGB(246, 246, 244),
    TextMid  = Color3.fromRGB(190, 189, 184),
    TextLow  = Color3.fromRGB(155, 153, 147),
    White    = Color3.new(1,1,1),

    Font     = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontSemi = Enum.Font.GothamSemibold,

    Toggles  = {},
    Options  = {},
    Registry = {},
    Signals  = {},
    Popups   = {},
    _aclean  = {},
    _currentTheme = "FROST",

    Themes = {
        FROST={Accent=Color3.fromRGB(35,184,241), BgDeep=Color3.fromRGB(24,23,21), BgMid=Color3.fromRGB(91,89,83), BgLight=Color3.fromRGB(126,124,117), SideCol=Color3.fromRGB(99,97,91)},
        VENOM={Accent=Color3.fromRGB(158,78,245), BgDeep=Color3.fromRGB(13,11,21),  BgMid=Color3.fromRGB(19,15,31),  BgLight=Color3.fromRGB(27,21,43),  SideCol=Color3.fromRGB(15,11,25)},
        BLOOD={Accent=Color3.fromRGB(215,52,52),  BgDeep=Color3.fromRGB(17,11,11),  BgMid=Color3.fromRGB(24,15,15),  BgLight=Color3.fromRGB(34,20,20),  SideCol=Color3.fromRGB(19,11,11)},
        EMBER={Accent=Color3.fromRGB(255,138,0),  BgDeep=Color3.fromRGB(17,13,9),   BgMid=Color3.fromRGB(25,19,11),  BgLight=Color3.fromRGB(35,27,15),  SideCol=Color3.fromRGB(19,13,9)},
        ACID ={Accent=Color3.fromRGB(115,215,0),  BgDeep=Color3.fromRGB(11,17,9),   BgMid=Color3.fromRGB(15,23,11),  BgLight=Color3.fromRGB(21,31,15),  SideCol=Color3.fromRGB(11,17,9)},
        GHOST={Accent=Color3.fromRGB(185,192,212),BgDeep=Color3.fromRGB(15,16,21),  BgMid=Color3.fromRGB(21,23,31),  BgLight=Color3.fromRGB(29,32,43),  SideCol=Color3.fromRGB(17,18,27)},
    },
}
_genv.Toggles=L.Toggles; _genv.Options=L.Options

-- ================================================================
-- HELPERS
-- ================================================================
local function TW(i,p,d,s,dir)
    if not i or not i.Parent then return end
    TS:Create(i,TweenInfo.new(d or 0.18,s or Enum.EasingStyle.Quint,dir or Enum.EasingDirection.Out),p):Play()
end

function L:N(cls,props)
    local i = type(cls)=="string" and Instance.new(cls) or cls
    for k,v in next,props do
        if k~="Parent" then pcall(function() i[k]=v end) end
    end
    if props.Parent then i.Parent=props.Parent end
    return i
end

function L:Cor(i,r) return self:N("UICorner",{CornerRadius=UDim.new(0,r or 8),Parent=i}) end

function L:Str(i,col,th,tr)
    return self:N("UIStroke",{
        Color=col or self.White, Thickness=th or 1,
        Transparency=tr or 0.88,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
        Parent=i,
    })
end

function L:Reg(i,p,k) table.insert(self.Registry,{inst=i,prop=p,key=k}) end
function L:Sig(s) table.insert(self.Signals,s) end
function L:CB(f,...) if type(f)=="function" then pcall(f,...) end end
L.SafeCallback=L.CB

function L:SetTheme(name)
    local t=self.Themes[name]; if not t then return end
    self._currentTheme=name
    for k,v in next,t do self[k]=v end
    for _,r in next,self.Registry do
        if r.inst and r.inst.Parent then
            local c=self[r.key]
            if typeof(c)=="Color3" then TW(r.inst,{[r.prop]=c},0.3) end
        end
    end
    if self._onTheme then self._onTheme(name) end
    self:Notify({Title="Theme: "..name,Duration=2})
end

-- ================================================================
-- NOTIFICATIONS
-- ================================================================
local NA=L:N("Frame",{
    BackgroundTransparency=1,AnchorPoint=Vector2.new(1,1),
    Position=UDim2.new(1,-16,1,-16),Size=UDim2.fromOffset(290,500),
    ZIndex=200,Parent=SG,
})
L:N("UIListLayout",{
    VerticalAlignment=Enum.VerticalAlignment.Bottom,
    HorizontalAlignment=Enum.HorizontalAlignment.Right,
    FillDirection=Enum.FillDirection.Vertical,
    Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,
    Parent=NA,
})

function L:Notify(opts)
    opts=type(opts)=="string" and {Title=opts,Duration=4} or opts
    opts.Body=opts.Body or opts.Content or opts.SubContent
    local dur=opts.Duration or 4
    local h=opts.Body and 66 or 46
    local c=self:N("Frame",{
        BackgroundColor3=self.BgMid,BackgroundTransparency=0.08,
        Size=UDim2.new(1,0,0,h),ClipsDescendants=true,ZIndex=201,Parent=NA,
    })
    self:Cor(c,10); self:Str(c,self.White,1,0.82)
    local bar=self:N("Frame",{BackgroundColor3=self.Accent,BorderSizePixel=0,
        Size=UDim2.fromOffset(3,h),ZIndex=202,Parent=c})
    self:Reg(bar,"BackgroundColor3","Accent")
    self:N("TextLabel",{BackgroundTransparency=1,Font=self.FontBold,
        Text=opts.Title or "",TextColor3=self.TextHi,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(14,opts.Body and 7 or 14),
        Size=UDim2.new(1,-18,0,18),ZIndex=202,Parent=c})
    if opts.Body then
        self:N("TextLabel",{BackgroundTransparency=1,Font=self.Font,
            Text=opts.Body,TextColor3=self.TextMid,TextSize=12,
            TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(14,27),Size=UDim2.new(1,-18,0,30),
            ZIndex=202,Parent=c})
    end
    local prog=self:N("Frame",{BackgroundColor3=self.Accent,BackgroundTransparency=0.6,
        BorderSizePixel=0,AnchorPoint=Vector2.new(0,1),
        Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,2),ZIndex=203,Parent=c})
    self:Reg(prog,"BackgroundColor3","Accent")
    c.BackgroundTransparency=1; TW(c,{BackgroundTransparency=0.08},0.2)
    TW(prog,{Size=UDim2.fromOffset(0,2)},dur,Enum.EasingStyle.Linear)
    task.delay(dur,function() TW(c,{BackgroundTransparency=1},0.22) task.wait(0.28) pcall(function()c:Destroy()end) end)
end

-- ================================================================
-- DRAG
-- ================================================================
function L:Drag(handle,target,maxY)
    local dn,s0,p0=false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if maxY and (Mouse.Y-handle.AbsolutePosition.Y)>maxY then return end
        dn=true; s0=Vector2.new(Mouse.X,Mouse.Y); p0=target.Position
    end)
    UIS.InputChanged:Connect(function(i)
        if not dn or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d=Vector2.new(Mouse.X,Mouse.Y)-s0
        target.Position=UDim2.new(p0.X.Scale,p0.X.Offset+d.X,p0.Y.Scale,p0.Y.Offset+d.Y)
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dn=false end
    end)
end

-- ================================================================
-- ACRYLIC (7kayoh/Fluent technique)
-- ================================================================
local function MakeAcrylic(parent)
    local vp=Instance.new("ViewportFrame")
    vp.BackgroundTransparency=1; vp.Size=UDim2.fromScale(1,1); vp.ZIndex=1
    vp.Ambient=Color3.fromRGB(18,20,30)
    vp.LightColor=Color3.fromRGB(220,225,255)
    vp.LightDirection=Vector3.new(-1,-2,-1)
    vp.Parent=parent

    local vpCam=Instance.new("Camera"); vpCam.FieldOfView=Cam.FieldOfView
    vp.CurrentCamera=vpCam; vpCam.Parent=vp

    local dof=Instance.new("DepthOfFieldEffect")
    dof.FocusDistance=0; dof.InFocusRadius=0.1
    dof.NearIntensity=1; dof.FarIntensity=0; dof.Enabled=true; dof.Parent=vpCam

    local folder=Instance.new("Folder"); folder.Name="_LWAcrylic"; folder.Parent=WS

    local function mkPart()
        local p=Instance.new("Part")
        p.Material=Enum.Material.Glass; p.Color=Color3.fromRGB(22,25,38)
        p.Transparency=0.82; p.Reflectance=0; p.Anchored=true
        p.CanCollide=false; p.CastShadow=false
        p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
        return p
    end
    local wsPart=mkPart(); wsPart.Parent=folder
    local vpPart=mkPart(); vpPart.Parent=vp

    -- Overlay tint
    local ov=Instance.new("Frame")
    ov.BackgroundColor3=Color3.fromRGB(15,17,26); ov.BackgroundTransparency=0.3
    ov.BorderSizePixel=0; ov.Size=UDim2.fromScale(1,1); ov.ZIndex=2; ov.Parent=parent

    local conn=RS.RenderStepped:Connect(function()
        local cf=Cam.CFrame; local fov=Cam.FieldOfView; local dist=2
        local pcf=cf*CFrame.new(0,0,-dist)
        wsPart.CFrame=pcf; vpPart.CFrame=pcf
        local abs=vp.AbsoluteSize
        if abs.X>0 and abs.Y>0 then
            local hH=math.tan(math.rad(fov*0.5))*dist
            local hW=hH*(abs.X/abs.Y)
            local sz=Vector3.new(hW*2+0.5,hH*2+0.5,0.05)
            wsPart.Size=sz; vpPart.Size=sz
        end
        vpCam.CFrame=cf; vpCam.FieldOfView=fov
    end)

    return ov, function() conn:Disconnect(); pcall(function()folder:Destroy()end) end
end

-- ================================================================
-- LOADING SCREEN
-- ================================================================
function L:ShowLoading(done)
    local ov=self:N("Frame",{BackgroundColor3=self.BgDeep,BackgroundTransparency=0,
        Size=UDim2.fromScale(1,1),ZIndex=100,Parent=SG})
    local dia=self:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.43,0),Size=UDim2.fromOffset(0,0),
        BackgroundColor3=self.Accent,Rotation=45,BorderSizePixel=0,ZIndex=101,Parent=ov})
    self:Cor(dia,8); self:Reg(dia,"BackgroundColor3","Accent")
    local ttl=self:N("TextLabel",{BackgroundTransparency=1,Font=self.FontBold,
        Text="LUMINWARE",TextColor3=self.TextHi,TextSize=22,TextTransparency=1,
        AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0.52,0),
        Size=UDim2.new(1,0,0,28),TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=101,Parent=ov})
    local sub=self:N("TextLabel",{BackgroundTransparency=1,Font=self.Font,
        Text="INITIALIZING...",TextColor3=self.TextLow,TextSize=11,
        AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0.585,0),
        Size=UDim2.new(1,0,0,16),TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=101,Parent=ov})
    local bbg=self:N("Frame",{AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.new(0.5,0,0.62,0),Size=UDim2.fromOffset(170,3),
        BackgroundColor3=self.BgLight,BorderSizePixel=0,ZIndex=101,Parent=ov})
    self:Cor(bbg,2)
    local bf=self:N("Frame",{BackgroundColor3=self.Accent,BorderSizePixel=0,
        Size=UDim2.new(0,0,1,0),ZIndex=102,Parent=bbg})
    self:Cor(bf,2); self:Reg(bf,"BackgroundColor3","Accent")
    TW(dia,{Size=UDim2.fromOffset(50,50)},0.38,Enum.EasingStyle.Back)
    task.wait(0.28); TW(ttl,{TextTransparency=0},0.28)
    local msgs={"LOADING MODULES...","PATCHING MEMORY...","READY"}
    for n,m in ipairs(msgs) do
        sub.Text=m; TW(bf,{Size=UDim2.new(n/#msgs,0,1,0)},0.32,Enum.EasingStyle.Quint)
        task.wait(0.38)
    end
    task.wait(0.08); TW(ov,{BackgroundTransparency=1},0.35); task.wait(0.4)
    pcall(function()ov:Destroy()end); if done then done() end
end

-- ================================================================
-- CARD / ELEMENT FACTORY
-- ================================================================
local function NewCard(L, col, title)
    local card=L:N("Frame",{
        BackgroundColor3=L.BgMid,BackgroundTransparency=0.15,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=7,Parent=col,
    })
    L:Cor(card,10); L:Str(card,L.White,1,0.91); L:Reg(card,"BackgroundColor3","BgMid")
    -- top highlight
    L:N("Frame",{BackgroundColor3=L.White,BackgroundTransparency=0.89,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,1),ZIndex=8,Parent=card})

    if title and title~="" then
        local hdr=L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,30),ZIndex=8,Parent=card})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=string.upper(title),TextColor3=L.TextLow,TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-28,1,0),ZIndex=9,Parent=hdr})
        L:N("Frame",{BackgroundColor3=L.White,BackgroundTransparency=0.91,BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
            Size=UDim2.new(1,0,0,1),ZIndex=9,Parent=hdr})
    end

    local body=L:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,title~="" and 30 or 0),
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=8,Parent=card})
    L:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,Parent=body})
    L:N("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),
        PaddingBottom=UDim.new(0,10),Parent=body})

    local function Row(h)
        return L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h or 40),ZIndex=9,Parent=body})
    end
    local function LblL(par,txt)
        return L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,
            Text=txt or "",TextColor3=L.TextHi,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(0.6,0,1,0),ZIndex=10,Parent=par})
    end

    local Card={}

    function Card:AddParagraph(info)
        info=type(info)=="string" and {Title=info} or (info or {})
        local text=info.Content or info.Description or ""
        local lines=math.max(1,select(2,string.gsub(text,"\n","\n"))+1)
        local row=Row(30+(lines*16))
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=info.Title or info.Label or "Paragraph",TextColor3=L.TextHi,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
            Size=UDim2.new(1,0,0,22),ZIndex=10,Parent=row})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,
            Text=text,TextColor3=L.TextMid,TextSize=11,TextWrapped=true,
            TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
            Position=UDim2.fromOffset(0,22),Size=UDim2.new(1,0,1,-22),ZIndex=10,Parent=row})
        return row
    end

    -- TOGGLE
    function Card:AddToggle(idx,info)
        info=info or {}
        local row=Row(40); local lbl=LblL(row,info.Title or info.Label or info.Text or idx)
        local track=L:N("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
            Size=UDim2.fromOffset(40,22),BackgroundColor3=L.BgLight,ZIndex=10,Parent=row})
        L:Cor(track,11); L:Reg(track,"BackgroundColor3","BgLight")
        local knob=L:N("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,2,0.5,0),
            Size=UDim2.fromOffset(18,18),BackgroundColor3=L.TextMid,ZIndex=11,Parent=track})
        L:Cor(knob,9)
        local T={Value=not not info.Default,Type="Toggle",Callback=info.Callback or function()end,Addons={}}
        function T:Render(an)
            local tc=self.Value and L.Accent or L.BgLight
            local kc=self.Value and L.White or L.TextMid
            local kp=self.Value and UDim2.new(1,-20,0.5,0) or UDim2.new(0,2,0.5,0)
            if an then TW(track,{BackgroundColor3=tc},0.16);TW(knob,{BackgroundColor3=kc,Position=kp},0.16)
            else track.BackgroundColor3=tc;knob.BackgroundColor3=kc;knob.Position=kp end
            for _,r in next,L.Registry do if r.inst==track then r.key=self.Value and "Accent" or "BgLight" end end
        end
        function T:SetValue(v) self.Value=not not v;self:Render(true);L:CB(self.Callback,self.Value);L:CB(self.Changed,self.Value) end
        function T:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        local hit=L:N("TextButton",{BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1),ZIndex=12,Parent=row})
        hit.Activated:Connect(function() T:SetValue(not T.Value) end)
        hit.MouseEnter:Connect(function() TW(lbl,{TextColor3=L.Accent},0.1) end)
        hit.MouseLeave:Connect(function() TW(lbl,{TextColor3=L.TextHi},0.1) end)
        T:Render(false); L.Toggles[idx]=T; L.Options[idx]=T; return T
    end

    -- SLIDER
    function Card:AddSlider(idx,info)
        info=info or {}
        local mn=info.Min or 0;local mx=info.Max or 100;local def=info.Default or mn;local suf=info.Suffix or ""
        local wrap=L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,50),ZIndex=9,Parent=body})
        -- header row: label + value on same line
        local hrow=L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),ZIndex=10,Parent=wrap})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,
            Text=info.Title or info.Label or info.Text or idx,TextColor3=L.TextHi,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(0.65,0,1,0),ZIndex=11,Parent=hrow})
        local vLbl=L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=tostring(def)..suf,TextColor3=L.Accent,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Right,
            AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),
            Size=UDim2.new(0.35,0,1,0),ZIndex=11,Parent=hrow})
        L:Reg(vLbl,"TextColor3","Accent")
        -- track
        local trk=L:N("Frame",{BorderSizePixel=0,Position=UDim2.fromOffset(0,26),
            BackgroundColor3=L.BgLight,Size=UDim2.new(1,0,0,4),ZIndex=10,Parent=wrap})
        L:Cor(trk,2); L:Reg(trk,"BackgroundColor3","BgLight")
        local fill=L:N("Frame",{BackgroundColor3=L.Accent,BorderSizePixel=0,
            Size=UDim2.new(0,0,1,0),ZIndex=11,Parent=trk})
        L:Cor(fill,2); L:Reg(fill,"BackgroundColor3","Accent")
        local knob=L:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,0,0.5,0),
            Size=UDim2.fromOffset(14,14),BackgroundColor3=L.Accent,ZIndex=12,Parent=trk})
        L:Cor(knob,7); L:Reg(knob,"BackgroundColor3","Accent")
        L:N("UIStroke",{Color=L.White,Thickness=2,Transparency=0.74,
            ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=knob})
        local S={Value=def,Min=mn,Max=mx,Rounding=info.Rounding or 0,Type="Slider",Callback=info.Callback or function()end}
        local function rnd(v) if S.Rounding==0 then return math.floor(v+0.5) end
            return tonumber(string.format("%."..S.Rounding.."f",v)) end
        function S:Render()
            local p=math.clamp((self.Value-mn)/(mx-mn),0,1)
            fill.Size=UDim2.new(p,0,1,0);knob.Position=UDim2.new(p,0,0.5,0)
            vLbl.Text=tostring(self.Value)..suf
        end
        function S:SetValue(v) local n=tonumber(v);if not n then return end
            self.Value=rnd(math.clamp(n,mn,mx));self:Render()
            L:CB(self.Callback,self.Value);L:CB(self.Changed,self.Value) end
        function S:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        local function drag()
            local c;c=RS.Heartbeat:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                local p=math.clamp((Mouse.X-trk.AbsolutePosition.X)/trk.AbsoluteSize.X,0,1)
                S:SetValue(mn+p*(mx-mn))
            end)
        end
        trk.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag() end end)
        knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag() end end)
        S:Render(); L.Options[idx]=S; return S
    end

    -- BUTTON
    function Card:AddButton(info)
        info=type(info)=="string" and {Label=info} or info
        local row=Row(40); LblL(row,info.Title or info.Label or info.Text or "")
        local btn=L:N("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
            BackgroundColor3=L.BgLight,BackgroundTransparency=0.2,
            Font=L.FontSemi,Text=info.Action or "Execute",TextColor3=L.TextHi,TextSize=12,
            Size=UDim2.fromOffset(84,28),ZIndex=10,Parent=row})
        L:Cor(btn,7); L:Str(btn,L.White,1,0.85)
        btn.Activated:Connect(function()
            TW(btn,{BackgroundColor3=L.Accent},0.07)
            task.delay(0.15,function() TW(btn,{BackgroundColor3=L.BgLight},0.2) end)
            L:CB(info.Callback or info.Func)
        end)
        btn.MouseEnter:Connect(function() TW(btn,{BackgroundTransparency=0.0},0.1) end)
        btn.MouseLeave:Connect(function() TW(btn,{BackgroundTransparency=0.2},0.1) end)
        return btn
    end

    -- DROPDOWN
    function Card:AddDropdown(idx,info)
        info=info or {}
        local wrap=L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,58),ZIndex=9,Parent=body})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,
            Text=info.Title or info.Label or info.Text or idx,TextColor3=L.TextHi,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,0,0,20),ZIndex=10,Parent=wrap})
        local frame=L:N("Frame",{BackgroundColor3=L.BgLight,BackgroundTransparency=0.12,
            BorderSizePixel=0,Position=UDim2.fromOffset(0,22),Size=UDim2.new(1,0,0,30),
            ZIndex=10,Parent=wrap})
        L:Cor(frame,7); L:Str(frame,L.White,1,0.83); L:Reg(frame,"BackgroundColor3","BgLight")
        local sel=L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=tostring(info.Default or "--"),TextColor3=L.TextHi,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-34,1,0),ZIndex=11,Parent=frame})
        local arr=L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontBold,
            Text="v",TextColor3=L.TextMid,TextSize=14,
            AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-9,0.5,0),
            Size=UDim2.fromOffset(16,16),ZIndex=11,Parent=frame})

        local initial=info.Default
        if not info.Multi and type(initial)=="number" then initial=(info.Values or {})[initial] end
        if info.Multi then
            local mapped={}
            for _,v in ipairs(initial or {}) do mapped[v]=true end
            initial=mapped
        end
        local DD={Value=initial,Values=info.Values or {},Multi=not not info.Multi,
            Type="Dropdown",Callback=info.Callback or function()end}
        local function display()
            if not DD.Multi then return tostring(DD.Value or "--") end
            local values={}
            for _,v in ipairs(DD.Values) do if DD.Value[v] then table.insert(values,tostring(v)) end end
            return #values>0 and table.concat(values,", ") or "--"
        end
        sel.Text=display()

        -- popup parented to SG
        local pop=L:N("Frame",{BackgroundColor3=L.BgMid,BackgroundTransparency=0.04,
            BorderSizePixel=0,ZIndex=50,Visible=false,Parent=SG})
        L:Cor(pop,8); L:Str(pop,L.White,1,0.78); L:Reg(pop,"BackgroundColor3","BgMid")
        L:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
            SortOrder=Enum.SortOrder.LayoutOrder,Parent=pop})
        L:N("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=pop})

        local function close()
            pop.Visible=false; TW(arr,{Rotation=0},0.12)
        end
        table.insert(L.Popups,close)

        local function build()
            for _,c in next,pop:GetChildren() do if c:IsA("TextButton") then c:Destroy() end end
            for _,v in next,DD.Values do
                local isSel=DD.Multi and DD.Value[v] or (v==DD.Value)
                local it=L:N("TextButton",{BackgroundColor3=isSel and L.Accent or L.BgLight,
                    BackgroundTransparency=isSel and 0.72 or 0.9,Font=L.FontSemi,Text="",
                    Size=UDim2.new(1,0,0,30),ZIndex=51,Parent=pop})
                L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
                    Text=tostring(v),TextColor3=isSel and L.TextHi or L.TextMid,TextSize=13,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-10,1,0),ZIndex=52,Parent=it})
                local vv=v
                it.Activated:Connect(function()
                    if DD.Multi then DD.Value[vv]=not DD.Value[vv] else DD.Value=vv;close() end
                    sel.Text=display();build()
                    L:CB(DD.Callback,DD.Value); L:CB(DD.Changed,DD.Value)
                end)
                it.MouseEnter:Connect(function() if not isSel then TW(it,{BackgroundTransparency=0.7},0.07) end end)
                it.MouseLeave:Connect(function() if not isSel then TW(it,{BackgroundTransparency=0.9},0.07) end end)
            end
            local n=math.min(#DD.Values,8)
            pop.Size=UDim2.fromOffset(frame.AbsoluteSize.X,n*30+8)
            pop.Position=UDim2.fromOffset(frame.AbsolutePosition.X,frame.AbsolutePosition.Y+frame.AbsoluteSize.Y+3)
        end

        local hit=L:N("TextButton",{BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1),ZIndex=12,Parent=frame})
        hit.Activated:Connect(function()
            if pop.Visible then close()
            else for _,fn in next,L.Popups do fn() end; build(); pop.Visible=true; TW(arr,{Rotation=180},0.12) end
        end)

        function DD:SetValue(v) self.Value=v or (self.Multi and {} or nil);sel.Text=display();build();L:CB(self.Callback,self.Value);L:CB(self.Changed,self.Value) end
        function DD:SetValues(vs) self.Values=vs;build() end
        function DD:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        L.Options[idx]=DD; return DD
    end

    -- INPUT
    function Card:AddInput(idx,info)
        info=info or {}
        local wrap=L:N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,58),ZIndex=9,Parent=body})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,
            Text=info.Title or info.Label or info.Text or idx,TextColor3=L.TextHi,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,0,0,20),ZIndex=10,Parent=wrap})
        local box=L:N("TextBox",{BackgroundColor3=L.BgLight,BackgroundTransparency=0.12,
            Font=L.Font,Text=info.Default or "",PlaceholderText=info.Placeholder or "",
            PlaceholderColor3=L.TextLow,TextColor3=L.TextHi,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,
            Position=UDim2.fromOffset(0,22),Size=UDim2.new(1,0,0,30),ZIndex=10,Parent=wrap})
        L:Cor(box,7); L:Str(box,L.White,1,0.83)
        L:N("UIPadding",{PaddingLeft=UDim.new(0,10),Parent=box})
        local I={Value=info.Default or "",Type="Input",Callback=info.Callback or function()end}
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if info.Numeric and not tonumber(box.Text) and #box.Text>0 then box.Text=I.Value;return end
            I.Value=box.Text; if not info.Finished then L:CB(I.Callback,I.Value) end
        end)
        box.FocusLost:Connect(function(e) if info.Finished and e then L:CB(I.Callback,I.Value) end; L:CB(I.Changed,I.Value) end)
        function I:SetValue(v) box.Text=tostring(v);self.Value=tostring(v) end
        function I:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        L.Options[idx]=I; return I
    end

    -- KEYBIND
    function Card:AddKeybind(idx,info)
        info=info or {}
        local row=Row(40); LblL(row,info.Title or info.Label or info.Text or idx)
        local kbtn=L:N("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
            BackgroundColor3=L.BgLight,BackgroundTransparency=0.12,
            Font=L.FontSemi,Text=info.Default or "None",TextColor3=L.Accent,TextSize=12,
            Size=UDim2.fromOffset(70,26),ZIndex=10,Parent=row})
        L:Cor(kbtn,6); L:Str(kbtn,L.White,1,0.83); L:Reg(kbtn,"TextColor3","Accent")
        local KP={Value=info.Default or "None",Mode=info.Mode or "Toggle",
            Toggled=false,Type="KeyPicker",Callback=info.Callback or function()end,
            ChangedCallback=info.ChangedCallback}
        local function inputName(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then return "MB1" end
            if i.UserInputType==Enum.UserInputType.MouseButton2 then return "MB2" end
            if i.UserInputType==Enum.UserInputType.Keyboard then return i.KeyCode.Name end
        end
        local function matches(i) return inputName(i)==KP.Value end
        local picking=false
        kbtn.Activated:Connect(function()
            if picking then return end; picking=true; kbtn.Text="..."
            local c; c=UIS.InputBegan:Connect(function(i)
                local name=inputName(i)
                if not name then return end
                KP.Value=name;kbtn.Text=name;picking=false;c:Disconnect()
                L:CB(KP.ChangedCallback,name);L:CB(KP.Changed,name)
            end)
        end)
        UIS.InputBegan:Connect(function(i,gp)
            if picking then return end
            if not gp and matches(i) then
                if KP.Mode=="Toggle" then KP.Toggled=not KP.Toggled else KP.Toggled=true end
                L:CB(KP.Callback,KP.Toggled);L:CB(KP.Clicked,KP.Toggled)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if matches(i) and KP.Mode=="Hold" then KP.Toggled=false;L:CB(KP.Callback,false) end
        end)
        function KP:GetState() return self.Mode=="Always" or self.Toggled end
        function KP:SetValue(d,mode)
            local key=type(d)=="table" and d[1] or d
            self.Value=key or "None";self.Mode=mode or (type(d)=="table" and d[2]) or self.Mode;kbtn.Text=self.Value
            L:CB(self.ChangedCallback,self.Value);L:CB(self.Changed,self.Value)
        end
        function KP:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function KP:OnClick(fn) self.Clicked=fn end
        L.Options[idx]=KP; return KP
    end

    -- COLOR PICKER
    function Card:AddColorPicker(idx,info)
        info=info or {}
        local row=Row(40); LblL(row,info.Label or info.Title or idx)
        local sw=L:N("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
            BackgroundColor3=info.Default or L.Accent,Size=UDim2.fromOffset(38,20),
            Text="",ZIndex=10,Parent=row})
        L:Cor(sw,5); L:Str(sw,L.White,1,0.82)
        local CP={Value=info.Default or L.Accent,Transparency=info.Transparency or 0,
            Type="ColorPicker",Callback=info.Callback or function()end}
        function CP:SetHSV(c) self.Hue,self.Sat,self.Vib=Color3.toHSV(c) end
        CP:SetHSV(CP.Value)
        local pop=L:N("Frame",{BackgroundColor3=L.BgMid,BackgroundTransparency=0.04,
            BorderSizePixel=0,Size=UDim2.fromOffset(224,252),Visible=false,ZIndex=50,Parent=SG})
        L:Cor(pop,10); L:Str(pop,L.White,1,0.78); L:Reg(pop,"BackgroundColor3","BgMid")
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=info.Title or "Color",TextColor3=L.TextHi,TextSize=13,
            Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,20),ZIndex=51,Parent=pop})
        local svM=L:N("ImageLabel",{BorderSizePixel=0,Position=UDim2.fromOffset(10,32),
            Size=UDim2.fromOffset(164,164),Image="rbxassetid://4155801252",ZIndex=51,Parent=pop})
        L:Cor(svM,5)
        local svC=L:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(10,10),
            BackgroundColor3=L.White,ZIndex=52,Parent=svM})
        L:Cor(svC,5); L:N("UIStroke",{Color=Color3.new(0,0,0),Thickness=1.5,Parent=svC})
        local hB=L:N("Frame",{BorderSizePixel=0,Position=UDim2.fromOffset(180,32),
            Size=UDim2.fromOffset(14,164),ZIndex=51,Parent=pop})
        L:Cor(hB,4)
        local hSeq={}; for i=0,10 do hSeq[#hSeq+1]=ColorSequenceKeypoint.new(i/10,Color3.fromHSV(i/10,1,1)) end
        L:N("UIGradient",{Color=ColorSequence.new(hSeq),Rotation=90,Parent=hB})
        local hC=L:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=L.White,
            BorderSizePixel=0,Size=UDim2.fromOffset(14,4),ZIndex=52,Parent=hB})
        local hexB=L:N("TextBox",{BackgroundColor3=L.BgLight,BackgroundTransparency=0.5,
            Font=L.Font,Text="#"..CP.Value:ToHex():upper(),PlaceholderText="#FFFFFF",
            TextColor3=L.TextHi,TextSize=12,ClearTextOnFocus=false,
            Position=UDim2.fromOffset(10,204),Size=UDim2.fromOffset(100,28),ZIndex=51,Parent=pop})
        L:Cor(hexB,5); L:N("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=hexB})
        function CP:Display()
            self.Value=Color3.fromHSV(self.Hue,self.Sat,self.Vib)
            svM.BackgroundColor3=Color3.fromHSV(self.Hue,1,1)
            sw.BackgroundColor3=self.Value
            svC.Position=UDim2.new(self.Sat,0,1-self.Vib,0)
            hC.Position=UDim2.new(0,0,self.Hue,0)
            hexB.Text="#"..self.Value:ToHex():upper()
            L:CB(self.Callback,self.Value); L:CB(self.Changed,self.Value)
        end
        svM.InputBegan:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local c;c=RS.Heartbeat:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                CP.Sat=math.clamp((Mouse.X-svM.AbsolutePosition.X)/svM.AbsoluteSize.X,0,1)
                CP.Vib=1-math.clamp((Mouse.Y-svM.AbsolutePosition.Y)/svM.AbsoluteSize.Y,0,1)
                CP:Display()
            end)
        end)
        hB.InputBegan:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local c;c=RS.Heartbeat:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect();return end
                CP.Hue=math.clamp((Mouse.Y-hB.AbsolutePosition.Y)/hB.AbsoluteSize.Y,0,1)
                CP:Display()
            end)
        end)
        hexB.FocusLost:Connect(function(e)
            if not e then return end
            local ok,col=pcall(Color3.fromHex,hexB.Text); if ok then CP:SetHSV(col);CP:Display() end
        end)
        local open=false
        sw.Activated:Connect(function()
            open=not open
            if open then
                for _,fn in next,L.Popups do fn() end
                pop.Position=UDim2.fromOffset(
                    math.max(4,sw.AbsolutePosition.X-224),
                    sw.AbsolutePosition.Y+2)
                pop.Visible=true
            else pop.Visible=false end
        end)
        table.insert(L.Popups,function() pop.Visible=false;open=false end)
        function CP:SetValueRGB(c,t) self.Transparency=t or 0;self:SetHSV(c);self:Display() end
        function CP:SetValue(h,t) self.Transparency=t or 0;self:SetHSV(Color3.fromHSV(h[1],h[2],h[3]));self:Display() end
        function CP:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        CP:Display(); L.Options[idx]=CP; return CP
    end
    Card.AddColorpicker=Card.AddColorPicker

    return Card
end

-- ================================================================
-- SCROLL COLUMN
-- ================================================================
local function NewScrollCol(L, parent, xOff, widthPx, height)
    local col=L:N("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.fromOffset(xOff+5,4),
        Size=UDim2.fromOffset(widthPx-10,height-8),
        CanvasSize=UDim2.fromOffset(0,0),
        ScrollBarThickness=3,
        ScrollBarImageColor3=L.Accent,
        ScrollBarImageTransparency=0.5,
        TopImage="",BottomImage="",
        ZIndex=6,Parent=parent})
    L:Reg(col,"ScrollBarImageColor3","Accent")
    local lay=L:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
        SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8),Parent=col})
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        col.CanvasSize=UDim2.fromOffset(0,lay.AbsoluteContentSize.Y+8)
    end)
    return col
end

-- ================================================================
-- CREATE WINDOW
-- ================================================================
function L:CreateWindow(cfg)
    cfg=cfg or {}
    if cfg.Theme=="Dark" then cfg.Theme="FROST" end
    if cfg.Theme and self.Themes[string.upper(cfg.Theme)] then self:SetTheme(string.upper(cfg.Theme)) end
    local function px(axis, fallback)
        if not cfg.Size then return fallback end
        local value=cfg.Size[axis]
        if typeof(value)=="UDim" then return value.Offset end
        return tonumber(value) or fallback
    end
    local WW  = px("X",900)
    local WH  = px("Y",560)
    local logoId = cfg.Logo or ""
    local useAcr = cfg.Acrylic ~= false

    local Win={Tabs={},_tabOrder={},Size=UDim2.fromOffset(WW,WH)}

    -- ROOT
    local Root=self:N("Frame",{BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(WW,WH),ZIndex=2,Visible=false,Parent=SG})

    -- MINIMIZE ICON
    local MinIcon=self:N("Frame",{BackgroundColor3=self.BgMid,BackgroundTransparency=0.08,
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(56,56),Visible=false,ZIndex=80,Parent=SG})
    self:Cor(MinIcon,14); self:Str(MinIcon,self.White,1,0.78); self:Drag(MinIcon,MinIcon)
    if logoId~="" then
        self:N("ImageLabel",{BackgroundTransparency=1,Image=logoId,
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(34,34),ScaleType=Enum.ScaleType.Fit,ZIndex=81,Parent=MinIcon})
    else
        local d=self:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(20,20),BackgroundColor3=self.Accent,Rotation=45,
            BorderSizePixel=0,ZIndex=81,Parent=MinIcon})
        self:Cor(d,4); self:Reg(d,"BackgroundColor3","Accent")
    end
    self:N("TextButton",{BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1),
        ZIndex=82,Parent=MinIcon}).Activated:Connect(function()
        MinIcon.Visible=false; Root.Visible=true end)

    -- Main panel clips acrylic inside rounded corners.
    local Main=self:N("Frame",{BackgroundColor3=self.BgDeep,BackgroundTransparency=0.04,
        BorderSizePixel=0,Size=UDim2.fromScale(1,1),
        ClipsDescendants=true,ZIndex=2,Parent=Root})
    self:Cor(Main,14); self:Str(Main,self.White,1,0.83); self:Reg(Main,"BackgroundColor3","BgDeep")
    self.Root=Root; self.Main=Main

    -- Acrylic behind everything
    if useAcr then
        local af=self:N("Frame",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=1,Parent=Main})
        self.AcrylicFrame=af
        local ov,cleanup=MakeAcrylic(af)
        self:Reg(ov,"BackgroundColor3","BgDeep")
        table.insert(self._aclean,cleanup)
    end

    -- top highlight line
    self:N("Frame",{BackgroundColor3=self.White,BackgroundTransparency=0.87,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,1),ZIndex=5,Parent=Main})

    -- Sidebar
    local SW=62
    -- Sidebar is a simple frame, no UICorner (Main handles the outer rounding)
    local SB=self:N("Frame",{BackgroundColor3=self.SideCol,BackgroundTransparency=0.04,
        BorderSizePixel=0,Size=UDim2.fromOffset(SW,WH),ZIndex=5,Parent=Main})
    self:Reg(SB,"BackgroundColor3","SideCol")
    -- right edge line
    self:N("Frame",{BackgroundColor3=self.White,BackgroundTransparency=0.88,BorderSizePixel=0,
        Position=UDim2.fromOffset(SW-1,0),Size=UDim2.fromOffset(1,WH),ZIndex=6,Parent=Main})

    -- Logo
    local logoH=58
    local logoArea=self:N("Frame",{BackgroundTransparency=1,Size=UDim2.fromOffset(SW,logoH),ZIndex=6,Parent=SB})
    if logoId~="" then
        self:N("ImageLabel",{BackgroundTransparency=1,Image=logoId,
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=7,Parent=logoArea})
    else
        local d=self:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(18,18),BackgroundColor3=self.Accent,Rotation=45,
            BorderSizePixel=0,ZIndex=7,Parent=logoArea})
        self:Cor(d,4); self:Reg(d,"BackgroundColor3","Accent")
    end
    -- logo bottom line
    self:N("Frame",{BackgroundColor3=self.White,BackgroundTransparency=0.90,BorderSizePixel=0,
        Position=UDim2.fromOffset(0,logoH-1),Size=UDim2.fromOffset(SW,1),ZIndex=6,Parent=SB})

    -- Nav list
    local NavList=self:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,logoH),Size=UDim2.new(1,0,1,-(logoH+80)),
        ZIndex=6,Parent=SB})
    self:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder,Parent=NavList})

    -- Active tab indicator (3px bar on right edge of sidebar)
    local NavInd=self:N("Frame",{BackgroundColor3=self.Accent,BorderSizePixel=0,
        Position=UDim2.fromOffset(SW-3,logoH+8),Size=UDim2.fromOffset(3,30),
        ZIndex=7,Parent=Main})
    self:Cor(NavInd,2); self:Reg(NavInd,"BackgroundColor3","Accent")

    -- Bottom buttons (minimize + close)
    local BotRow=self:N("Frame",{BackgroundTransparency=1,
        AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-8),
        Size=UDim2.fromOffset(SW,84),ZIndex=6,Parent=SB})
    self:N("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=BotRow})

    local function SBtn(txt,bg,fn)
        local b=self:N("TextButton",{BackgroundColor3=bg or self.BgLight,BackgroundTransparency=0.55,
            Size=UDim2.fromOffset(36,36),Font=self.FontBold,Text=txt,
            TextColor3=self.TextLow,TextSize=14,ZIndex=7,Parent=BotRow})
        self:Cor(b,9)
        b.MouseEnter:Connect(function() TW(b,{BackgroundTransparency=0.25,TextColor3=self.TextHi},0.1) end)
        b.MouseLeave:Connect(function() TW(b,{BackgroundTransparency=0.55,TextColor3=self.TextLow},0.1) end)
        b.Activated:Connect(fn); return b
    end
    SBtn("-",nil,function() Root.Visible=false; MinIcon.Visible=true end)
    SBtn("X",Color3.fromRGB(48,14,14),function()
        self:Notify({Title="Closing...",Duration=0.7})
        task.delay(0.6,function() self:Unload() end)
    end)

    -- Content area
    local Content=self:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(SW,0),Size=UDim2.fromOffset(WW-SW,WH),
        ZIndex=5,Parent=Main})

    -- Top bar
    local TopH=48
    local TopBar=self:N("Frame",{BackgroundTransparency=1,
        Size=UDim2.fromOffset(WW-SW,TopH),ZIndex=6,Parent=Content})
    self:Drag(TopBar,Root,TopH)
    self:N("TextLabel",{BackgroundTransparency=1,Font=self.FontBold,
        Text=string.upper(cfg.Title or "LUMINWARE"),TextColor3=self.TextHi,TextSize=15,
        TextXAlignment=Enum.TextXAlignment.Left,
        Position=UDim2.fromOffset(16,0),Size=UDim2.fromOffset((WW-SW)*0.6,TopH),
        ZIndex=7,Parent=TopBar})

    -- Top-right dots
    local DR=self:N("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-14,0.5,0),Size=UDim2.fromOffset(40,14),ZIndex=7,Parent=TopBar})
    self:N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Right,VerticalAlignment=Enum.VerticalAlignment.Center,
        Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,Parent=DR})
    local function Dot(col,fn)
        local d=self:N("TextButton",{BackgroundColor3=col,Size=UDim2.fromOffset(13,13),Text="",ZIndex=8,Parent=DR})
        self:Cor(d,7)
        d.MouseEnter:Connect(function() TW(d,{Size=UDim2.fromOffset(15,15)},0.09) end)
        d.MouseLeave:Connect(function() TW(d,{Size=UDim2.fromOffset(13,13)},0.09) end)
        d.Activated:Connect(fn)
    end
    Dot(Color3.fromRGB(255,188,44),function() Root.Visible=false; MinIcon.Visible=true end)
    Dot(Color3.fromRGB(254,96,87),function()
        self:Notify({Title="Closing...",Duration=0.7})
        task.delay(0.6,function() self:Unload() end)
    end)

    -- Divider under top bar
    self:N("Frame",{BackgroundColor3=self.White,BackgroundTransparency=0.88,BorderSizePixel=0,
        Position=UDim2.fromOffset(0,TopH-1),Size=UDim2.fromOffset(WW-SW,1),ZIndex=6,Parent=Content})

    -- Main tab row
    -- Key fix: track tab widths manually so we never need AbsolutePosition
    local TabRowH=32
    local TabRowY=TopH+1
    local tabXCursor=0   -- cumulative X offset for underline positioning

    local TabRowFrame=self:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(14,TabRowY),
        Size=UDim2.fromOffset(WW-SW-28,TabRowH),
        ZIndex=6,Parent=Content})
    self:N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
        VerticalAlignment=Enum.VerticalAlignment.Center,
        Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder,Parent=TabRowFrame})
    -- base line
    self:N("Frame",{BackgroundColor3=self.White,BackgroundTransparency=0.89,BorderSizePixel=0,
        AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
        Size=UDim2.new(1,0,0,1),ZIndex=7,Parent=TabRowFrame})
    -- active underline
    local TabUL=self:N("Frame",{BackgroundColor3=self.Accent,BorderSizePixel=0,
        AnchorPoint=Vector2.new(0,1),Position=UDim2.fromOffset(0,TabRowH),
        Size=UDim2.fromOffset(0,2),ZIndex=8,Parent=TabRowFrame})
    self:Cor(TabUL,1); self:Reg(TabUL,"BackgroundColor3","Accent")

    -- Divider below tab row
    self:N("Frame",{BackgroundColor3=self.White,BackgroundTransparency=0.90,BorderSizePixel=0,
        Position=UDim2.fromOffset(0,TabRowY+TabRowH),Size=UDim2.fromOffset(WW-SW,1),
        ZIndex=6,Parent=Content})

    -- Tab content host
    local TabHostY=TabRowY+TabRowH+2
    local TabHostH=WH-TabHostY
    local TabHost=self:N("Frame",{BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,TabHostY),
        Size=UDim2.fromOffset(WW-SW,TabHostH),
        ZIndex=5,Parent=Content})

    -- Add tab
    local NAV_ICONS={
        Aimbot="A", ESP="E", Movement="M", Misc="X", Settings="S",
    }

    function Win:AddTab(opts)
        opts=type(opts)=="string" and {Name=opts} or opts
        local name=opts.Name or opts.Title or "Tab"
        local Tab={_name=name,Subtabs={},_subtabOrder={}}

        -- NAV BUTTON (sidebar)
        local navBtn=L:N("TextButton",{BackgroundColor3=L.BgLight,BackgroundTransparency=1,
            Size=UDim2.fromOffset(44,44),Font=L.FontBold,
            Text=NAV_ICONS[name] or string.upper(string.sub(name,1,2)),
            TextColor3=L.TextLow,TextSize=16,ZIndex=7,Parent=NavList})
        L:Cor(navBtn,10)
        -- tooltip
        local tip=L:N("Frame",{BackgroundColor3=L.BgMid,BackgroundTransparency=0.04,
            BorderSizePixel=0,AnchorPoint=Vector2.new(0,0.5),
            Position=UDim2.new(1,6,0.5,0),Size=UDim2.fromOffset(0,24),
            Visible=false,ZIndex=30,Parent=navBtn,ClipsDescendants=true})
        self:Cor(tip,6); self:Str(tip)
        local tipLbl=L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=name,TextColor3=L.TextHi,TextSize=12,
            AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0.5,0),
            Size=UDim2.fromOffset(200,24),ZIndex=31,Parent=tip})
        navBtn.MouseEnter:Connect(function()
            local tw=tipLbl.TextBounds.X+16
            tip.Size=UDim2.fromOffset(tw,24); tip.Visible=true
        end)
        navBtn.MouseLeave:Connect(function() tip.Visible=false end)

        -- MAIN TAB BUTTON
        local TBW=80
        local myTabX=tabXCursor   -- capture current X for underline positioning
        tabXCursor=tabXCursor+TBW  -- advance cursor

        local tabBtn=L:N("TextButton",{BackgroundTransparency=1,Font=L.FontSemi,
            Text=name,TextColor3=L.TextMid,TextSize=14,
            Size=UDim2.fromOffset(TBW,TabRowH),ZIndex=7,Parent=TabRowFrame})

        -- TAB FRAME
        local tabFrm=L:N("Frame",{BackgroundTransparency=1,
            Size=UDim2.fromOffset(WW-SW,TabHostH),Visible=false,ZIndex=5,Parent=TabHost})

        -- SUBTAB ROW
        local SubRowH=28
        local subXCursor=0   -- for subtab underline

        local SubRow=L:N("Frame",{BackgroundTransparency=1,
            Position=UDim2.fromOffset(12,0),Size=UDim2.fromOffset(WW-SW-24,SubRowH),
            ZIndex=6,Parent=tabFrm})
        self:N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
            VerticalAlignment=Enum.VerticalAlignment.Center,
            Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder,Parent=SubRow})
        -- subtab base line
        self:N("Frame",{BackgroundColor3=L.White,BackgroundTransparency=0.89,BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
            Size=UDim2.new(1,0,0,1),ZIndex=7,Parent=SubRow})
        -- subtab underline
        local SubUL=L:N("Frame",{BackgroundColor3=L.Accent,BorderSizePixel=0,
            AnchorPoint=Vector2.new(0,1),Position=UDim2.fromOffset(0,SubRowH),
            Size=UDim2.fromOffset(0,2),ZIndex=8,Parent=SubRow})
        L:Cor(SubUL,1); L:Reg(SubUL,"BackgroundColor3","Accent")

        -- SUBTAB CONTENT HOST
        local SubHostY=SubRowH+4
        local SubHostH=TabHostH-SubHostY
        local SubHost=L:N("Frame",{BackgroundTransparency=1,
            Position=UDim2.fromOffset(0,SubHostY),
            Size=UDim2.fromOffset(WW-SW,SubHostH),
            ZIndex=5,Parent=tabFrm})

        -- Column widths (pixel-based, not scale)
        local colW=math.floor((WW-SW)/2)

        -- ADD SUBTAB
        function Tab:AddSubtab(subName)
            local Sub={_name=subName}
            local SBW=74
            local mySubX=subXCursor
            subXCursor=subXCursor+SBW

            local sBg=L:N("TextButton",{BackgroundTransparency=1,Font=L.FontSemi,
                Text=subName,TextColor3=L.TextMid,TextSize=13,
                Size=UDim2.fromOffset(SBW,SubRowH),ZIndex=7,Parent=SubRow})

            local sFrm=L:N("Frame",{BackgroundTransparency=1,
                Size=UDim2.fromOffset(WW-SW,SubHostH),Visible=false,ZIndex=5,Parent=SubHost})

            -- Two pixel-exact columns
            local leftCol =NewScrollCol(L,sFrm,0,       colW,    SubHostH)
            local rightCol=NewScrollCol(L,sFrm,colW,    colW,    SubHostH)

            local function Pane(col)
                local P={}
                function P:AddCard(t) return NewCard(L,col,t or "") end
                return P
            end
            Sub.Left=Pane(leftCol); Sub.Right=Pane(rightCol)

            function Sub:Show()
                for _,s in next,Tab.Subtabs do s:Hide() end
                sFrm.Visible=true; Sub._active=true
                TW(sBg,{TextColor3=L.TextHi},0.14)
                -- Use pre-computed X, no AbsolutePosition needed
                TW(SubUL,{Position=UDim2.fromOffset(mySubX,SubRowH),Size=UDim2.fromOffset(SBW,2)},0.18)
            end
            function Sub:Hide()
                sFrm.Visible=false; Sub._active=false
                TW(sBg,{TextColor3=L.TextMid},0.14)
            end
            sBg.Activated:Connect(function() Sub:Show() end)

            Tab.Subtabs[subName]=Sub; table.insert(Tab._subtabOrder,Sub)
            if #Tab._subtabOrder==1 then task.defer(function() Sub:Show() end) end
            return Sub
        end

        function Tab:_DefaultSubtab()
            if not self._defaultSubtab then
                self._defaultSubtab=self:AddSubtab("Main")
                self._nextColumn="Left"
            end
            return self._defaultSubtab
        end

        function Tab:AddSection(title)
            local sub=self:_DefaultSubtab()
            local side=self._nextColumn or "Left"
            self._nextColumn=side=="Left" and "Right" or "Left"
            return sub[side]:AddCard(title or "")
        end

        function Tab:_DefaultCard()
            if not self._defaultCard then self._defaultCard=self:AddSection("") end
            return self._defaultCard
        end

        for _,method in ipairs({"AddParagraph","AddButton","AddToggle","AddSlider","AddDropdown","AddInput","AddKeybind","AddColorPicker","AddColorpicker"}) do
            Tab[method]=function(self,...)
                local card=self:_DefaultCard()
                return card[method](card,...)
            end
        end

        -- SHOW / HIDE TAB
        local myNavY=0   -- will be set when first nav button is positioned

        function Tab:ShowTab()
            for _,t in next,Win.Tabs do t:HideTab() end
            tabFrm.Visible=true; Tab._active=true
            TW(navBtn,{BackgroundTransparency=0.76},0.14)
            TW(navBtn,{TextColor3=L.Accent},0.14)
            TW(tabBtn,{TextColor3=L.TextHi},0.14)
            -- Main tab underline uses pre-computed X.
            TW(TabUL,{Position=UDim2.fromOffset(myTabX,TabRowH),Size=UDim2.fromOffset(TBW,2)},0.18)
            -- Compute the nav indicator Y from the tab index.
            local idx=0
            for i,t in ipairs(Win._tabOrder) do if t==Tab then idx=i;break end end
            local navY=logoH+8+(idx-1)*(44+5)
            TW(NavInd,{Position=UDim2.fromOffset(SW-3,navY)},0.2)
        end
        function Tab:HideTab()
            tabFrm.Visible=false; Tab._active=false
            TW(navBtn,{BackgroundTransparency=1},0.14)
            TW(navBtn,{TextColor3=L.TextLow},0.14)
            TW(tabBtn,{TextColor3=L.TextMid},0.14)
        end

        navBtn.Activated:Connect(function() Tab:ShowTab() end)
        tabBtn.Activated:Connect(function() Tab:ShowTab() end)

        Win.Tabs[name]=Tab; table.insert(Win._tabOrder,Tab)
        if #Win._tabOrder==1 then task.defer(function() Tab:ShowTab() end) end
        return Tab
    end

    -- Global: close popups on outside click
    L:Sig(UIS.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            for _,fn in next,L.Popups do fn() end
        end
    end))
    -- RightShift toggle
    L:Sig(UIS.InputBegan:Connect(function(i,gp)
        if i.KeyCode==Enum.KeyCode.RightShift and not gp then
            Root.Visible=not Root.Visible
        end
    end))

    function Win:Toggle() Root.Visible=not Root.Visible end
    function Win:SelectTab(index)
        local tab=type(index)=="number" and self._tabOrder[index] or self.Tabs[index]
        if tab then tab:ShowTab() end
    end
    function Win:Minimize() Root.Visible=false; MinIcon.Visible=true end
    function Win:Dialog(info)
        info=info or {}
        local shade=L:N("TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0,0,0),
            BackgroundTransparency=0.35,Text="",Size=UDim2.fromScale(1,1),ZIndex=150,Parent=SG})
        local box=L:N("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(360,180),BackgroundColor3=L.BgMid,ZIndex=151,Parent=shade})
        L:Cor(box,16);L:Str(box,L.White,1,0.75)
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.FontBold,Text=info.Title or "Dialog",
            TextColor3=L.TextHi,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,
            Position=UDim2.fromOffset(18,12),Size=UDim2.new(1,-36,0,28),ZIndex=152,Parent=box})
        L:N("TextLabel",{BackgroundTransparency=1,Font=L.Font,Text=info.Content or "",
            TextColor3=L.TextMid,TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top,Position=UDim2.fromOffset(18,48),
            Size=UDim2.new(1,-36,0,70),ZIndex=152,Parent=box})
        local row=L:N("Frame",{BackgroundTransparency=1,Position=UDim2.new(0,18,1,-48),
            Size=UDim2.new(1,-36,0,32),ZIndex=152,Parent=box})
        L:N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,
            Padding=UDim.new(0,8),Parent=row})
        for _,button in ipairs(info.Buttons or {{Title="Okay"}}) do
            local b=L:N("TextButton",{BackgroundColor3=L.BgLight,Text=button.Title or "Okay",Font=L.FontSemi,
                TextColor3=L.TextHi,TextSize=12,Size=UDim2.fromOffset(88,30),ZIndex=153,Parent=row})
            L:Cor(b,9); b.Activated:Connect(function() L:CB(button.Callback);shade:Destroy() end)
        end
        shade.Activated:Connect(function() shade:Destroy() end)
    end

    L:ShowLoading(function() Root.Visible=true end)
    L.Window=Win; return Win
end

-- ================================================================
-- UNLOAD
-- ================================================================
function L:Unload()
    for _,fn in next,self._aclean do pcall(fn) end
    for _,s  in next,self.Signals  do pcall(function()s:Disconnect()end) end
    pcall(function() SG:Destroy() end)
    _genv.Toggles=nil; _genv.Options=nil
end
L.Destroy=L.Unload
function L:ToggleTransparency(value)
    if self.Main then TW(self.Main,{BackgroundTransparency=value and 0.3 or 0.04},0.2) end
end
function L:ToggleAcrylic(value)
    self.AcrylicEnabled=value~=false
    if self.AcrylicFrame then self.AcrylicFrame.Visible=self.AcrylicEnabled end
end

return L
