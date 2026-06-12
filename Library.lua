-- Luminware Concept UI Library
-- A reusable Roblox UI library built directly from the frosted home-control concept.

local CloneRef=typeof(cloneref)=="function" and cloneref or function(value) return value end
local ProtectGui=typeof(protectgui)=="function" and protectgui
    or (syn and typeof(syn.protect_gui)=="function" and syn.protect_gui)
    or function() end

local function service(name)
    local object=game:GetService(name)
    local success,reference=pcall(CloneRef,object)
    return success and reference or object
end

local TS=service("TweenService")
local UIS=service("UserInputService")
local RS=service("RunService")
local Players=service("Players")
local Stats=service("Stats")
local MarketplaceService=service("MarketplaceService")
local LocalizationService=service("LocalizationService")
local CoreGui=service("CoreGui")
local Workspace=service("Workspace")

local Player=Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse=Player:GetMouse()
local Parent=CoreGui
pcall(function() if typeof(gethui)=="function" then Parent=CloneRef(gethui()) end end)

local checked={}
for _,container in ipairs({Parent,CoreGui}) do
    if container and not checked[container] then
        checked[container]=true
        local old=container:FindFirstChild("LuminwareConcept")
        if old then old:Destroy() end
    end
end

local Screen=Instance.new("ScreenGui")
Screen.Name="LuminwareConcept"
Screen.IgnoreGuiInset=true
Screen.ResetOnSpawn=false
Screen.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(ProtectGui,Screen)
Screen.Parent=Parent

local L={
    Version="3.0.0",
    Options={},
    Toggles={},
    Signals={},
    Windows={},
    Registry={},
    Popups={},
    PopupClosers={},
    PopupTriggers={},
    Overlays={},
    OnUnloadCallbacks={},
    Unloaded=false,
    Theme="Concept",
    Colors={
        Accent=Color3.fromRGB(46,156,214),
        Panel=Color3.fromRGB(22,24,27),
        Rail=Color3.fromRGB(38,41,45),
        Card=Color3.fromRGB(43,46,50),
        Control=Color3.fromRGB(62,66,71),
        Text=Color3.fromRGB(213,216,220),
        Muted=Color3.fromRGB(137,142,148),
        Dark=Color3.fromRGB(14,16,18),
        White=Color3.fromRGB(192,197,202),
        Outline=Color3.fromRGB(104,110,116),
    },
    Themes={
        Concept={Accent=Color3.fromRGB(46,156,214),Panel=Color3.fromRGB(22,24,27),Card=Color3.fromRGB(43,46,50),Rail=Color3.fromRGB(38,41,45),Control=Color3.fromRGB(62,66,71),Text=Color3.fromRGB(213,216,220),Muted=Color3.fromRGB(137,142,148),Dark=Color3.fromRGB(14,16,18),White=Color3.fromRGB(192,197,202),Outline=Color3.fromRGB(104,110,116)},
        Carbon={Accent=Color3.fromRGB(95,164,214),Panel=Color3.fromRGB(17,18,20),Card=Color3.fromRGB(31,33,36),Rail=Color3.fromRGB(27,29,32),Control=Color3.fromRGB(48,51,55),Text=Color3.fromRGB(205,208,212),Muted=Color3.fromRGB(123,128,134),Dark=Color3.fromRGB(9,10,12),White=Color3.fromRGB(181,185,190),Outline=Color3.fromRGB(78,83,89)},
        Graphite={Accent=Color3.fromRGB(126,142,158),Panel=Color3.fromRGB(27,29,31),Card=Color3.fromRGB(48,51,54),Rail=Color3.fromRGB(43,46,49),Control=Color3.fromRGB(67,71,75),Text=Color3.fromRGB(216,218,220),Muted=Color3.fromRGB(143,147,151),Dark=Color3.fromRGB(17,18,20),White=Color3.fromRGB(195,198,201),Outline=Color3.fromRGB(100,105,110)},
        Midnight={Accent=Color3.fromRGB(77,126,214),Panel=Color3.fromRGB(17,21,29),Card=Color3.fromRGB(31,37,48),Rail=Color3.fromRGB(27,33,43),Control=Color3.fromRGB(46,55,70),Text=Color3.fromRGB(207,214,225),Muted=Color3.fromRGB(124,134,150),Dark=Color3.fromRGB(10,13,19),White=Color3.fromRGB(184,193,207),Outline=Color3.fromRGB(77,88,105)},
        Obsidian={Accent=Color3.fromRGB(204,91,99),Panel=Color3.fromRGB(31,29,32),Card=Color3.fromRGB(51,48,53),Rail=Color3.fromRGB(45,42,47),Control=Color3.fromRGB(70,65,72),Text=Color3.fromRGB(224,218,225),Muted=Color3.fromRGB(155,146,157),Dark=Color3.fromRGB(21,19,22),White=Color3.fromRGB(207,199,208),Outline=Color3.fromRGB(111,101,113)},
        Warm={Accent=Color3.fromRGB(196,139,74),Panel=Color3.fromRGB(30,27,24),Card=Color3.fromRGB(51,46,41),Rail=Color3.fromRGB(44,40,36),Control=Color3.fromRGB(70,63,56),Text=Color3.fromRGB(218,211,202),Muted=Color3.fromRGB(148,137,125),Dark=Color3.fromRGB(18,15,13),White=Color3.fromRGB(199,191,181),Outline=Color3.fromRGB(103,93,82)},
        Plum={Accent=Color3.fromRGB(148,94,196),Panel=Color3.fromRGB(27,23,30),Card=Color3.fromRGB(49,42,54),Rail=Color3.fromRGB(43,37,48),Control=Color3.fromRGB(68,58,75),Text=Color3.fromRGB(216,208,220),Muted=Color3.fromRGB(145,133,151),Dark=Color3.fromRGB(16,13,18),White=Color3.fromRGB(197,187,202),Outline=Color3.fromRGB(100,87,107)},
    },
}

local function themeValue(key) return L.Colors[key] or key end
local function bind(object,properties)
    L.Registry[object]=properties
    for property,key in next,properties do object[property]=themeValue(key) end
    return object
end
local function unbind(object) L.Registry[object]=nil end
local function closePopups(except)
    for popup,owner in next,L.Popups do
        if popup~=except and popup.Parent then
            local closer=L.PopupClosers[popup]
            if closer then closer() else popup.Visible=false end
        end
    end
end
local function ownPopup(popup,window,closer,trigger)
    L.Popups[popup]=window
    L.PopupClosers[popup]=closer
    L.PopupTriggers[popup]=trigger
    popup.Destroying:Connect(function() L.Popups[popup]=nil;L.PopupClosers[popup]=nil;L.PopupTriggers[popup]=nil end)
    return popup
end
local function ownOverlay(object)
    L.Overlays[object]=true
    object.Destroying:Connect(function() L.Overlays[object]=nil end)
    return object
end

local function new(class,props,parent)
    local object=Instance.new(class)
    for key,value in next,props or {} do
        if key~="Parent" then pcall(function() object[key]=value end) end
    end
    object.Parent=parent or props and props.Parent
    return object
end
local function corner(parent,r) return new("UICorner",{CornerRadius=UDim.new(0,r or 12)},parent) end
local function stroke(parent,t) return bind(new("UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=L.Colors.Outline,Transparency=t or 0.86,Thickness=1},parent),{Color="Outline"}) end
local function pad(parent,l,r,t,b) return new("UIPadding",{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0),PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0)},parent) end
local function logo(parent,size,z)
    local mark=new("Frame",{BackgroundTransparency=1,Size=UDim2.fromOffset(size,size),ZIndex=z or 2},parent)
    local letters=bind(new("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.GothamBold,Text="LW",
        TextColor3=L.Colors.Text,TextSize=math.floor(size*0.48),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=(z or 2)+1},mark),{TextColor3="Text"})
    local bar=bind(new("Frame",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-3),Size=UDim2.fromOffset(size*0.58,3),
        BackgroundColor3=L.Colors.Accent,ZIndex=(z or 2)+2},mark),{BackgroundColor3="Accent"});corner(bar,1)
    return mark
end
local function tween(object,props,d)
    if object and object.Parent then TS:Create(object,TweenInfo.new(d or 0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props):Play() end
end
local function callback(fn,...) if typeof(fn)=="function" then task.spawn(fn,...) end end
function L:SafeCallback(fn,...)
    if typeof(fn)~="function" then return end
    local args=table.pack(...)
    task.spawn(function()
        local ok,err=pcall(fn,table.unpack(args,1,args.n))
        if not ok then L:Notify({Title="Callback error",Content=tostring(err),Duration=6}) end
    end)
end
local function text(parent,value,size,color,bold)
    local label=new("TextLabel",{BackgroundTransparency=1,Font=bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
        Text=value or "",TextColor3=color or L.Colors.Text,TextSize=size or 12,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},parent)
    if color==L.Colors.Muted then bind(label,{TextColor3="Muted"}) elseif color==nil or color==L.Colors.Text then bind(label,{TextColor3="Text"}) end
    return label
end
local register
local function drag(handle,target)
    local active,touchInput,startPointer,startPosition=false
    local state={Moved=false}
    local function pointer(input)
        if input and input.UserInputType==Enum.UserInputType.Touch then return Vector2.new(input.Position.X,input.Position.Y) end
        return Vector2.new(Mouse.X,Mouse.Y)
    end
    register(handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            active=true;touchInput=i.UserInputType==Enum.UserInputType.Touch and i or nil;startPointer=pointer(i)
            state.Moved=false
            startPosition=target.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then active=false;touchInput=nil end end)
        end
    end))
    register(UIS.InputChanged:Connect(function(i)
        local movingMouse=i.UserInputType==Enum.UserInputType.MouseMovement and touchInput==nil
        local movingTouch=touchInput~=nil and i==touchInput
        if active and (movingMouse or movingTouch) then
            local d=pointer(i)-startPointer
            if d.Magnitude>3 then state.Moved=true end
            local viewport=Workspace.CurrentCamera.ViewportSize
            local rawX=viewport.X*startPosition.X.Scale+startPosition.X.Offset+d.X
            local rawY=viewport.Y*startPosition.Y.Scale+startPosition.Y.Offset+d.Y
            local x=math.clamp(rawX,20-target.AbsoluteSize.X*(1-target.AnchorPoint.X),viewport.X-20+target.AbsoluteSize.X*target.AnchorPoint.X)
            local y=math.clamp(rawY,20-target.AbsoluteSize.Y*(1-target.AnchorPoint.Y),viewport.Y-20+target.AbsoluteSize.Y*target.AnchorPoint.Y)
            target.Position=UDim2.new(startPosition.X.Scale,x-viewport.X*startPosition.X.Scale,startPosition.Y.Scale,y-viewport.Y*startPosition.Y.Scale)
        end
    end))
    register(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i==touchInput then active=false;touchInput=nil end end))
    return state
end
register=function(signal) table.insert(L.Signals,signal);return signal end

local Notifications=new("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-18),
    Size=UDim2.fromOffset(300,500),BackgroundTransparency=1,ZIndex=300},Screen)
new("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Right,
    Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},Notifications)
register(UIS.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        local point=input.Position
        for popup in next,L.Popups do
            if popup.Visible then
                local p,s=popup.AbsolutePosition,popup.AbsoluteSize
                if point.X>=p.X and point.X<=p.X+s.X and point.Y>=p.Y and point.Y<=p.Y+s.Y then return end
                local trigger=L.PopupTriggers[popup]
                if trigger and trigger.Parent then
                    local tp,ts=trigger.AbsolutePosition,trigger.AbsoluteSize
                    if point.X>=tp.X and point.X<=tp.X+ts.X and point.Y>=tp.Y and point.Y<=tp.Y+ts.Y then return end
                end
            end
        end
        closePopups()
    end
end))

local Watermark=ownOverlay(bind(new("Frame",{Visible=false,Active=true,Position=UDim2.fromOffset(12,12),Size=UDim2.fromOffset(410,30),
    BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.12,ZIndex=290},Screen),{BackgroundColor3="Card"}))
corner(Watermark,5);stroke(Watermark,0.68)
local WatermarkText=text(Watermark,"Luminware",10,L.Colors.Text,true);WatermarkText.Position=UDim2.fromOffset(11,0);WatermarkText.Size=UDim2.new(1,-22,1,0)
local WatermarkPrefix="Luminware"
local ExperienceName=game.Name
local fps,frames,lastFps=0,0,os.clock()
drag(Watermark,Watermark)
task.spawn(function()
    local ok,info=pcall(MarketplaceService.GetProductInfo,MarketplaceService,game.PlaceId)
    if ok and info and info.Name then ExperienceName=info.Name end
end)
register(RS.RenderStepped:Connect(function()
    frames+=1
    local now=os.clock()
    if now-lastFps>=1 then fps=math.floor(frames/(now-lastFps)+0.5);frames=0;lastFps=now end
end))
task.spawn(function()
    while Screen.Parent do
        local ping="?"
        pcall(function() ping=Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():match("[%d%.]+") or "?" end)
        WatermarkText.Text=("%s  |  %s  |  %d FPS  |  %sms"):format(WatermarkPrefix,ExperienceName,fps,ping)
        task.wait(0.5)
    end
end)
function L:SetWatermark(value) WatermarkPrefix=tostring(value) end
function L:SetWatermarkVisibility(value) Watermark.Visible=not not value end
function L:GetSessionInfo()
    local ping="?"
    pcall(function() ping=Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():match("[%d%.]+") or "?" end)
    local executor="Unknown"
    pcall(function()
        if typeof(identifyexecutor)=="function" then executor=tostring(identifyexecutor())
        elseif typeof(getexecutorname)=="function" then executor=tostring(getexecutorname()) end
    end)
    local global=typeof(getgenv)=="function" and getgenv() or {}
    local humanoid=Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local device=UIS.TouchEnabled and "Touch" or UIS.GamepadEnabled and "Gamepad" or "Keyboard / Mouse"
    return {
        DisplayName=Player.DisplayName,Username=Player.Name,UserId=Player.UserId,AccountAge=Player.AccountAge,
        Membership=Player.MembershipType.Name,Team=Player.Team and Player.Team.Name or "None",
        Health=humanoid and math.floor(humanoid.Health+0.5) or 0,MaxHealth=humanoid and math.floor(humanoid.MaxHealth+0.5) or 0,
        Executor=executor,Experience=ExperienceName,PlaceId=game.PlaceId,JobId=game.JobId,
        Players=#Players:GetPlayers(),MaxPlayers=Players.MaxPlayers,FPS=fps,Ping=ping,
        Device=device,Locale=LocalizationService.RobloxLocaleId,ServerUptime=math.floor(Workspace.DistributedGameTime),
        Subscription=tostring(global.LuminwareSubscription or "Not configured"),
        SubscriptionLife=tostring(global.LuminwareSubscriptionLife or "Not configured"),
    }
end
function L:OnUnload(fn) table.insert(self.OnUnloadCallbacks,fn) end

local KeybindFrame=bind(new("Frame",{Visible=false,Position=UDim2.fromOffset(12,52),Size=UDim2.fromOffset(220,0),
    AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.12,ZIndex=289},Screen),{BackgroundColor3="Card"})
corner(KeybindFrame,5);stroke(KeybindFrame,0.68);pad(KeybindFrame,10,10,8,8)
new("UIListLayout",{Padding=UDim.new(0,4)},KeybindFrame)
L.KeybindFrame=KeybindFrame

function L:Notify(info)
    info=type(info)=="string" and {Title=info} or info or {}
    local box=bind(new("Frame",{BackgroundColor3=self.Colors.Card,BackgroundTransparency=0.12,
        Size=UDim2.fromOffset(290,info.Content and 72 or 50),ZIndex=301},Notifications),{BackgroundColor3="Card"})
    corner(box,6);stroke(box,0.72)
    local title=text(box,info.Title or "Notification",12,self.Colors.Text,true)
    title.Position=UDim2.fromOffset(15,8);title.Size=UDim2.new(1,-30,0,20)
    if info.Content or info.SubContent then
        local body=text(box,info.Content or info.SubContent,10,self.Colors.Muted)
        body.Position=UDim2.fromOffset(15,29);body.Size=UDim2.new(1,-30,0,28);body.TextWrapped=true
    end
    box.BackgroundTransparency=1;tween(box,{BackgroundTransparency=0.12},0.2)
    task.delay(info.Duration or 4,function() tween(box,{BackgroundTransparency=1},0.2);task.wait(0.25);unbind(box);box:Destroy() end)
end

function L:CreateLoader(info)
    info=type(info)=="string" and {Title=info} or info or {}
    local startedAt=os.clock()
    local minimumDuration=info.MinimumDuration or 2.4
    self.LoaderActive=true
    local overlay=new("Frame",{Active=true,Size=UDim2.fromScale(1,1),BackgroundColor3=self.Colors.Dark,BackgroundTransparency=1,ZIndex=400},Screen)
    local card=bind(new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,10),Size=UDim2.fromOffset(390,164),
        BackgroundColor3=self.Colors.Panel,BackgroundTransparency=1,ZIndex=401},overlay),{BackgroundColor3="Panel"})
    corner(card,7);local cardStroke=stroke(card,1)
    local loaderLogo=logo(card,42,402);loaderLogo.Position=UDim2.fromOffset(20,15)
    local title=text(card,info.Title or "Luminware",15,self.Colors.Text,true);title.Position=UDim2.fromOffset(72,20);title.Size=UDim2.new(1,-94,0,24);title.TextTransparency=1;title.ZIndex=402
    local subtitle=text(card,info.Subtitle or "Initializing interface",10,self.Colors.Muted);subtitle.Position=UDim2.fromOffset(72,44);subtitle.Size=UDim2.new(1,-94,0,20);subtitle.TextTransparency=1;subtitle.ZIndex=402
    local status=text(card,info.Status or "Starting",10,self.Colors.Muted);status.Position=UDim2.fromOffset(22,86);status.Size=UDim2.new(1,-74,0,18);status.TextTransparency=1;status.ZIndex=402
    local percent=text(card,"0%",10,self.Colors.Text,true);percent.AnchorPoint=Vector2.new(1,0);percent.Position=UDim2.new(1,-22,0,86);percent.Size=UDim2.fromOffset(42,18);percent.TextXAlignment=Enum.TextXAlignment.Right;percent.TextTransparency=1;percent.ZIndex=402
    local track=bind(new("Frame",{Position=UDim2.fromOffset(22,116),Size=UDim2.new(1,-44,0,5),BackgroundColor3=self.Colors.Control,BackgroundTransparency=0.15,ZIndex=402},card),{BackgroundColor3="Control"});corner(track,3)
    track.BackgroundTransparency=1
    local fill=bind(new("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=self.Colors.Accent,ZIndex=403},track),{BackgroundColor3="Accent"});corner(fill,3)
    fill.BackgroundTransparency=1
    local api={Root=overlay,Value=0}
    function api:SetProgress(value,newStatus)
        self.Value=math.clamp(tonumber(value) or 0,0,1)
        if newStatus then status.Text=tostring(newStatus) end
        percent.Text=("%d%%"):format(math.floor(self.Value*100+0.5))
        tween(fill,{Size=UDim2.fromScale(self.Value,1)},0.32)
    end
    function api:SetStatus(value) status.Text=tostring(value) end
    function api:Run(steps)
        task.spawn(function()
            for i,step in ipairs(steps or {}) do
                self:SetProgress(step.Progress or i/#steps,step.Status or step.Title)
                if typeof(step.Callback)=="function" then pcall(step.Callback) end
                task.wait(step.Duration or 0.25)
            end
            self:Complete(info.CompleteText or "Ready")
        end)
        return self
    end
    function api:Complete(finalStatus,onComplete)
        if not overlay.Parent or self.Completing then return end
        self.Completing=true
        local remaining=math.max(0.35,minimumDuration-(os.clock()-startedAt))
        local from=self.Value
        task.spawn(function()
            local began=os.clock()
            while overlay.Parent and os.clock()-began<remaining do
                local alpha=math.clamp((os.clock()-began)/remaining,0,1)
                self.Value=from+(1-from)*alpha
                status.Text=finalStatus or "Finalizing interface"
                percent.Text=("%d%%"):format(math.floor(self.Value*100+0.5))
                fill.Size=UDim2.fromScale(self.Value,1)
                task.wait(0.05)
            end
            if overlay.Parent then self:SetProgress(1,finalStatus or "Ready") end
        end)
        task.delay(remaining+0.32,function()
            if not overlay.Parent then return end
            tween(card,{Position=UDim2.new(0.5,0,0.5,-8),BackgroundTransparency=1},0.28)
            tween(cardStroke,{Transparency=1},0.24)
            for _,label in ipairs({title,subtitle,status,percent}) do tween(label,{TextTransparency=1},0.2) end
            tween(track,{BackgroundTransparency=1},0.2);tween(fill,{BackgroundTransparency=1},0.2);tween(overlay,{BackgroundTransparency=1},0.32)
            task.wait(0.36);overlay:Destroy();L.LoaderActive=false
            if L.AcrylicRequested then L:ToggleAcrylic(true) end
            callback(onComplete)
        end)
    end
    tween(overlay,{BackgroundTransparency=0.28},0.22)
    tween(card,{Position=UDim2.fromScale(0.5,0.5),BackgroundTransparency=0.02},0.34);tween(cardStroke,{Transparency=0.72},0.3)
    tween(track,{BackgroundTransparency=0.18},0.28);tween(fill,{BackgroundTransparency=0},0.28)
    for _,label in ipairs({title,subtitle,status,percent}) do tween(label,{TextTransparency=0},0.28) end
    return api
end

function L:CreateFOVCircle(info)
    info=info or {}
    local circle=ownOverlay(new("Frame",{Visible=not not info.Visible,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset((info.Radius or 120)*2,(info.Radius or 120)*2),BackgroundTransparency=1,ZIndex=280},Screen))
    corner(circle,999);local outline=bind(new("UIStroke",{Color=info.Color or self.Colors.Accent,Transparency=info.Transparency or 0.18,Thickness=info.Thickness or 1.5},circle),{Color="Accent"})
    local api={Root=circle,Radius=info.Radius or 120}
    function api:SetVisible(value) circle.Visible=not not value end
    function api:SetRadius(value) self.Radius=math.clamp(tonumber(value) or self.Radius,20,500);tween(circle,{Size=UDim2.fromOffset(self.Radius*2,self.Radius*2)},0.18) end
    function api:SetPosition(value) circle.Position=UDim2.fromOffset(value.X,value.Y) end
    function api:SetColor(value) L.Registry[outline]=nil;outline.Color=value end
    return api
end

function L:CreateESPPreview(info)
    info=info or {}
    local box=ownOverlay(new("Frame",{Visible=not not info.Visible,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(130,190),BackgroundTransparency=1,ZIndex=281},Screen))
    local outline=bind(new("UIStroke",{Color=self.Colors.Accent,Transparency=0.08,Thickness=1.5},box),{Color="Accent"})
    local label=text(box,info.Text or "VISUAL PREVIEW",10,self.Colors.Text,true);label.AnchorPoint=Vector2.new(0.5,1);label.Position=UDim2.new(0.5,0,0,-7);label.Size=UDim2.fromOffset(160,18);label.TextXAlignment=Enum.TextXAlignment.Center
    local health=bind(new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.fromOffset(-6,0),Size=UDim2.fromOffset(3,190),BackgroundColor3=self.Colors.Dark,ZIndex=282},box),{BackgroundColor3="Dark"});corner(health,2)
    local healthFill=bind(new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),Size=UDim2.fromScale(1,0.78),BackgroundColor3=self.Colors.Accent,ZIndex=283},health),{BackgroundColor3="Accent"});corner(healthFill,2)
    local api={Root=box}
    function api:SetVisible(value) box.Visible=not not value end
    function api:SetHealth(value) tween(healthFill,{Size=UDim2.fromScale(1,math.clamp(tonumber(value) or 0,0,1))},0.2) end
    function api:SetText(value) label.Text=tostring(value) end
    return api
end

local function makeToggle(parent,initial,changed)
    local state=not not initial
    local track=new("TextButton",{AutoButtonColor=false,Text="",BackgroundColor3=state and L.Colors.Accent or L.Colors.Control,
        Size=UDim2.fromOffset(46,25)},parent);corner(track,5)
    local knob=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=L.Colors.White,
        Position=UDim2.fromOffset(state and 33.5 or 12.5,12.5),Size=UDim2.fromOffset(19,19)},track);corner(knob,5)
    local api={Value=state,Type="Toggle"}
    function api:SetValue(v)
        self.Value=not not v
        tween(track,{BackgroundColor3=self.Value and L.Colors.Accent or L.Colors.Control})
        tween(knob,{Position=UDim2.fromOffset(self.Value and 33.5 or 12.5,12.5)})
        callback(changed,self.Value);callback(self.Changed,self.Value)
    end
    function api:RefreshTheme() track.BackgroundColor3=self.Value and L.Colors.Accent or L.Colors.Control;knob.BackgroundColor3=L.Colors.White end
    function api:SetDisabled(v) self.Disabled=not not v;track.Active=not self.Disabled;track.BackgroundTransparency=self.Disabled and 0.55 or 0 end
    function api:SetVisible(v) track.Parent.Visible=not not v end
    function api:OnChanged(fn) self.Changed=fn;fn(self.Value) end
    track.Activated:Connect(function() if not api.Disabled then api:SetValue(not api.Value) end end)
    return api,track
end

local function finishOption(option,root)
    option.Root=root
    function option:SetVisible(value) root.Visible=not not value end
    function option:SetDisabled(value) self.Disabled=not not value;root.Active=not self.Disabled;root.BackgroundTransparency=self.Disabled and 0.45 or 1 end
    return option
end

local function createCard(column,title,window)
    local card=bind(new("Frame",{BackgroundColor3=L.Colors.Dark,BackgroundTransparency=0.16,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},column)
        ,{BackgroundColor3="Dark"})
    card:SetAttribute("SearchText",title or "")
    corner(card,7);stroke(card,0.76);pad(card,14,14,12,14)
    local layout=new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},card)
    local api={Title=title or "",Root=card,Window=window}
    if title and title~="" then
        local header=text(card,title,14,L.Colors.Text,true);header.Size=UDim2.new(1,0,0,24);header.LayoutOrder=-100
    end
    local function row(height)
        return new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 38)},card)
    end
    local function rowTitle(r,info)
        local label=text(r,info.Title or info.Text or info.Label or "",13,L.Colors.Text)
        label.Size=UDim2.new(0.58,0,1,0)
        if info.Tooltip then
            local tip=ownPopup(bind(new("Frame",{Visible=false,BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.08,
                Size=UDim2.fromOffset(220,36),ZIndex=230},Screen),{BackgroundColor3="Card"}),window)
            corner(tip,5);stroke(tip,0.68)
            local tipText=text(tip,info.Tooltip,10,L.Colors.Text);tipText.Position=UDim2.fromOffset(10,0);tipText.Size=UDim2.new(1,-20,1,0);tipText.TextWrapped=true
            label.Active=true
            label.MouseEnter:Connect(function() closePopups(tip);tip.Position=UDim2.fromOffset(Mouse.X+12,Mouse.Y+12);tip.Visible=true end)
            label.MouseLeave:Connect(function() tip.Visible=false end)
        end
        return label
    end

    function api:AddParagraph(info)
        info=type(info)=="string" and {Title=info} or info or {}
        local r=row(info.Content and 58 or 30)
        local a=text(r,info.Title or "Paragraph",13,L.Colors.Text,true);a.Size=UDim2.new(1,0,0,22)
        if info.Content then
            local b=text(r,info.Content,11,L.Colors.Muted);b.Position=UDim2.fromOffset(0,23);b.Size=UDim2.new(1,0,1,-23);b.TextWrapped=true;b.TextYAlignment=Enum.TextYAlignment.Top
        end
        return r
    end
    function api:AddLabel(value,wrap)
        local r=row(wrap and 54 or 28)
        local label=text(r,value,12,L.Colors.Text);label.Size=UDim2.fromScale(1,1);label.TextWrapped=not not wrap;label.TextYAlignment=Enum.TextYAlignment.Top
        local result={Root=r}
        function result:SetText(v) label.Text=tostring(v) end
        function result:AddColorPicker(index,info) return api:AddColorpicker(index,info) end
        function result:AddKeyPicker(index,info) return api:AddKeybind(index,info) end
        return result
    end
    function api:AddStat(label,value,wrap)
        local r=row(wrap and 48 or 32)
        local key=text(r,tostring(label or ""),11,L.Colors.Muted,true);key.Size=UDim2.new(0.42,0,1,-1)
        local resultText=text(r,tostring(value or ""),12,L.Colors.Text,true);resultText.Position=UDim2.new(0.42,10,0,wrap and 5 or 0);resultText.Size=UDim2.new(0.58,-10,1,wrap and -6 or -1)
        resultText.TextXAlignment=Enum.TextXAlignment.Right;resultText.TextWrapped=not not wrap;resultText.TextYAlignment=wrap and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        local line=bind(new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BackgroundTransparency=0.88},r),{BackgroundColor3="Outline"})
        local result={Root=r}
        function result:SetValue(v) resultText.Text=tostring(v or "") end
        function result:SetLabel(v) key.Text=tostring(v or "") end
        function result:SetText(v) resultText.Text=tostring(v or "") end
        return result
    end
    function api:AddDivider()
        local r=row(9)
        local line=bind(new("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.new(1,0,0,1),BackgroundTransparency=0.72},r),{BackgroundColor3="Muted"})
        return line
    end
    function api:AddButton(info,second)
        info=type(info)=="string" and {Title=info,Callback=second} or info or {}
        local r=row(38);rowTitle(r,info)
        local b=bind(new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(92,30),
            AutoButtonColor=false,BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.25,
            Font=Enum.Font.Gotham,Text=info.Action or "Action",TextColor3=L.Colors.Text,TextSize=12},r),{BackgroundColor3="Control",TextColor3="Text"})
        corner(b,6);stroke(b,0.78)
        b.MouseEnter:Connect(function() tween(b,{BackgroundTransparency=0.08},0.14) end)
        b.MouseLeave:Connect(function() tween(b,{BackgroundTransparency=0.25},0.14) end)
        local clicks=0
        b.Activated:Connect(function()
            if info.DoubleClick then clicks+=1;if clicks<2 then task.delay(0.35,function()clicks=0 end);return end;clicks=0 end
            tween(b,{BackgroundColor3=L.Colors.Accent},0.08);task.delay(0.18,function()tween(b,{BackgroundColor3=L.Colors.Control})end);L:SafeCallback(info.Callback or info.Func)
        end)
        local result={Root=b}
        function result:AddButton(nextInfo,nextCallback) return api:AddButton(type(nextInfo)=="table" and nextInfo or {Title=nextInfo,Callback=nextCallback}) end
        return result
    end
    function api:AddToggle(index,info)
        info=info or {};local r=row(38);rowTitle(r,info)
        local option,track=makeToggle(r,info.Default,function(v) callback(info.Callback,v) end)
        finishOption(option,r)
        track.AnchorPoint=Vector2.new(1,0.5);track.Position=UDim2.new(1,0,0.5,0)
        L.Options[index]=option;L.Toggles[index]=option;return option
    end
    function api:AddSlider(index,info)
        info=info or {};local min,max=info.Min or 0,info.Max or 100
        local option={Value=info.Default or min,Min=min,Max=max,Type="Slider"}
        local r=row(52);local title=rowTitle(r,info);title.Size=UDim2.new(1,-62,0,20)
        finishOption(option,r)
        local badge=bind(new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(50,20),
            BackgroundColor3=L.Colors.Dark,BackgroundTransparency=0.34},r),{BackgroundColor3="Dark"});corner(badge,4);stroke(badge,0.88)
        local value=text(badge,"",9,L.Colors.Muted,true);value.Size=UDim2.fromScale(1,1);value.TextXAlignment=Enum.TextXAlignment.Center
        local track=bind(new("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0,38),Size=UDim2.new(1,0,0,5),
            BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.18},r),{BackgroundColor3="Control"});corner(track,3)
        local fill=bind(new("Frame",{BackgroundColor3=L.Colors.Accent,Size=UDim2.fromScale(0,1)},track),{BackgroundColor3="Accent"});corner(fill,3)
        local knob=bind(new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(11,11),
            BackgroundColor3=L.Colors.Text},track),{BackgroundColor3="Text"});corner(knob,6);stroke(knob,0.82)
        local hit=new("TextButton",{AutoButtonColor=false,Text="",BackgroundTransparency=1,AnchorPoint=Vector2.new(0,0.5),
            Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0,24),ZIndex=2},track)
        function option:SetValue(v,immediate)
            local n=math.clamp(tonumber(v) or min,min,max)
            local rounding=info.Rounding or 0;n=tonumber(string.format("%."..rounding.."f",n))
            self.Value=n;local p=max==min and 0 or (n-min)/(max-min)
            if immediate then fill.Size=UDim2.fromScale(p,1);knob.Position=UDim2.fromScale(p,0.5)
            else tween(fill,{Size=UDim2.fromScale(p,1)},0.16);tween(knob,{Position=UDim2.fromScale(p,0.5)},0.16) end
            value.Text=tostring(n)..(info.Suffix or "")
            callback(info.Callback,n);callback(self.Changed,n)
        end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:RefreshTheme() end
        local down=false
        local function setFromX(x) option:SetValue(min+math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(max-min),true) end
        hit.MouseEnter:Connect(function() if not down then tween(knob,{Size=UDim2.fromOffset(13,13)},0.14) end end)
        hit.MouseLeave:Connect(function() if not down then tween(knob,{Size=UDim2.fromOffset(11,11)},0.14) end end)
        hit.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                down=true;tween(knob,{Size=UDim2.fromOffset(15,15)},0.12);setFromX(i.UserInputType==Enum.UserInputType.Touch and i.Position.X or Mouse.X)
            end
        end)
        register(UIS.InputChanged:Connect(function(i)
            if down and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setFromX(i.UserInputType==Enum.UserInputType.Touch and i.Position.X or Mouse.X) end
        end))
        register(UIS.InputEnded:Connect(function(i) if down and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then down=false;tween(knob,{Size=UDim2.fromOffset(11,11)},0.14) end end))
        option:SetValue(option.Value);L.Options[index]=option;return option
    end
    function api:AddDropdown(index,info)
        info=info or {};local values=info.Values or {};local initial=info.Default
        if info.SpecialType=="Player" then values={} for _,player in ipairs(Players:GetPlayers()) do table.insert(values,player.Name) end table.sort(values) end
        if not info.Multi and type(initial)=="number" then initial=values[initial] end
        if info.Multi then local m={} for _,v in ipairs(initial or {}) do m[v]=true end initial=m end
        local option={Value=initial,Values=values,Multi=not not info.Multi,Type="Dropdown"}
        local r=row(62);local t=rowTitle(r,info);t.Size=UDim2.new(1,0,0,20)
        local box=bind(new("TextButton",{AutoButtonColor=false,Position=UDim2.fromOffset(0,25),Size=UDim2.new(1,0,0,31),
            BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.27,Font=Enum.Font.Gotham,Text="",TextColor3=L.Colors.Text,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},r),{BackgroundColor3="Control",TextColor3="Text"});corner(box,5);stroke(box,0.8);pad(box,11,11)
        finishOption(option,r)
        local pop=bind(new("ScrollingFrame",{Visible=false,Position=UDim2.fromOffset(0,62),BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.08,
            Size=UDim2.new(1,0,0,0),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ScrollBarThickness=2,ScrollBarImageColor3=L.Colors.Accent,BorderSizePixel=0,ZIndex=2},r),{BackgroundColor3="Card",ScrollBarImageColor3="Accent"});corner(pop,5);stroke(pop,0.7);pad(pop,5,5,5,5)
        local popLayout=new("UIListLayout",{Padding=UDim.new(0,3)},pop)
        local function close()
            pop.Visible=false
            r.Size=UDim2.new(1,0,0,62)
        end
        ownPopup(pop,window,close,box)
        local function display()
            if not option.Multi then return tostring(option.Value or "Select") end
            local out={} for _,v in ipairs(option.Values) do if option.Value[v] then table.insert(out,tostring(v)) end end
            return #out>0 and table.concat(out,", ") or "Select"
        end
        local function render()
            box.Text=display()
            for _,c in ipairs(pop:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _,v in ipairs(option.Values) do
                local selected=option.Multi and option.Value[v] or option.Value==v
                local item=new("TextButton",{AutoButtonColor=false,BackgroundColor3=selected and L.Colors.White or L.Colors.Control,
                    BackgroundTransparency=selected and 0 or 0.35,Size=UDim2.new(1,0,0,28),Font=Enum.Font.Gotham,Text=tostring(v),
                    TextColor3=selected and L.Colors.Dark or L.Colors.Text,TextSize=11,ZIndex=201},pop);corner(item,4)
                item.Activated:Connect(function()
                    if option.Multi then option.Value[v]=not option.Value[v] else option.Value=v;close() end
                    render();callback(info.Callback,option.Value);callback(option.Changed,option.Value)
                end)
            end
        end
        function option:SetValue(v) self.Value=v or (self.Multi and {} or nil);render();callback(info.Callback,self.Value);callback(self.Changed,self.Value) end
        function option:SetValues(v) self.Values=v or {};render() end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:RefreshTheme() box.BackgroundColor3=L.Colors.Control;pop.BackgroundColor3=L.Colors.Card;render() end
        box.Activated:Connect(function()
            local opening=not pop.Visible;closePopups(pop)
            if opening then
                local height=math.min(math.max(#option.Values*31+10,42),190)
                pop.Size=UDim2.new(1,0,0,height);pop.Visible=true
                r.Size=UDim2.new(1,0,0,68+height)
            else close() end
        end)
        render();L.Options[index]=option;return option
    end
    function api:AddInput(index,info)
        info=info or {};local option={Value=tostring(info.Default or ""),Type="Input"}
        local r=row(62);local t=rowTitle(r,info);t.Size=UDim2.new(1,0,0,20)
        finishOption(option,r)
        local box=bind(new("TextBox",{Position=UDim2.fromOffset(0,25),Size=UDim2.new(1,0,0,31),BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.27,
            ClearTextOnFocus=false,Font=Enum.Font.Gotham,Text=option.Value,PlaceholderText=info.Placeholder or "",TextColor3=L.Colors.Text,
            PlaceholderColor3=L.Colors.Muted,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},r),{BackgroundColor3="Control",TextColor3="Text",PlaceholderColor3="Muted"});corner(box,5);stroke(box,0.8);pad(box,11,11)
        function option:SetValue(v) self.Value=tostring(v or "");box.Text=self.Value end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:RefreshTheme() box.BackgroundColor3=L.Colors.Control end
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if info.MaxLength and #box.Text>info.MaxLength then box.Text=box.Text:sub(1,info.MaxLength) end
            if info.Numeric and box.Text~="" and not tonumber(box.Text) then box.Text=option.Value else option.Value=box.Text;if not info.Finished then callback(info.Callback,option.Value);callback(option.Changed,option.Value) end end
        end)
        box.FocusLost:Connect(function(enter) if info.Finished and enter then callback(info.Callback,option.Value);callback(option.Changed,option.Value) end end)
        L.Options[index]=option;return option
    end
    function api:AddKeybind(index,info)
        info=info or {};local option={Value=info.Default or "None",Mode=info.Mode or "Toggle",Toggled=false,Type="KeyPicker"}
        local r=row(38);rowTitle(r,info)
        finishOption(option,r)
        local button=bind(new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(90,29),
            BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.27,Font=Enum.Font.Gotham,Text=option.Value,TextColor3=L.Colors.Text,TextSize=10},r),{BackgroundColor3="Control",TextColor3="Text"});corner(button,5);stroke(button,0.8)
        local picking=false
        local display
        if not info.NoUI then
            display=text(KeybindFrame,(info.Text or info.Title or index).." ["..option.Value.."]",10,L.Colors.Text)
            display.Size=UDim2.new(1,0,0,20)
        end
        local function name(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then return "MB1" elseif i.UserInputType==Enum.UserInputType.MouseButton2 then return "MB2" elseif i.UserInputType==Enum.UserInputType.Keyboard then return i.KeyCode.Name end end
        function option:SetValue(v,mode) self.Value=type(v)=="table" and v[1] or v;self.Mode=mode or (type(v)=="table" and v[2]) or self.Mode;button.Text=self.Value;if display then display.Text=(info.Text or info.Title or index).." ["..self.Value.."]" end;callback(info.ChangedCallback,self.Value);callback(self.Changed,self.Value) end
        function option:GetState() return self.Mode=="Always" or self.Toggled end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:OnClick(fn) self.Clicked=fn end
        function option:RefreshTheme() button.BackgroundColor3=L.Colors.Control end
        button.Activated:Connect(function() picking=true;button.Text="...";local c;c=UIS.InputBegan:Connect(function(i) local n=name(i);if n then picking=false;c:Disconnect();option:SetValue(n) end end) end)
        register(UIS.InputBegan:Connect(function(i,gp) if not gp and not picking and name(i)==option.Value then option.Toggled=option.Mode=="Toggle" and not option.Toggled or true;if display then display.TextColor3=option.Toggled and L.Colors.Accent or L.Colors.Text end;callback(info.Callback,option.Toggled);callback(option.Clicked,option.Toggled) end end))
        register(UIS.InputEnded:Connect(function(i) if option.Mode=="Hold" and name(i)==option.Value then option.Toggled=false;if display then display.TextColor3=L.Colors.Text end;callback(info.Callback,false) end end))
        L.Options[index]=option;return option
    end
    function api:AddColorpicker(index,info)
        info=info or {};local option={Value=info.Default or L.Colors.Accent,Transparency=info.Transparency or 0,Type="ColorPicker"}
        local r=row(38);rowTitle(r,info)
        finishOption(option,r)
        local swatch=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(30,30),Text="",BackgroundColor3=option.Value},r);corner(swatch,3);stroke(swatch,0.65)
        local hue,sat,val=Color3.toHSV(option.Value)
        local pop=ownPopup(bind(new("Frame",{Visible=false,BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.04,Size=UDim2.fromOffset(240,250),ZIndex=200},Screen),{BackgroundColor3="Card"}),window);corner(pop,5);stroke(pop,0.6);pad(pop,12,12,12,12)
        local title=text(pop,info.Title or info.Text or "Color picker",12,L.Colors.Text,true);title.Size=UDim2.new(1,0,0,22)
        local sv=new("Frame",{Position=UDim2.fromOffset(0,30),Size=UDim2.new(1,-25,0,150),BackgroundColor3=Color3.fromHSV(hue,1,1),ClipsDescendants=true,ZIndex=201},pop);corner(sv,2)
        local saturation=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=201},sv)
        new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})},saturation)
        local valueShade=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=201},sv)
        new("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})},valueShade)
        local svCursor=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(12,12),BackgroundColor3=L.Colors.White,ZIndex=202},sv);corner(svCursor,6);stroke(svCursor,0.1)
        local hueBar=new("Frame",{Position=UDim2.new(1,-17,0,30),Size=UDim2.fromOffset(17,150),ZIndex=201},pop);corner(hueBar,2)
        local hueKeys={} for i=0,10 do table.insert(hueKeys,ColorSequenceKeypoint.new(i/10,Color3.fromHSV(i/10,1,1))) end
        new("UIGradient",{Color=ColorSequence.new(hueKeys),Rotation=90},hueBar)
        local hueCursor=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,hue),Size=UDim2.fromOffset(21,5),BackgroundColor3=L.Colors.White,ZIndex=202},hueBar);corner(hueCursor,3)
        local hex=new("TextBox",{ClearTextOnFocus=false,Position=UDim2.fromOffset(0,190),BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.2,Size=UDim2.new(1,0,0,32),
            Font=Enum.Font.Gotham,Text="#"..option.Value:ToHex(),TextColor3=L.Colors.Text,TextSize=11,ZIndex=201},pop);corner(hex,4)
        local function render(fire)
            option.Value=Color3.fromHSV(hue,sat,val);swatch.BackgroundColor3=option.Value;sv.BackgroundColor3=Color3.fromHSV(hue,1,1)
            svCursor.Position=UDim2.fromScale(sat,1-val);hueCursor.Position=UDim2.fromScale(0.5,hue);hex.Text="#"..option.Value:ToHex()
            if fire then callback(info.Callback,option.Value);callback(option.Changed,option.Value) end
        end
        function option:SetValueRGB(c,t) self.Transparency=t or self.Transparency;hue,sat,val=Color3.toHSV(c);render(true) end
        function option:SetValue(hsv,t)
            if typeof(hsv)=="Color3" then return self:SetValueRGB(hsv,t) end
            hue,sat,val=hsv[1],hsv[2],hsv[3];self.Transparency=t or self.Transparency;render(true)
        end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:RefreshTheme() pop.BackgroundColor3=L.Colors.Card end
        hex.FocusLost:Connect(function() local ok,c=pcall(Color3.fromHex,hex.Text);if ok then option:SetValueRGB(c) end end)
        local svDown,hueDown=false,false
        local function updateSV() sat=math.clamp((Mouse.X-sv.AbsolutePosition.X)/sv.AbsoluteSize.X,0,1);val=1-math.clamp((Mouse.Y-sv.AbsolutePosition.Y)/sv.AbsoluteSize.Y,0,1);render(true) end
        local function updateHue() hue=math.clamp((Mouse.Y-hueBar.AbsolutePosition.Y)/hueBar.AbsoluteSize.Y,0,1);render(true) end
        sv.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDown=true;updateSV() end end)
        hueBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hueDown=true;updateHue() end end)
        register(UIS.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then if svDown then updateSV() elseif hueDown then updateHue() end end end))
        register(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDown=false;hueDown=false end end))
        swatch.Activated:Connect(function()
            local opening=not pop.Visible;closePopups(pop)
            pop.Position=UDim2.fromOffset(math.clamp(swatch.AbsolutePosition.X-194,8,Workspace.CurrentCamera.ViewportSize.X-248),math.clamp(swatch.AbsolutePosition.Y+32,8,Workspace.CurrentCamera.ViewportSize.Y-258));pop.Visible=opening
        end)
        render(false)
        L.Options[index]=option;return option
    end
    api.AddColorPicker=api.AddColorpicker
    api.AddKeyPicker=api.AddKeybind
    function api:SetVisible(value) card.Visible=not not value end
    function api:AddDependencyBox()
        local dep=createCard(card,"",window)
        dep.Root.BackgroundTransparency=1
        function dep:SetupDependencies(dependencies)
            local function update()
                local visible=true
                for _,dependency in ipairs(dependencies or {}) do
                    if dependency[1].Value~=dependency[2] then visible=false;break end
                end
                dep.Root.Visible=visible
            end
            for _,dependency in ipairs(dependencies or {}) do
                if dependency[1].OnChanged then dependency[1]:OnChanged(update) end
            end
            update()
        end
        return dep
    end
    return api
end

local function makeColumn(parent,x,w,window,side)
    local offset=x==0 and 2 or 5
    local col=new("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,Position=UDim2.new(x,offset,0,2),Size=UDim2.new(w,-9,1,-4),
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=L.Colors.Accent},parent)
    pad(col,2,4,2,4)
    new("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},col)
    return {Root=col,Side=side,AddCard=function(_,title)
        local card=createCard(col,title,window)
        card.Root:SetAttribute("LuminwareColumn",side)
        return card
    end}
end

function L:CreateWindow(config)
    config=config or {};local width=config.Size and config.Size.X.Offset or 900;local height=config.Size and config.Size.Y.Offset or 600
    local initiallyVisible=config.Visible~=false
    local window={Tabs={},TabOrder={},NavButtons={},MobileMode=not not config.MobileMode,SmallIconEnabled=config.SmallIcon~=false,Visible=initiallyVisible}
    local desktopSize=Vector2.new(width,height)
    local mobileSize=Vector2.new(config.MobileSize and config.MobileSize.X.Offset or 820,config.MobileSize and config.MobileSize.Y.Offset or 520)
    if window.MobileMode then width=mobileSize.X;height=mobileSize.Y end
    local root=new("Frame",{Visible=initiallyVisible,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(width,height),BackgroundTransparency=1},Screen)
    local scale=new("UIScale",{Scale=0.965},root)
    local panel=bind(new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=self.Colors.Panel,BackgroundTransparency=1,ClipsDescendants=true},root),{BackgroundColor3="Panel"});corner(panel,12);stroke(panel,0.78)
    local rail=bind(new("Frame",{Position=UDim2.fromOffset(14,14),Size=UDim2.new(0,72,1,-28),BackgroundColor3=self.Colors.Rail,BackgroundTransparency=0.18},panel),{BackgroundColor3="Rail"});corner(rail,9);stroke(rail,0.8)
    local brand=logo(rail,34,3);brand.AnchorPoint=Vector2.new(0.5,0);brand.Position=UDim2.new(0.5,0,0,13)
    local nav=new("ScrollingFrame",{Position=UDim2.fromOffset(8,62),Size=UDim2.new(1,-16,1,-124),BackgroundTransparency=1,BorderSizePixel=0,
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y},rail)
    new("UIListLayout",{Padding=UDim.new(0,8),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},nav)
    local settingsButton=bind(new("TextButton",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-12),Size=UDim2.fromOffset(44,38),BackgroundColor3=self.Colors.Dark,BackgroundTransparency=0.65,
        Font=Enum.Font.GothamMedium,Text="",TextColor3=self.Colors.Muted,TextSize=9},rail),{BackgroundColor3="Dark",TextColor3="Muted"});corner(settingsButton,5);stroke(settingsButton,0.86)
    local settingsGlyph=bind(new("TextLabel",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(18,18),
        BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Text="S",TextColor3=self.Colors.Muted,TextSize=12,ZIndex=4},settingsButton),{TextColor3="Muted"})
    local content=new("Frame",{Position=UDim2.fromOffset(104,14),Size=UDim2.new(1,-118,1,-28),BackgroundTransparency=1},panel)
    local header=new("Frame",{Size=UDim2.new(1,0,0,54),BackgroundTransparency=1},content)
    local dragSurface=new("TextButton",{AutoButtonColor=false,Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=1},header);drag(dragSurface,root)
    local subtabs=new("ScrollingFrame",{Position=UDim2.fromOffset(0,4),Size=UDim2.new(1,-390,0,42),BackgroundTransparency=1,BorderSizePixel=0,
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.X,ZIndex=2},header)
    local subLayout=new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},subtabs)
    local searchHolder=bind(new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-84,0,5),Size=UDim2.fromOffset(280,35),
        BackgroundColor3=self.Colors.Dark,BackgroundTransparency=0.34,ZIndex=2},header),{BackgroundColor3="Dark"});corner(searchHolder,5);stroke(searchHolder,0.88)
    local searchIcon=bind(new("TextLabel",{Position=UDim2.fromOffset(12,8),Size=UDim2.fromOffset(15,18),BackgroundTransparency=1,
        Font=Enum.Font.GothamMedium,Text="?",TextColor3=self.Colors.Muted,TextSize=12,ZIndex=3},searchHolder),{TextColor3="Muted"})
    local search=bind(new("TextBox",{Position=UDim2.fromOffset(36,0),Size=UDim2.new(1,-44,1,0),BackgroundTransparency=1,
        ClearTextOnFocus=false,Font=Enum.Font.Gotham,PlaceholderText="Search features",PlaceholderColor3=self.Colors.Muted,Text="",TextColor3=self.Colors.Text,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},searchHolder),{PlaceholderColor3="Muted",TextColor3="Text"})
    local minimize=bind(new("TextButton",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-39,0,6),Size=UDim2.fromOffset(34,32),AutoButtonColor=false,
        BackgroundColor3=self.Colors.Control,BackgroundTransparency=0.6,Font=Enum.Font.GothamMedium,Text="",TextColor3=self.Colors.Muted,TextSize=16,ZIndex=3},header),{BackgroundColor3="Control",TextColor3="Muted"});corner(minimize,4)
    local minimizeIcon=bind(new("TextLabel",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(14,14),
        BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Text="-",TextColor3=self.Colors.Muted,TextSize=14,ZIndex=4},minimize),{TextColor3="Muted"})
    local destroy=bind(new("TextButton",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,6),Size=UDim2.fromOffset(34,32),AutoButtonColor=false,
        BackgroundColor3=self.Colors.Control,BackgroundTransparency=0.6,Font=Enum.Font.GothamMedium,Text="",TextColor3=self.Colors.Muted,TextSize=10,ZIndex=3},header),{BackgroundColor3="Control",TextColor3="Muted"});corner(destroy,4)
    local destroyIcon=bind(new("TextLabel",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(14,14),
        BackgroundTransparency=1,Font=Enum.Font.GothamMedium,Text="X",TextColor3=self.Colors.Muted,TextSize=11,ZIndex=4},destroy),{TextColor3="Muted"})
    local pages=new("Frame",{Position=UDim2.fromOffset(0,56),Size=UDim2.new(1,0,1,-56),BackgroundTransparency=1,ClipsDescendants=true},content)
    local resizeGrip=bind(new("TextButton",{AutoButtonColor=false,Text="",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-7,1,-7),
        Size=UDim2.fromOffset(22,22),BackgroundColor3=self.Colors.Control,BackgroundTransparency=0.72,ZIndex=20},panel),{BackgroundColor3="Control"});corner(resizeGrip,8)
    local gripLine=bind(new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(8,2),
        Rotation=-45,BackgroundColor3=self.Colors.Muted,ZIndex=21},resizeGrip),{BackgroundColor3="Muted"});corner(gripLine,1)
    local icon=bind(new("TextButton",{Visible=false,AutoButtonColor=false,Text="",Font=Enum.Font.GothamMedium,TextSize=14,TextColor3=self.Colors.Text,
        Position=UDim2.fromOffset(18,70),Size=UDim2.fromOffset(48,48),BackgroundColor3=self.Colors.Panel,BackgroundTransparency=0.06,ZIndex=295},Screen),{BackgroundColor3="Panel",TextColor3="Text"})
    corner(icon,7);stroke(icon,0.66);local iconLogo=logo(icon,36,296);iconLogo.AnchorPoint=Vector2.new(0.5,0.5);iconLogo.Position=UDim2.fromScale(0.5,0.5);local iconDrag=drag(icon,icon)
    local function layoutSubtab(sub,mobile)
        if not sub.Left or not sub.Right then return end
        local left,right=sub.Left.Root,sub.Right.Root
        if mobile then
            for _,child in ipairs(right:GetChildren()) do
                if child:IsA("Frame") then
                    child:SetAttribute("LuminwareColumn","Right")
                    child.Parent=left
                end
            end
            left.Position=UDim2.fromOffset(2,2);left.Size=UDim2.new(1,-4,1,-4);right.Visible=false
        else
            for _,child in ipairs(left:GetChildren()) do
                if child:IsA("Frame") and child:GetAttribute("LuminwareColumn")=="Right" then child.Parent=right end
            end
            left.Position=UDim2.new(0,2,0,2);left.Size=UDim2.new(0.5,-9,1,-4)
            right.Position=UDim2.new(0.5,5,0,2);right.Size=UDim2.new(0.5,-9,1,-4);right.Visible=true
        end
    end
    local function applyResponsive()
        local mobile=window.MobileMode
        rail.Position=UDim2.fromOffset(mobile and 10 or 14,mobile and 10 or 14)
        rail.Size=UDim2.new(0,mobile and 58 or 72,1,mobile and -20 or -28)
        brand.Size=UDim2.fromOffset(mobile and 28 or 34,mobile and 28 or 34)
        brand.Position=UDim2.new(0.5,0,0,mobile and 10 or 13)
        nav.Position=UDim2.fromOffset(mobile and 6 or 8,mobile and 50 or 62)
        nav.Size=UDim2.new(1,mobile and -12 or -16,1,mobile and -104 or -124)
        settingsButton.Size=UDim2.fromOffset(mobile and 38 or 44,mobile and 34 or 38)
        settingsButton.Position=UDim2.new(0.5,0,1,mobile and -9 or -12)
        content.Position=UDim2.fromOffset(mobile and 80 or 104,mobile and 10 or 14)
        content.Size=UDim2.new(1,mobile and -90 or -118,1,mobile and -20 or -28)
        searchHolder.Size=UDim2.fromOffset(mobile and 200 or 280,35)
        subtabs.Size=UDim2.new(1,mobile and -310 or -390,0,42)
        for _,button in ipairs(window.NavButtons) do button.Size=UDim2.fromOffset(mobile and 38 or 46,mobile and 36 or 40) end
        for _,tab in ipairs(window.TabOrder) do for _,sub in ipairs(tab.SubtabOrder) do layoutSubtab(sub,mobile) end end
    end
    local function resize()
        applyResponsive()
        local v=Workspace.CurrentCamera.ViewportSize
        local logical=root.Size
        scale.Scale=math.min(1,v.X/(logical.X.Offset+36),v.Y/(logical.Y.Offset+36))
    end
    resize();local finalScale=scale.Scale
    if initiallyVisible then scale.Scale=finalScale*0.965;tween(scale,{Scale=finalScale},0.38);tween(panel,{BackgroundTransparency=0.17},0.32)
    else scale.Scale=finalScale;panel.BackgroundTransparency=0.17 end
    register(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize))
    local resizing,startPointer,startSize=false
    resizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            resizing=true;startPointer=input.UserInputType==Enum.UserInputType.Touch and input.Position or Vector2.new(Mouse.X,Mouse.Y)
            startSize=Vector2.new(root.Size.X.Offset,root.Size.Y.Offset)
            tween(resizeGrip,{BackgroundTransparency=0.3},0.12)
        end
    end)
    register(UIS.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local point=input.UserInputType==Enum.UserInputType.Touch and input.Position or Vector2.new(Mouse.X,Mouse.Y)
            local delta=(point-startPointer)/math.max(scale.Scale,0.01)
            root.Size=UDim2.fromOffset(math.clamp(startSize.X+delta.X,620,1200),math.clamp(startSize.Y+delta.Y,420,820))
            resize()
        end
    end))
    register(UIS.InputEnded:Connect(function(input)
        if resizing and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then resizing=false;tween(resizeGrip,{BackgroundTransparency=0.72},0.12) end
    end))
    settingsButton.Activated:Connect(function() if window.SettingsTab then window.SettingsTab:Show() end end)
    minimize.Activated:Connect(function() window:Minimize() end)
    destroy.Activated:Connect(function() window:Minimize() end)
    for _,control in ipairs({settingsButton,minimize,destroy}) do
        control.MouseEnter:Connect(function() tween(control,{BackgroundTransparency=0.28},0.12) end)
        control.MouseLeave:Connect(function() tween(control,{BackgroundTransparency=control==settingsButton and (window.SettingsTab and window.SettingsTab.Active and 0.28 or 0.65) or 0.6},0.12) end)
    end
    search:GetPropertyChangedSignal("Text"):Connect(function()
        local q=search.Text:lower()
        for _,tab in ipairs(window.TabOrder) do for _,sub in ipairs(tab.SubtabOrder) do
            for _,col in ipairs({sub.Left.Root,sub.Right.Root}) do for _,card in ipairs(col:GetChildren()) do
                if card:IsA("Frame") then card.Visible=q=="" or tostring(card:GetAttribute("SearchText") or ""):lower():find(q,1,true)~=nil end
            end end
        end end
    end)

    function window:AddTab(info)
        info=type(info)=="string" and {Title=info} or info or {}
        local title=info.Title or info.Name or "Tab";local tab={Title=title,Subtabs={},SubtabOrder={},IsSettings=not not info.Settings}
        local button=bind(new("TextButton",{AutoButtonColor=false,Size=UDim2.fromOffset(46,40),BackgroundColor3=L.Colors.Dark,BackgroundTransparency=1,
            Font=Enum.Font.GothamMedium,Text="",TextColor3=L.Colors.Text,TextSize=13,Visible=not info.Settings},nav),{BackgroundColor3="Dark",TextColor3="Text"});corner(button,5)
        table.insert(window.NavButtons,button);applyResponsive()
        local tabIcon=text(button,info.IconText or title:sub(1,1):upper(),12,L.Colors.Muted,true)
        tabIcon.AnchorPoint=Vector2.new(0.5,0.5);tabIcon.Position=UDim2.fromScale(0.5,0.5);tabIcon.Size=UDim2.fromOffset(20,20)
        tabIcon.TextXAlignment=Enum.TextXAlignment.Center
        local function iconColor(color) tween(tabIcon,{TextColor3=color}) end
        button.MouseEnter:Connect(function() if not tab.Active then tween(button,{BackgroundTransparency=0.68},0.14);iconColor(L.Colors.Text) end end)
        button.MouseLeave:Connect(function() if not tab.Active then tween(button,{BackgroundTransparency=1},0.14);iconColor(L.Colors.Muted) end end)
        function tab:Show()
            closePopups()
            for _,other in ipairs(window.TabOrder) do other:Hide() end
            self.Active=true;tween(button,{BackgroundTransparency=0.38})
            iconColor(L.Colors.Text)
            tween(settingsButton,{BackgroundTransparency=self.IsSettings and 0.28 or 0.65,TextColor3=self.IsSettings and L.Colors.Text or L.Colors.Muted})
            tween(settingsGlyph,{TextColor3=self.IsSettings and L.Colors.Text or L.Colors.Muted})
            for _,sub in ipairs(self.SubtabOrder) do sub.Button.Visible=true end
            if self.SubtabOrder[1] then self.SubtabOrder[1]:Show() end
        end
        function tab:Hide()
            closePopups()
            self.Active=false;tween(button,{BackgroundTransparency=1})
            iconColor(L.Colors.Muted)
            for _,s in ipairs(self.SubtabOrder) do s:Hide();s.Button.Visible=false end
        end
        button.Activated:Connect(function() tab:Show() end)
        function tab:AddSubtab(name)
            local sub={Title=name,Tab=tab}
            local sb=new("TextButton",{AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromOffset(math.max(76,#name*8+20),38),
                Font=Enum.Font.Gotham,Text=name,TextColor3=L.Colors.Muted,TextSize=12,Visible=tab.Active},subtabs)
            local line=bind(new("Frame",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,0),Size=UDim2.new(1,-18,0,1),BackgroundColor3=L.Colors.Accent,BackgroundTransparency=1},sb),{BackgroundColor3="Accent"})
            local page=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},pages)
            sub.Root=page;sub.Button=sb;sub.Left=makeColumn(page,0,0.5,window,"Left");sub.Right=makeColumn(page,0.5,0.5,window,"Right")
            local addRightCard=sub.Right.AddCard
            function sub.Right:AddCard(cardTitle)
                local card=addRightCard(self,cardTitle)
                if window.MobileMode then card.Root.Parent=sub.Left.Root end
                return card
            end
            function sub:Show()
                for _,other in ipairs(tab.SubtabOrder) do other:Hide() end
                layoutSubtab(self,window.MobileMode)
                page.Visible=true;page.Position=UDim2.fromOffset(7,0);self.Active=true
                tween(page,{Position=UDim2.fromOffset(0,0)},0.28);tween(sb,{TextColor3=L.Colors.Text});tween(line,{BackgroundTransparency=0})
            end
            function sub:Hide() page.Visible=false;self.Active=false;tween(sb,{TextColor3=L.Colors.Muted});tween(line,{BackgroundTransparency=1}) end
            sb.Activated:Connect(function() sub:Show() end)
            tab.Subtabs[name]=sub;table.insert(tab.SubtabOrder,sub)
            if #tab.SubtabOrder==1 and tab.Active then sub:Show() end
            return sub
        end
        function tab:AddSection(title)
            if not self.DefaultSubtab then self.DefaultSubtab=self:AddSubtab("Main");self.NextSide="Left" end
            local side=self.NextSide;self.NextSide=side=="Left" and "Right" or "Left"
            return self.DefaultSubtab[side]:AddCard(title)
        end
        function tab:AddLeftGroupbox(title)
            if not self.DefaultSubtab then self.DefaultSubtab=self:AddSubtab("Main") end
            return self.DefaultSubtab.Left:AddCard(title)
        end
        function tab:AddRightGroupbox(title)
            if not self.DefaultSubtab then self.DefaultSubtab=self:AddSubtab("Main") end
            return self.DefaultSubtab.Right:AddCard(title)
        end
        function tab:AddGroupbox(info)
            info=type(info)=="string" and {Name=info,Side=1} or info or {}
            return (info.Side==2 and self:AddRightGroupbox(info.Name or info.Title) or self:AddLeftGroupbox(info.Name or info.Title))
        end
        local function addTabbox(side)
            if not tab.DefaultSubtab then tab.DefaultSubtab=tab:AddSubtab("Main") end
            local column=tab.DefaultSubtab[side].Root
            local container=bind(new("Frame",{BackgroundColor3=L.Colors.Dark,BackgroundTransparency=0.16,
                Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},column),{BackgroundColor3="Dark"})
            container:SetAttribute("LuminwareColumn",side)
            if window.MobileMode and side=="Right" then container.Parent=tab.DefaultSubtab.Left.Root end
            corner(container,7);stroke(container,0.8);pad(container,10,10,10,10)
            local tabsRow=new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,32)},container)
            new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5)},tabsRow)
            local body=new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,38),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},container)
            local box={Tabs={},Order={}}
            function box:AddTab(name)
                local button=bind(new("TextButton",{AutoButtonColor=false,Size=UDim2.fromOffset(math.max(68,#name*7+18),30),
                    BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.45,Font=Enum.Font.Gotham,Text=name,TextColor3=L.Colors.Muted,TextSize=10},tabsRow),{BackgroundColor3="Control",TextColor3="Muted"});corner(button,4)
                local holder=new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Visible=false},body)
                local card=createCard(holder,"",window);card.Root.BackgroundTransparency=1
                function card:Show()
                    for _,entry in ipairs(box.Order) do entry.Card.Root.Parent.Visible=false;tween(entry.Button,{BackgroundTransparency=0.45,TextColor3=L.Colors.Muted}) end
                    holder.Visible=true;tween(button,{BackgroundTransparency=0.12,TextColor3=L.Colors.Text})
                end
                button.Activated:Connect(function()card:Show()end)
                self.Tabs[name]=card;table.insert(self.Order,{Card=card,Button=button})
                if #self.Order==1 then card:Show() end
                return card
            end
            return box
        end
        function tab:AddLeftTabbox() return addTabbox("Left") end
        function tab:AddRightTabbox() return addTabbox("Right") end
        local methods={"AddParagraph","AddLabel","AddStat","AddDivider","AddButton","AddToggle","AddSlider","AddDropdown","AddInput","AddKeybind","AddKeyPicker","AddColorpicker","AddColorPicker","AddDependencyBox"}
        for _,method in ipairs(methods) do tab[method]=function(self,...) if not self.DefaultCard then self.DefaultCard=self:AddSection("") end return self.DefaultCard[method](self.DefaultCard,...) end end
        window.Tabs[title]=tab;table.insert(window.TabOrder,tab);if info.Settings then window.SettingsTab=tab end;if #window.TabOrder==1 then tab:Show() end;return tab
    end
    function window:SelectTab(which) local tab=type(which)=="number" and self.TabOrder[which] or self.Tabs[which];if tab then tab:Show() end end
    function window:SetVisible(value)
        value=not not value
        if self.Visible==value then return end
        closePopups();self.Visible=value;self.VisibilityToken=(self.VisibilityToken or 0)+1;local token=self.VisibilityToken
        if value then
            root.Visible=true;icon.Visible=false;resize();local targetScale=scale.Scale
            local restingPosition=self.RestingPosition or root.Position
            for overlay,wasVisible in next,self.OverlayVisibility or {} do if overlay.Parent then overlay.Visible=wasVisible end end
            self.OverlayVisibility=nil
            scale.Scale=targetScale*0.94;panel.BackgroundTransparency=0.88
            root.Position=UDim2.new(restingPosition.X.Scale,restingPosition.X.Offset,restingPosition.Y.Scale,restingPosition.Y.Offset+12)
            tween(root,{Position=restingPosition},0.34);tween(scale,{Scale=targetScale},0.38);tween(panel,{BackgroundTransparency=0.17},0.3)
        else
            self.OverlayVisibility={}
            for overlay in next,L.Overlays do if overlay.Parent then self.OverlayVisibility[overlay]=overlay.Visible;overlay.Visible=false end end
            local targetScale=scale.Scale
            local restingPosition=root.Position
            self.RestingPosition=restingPosition
            local exitPosition=UDim2.new(restingPosition.X.Scale,restingPosition.X.Offset,restingPosition.Y.Scale,restingPosition.Y.Offset+10)
            tween(root,{Position=exitPosition},0.28);tween(scale,{Scale=targetScale*0.94},0.3);tween(panel,{BackgroundTransparency=0.92},0.26)
            task.delay(0.3,function()
                if self.VisibilityToken~=token then return end
                root.Visible=false;root.Position=restingPosition;scale.Scale=targetScale;panel.BackgroundTransparency=0.17
                icon.Visible=self.SmallIconEnabled
                if icon.Visible then
                    icon.Size=UDim2.fromOffset(38,38);icon.BackgroundTransparency=0.72
                    tween(icon,{Size=UDim2.fromOffset(54,54),BackgroundTransparency=0.06},0.32)
                end
            end)
        end
    end
    function window:Toggle() self:SetVisible(not self.Visible) end
    function window:Minimize() self:SetVisible(false) end
    function window:SetSmallIconEnabled(value) self.SmallIconEnabled=not not value;icon.Visible=not root.Visible and self.SmallIconEnabled end
    function window:SetMobileMode(value)
        self.MobileMode=not not value
        local size=self.MobileMode and mobileSize or desktopSize
        tween(root,{Size=UDim2.fromOffset(size.X,size.Y)},0.28);task.delay(0.3,resize)
    end
    function window:Destroy()
        closePopups()
        local position=root.Position
        tween(root,{Position=UDim2.new(position.X.Scale,position.X.Offset,position.Y.Scale,position.Y.Offset+14)},0.3)
        tween(scale,{Scale=scale.Scale*0.92},0.32);tween(panel,{BackgroundTransparency=1},0.28)
        task.delay(0.34,function()
            for popup,owner in next,L.Popups do if owner==window then unbind(popup);popup:Destroy() end end
            icon:Destroy();root:Destroy()
        end)
    end
    function window:Dialog(info)
        info=info or {};closePopups();local shade=ownPopup(new("TextButton",{AutoButtonColor=false,Text="",BackgroundColor3=Color3.new(),BackgroundTransparency=0.45,Size=UDim2.fromScale(1,1),ZIndex=250},Screen),window)
        local box=bind(new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(390,190),BackgroundColor3=L.Colors.Card,ZIndex=251},shade),{BackgroundColor3="Card"});corner(box,7);stroke(box,0.65);pad(box,18,18,16,16)
        local ttl=text(box,info.Title or "Dialog",15,L.Colors.Text,true);ttl.Size=UDim2.new(1,0,0,24)
        local body=text(box,info.Content or "",11,L.Colors.Muted);body.Position=UDim2.fromOffset(0,34);body.Size=UDim2.new(1,0,0,75);body.TextWrapped=true;body.TextYAlignment=Enum.TextYAlignment.Top
        local buttons=new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,34),BackgroundTransparency=1},box)
        new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,8)},buttons)
        for _,b in ipairs(info.Buttons or {{Title="Okay"}}) do local x=bind(new("TextButton",{Size=UDim2.fromOffset(92,32),BackgroundColor3=L.Colors.Control,Font=Enum.Font.Gotham,Text=b.Title or "Okay",TextColor3=L.Colors.Text,TextSize=11,ZIndex=252},buttons),{BackgroundColor3="Control",TextColor3="Text"});corner(x,5);x.Activated:Connect(function()callback(b.Callback);shade:Destroy()end) end
        shade.Activated:Connect(function() shade:Destroy() end)
    end
    window.Root=root;window.Panel=panel;self.Window=window;table.insert(self.Windows,window)
    icon.Activated:Connect(function() if not iconDrag.Moved then window:SetVisible(true) end end)
    if config.Acrylic~=false then self:ToggleAcrylic(true) end
    return window
end

function L:SetTheme(name)
    local theme=type(name)=="table" and name or self.Themes[name]
    if not theme then return end
    if type(name)=="string" then self.Theme=name end
    for key,value in next,theme do self.Colors[key]=value end
    self:UpdateColorsUsingRegistry()
    self:Notify({Title="Theme changed",Content="Applied "..tostring(type(name)=="string" and name or "custom theme"),Duration=3})
end
function L:UpdateColorsUsingRegistry()
    for object,properties in next,self.Registry do
        if object.Parent then for property,key in next,properties do pcall(function()object[property]=themeValue(key)end) end else self.Registry[object]=nil end
    end
    for _,option in next,self.Options do if option.RefreshTheme then option:RefreshTheme() end end
end
function L:ToggleAcrylic(value)
    self.AcrylicRequested=value~=false
end
function L:ToggleTransparency(value) for _,w in ipairs(self.Windows) do tween(w.Panel,{BackgroundTransparency=value and 0.35 or 0.17}) end end
function L:SetMobileMode(value) if self.Window then self.Window:SetMobileMode(value) end end
function L:SetSmallIconEnabled(value) if self.Window then self.Window:SetSmallIconEnabled(value) end end
function L:AttemptSave() if self.SaveManager and self.SaveManager.Save then pcall(function()self.SaveManager:Save()end) end end
function L:Destroy() self:Unload() end
function L:Unload()
    self.Unloaded=true
    for _,fn in ipairs(self.OnUnloadCallbacks) do pcall(fn) end
    for _,s in ipairs(self.Signals) do pcall(function()s:Disconnect()end) end
    Screen:Destroy()
    pcall(function() if typeof(getgenv)=="function" then getgenv().Options=nil;getgenv().Toggles=nil end end)
end

pcall(function() if typeof(getgenv)=="function" then getgenv().Options=L.Options;getgenv().Toggles=L.Toggles end end)
return L
