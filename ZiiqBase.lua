local Library = {}
function Library:CreateWindow(options)
options=options or {}
-- ZIIQ Hub · compact Roblox interface

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local lp     = Players.LocalPlayer
local lpName = lp.Name
local lpId   = lp.UserId

-- Executor APIs vary on mobile; keep the UI usable without optional APIs.
local runtimeEnv = shared or {}
if type(getgenv)=="function" then
    local ok, env=pcall(getgenv)
    if ok and type(env)=="table" then runtimeEnv=env end
end
local function hiddenGuiRoot()
    if type(gethui)=="function" then
        local ok, root=pcall(gethui)
        if ok and typeof(root)=="Instance" then return root end
    end
    return nil
end

-- ════════════════════════════════════════
--  PALETTE  (exact HTML variables)
-- ════════════════════════════════════════
local function hex(h)
    h = h:gsub("#","")
    return Color3.fromRGB(
        tonumber(h:sub(1,2),16),
        tonumber(h:sub(3,4),16),
        tonumber(h:sub(5,6),16))
end
local C = {
    bg0=hex"0b0c0f", bg1=hex"101114", bg2=hex"17191e",
    bg3=hex"1d2026", bg4=hex"292c33",
    bd0=hex"202329", bd1=hex"30343c", bd2=hex"454a54",
    t0=hex"f0f0ed",  t1=hex"b3b4b5",  t2=hex"9a9ca2",  t3=hex"74777f",
    accent=hex"c7c9ce", accentSoft=hex"26282d",
    red=hex"ff5f57", yel=hex"febc2e", grn=hex"28c840",
    -- icon accent colours (ri-* classes)
    ired=hex"ff5f57", iblue=hex"5f8eff", iyel=hex"febc2e",
    igrn=hex"28c840", icyan=hex"28d4d4", ipur=hex"a855ff",
    ipink=hex"ff50a0", iorng=hex"ff8c32",
}

local THEME_KEYS={"bg0","bg1","bg2","bg3","bg4","bd0","bd1","bd2","t0","t1","t2","t3","accent","accentSoft"}
local THEME_PRESETS={
    Black={bg0=hex"0b0c0f",bg1=hex"101114",bg2=hex"17191e",bg3=hex"1d2026",bg4=hex"292c33",bd0=hex"202329",bd1=hex"30343c",bd2=hex"454a54",t0=hex"f0f0ed",t1=hex"b3b4b5",t2=hex"9a9ca2",t3=hex"74777f",accent=hex"c7c9ce",accentSoft=hex"26282d"},
    White={bg0=hex"e9e9ec",bg1=hex"ffffff",bg2=hex"f5f5f7",bg3=hex"ebebef",bg4=hex"dedfe4",bd0=hex"dedfe4",bd1=hex"c9cbd2",bd2=hex"afb2bc",t0=hex"17181c",t1=hex"3e4149",t2=hex"696d77",t3=hex"8b8f98",accent=hex"393d47",accentSoft=hex"e5e6ea"},
    Purple={bg0=hex"0d0a12",bg1=hex"14101b",bg2=hex"1c1726",bg3=hex"272033",bg4=hex"352b45",bd0=hex"30273d",bd1=hex"433656",bd2=hex"5a4772",t0=hex"f5f0fb",t1=hex"c3b8d2",t2=hex"9386a4",t3=hex"62566f",accent=hex"c4a2ff",accentSoft=hex"30213f"},
    Red={bg0=hex"110b0c",bg1=hex"191112",bg2=hex"241719",bg3=hex"321e21",bg4=hex"44272b",bd0=hex"382326",bd1=hex"503035",bd2=hex"704047",t0=hex"faf1f2",t1=hex"d1b8bb",t2=hex"a18488",t3=hex"6d5559",accent=hex"ef7b86",accentSoft=hex"3b2025"},
}
local selectedTheme="Black"
local activeNav
local toggleStates={}

-- ════════════════════════════════════════
--  CLEANUP / UNLOAD SUPPORT
-- ════════════════════════════════════════
local stellarConnections = {}
local function cleanUp()

    for _, c in ipairs(stellarConnections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    table.clear(stellarConnections)

end

-- ════════════════════════════════════════
--  UTILS
-- ════════════════════════════════════════
local function tw(obj,props,dur,style,dir)
    TweenService:Create(obj,
        TweenInfo.new(dur or .18,style or Enum.EasingStyle.Quint,
                      dir  or Enum.EasingDirection.Out),props):Play()
end
local function colorRole(color)
    if typeof(color)~="Color3" then return nil end
    for _,key in ipairs(THEME_KEYS) do
        if C[key]==color then return key end
    end
    return nil
end
local function corner(o,r)
    local u=Instance.new("UICorner"); u.CornerRadius=UDim.new(0,r or 8); u.Parent=o; return u
end
local function stroke(o,clr,t2)
    local s=Instance.new("UIStroke"); s.Color=clr or C.bd0
    s:SetAttribute("_ThemeColorRole",colorRole(s.Color))
    s.Thickness=t2 or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    s.Parent=o; return s
end
local function F(p)
    local f=Instance.new(p.class or "Frame")
    f.BackgroundColor3=typeof(p.bg)=="Color3" and p.bg or C.bg1
    f:SetAttribute("_ThemeColorRole",colorRole(f.BackgroundColor3)); f.BorderSizePixel=0
    f.Size=p.sz or UDim2.fromScale(1,1); f.Position=p.pos or UDim2.new()
    f.ZIndex=p.z or 1; f.ClipsDescendants=p.clip or false
    if p.parent then f.Parent=p.parent end; return f
end
local function L(p)
    local t=Instance.new("TextLabel")
    t.BackgroundTransparency=1; t.Text=p.text or ""
    t.TextColor3=p.color or C.t0; t:SetAttribute("_ThemeTextRole",colorRole(t.TextColor3)); t.Font=p.font or Enum.Font.GothamBold
    t.TextSize=(p.ts or 11) + 1
    t.TextXAlignment=p.xa or Enum.TextXAlignment.Left
    t.TextYAlignment=p.ya or Enum.TextYAlignment.Center
    t.Size=p.sz or UDim2.fromScale(1,1); t.Position=p.pos or UDim2.new()
    t.ZIndex=p.z or 2; t.RichText=p.rich or false
    if p.parent then t.Parent=p.parent end; return t
end
local function B(p)
    local b=Instance.new("TextButton")
    b.BackgroundColor3=p.bg or C.bg4; b:SetAttribute("_ThemeColorRole",colorRole(b.BackgroundColor3)); b.BorderSizePixel=0
    b.Text=p.text or ""; b.TextColor3=p.color or C.t0; b:SetAttribute("_ThemeTextRole",colorRole(b.TextColor3))
    b.Font=p.font or Enum.Font.GothamBold; b.TextSize=(p.ts or 11) + 1
    b.Size=p.sz or UDim2.fromOffset(80,28); b.Position=p.pos or UDim2.new()
    b.ZIndex=p.z or 3; b.AutoButtonColor=false
    b.TextXAlignment=p.xa or Enum.TextXAlignment.Center
    if p.parent then b.Parent=p.parent end; return b
end

local function gradient(o, a, b, rotation)
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new(a,b); g.Rotation=rotation or 0; g.Parent=o
    return g
end

local function addShadow(o, transparency)
    local s=Instance.new("ImageLabel")
    s.Name="Shadow"; s.BackgroundTransparency=1; s.Image="rbxassetid://6014261993"
    s.ImageColor3=Color3.new(0,0,0); s.ImageTransparency=transparency or 0.45
    s.ScaleType=Enum.ScaleType.Slice; s.SliceCenter=Rect.new(49,49,450,450)
    s.Size=UDim2.new(1,34,1,34); s.Position=UDim2.fromOffset(-17,12)
    s.ZIndex=0; s.Parent=o
    return s
end
local function IL(p)
    local i=Instance.new("ImageLabel")
    i.BackgroundTransparency=(p.bgt~=nil)and p.bgt or 1
    i.BackgroundColor3=p.bg or C.bg3; i.Image=p.img or ""
    i.Size=p.sz or UDim2.fromOffset(36,36); i.Position=p.pos or UDim2.new()
    i.ZIndex=p.z or 2; i.ScaleType=Enum.ScaleType.Fit
    i.ImageColor3=p.color or Color3.new(1,1,1)
    i:SetAttribute("_ThemeImageRole",colorRole(i.ImageColor3))
    if p.parent then i.Parent=p.parent end; return i
end

-- ════════════════════════════════════════
--  DROPDOWN TRANSITIONS
-- ════════════════════════════════════════
local function fadeDrop(list, fadeOut, selectedText)
    local dur = 0.2
    for _, ch in ipairs(list:GetChildren()) do
        if ch:IsA("TextButton") then
            local itemStroke=ch:FindFirstChildOfClass("UIStroke")
            if fadeOut then
                tw(ch, {TextTransparency=1, BackgroundTransparency=1}, dur)
                if itemStroke then tw(itemStroke,{Transparency=1},dur) end
            else
                ch.TextTransparency=0
                local selected=type(selectedText)=="table" and selectedText[ch.Text] or ch.Text==selectedText
                if selected then
                    ch.BackgroundColor3 = C.bg3
                    ch.BackgroundTransparency = 0
                    ch.TextColor3 = C.t0
                    if itemStroke then itemStroke.Color=C.bd1; itemStroke.Transparency=0.3 end
                else
                    ch.BackgroundColor3 = C.bg0
                    ch.BackgroundTransparency = 0
                    ch.TextColor3 = C.t1
                    if itemStroke then itemStroke.Color=C.bd0; itemStroke.Transparency=0.48 end
                end
            end
        elseif ch:IsA("UIStroke") then
            if fadeOut then
                tw(ch, {Transparency=1}, dur)
            else
                ch.Transparency=ch.Parent:IsA("TextButton") and 0.5 or 0.18
            end
        end
    end
    if fadeOut then
        tw(list, {BackgroundTransparency=1}, dur)
    else
        list.BackgroundTransparency=0
    end
end

local function getAvatarUrl(uid)
    local ok,res=pcall(function()
        local fn=(syn and syn.request) or (http and http.request) or request
        if type(fn)~="function" then return nil end
        local r=fn({
            Url=("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=150x150&format=Png&isCircular=true"):format(uid),
            Method="GET"})
        if r.StatusCode~=200 then return end
        local d=HttpService:JSONDecode(r.Body)
        return d and d.data and d.data[1] and d.data[1].imageUrl
    end)
    return ok and res or nil
end

-- ════════════════════════════════════════
--  CHAR STATS
-- ════════════════════════════════════════
local function getStats()
    local char=lp.Character
    if not char then return 100,16,50 end
    local h=char:FindFirstChildOfClass("Humanoid")
    if not h then return 100,16,50 end
    return math.round(h.Health), math.round(h.WalkSpeed),
           math.round(h.JumpPower~=0 and h.JumpPower or h.JumpHeight*3.5)
end

-- ════════════════════════════════════════
--  DESTROY OLD
-- ════════════════════════════════════════
pcall(function()
    local hidden=hiddenGuiRoot()
    local playerGui=lp:FindFirstChildOfClass("PlayerGui")
    for _, root in pairs({hidden=hidden,playerGui=playerGui}) do
        local old=root:FindFirstChild("StellarHub")
        if old then old:Destroy() end
    end
end)

local sg=Instance.new("ScreenGui")
sg.Name="StellarHub"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.IgnoreGuiInset=true
pcall(function() sg.Parent=hiddenGuiRoot() end)
if not sg.Parent then sg.Parent=lp:WaitForChild("PlayerGui") end

-- ════════════════════════════════════════
--  WINDOW  760 × 500
-- ════════════════════════════════════════
local WW,WH,SBW=760,500,226
local FULL_SBW=SBW

local win=F({class="Frame",bg=C.bg1,
    sz=UDim2.fromOffset(WW,WH),
    pos=UDim2.new(0.5,0,0.5,0),
    parent=sg,z=2,clip=true})
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.BackgroundTransparency=0
corner(win,12)
local winScale = Instance.new("UIScale")
winScale.Scale = 0
winScale.Parent = win

-- Keep the hub readable on small screens without changing its layout math.
local viewScale = Instance.new("UIScale")
viewScale.Parent = win
local function updateViewScale()
    local cam=workspace.CurrentCamera
    if not cam then return end
    local v=cam.ViewportSize
    viewScale.Scale=math.clamp(math.min((v.X-32)/WW,(v.Y-64)/WH),0.56,1)
end
updateViewScale()
if workspace.CurrentCamera then
    table.insert(stellarConnections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateViewScale))
end

-- Entry / exit animation.
tw(winScale,{Scale=1},0.4,Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ════════════════════════════════════════
--  TITLEBAR (DRAG) & CLOSE
-- ════════════════════════════════════════
-- Visible top bar spanning the full width
local tbar=F({bg=C.bg0,sz=UDim2.new(1,0,0,54),parent=win,z=10})
tbar.BackgroundTransparency = 0
local topRule=F({bg=C.bd0,sz=UDim2.new(1,0,0,1),pos=UDim2.new(0,0,1,-1),parent=tbar,z=13})
topRule:SetAttribute("_ThemeColorRole","bd0")
local crumbSep=F({bg=C.bd0,sz=UDim2.fromOffset(1,24),pos=UDim2.new(0,SBW-1,0.5,-12),parent=tbar,z=13})
crumbSep:SetAttribute("_ThemeColorRole","bd0")
local crumbSection=L({text="Workspace",color=C.t0,ts=14,font=Enum.Font.GothamBold,
    sz=UDim2.new(1,-(SBW+100),0,22),pos=UDim2.new(0,SBW+18,0.5,-11),parent=tbar,z=12})

local uiClosing=false
local mToggleScale
local function closeApp()
    if uiClosing then return end
    uiClosing=true
    local closeDuration=0.38
    tw(winScale,{Scale=0},closeDuration,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
    if mToggleScale and mToggleScale.Parent then
        tw(mToggleScale,{Scale=0},closeDuration,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
    end
    task.delay(closeDuration+0.03,function()
        cleanUp()
        if sg and sg.Parent then sg:Destroy() end
    end)
end

local hubVis=true
local function toggleHub()
    hubVis=not hubVis
    if hubVis then
        win.Visible=true
        tw(winScale,{Scale=1},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    else
        tw(winScale,{Scale=0},0.35,Enum.EasingStyle.Back,Enum.EasingDirection.In)
        task.delay(0.35,function()
            if not hubVis and win.Parent then win.Visible=false end
        end)
    end
end

local function resizeGrip(parent)
    -- Minimal single-stroke minimize control, with an invisible tap target.
    local grip=B({bg=parent.BackgroundColor3,text="",color=C.t1,ts=15,font=Enum.Font.GothamBold,
        sz=UDim2.fromOffset(24,20),pos=UDim2.new(1,-24,1,-20),parent=parent,z=40})
    grip.Name="MinimizeResizeControl"
    grip.BackgroundTransparency=1
    local mark=F({bg=C.t1,sz=UDim2.fromOffset(13,2),pos=UDim2.fromOffset(7,8),parent=grip,z=41})
    mark.Rotation=48
    corner(mark,1)
    grip.MouseEnter:Connect(function() tw(mark,{BackgroundColor3=C.t0},0.14) end)
    grip.MouseLeave:Connect(function() tw(mark,{BackgroundColor3=C.t1},0.18) end)
    return grip
end

-- Header theme selector and compact window controls.
local applyTheme
local headerTheme=B({bg=C.bg2,text="",sz=UDim2.fromOffset(104,28),
    pos=UDim2.new(1,-226,0.5,-14),parent=tbar,z=15})
headerTheme.Name="HeaderThemeSelector"
corner(headerTheme,6)
stroke(headerTheme,C.bd1,1)
local headerThemeLabel=L({text="Dark",color=C.t1,ts=10,font=Enum.Font.GothamBold,
    sz=UDim2.new(1,-28,1,0),pos=UDim2.new(0,10,0,0),parent=headerTheme,z=16})
local caretA=F({bg=C.t2,sz=UDim2.fromOffset(6,2),pos=UDim2.new(1,-21,0.5,-1),parent=headerTheme,z=16})
caretA.Rotation=45
local caretB=F({bg=C.t2,sz=UDim2.fromOffset(6,2),pos=UDim2.new(1,-17,0.5,-1),parent=headerTheme,z=16})
caretB.Rotation=-45
local headerThemeMenu=F({bg=C.bg2,sz=UDim2.fromOffset(104,0),
    pos=UDim2.new(1,-226,0,46),parent=tbar,z=40,clip=true})
headerThemeMenu.Name="HeaderThemeMenu"
corner(headerThemeMenu,7)
local headerThemeMenuStroke=stroke(headerThemeMenu,C.bd1,1)
headerThemeMenu.Visible=false
local themeList={{"Dark","Black"},{"White","White"},{"Purple","Purple"},{"Red","Red"}}
local headerThemeOptions={}
local setHeaderMenuOpen
for i,theme in ipairs(themeList) do
    local displayName,themeName=theme[1],theme[2]
    local option=B({bg=C.bg2,text=displayName,color=C.t1,ts=10,font=Enum.Font.GothamBold,
        sz=UDim2.new(1,-8,0,27),pos=UDim2.new(0,4,0,(i-1)*27+4),parent=headerThemeMenu,z=41,
        xa=Enum.TextXAlignment.Left})
    corner(option,5)
    headerThemeOptions[#headerThemeOptions+1]=option
    option.MouseEnter:Connect(function() tw(option,{BackgroundColor3=C.bg3,TextColor3=C.t0},0.12) end)
    option.MouseLeave:Connect(function() tw(option,{BackgroundColor3=C.bg2,TextColor3=C.t1},0.12) end)
    option.Activated:Connect(function()
        if applyTheme then applyTheme(themeName) end
        headerThemeLabel.Text=displayName
        if setHeaderMenuOpen then setHeaderMenuOpen(false) end
    end)
end
local headerThemeOpen=false
setHeaderMenuOpen=function(open)
    if headerThemeOpen==open then return end
    headerThemeOpen=open
    local targetHeight=open and 116 or 0
    tw(caretA,{Rotation=open and -45 or 45},0.16,Enum.EasingStyle.Quint)
    tw(caretB,{Rotation=open and 45 or -45},0.16,Enum.EasingStyle.Quint)
    if open then
        headerThemeMenu.Visible=true
        headerThemeMenu.Size=UDim2.fromOffset(104,0)
        headerThemeMenu.BackgroundTransparency=1
        headerThemeMenuStroke.Transparency=1
        for _,option in ipairs(headerThemeOptions) do
            option.TextTransparency=1
            option.BackgroundTransparency=1
        end
        tw(headerThemeMenu,{Size=UDim2.fromOffset(104,targetHeight),BackgroundTransparency=0},0.24,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
        tw(headerThemeMenuStroke,{Transparency=0},0.2)
        for i,option in ipairs(headerThemeOptions) do
            task.delay((i-1)*0.025,function()
                if headerThemeOpen and option.Parent then
                    tw(option,{TextTransparency=0,BackgroundTransparency=0},0.18,Enum.EasingStyle.Quint)
                end
            end)
        end
    else
        tw(headerThemeMenu,{Size=UDim2.fromOffset(104,0),BackgroundTransparency=1},0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        tw(headerThemeMenuStroke,{Transparency=1},0.15)
        for _,option in ipairs(headerThemeOptions) do
            tw(option,{TextTransparency=1,BackgroundTransparency=1},0.12)
        end
        task.delay(0.2,function()
            if not headerThemeOpen and headerThemeMenu.Parent then headerThemeMenu.Visible=false end
        end)
    end
end
headerTheme.Activated:Connect(function() setHeaderMenuOpen(not headerThemeOpen) end)
headerThemeLabel.Text=selectedTheme=="Black" and "Dark" or selectedTheme

local animateIslandTap
local function headerControl(kind,x,name,onClick)
    local button=B({bg=C.bg0,text="",sz=UDim2.fromOffset(28,30),
        pos=UDim2.new(1,x,0.5,-15),parent=tbar,z=14})
    button.Name=name
    button.MouseEnter:Connect(function() tw(button,{BackgroundColor3=C.bg3,TextColor3=C.t0},0.12) end)
    button.MouseLeave:Connect(function() tw(button,{BackgroundColor3=C.bg0,TextColor3=C.t1},0.12) end)
    button.Activated:Connect(onClick)
    local function bar(w,h,px,py,rotation)
        local part=F({bg=C.t1,sz=UDim2.fromOffset(w,h),pos=UDim2.new(0.5,px,0.5,py),parent=button,z=15})
        part.AnchorPoint=Vector2.new(0.5,0.5)
        part.Rotation=rotation or 0
        corner(part,1)
        return part
    end
    if kind=="minimize" then
        bar(11,2,0,1,0)
    elseif kind=="restore" then
        local outline=F({bg=C.bg0,sz=UDim2.fromOffset(9,9),pos=UDim2.new(0.5,-4.5,0.5,-4.5),parent=button,z=15})
        outline.BackgroundTransparency=1
        stroke(outline,C.t1,1.5)
    else
        bar(15,2,0,0,45)
        bar(15,2,0,0,-45)
    end
    return button
end
headerControl("close",-42,"Close",function()
    closeApp()
end)
headerControl("restore",-78,"Restore",function()
    win.Size=UDim2.fromOffset(WW,WH)
    win.Position=UDim2.new(0.5,0,0.5,0)
end)
headerControl("minimize",-114,"Minimize",toggleHub)

-- Branding inside the top bar (Top Left)
local myLogoID = "134013054250379"
local logoImg = Instance.new("ImageLabel")
logoImg.BackgroundTransparency = 1
logoImg.Size = UDim2.fromOffset(68, 46)
logoImg.AnchorPoint = Vector2.new(0.5, 0.5)
logoImg.Position = UDim2.new(0, 32, 0.5, 0)
logoImg.Image = "rbxthumb://type=Asset&id="..myLogoID.."&w=420&h=420"
logoImg.ScaleType = Enum.ScaleType.Fit
logoImg.Rotation = 0
-- logoImg.ImageColor3 = hex"ffffff" -- ปิดบรรทัดนี้ไว้เพื่อให้โลโก้แสดงสีต้นฉบับ
logoImg.Parent = tbar
logoImg.ZIndex = 12

local brandName=L({text=options.Title or "ZIIQ",color=C.t0,ts=17,font=Enum.Font.GothamBold,
    sz=UDim2.fromOffset(118,22),pos=UDim2.new(0,72,0,6),parent=tbar,z=11})
local brandSubtitle=L({text=options.Subtitle or "UI Library",color=C.t2,ts=8,font=Enum.Font.GothamBold,
    sz=UDim2.fromOffset(160,14),pos=UDim2.new(0,72,0,32),parent=tbar,z=11})
-- ════════════════════════════════════════
--  SIDEBAR
-- ════════════════════════════════════════
local sb=F({bg=C.bg0,sz=UDim2.new(0,SBW,1,-54),pos=UDim2.new(0,0,0,54),parent=win,z=8})
F({bg=C.bd0,sz=UDim2.new(1,0,0,1),pos=UDim2.new(0,0,1,-1),parent=sb,z=5})

local NAV_DEFS = {}
for i, tab in ipairs(options.Tabs or {{Id="main", Title="General", Section="Workspace", Icon="farm"}}) do
    local id=tab.Id or tostring(i)
    assert(type(id)=="string" and id~="", "Tab Id must be a nonempty string")
    for _, existing in ipairs(NAV_DEFS) do assert(existing.id~=id,"Duplicate tab Id: "..id) end
    table.insert(NAV_DEFS,{id=id,lbl=tab.Title or id,section=tab.Section or "",icon=tab.Icon or "farm"})
end
assert(#NAV_DEFS>0,"At least one tab is required")

local navBtns   = {}
local navSectionLabels={}
local NAV_Y     = 14
local lastSection

local function addIconPart(parent,parts,x,y,w,h,roundness,rotation)
    local part=F({bg=C.t2,sz=UDim2.fromOffset(w,h),pos=UDim2.fromOffset(x,y),parent=parent,z=7})
    part.Rotation=rotation or 0
    if roundness then corner(part,roundness) end
    table.insert(parts,{obj=part,prop="BackgroundColor3"})
    return part
end

local function buildNavIcon(parent,kind)
    local holder=F({bg=C.bg0,sz=UDim2.fromOffset(26,26),pos=UDim2.new(0,7,0.5,-13),parent=parent,z=6})
    holder.BackgroundTransparency=1
    local parts={}
    if kind=="farm" then
        addIconPart(holder,parts,4,14,3,8,1)
        addIconPart(holder,parts,10,9,3,13,1)
        addIconPart(holder,parts,16,4,3,18,1)
    elseif kind=="combat" then
        local ring=F({bg=C.bg0,sz=UDim2.fromOffset(14,14),pos=UDim2.fromOffset(6,6),parent=holder,z=7})
        ring.BackgroundTransparency=1
        corner(ring,8)
        local outline=stroke(ring,C.t2,1.5)
        table.insert(parts,{obj=outline,prop="Color"})
        addIconPart(holder,parts,11,1,2,4,1)
        addIconPart(holder,parts,11,21,2,4,1)
        addIconPart(holder,parts,1,11,4,2,1)
        addIconPart(holder,parts,21,11,4,2,1)
        addIconPart(holder,parts,11,11,4,4,3)
    elseif kind=="move" then
        addIconPart(holder,parts,4,12,14,2,1,-45)
        addIconPart(holder,parts,15,3,2,8,1)
        addIconPart(holder,parts,10,3,7,2,1)
    else
        addIconPart(holder,parts,5,5,16,2,1)
        addIconPart(holder,parts,5,12,16,2,1)
        addIconPart(holder,parts,5,19,16,2,1)
        addIconPart(holder,parts,8,4,4,4,2)
        addIconPart(holder,parts,15,11,4,4,2)
        addIconPart(holder,parts,10,18,4,4,2)
    end
    return holder,parts
end

-- Build nav items
for i=1,#NAV_DEFS do
    local nd = NAV_DEFS[i]
    if nd.section~="" and nd.section~=lastSection then
        local sectionLabel=L({text=nd.section,color=C.t2,ts=11,font=Enum.Font.GothamBold,
            sz=UDim2.new(1,-32,0,16),pos=UDim2.new(0,14,0,NAV_Y),parent=sb,z=6})
        table.insert(navSectionLabels,sectionLabel)
        NAV_Y=NAV_Y+22
        lastSection=nd.section
    end
    local btnPos = UDim2.new(0,12,0,NAV_Y)
    local btn=B({bg=C.bg2,text="",sz=UDim2.new(1,-24,0,40),
        pos=btnPos,parent=sb,z=5})
    corner(btn,7)
    btn.BackgroundTransparency = 1
    local chip,iconParts=buildNavIcon(btn,nd.icon)
    local lblT=L({text=nd.lbl,color=C.t1,ts=12,font=Enum.Font.GothamBold,
        sz=UDim2.new(1,-52,1,0),pos=UDim2.new(0,44,0,0),parent=btn,z=6})
    navBtns[nd.id]={btn=btn,lbl=lblT,chip=chip,iconParts=iconParts,y=NAV_Y}
    NAV_Y=NAV_Y+46
end

local profileRule=F({bg=C.bd0,sz=UDim2.new(1,-28,0,1),pos=UDim2.new(0,14,1,-54),parent=sb,z=5})
profileRule:SetAttribute("_ThemeColorRole","bd0")
local profileAvatarBack=F({bg=C.bg3,sz=UDim2.fromOffset(36,36),pos=UDim2.new(0,12,1,-44),parent=sb,z=6})
corner(profileAvatarBack,8)
L({text=string.upper(string.sub(lpName,1,1)),color=C.t1,ts=12,font=Enum.Font.GothamBold,
    sz=UDim2.fromScale(1,1),parent=profileAvatarBack,z=7,xa=Enum.TextXAlignment.Center})
local profileAvatar=Instance.new("ImageLabel")
profileAvatar.Name="PlayerHeadshot"
profileAvatar.BackgroundTransparency=1
profileAvatar.Size=UDim2.fromOffset(36,36)
profileAvatar.Position=UDim2.new(0,12,1,-44)
profileAvatar.ScaleType=Enum.ScaleType.Crop
profileAvatar.ZIndex=8
profileAvatar.Parent=sb
corner(profileAvatar,8)
task.spawn(function()
    local ok,image=pcall(function()
        return Players:GetUserThumbnailAsync(lpId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
    end)
    if ok and profileAvatar.Parent then profileAvatar.Image=image end
end)
local profileName=L({text=lpName,color=C.t0,ts=11,font=Enum.Font.GothamBold,
    sz=UDim2.new(1,-68,0,16),pos=UDim2.new(0,58,1,-39),parent=sb,z=6})
local profileCaption=L({text="PLAYER PROFILE",color=C.t3,ts=8,font=Enum.Font.GothamBold,
    sz=UDim2.new(1,-68,0,12),pos=UDim2.new(0,58,1,-23),parent=sb,z=6})
-- ════════════════════════════════════════
--  CONTENT AREA
-- ════════════════════════════════════════
local content=F({bg=C.bg1,sz=UDim2.new(1,-SBW,1,-54),pos=UDim2.new(0,SBW,0,54),parent=win,z=4})
local splitRule=F({bg=C.bd0,sz=UDim2.new(0,1,1,-54),pos=UDim2.new(0,SBW-1,0,54),parent=win,z=13})
splitRule:SetAttribute("_ThemeColorRole","bd0")

local function updateResponsiveLayout()
    local compact=WW<620
    SBW=compact and 64 or FULL_SBW
    sb.Size=UDim2.new(0,SBW,1,-54)
    content.Position=UDim2.new(0,SBW,0,54)
    content.Size=UDim2.new(1,-SBW,1,-54)
    splitRule.Position=UDim2.new(0,SBW-1,0,54)
    crumbSep.Position=UDim2.new(0,SBW-1,0.5,-12)
    crumbSection.Position=UDim2.new(0,SBW+(compact and 14 or 18),0.5,-9)
    crumbSection.Size=UDim2.new(1,-(SBW+100),0,18)
    -- In icon-rail mode, let the brand mark fill the compact header cell.
    logoImg.Position=UDim2.new(0,32,0.5,0)
    logoImg.Size=compact and UDim2.fromOffset(54,50) or UDim2.fromOffset(68,46)
    logoImg.ZIndex=14
    brandName.Visible=not compact
    brandSubtitle.Visible=not compact

    for _,sectionLabel in ipairs(navSectionLabels) do
        sectionLabel.Visible=not compact
    end
    for i,nd in ipairs(NAV_DEFS) do
        local nav=navBtns[nd.id]
        if nav then
            nav.btn.Position=compact and UDim2.new(0,10,0,14+(i-1)*48) or UDim2.new(0,12,0,nav.y)
            nav.btn.Size=compact and UDim2.new(1,-20,0,42) or UDim2.new(1,-24,0,40)
            nav.lbl.Visible=not compact
        end
    end

    local avatarX=compact and math.floor((SBW-36)/2) or 12
    profileRule.Position=UDim2.new(0,compact and 8 or 14,1,-54)
    profileRule.Size=UDim2.new(1,compact and -16 or -28,0,1)
    profileAvatarBack.Position=UDim2.new(0,avatarX,1,-44)
    profileAvatar.Position=UDim2.new(0,avatarX,1,-44)
    profileName.Visible=not compact
    profileCaption.Visible=not compact
    updateViewScale()
end
updateResponsiveLayout()
table.insert(stellarConnections,win:GetPropertyChangedSignal("Size"):Connect(updateResponsiveLayout))

applyTheme=function(themeName)
    local preset=THEME_PRESETS[themeName]
    if not preset then return end
    selectedTheme=themeName
    if headerThemeLabel and headerThemeLabel.Parent then
        headerThemeLabel.Text=themeName=="Black" and "Dark" or themeName
    end
    for _,key in ipairs(THEME_KEYS) do C[key]=preset[key] end

    local function animateColor(obj,property,color)
        tw(obj,{[property]=color},0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
    end
    for _,obj in ipairs(sg:GetDescendants()) do
        local role=obj:GetAttribute("_ThemeColorRole")
        if role and preset[role] then
            if obj:IsA("UIStroke") then
                animateColor(obj,"Color",preset[role])
            elseif obj:IsA("GuiObject") then
                animateColor(obj,"BackgroundColor3",preset[role])
            end
        end
        local textRole=obj:GetAttribute("_ThemeTextRole")
        if textRole and preset[textRole] and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
            animateColor(obj,"TextColor3",preset[textRole])
        end
        local imageRole=obj:GetAttribute("_ThemeImageRole")
        if imageRole and preset[imageRole] and (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
            animateColor(obj,"ImageColor3",preset[imageRole])
        end
        local semantic=obj:GetAttribute("_ThemeSemantic")
        if semantic=="ToggleTrack" then
            local key=obj:GetAttribute("_ToggleKey")
            animateColor(obj,"BackgroundColor3",toggleStates[key] and C.accentSoft or C.bg4)
        elseif semantic=="ToggleKnob" then
            local key=obj:GetAttribute("_ToggleKey")
            animateColor(obj,"BackgroundColor3",toggleStates[key] and C.accent or C.bg3)
        end
    end
    for id,nav in pairs(navBtns) do
        local selected=id==activeNav
        tw(nav.btn,{BackgroundColor3=selected and C.accentSoft or C.bg0,
            BackgroundTransparency=selected and 0 or 1},0.25)
        tw(nav.lbl,{TextColor3=selected and C.t0 or C.t1},0.25)
        for _,part in ipairs(nav.iconParts) do
            tw(part.obj,{[part.prop]=selected and C.accent or C.t2},0.25)
        end
    end
end

-- ════════════════════════════════════════
--  PANEL HELPERS
-- ════════════════════════════════════════

-- Create a ScrollingFrame panel (mimics .cnt with overflow-y:auto)
local function makePanel()
    local sf=Instance.new("ScrollingFrame")
    sf.BackgroundTransparency=1
    sf.BorderSizePixel=0
    sf.Size=UDim2.new(1,-4,1,0)
    sf.Position=UDim2.new(0,4,0,0)
    sf.ScrollBarThickness=0
    sf.CanvasSize=UDim2.fromOffset(0,0)  -- will be set per panel
    sf.ScrollingDirection=Enum.ScrollingDirection.Y
    sf.ClipsDescendants=true
    sf.ZIndex=6
    sf.Visible=false
    sf.Parent=content
    return sf
end

local function secLbl(txt,parent,y)
    L({text=txt:upper(),color=C.t0,ts=11,font=Enum.Font.GothamBold,
       sz=UDim2.new(1,-44,0,18),pos=UDim2.new(0,20,0,y+2),parent=parent,z=6})
end

-- Row: bg2 rounded frame, hover → bg3
local function mkRow(parent,y,h,card)
    h=h or 46
    local r=F({bg=C.bg1,sz=UDim2.new(1,-40,0,h),pos=UDim2.new(0,20,0,y),parent=parent,z=6})
    if card then
        corner(r,8)
        stroke(r,C.bd0,1)
    else
        local divider=F({bg=C.bd0,sz=UDim2.new(1,0,0,1),pos=UDim2.new(0,0,1,-1),parent=r,z=7})
        divider.Name="RowDivider"
        divider:SetAttribute("_ThemeColorRole","bd0")
    end
    return r
end

-- Row text (title + subtitle), positioned right of icon badge
local function rowTxt(parent,title,sub)
    local x = 14
    local yC = math.floor((parent.Size.Y.Offset - 16)/2)
    L({text=title,color=C.t1,ts=13,font=Enum.Font.GothamBold,
       sz=UDim2.new(1,-x-24,0,16),pos=UDim2.new(0,x,0,sub and 6 or yC),parent=parent,z=7})
    if sub then
        L({text=sub,color=C.t2,ts=11,font=Enum.Font.GothamBold,
           sz=UDim2.new(1,-x-24,0,14),pos=UDim2.new(0,x,0,26),parent=parent,z=7})
    end
end

-- ── TOGGLE  (pure Roblox, no CSS) ──────
local function mkToggle(parent,key,cb)
    local wrap=F({bg=C.bg4,sz=UDim2.fromOffset(36,20),pos=UDim2.new(1,-48,0.5,-10),parent=parent,z=7})
    wrap:SetAttribute("_ThemeSemantic","ToggleTrack"); wrap:SetAttribute("_ToggleKey",key)
    corner(wrap,10)
    
    local knob=F({bg=C.bg3,sz=UDim2.fromOffset(14,14),pos=UDim2.new(0,3,0.5,-7),parent=wrap,z=8})
    knob:SetAttribute("_ThemeSemantic","ToggleKnob"); knob:SetAttribute("_ToggleKey",key)
    corner(knob,7)
    toggleStates[key]=false
    local tb=B({bg=hex"000000",sz=UDim2.fromScale(1,1),parent=wrap,z=9})
    tb.BackgroundTransparency=1
    tb.Activated:Connect(function()
        toggleStates[key]=not toggleStates[key]
        local on=toggleStates[key]
        tw(wrap,{BackgroundColor3=on and C.accentSoft or C.bg4},0.22)
        tw(knob,{Position=on and UDim2.new(0,19,0.5,-7) or UDim2.new(0,3,0.5,-7),
                 BackgroundColor3=on and C.accent or C.bg3},0.28,Enum.EasingStyle.Back)
        if cb then cb(on) end
    end)
    return tb
end

-- ── DROPDOWN HELPER ──────
local activeDropdownClose
local function mkDrop(parent, y, label, getOpts, defaultTxt, cb, fixedWidth, multiSelect)
    local dr=mkRow(parent, y, 42, true)
    -- Keep the dropdown card compact; its option list is a floating popup.
    dr.BackgroundTransparency=1
    local rowStroke=dr:FindFirstChildOfClass("UIStroke")
    if rowStroke then rowStroke:Destroy() end
    local ddCard=F({bg=C.bg1,sz=UDim2.new(1,0,0,42),parent=dr,z=6})
    corner(ddCard,8); stroke(ddCard,C.bd0,1)
    L({text=label, color=C.t1, ts=13, font=Enum.Font.GothamBold,
       sz=UDim2.new(0,110,0,16), pos=UDim2.new(0,14,0,13), parent=dr, z=7})
       
    local initW = fixedWidth or 180
    local ddTrig=F({bg=C.bg2,sz=UDim2.fromOffset(initW,28),pos=UDim2.new(1,-initW-12,0,7),parent=dr,z=7})
    corner(ddTrig,6); stroke(ddTrig,C.bd0,1)
    local ddL=L({text=defaultTxt or "",color=C.t0,ts=12,font=Enum.Font.GothamBold,
        sz=UDim2.new(1,-40,1,0),pos=UDim2.new(0,12,0,0),parent=ddTrig,z=8})
    ddL.TextTruncate=Enum.TextTruncate.AtEnd
    local ddCaretL=F({bg=C.t1,sz=UDim2.fromOffset(8,2),pos=UDim2.new(1,-25,0.5,-1),parent=ddTrig,z=8})
    local ddCaretR=F({bg=C.t1,sz=UDim2.fromOffset(8,2),pos=UDim2.new(1,-21,0.5,-1),parent=ddTrig,z=8})
    ddCaretL.Rotation=45
    ddCaretR.Rotation=-45
       
    local ddOpen=false
    local contentHeight=0
    local selectedOptions={}
    -- Popup is a content-layer sibling: it overlays rows without changing
    -- their layout, while inheriting the window's scale and coordinate space.
    local ddList=F({class="ScrollingFrame",bg=C.bg1,sz=UDim2.fromOffset(initW,0),parent=content,z=100,clip=true})
    ddList.ScrollingDirection=Enum.ScrollingDirection.Y
    ddList.ScrollingEnabled=true
    ddList.Active=true
    ddList.ElasticBehavior=Enum.ElasticBehavior.WhenScrollable
    ddList.ScrollBarThickness=3
    ddList.ScrollBarImageColor3=C.t3
    ddList.ScrollBarImageTransparency=0.15
    ddList.CanvasSize=UDim2.fromOffset(0,0)
    corner(ddList,8)
    local ddListStroke=stroke(ddList,C.bd1,1)
    ddListStroke.Transparency=0.18
    ddList.Visible=false
    
    local ddb=B({bg=hex"000000",sz=UDim2.fromScale(1,1),parent=ddTrig,z=9})
    ddb.BackgroundTransparency=1
    
    local function updDropSize()
        local p=ddTrig.AbsolutePosition
        local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        local viewportH=viewport and viewport.Y or 600
        local scale=math.max(viewScale.Scale,0.01)
        local below=math.max(0,(viewportH-(p.Y+ddTrig.AbsoluteSize.Y+8*scale))/scale)
        local maxH=math.min(contentHeight,220)
        return math.max(1,math.min(maxH,below))
    end

    local closeDrop
    
    local function populate()
        for _,ch in ipairs(ddList:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        local opts = type(getOpts)=="function" and getOpts() or getOpts
        if #opts==0 then return 0, initW end
        
        local ddW = fixedWidth or 180
        local rowHeight=36
        local itemHeight=30
        local inset=6
        
        ddTrig.Size = UDim2.fromOffset(ddW,28)
        ddTrig.Position = UDim2.new(1,-ddW-12,0,8)
        
        local h = #opts*rowHeight+12
        contentHeight=h
        ddList.CanvasPosition=Vector2.new(0,0)
        ddList.CanvasSize=UDim2.fromOffset(ddW,h)
        for i,opt in ipairs(opts) do
            local item=B({bg=C.bg0,text=opt,color=C.t1,ts=11,font=Enum.Font.GothamBold,
                sz=UDim2.new(1,-12,0,itemHeight),pos=UDim2.new(0,inset,0,(i-1)*rowHeight+6),parent=ddList,z=101,xa=Enum.TextXAlignment.Left})
            item.TextTruncate=Enum.TextTruncate.AtEnd
            corner(item,4)
            local itemPadding=Instance.new("UIPadding")
            itemPadding.PaddingLeft=UDim.new(0,10)
            itemPadding.PaddingRight=UDim.new(0,8)
            itemPadding.Parent=item
            local itemStroke=stroke(item,C.bd0,1)
            itemStroke.Transparency=0.5
            local function paintItem()
                local selected=multiSelect and selectedOptions[opt] or (opt==ddL.Text)
                tw(item,{BackgroundColor3=selected and C.bg3 or C.bg0,
                    BackgroundTransparency=0,
                    TextColor3=selected and C.t0 or C.t1},0.1)
                tw(itemStroke,{Color=selected and C.bd1 or C.bd0,
                    Transparency=selected and 0.3 or 0.48},0.1)
            end
            item.MouseEnter:Connect(function()
                if ddOpen then
                    local selected=multiSelect and selectedOptions[opt] or (opt==ddL.Text)
                    tw(item,{BackgroundColor3=selected and C.bg3 or C.bg2,
                        BackgroundTransparency=0,TextColor3=C.t0},0.12)
                    tw(itemStroke,{Color=C.bd1,Transparency=0.22},0.12)
                end
            end)
            item.MouseLeave:Connect(function() 
                if ddOpen then paintItem() end
            end)
            item.Activated:Connect(function()
                if not ddOpen then return end
                if multiSelect then
                    selectedOptions[opt]=not selectedOptions[opt] or nil
                    local chosen={}
                    for _,value in ipairs(opts) do
                        if selectedOptions[value] then table.insert(chosen,value) end
                    end
                    ddL.Text=#chosen>0 and (tostring(#chosen).." selected") or (defaultTxt or "Select")
                    paintItem()
                    if cb then cb(chosen,i) end
                    return
                end
                ddL.Text=opt
                closeDrop()
                if cb then cb(opt, i) end
            end)
        end
        return h, ddW
    end

    closeDrop=function()
        if not ddOpen then return end
        ddOpen=false
        tw(ddCaretL,{Rotation=45},0.14)
        tw(ddCaretR,{Rotation=-45},0.14)
        fadeDrop(ddList,true)
        tw(ddList,{Size=UDim2.fromOffset(ddList.Size.X.Offset,0)},0.2,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        if activeDropdownClose==closeDrop then activeDropdownClose=nil end
        task.delay(0.25,function() if not ddOpen then ddList.Visible=false end end)
    end
    
    ddb.Activated:Connect(function() 
        if not ddOpen then
            if activeDropdownClose then activeDropdownClose() end
            ddOpen=true
            activeDropdownClose=closeDrop
            local h, w = populate()
            if h==0 then ddOpen=false; return end
            local viewH=updDropSize()
            fadeDrop(ddList, false, multiSelect and selectedOptions or ddL.Text)
            ddList.Visible=true
            tw(ddCaretL,{Rotation=-45},0.14)
            tw(ddCaretR,{Rotation=45},0.14)
            local triggerPos=ddTrig.AbsolutePosition
            local triggerSize=ddTrig.AbsoluteSize
            local scale=math.max(viewScale.Scale,0.01)
            local contentPos=content.AbsolutePosition
            local popupWidth=triggerSize.X/scale
            local listX=(triggerPos.X-contentPos.X)/scale
            local listY=(triggerPos.Y-contentPos.Y+triggerSize.Y)/scale+4
            ddList.Size=UDim2.fromOffset(popupWidth,0)
            ddList.Position=UDim2.fromOffset(listX,listY)
            tw(ddList,{Size=UDim2.fromOffset(popupWidth,viewH)},0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
        else
            closeDrop()
        end
    end)

    if parent:IsA("ScrollingFrame") then
        parent:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if ddOpen then closeDrop() end
        end)
    end

    populate()
    
    return dr, function(newTxt)
        ddL.Text = newTxt
        populate()
    end
end

-- ════════════════════════════════════════
--  MAIN PANEL
-- ════════════════════════════════════════




local function addPageHeader(parent,title,subtitle)
    -- The selected page name is already shown in the top bar; keep only
    -- compact, meaningful section labels above the controls.
    return 12
end

local keybinds={toggleUI=options.ToggleKey or Enum.KeyCode.RightShift}
local panelMap={}
for _, definition in ipairs(NAV_DEFS) do panelMap[definition.id]=makePanel() end
local function switchPanel(id)
    if activeDropdownClose then activeDropdownClose() end
    for k,p in pairs(panelMap) do p.Visible=(k==id) end
    local nd=navBtns[id]
    crumbSection.Text=(nd and nd.lbl and nd.lbl.Text) or "Workspace"
    for k,nd in pairs(navBtns) do
        local on=(k==id)
        tw(nd.btn,{BackgroundTransparency=on and 0 or 1, BackgroundColor3=on and C.accentSoft or C.bg0},0.14)
        tw(nd.lbl,{TextColor3=on and C.t0 or C.t1},0.14)
        for _,part in ipairs(nd.iconParts) do
            tw(part.obj,{[part.prop]=on and C.accent or C.t2},0.14)
        end
    end
    activeNav=id
end

-- Wire nav buttons
for id,nd in pairs(navBtns) do
    nd.btn.Activated:Connect(function() switchPanel(id) end)
    nd.btn.MouseEnter:Connect(function()
        if activeNav~=id then tw(nd.btn,{BackgroundTransparency=0, BackgroundColor3=C.bg1},0.12) end
    end)
    nd.btn.MouseLeave:Connect(function()
        if activeNav~=id then tw(nd.btn,{BackgroundTransparency=1},0.16) end
    end)
end

task.defer(function() if sg.Parent then switchPanel(NAV_DEFS[1].id) end end)

-- ════════════════════════════════════════
--  DRAG
-- ════════════════════════════════════════
do
    local dragging,ds,sp=false
    tbar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; ds=inp.Position; sp=win.Position
        end
    end)
    tbar.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    table.insert(stellarConnections, UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end))
end

-- ════════════════════════════════════════
--  TOGGLE VISIBILITY
-- ════════════════════════════════════════
local UISConn
UISConn = UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==keybinds.toggleUI then toggleHub() end
end)
table.insert(stellarConnections, UISConn)

-- ════════════════════════════════════════
--  AVATAR → profile nav button (REMOVED)
-- ════════════════════════════════════════

-- ════════════════════════════════════════
--  RESIZE GRIP (Bottom Right)
-- ════════════════════════════════════════
local rGrip=resizeGrip(win)
local resizing = false
local resizeMoved = false
local rStartPos, rStartSize, rStartScale
rGrip.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeMoved = false
        rStartPos = inp.Position
        rStartSize = Vector2.new(win.Size.X.Offset,win.Size.Y.Offset)
        rStartScale = math.max(viewScale.Scale,0.1)
    end
end)
table.insert(stellarConnections,UserInputService.InputEnded:Connect(function(inp)
    if resizing and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
        resizing = false
        if not resizeMoved then toggleHub() end
    end
end))
table.insert(stellarConnections,UserInputService.InputChanged:Connect(function(inp)
    if resizing and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - rStartPos
        if delta.Magnitude>6 then resizeMoved=true end
        if not resizeMoved then return end
        local newW = math.clamp(rStartSize.X + delta.X/rStartScale, 480, 1000)
        local newH = math.clamp(rStartSize.Y + delta.Y/rStartScale, 300, 800)
        win.Size = UDim2.fromOffset(newW, newH)
        WW, WH = newW, newH
        updateResponsiveLayout()
    end
end))

-- ════════════════════════════════════════
--  MOBILE TOGGLE (Draggable ZIIQ pill)
-- ════════════════════════════════════════
local meteorLayer=Instance.new("Frame")
meteorLayer.Name="MobileMeteorLayer"
meteorLayer.BackgroundTransparency=1
meteorLayer.Size=UDim2.fromScale(1,1)
meteorLayer.Active=false
meteorLayer.Parent=sg
meteorLayer.ZIndex=997

local mToggle = Instance.new("ImageButton")
mToggle.Size = UDim2.fromOffset(204, 56)
mToggle.AnchorPoint = Vector2.new(0.5, 0)
mToggle.Position = UDim2.new(0.5, 0, 0, 15)
mToggle.BackgroundColor3 = C.bg0
mToggle:SetAttribute("_ThemeColorRole","bg0")
mToggle.BackgroundTransparency = 0.04
mToggle.BorderSizePixel = 0
mToggle.AutoButtonColor = false
mToggle.Active = true
mToggle.Selectable = true
corner(mToggle,23)
mToggle.BackgroundColor3=C.bg0
local mToggleStroke=stroke(mToggle,C.accent,1.25)
mToggleStroke.Transparency=0.62
mToggle.ClipsDescendants = true
mToggle.Parent = sg
mToggle.ZIndex = 999

mToggleScale=Instance.new("UIScale")
mToggleScale.Scale=1
mToggleScale.Parent=mToggle

local mSheen=Instance.new("Frame")
mSheen.Name="SoftSheen"
mSheen.BackgroundColor3=C.t0
mSheen.BackgroundTransparency=0.82
mSheen.BorderSizePixel=0
mSheen.Size=UDim2.fromOffset(26,78)
mSheen.Position=UDim2.new(0,-42,0.5,-39)
mSheen.Rotation=18
mSheen.ZIndex=999
mSheen.Parent=mToggle
local sheenGradient=Instance.new("UIGradient")
sheenGradient.Transparency=NumberSequence.new({
    NumberSequenceKeypoint.new(0,1),
    NumberSequenceKeypoint.new(0.5,0.2),
    NumberSequenceKeypoint.new(1,1),
})
sheenGradient.Parent=mSheen

local mLogo = Instance.new("ImageLabel")
mLogo.BackgroundTransparency = 1
mLogo.Size = UDim2.fromOffset(82,54)
mLogo.AnchorPoint = Vector2.new(0.5,0.5)
mLogo.Position = UDim2.new(0,42,0.5,0)
mLogo.Image = "rbxthumb://type=Asset&id="..myLogoID.."&w=420&h=420"
mLogo.ScaleType = Enum.ScaleType.Fit
mLogo.Rotation = 0
mLogo.Parent = mToggle
mLogo.ZIndex = 1000

local mBrandLabel=L({text=options.Title or "ZIIQ",color=C.t0,ts=14,font=Enum.Font.GothamBold,
    sz=UDim2.fromOffset(68,56),pos=UDim2.new(0,78,0,0),parent=mToggle,z=1000,
    xa=Enum.TextXAlignment.Center})

local mAvatar=Instance.new("ImageLabel")
mAvatar.Name="MobileProfileHeadshot"
mAvatar.BackgroundColor3=C.bg3
mAvatar.BackgroundTransparency=0
mAvatar.Size=UDim2.fromOffset(38,38)
mAvatar.Position=UDim2.new(1,-44,0.5,-19)
mAvatar.Image=profileAvatar.Image
mAvatar.ScaleType=Enum.ScaleType.Crop
mAvatar.Parent=mToggle
mAvatar.ZIndex=1000
corner(mAvatar,11)
stroke(mAvatar,C.bd1,1)
table.insert(stellarConnections,profileAvatar:GetPropertyChangedSignal("Image"):Connect(function()
    if mAvatar.Parent then mAvatar.Image=profileAvatar.Image end
end))

-- Quiet premium accent: a slow breathing outline and an occasional soft sheen.
task.spawn(function()
    while sg.Parent and mToggle.Parent do
        local pulse=TweenService:Create(mToggleStroke,
            TweenInfo.new(1.25,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
            {Transparency=0.34})
        pulse:Play(); pulse.Completed:Wait()
        if not sg.Parent or not mToggle.Parent then break end
        local rest=TweenService:Create(mToggleStroke,
            TweenInfo.new(1.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
            {Transparency=0.72})
        rest:Play(); rest.Completed:Wait()
        if not sg.Parent or not mToggle.Parent then break end
        task.wait(1.4)
        mSheen.Position=UDim2.new(0,-42,0.5,-39)
        tw(mSheen,{Position=UDim2.new(1,20,0.5,-39)},0.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
        task.wait(4.8)
    end
end)

local function spawnMeteor()
    if not sg.Parent or not mToggle.Visible then return end
    local p=mToggle.AbsolutePosition
    local s=mToggle.AbsoluteSize
    local fromLeft=math.random(0,1)==0
    local y=p.Y+math.random(-7,s.Y+7)
    local startX=fromLeft and (p.X-28) or (p.X+s.X+28)
    local endX=fromLeft and (p.X+s.X+30) or (p.X-30)
    local trail=Instance.new("Frame")
    trail.Name="MeteorTrail"
    trail.BorderSizePixel=0
    trail.BackgroundColor3=C.accent
    trail.BackgroundTransparency=0.18
    trail:SetAttribute("_ThemeColorRole","accent")
    trail.Size=UDim2.fromOffset(math.random(20,34),1.5)
    trail.Position=UDim2.fromOffset(startX,y)
    trail.Rotation=fromLeft and -18 or 18
    trail.ZIndex=998
    trail.Parent=meteorLayer
    local fade=Instance.new("UIGradient")
    fade.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.55,0.12),
        NumberSequenceKeypoint.new(1,1),
    })
    fade.Parent=trail
    TweenService:Create(trail,TweenInfo.new(0.85,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{
        Position=UDim2.fromOffset(endX,y-math.random(8,18)),
        BackgroundTransparency=1,
    }):Play()
    task.delay(0.9,function() if trail.Parent then trail:Destroy() end end)
end

task.spawn(function()
    while sg.Parent do
        task.wait(math.random(9,16)/10)
        spawnMeteor()
    end
end)

local tDrag, tStartPos, tDragStart, didMove, islandAnimating = false, nil, nil, false, false
local mToggleCorner=mToggle:FindFirstChildOfClass("UICorner")
animateIslandTap=function()
    if islandAnimating then return end
    islandAnimating=true
    local openInfo=TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
    TweenService:Create(mToggle,openInfo,{Size=UDim2.fromOffset(232,64)}):Play()
    TweenService:Create(mLogo,openInfo,{Size=UDim2.fromOffset(88,58),Position=UDim2.new(0,46,0.5,0)}):Play()
    TweenService:Create(mBrandLabel,openInfo,{Position=UDim2.new(0,83,0,0)}):Play()
    TweenService:Create(mAvatar,openInfo,{Size=UDim2.fromOffset(42,42),Position=UDim2.new(1,-49,0.5,-21)}):Play()
    TweenService:Create(mToggleStroke,openInfo,{Transparency=0.24,Thickness=1.6}):Play()
    if mToggleCorner then
        TweenService:Create(mToggleCorner,openInfo,{CornerRadius=UDim.new(0,32)}):Play()
    end
    TweenService:Create(mToggleScale,openInfo,{Scale=1.025}):Play()

    -- Reveal the main panel near the peak of the capsule's expansion.
    task.delay(0.12,toggleHub)
    task.delay(0.34,function()
        if not mToggle.Parent then return end
        local settle=TweenInfo.new(0.32,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        TweenService:Create(mToggle,settle,{Size=UDim2.fromOffset(204,56)}):Play()
        TweenService:Create(mLogo,settle,{Size=UDim2.fromOffset(82,54),Position=UDim2.new(0,42,0.5,0)}):Play()
        TweenService:Create(mBrandLabel,settle,{Position=UDim2.new(0,78,0,0)}):Play()
        TweenService:Create(mAvatar,settle,{Size=UDim2.fromOffset(38,38),Position=UDim2.new(1,-44,0.5,-19)}):Play()
        TweenService:Create(mToggleStroke,settle,{Transparency=0.62,Thickness=1.25}):Play()
        TweenService:Create(mToggleScale,settle,{Scale=1}):Play()
        if mToggleCorner then TweenService:Create(mToggleCorner,settle,{CornerRadius=UDim.new(0,23)}):Play() end
        task.delay(0.34,function() islandAnimating=false end)
    end)
end
table.insert(stellarConnections, mToggle.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        if islandAnimating then return end
        tw(mToggleScale,{Scale=0.97},0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
        tDrag = true
        tDragStart = inp.Position
        tStartPos = mToggle.Position
        didMove=false
    end
end))
table.insert(stellarConnections, mToggle.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        if not tDrag then return end
        tDrag = false
        if not didMove then animateIslandTap() end
    end
end))
table.insert(stellarConnections, UserInputService.InputChanged:Connect(function(inp)
    if tDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - tDragStart
        if delta.Magnitude>8 then didMove=true end
        if didMove then
            mToggle.Position = UDim2.new(
                tStartPos.X.Scale, tStartPos.X.Offset + delta.X,
                tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y
            )
        end
    end
end))

local window={Tabs={},Gui=sg}
local function invoke(callback,value)
    if type(callback)=="function" then
        task.spawn(function()
            local ok,err=pcall(callback,value)
            if not ok then warn("ZIIQ callback: "..tostring(err)) end
        end)
    end
end
for id,panel in pairs(panelMap) do
    local tab={Panel=panel,_y=12,_count=0}
    local function advance(height)
        local y=tab._y
        tab._y=y+height
        panel.CanvasSize=UDim2.fromOffset(0,tab._y+16)
        return y
    end
    function tab:AddSection(title)
        secLbl(title,panel,advance(30))
    end
    function tab:AddButton(config)
        config=config or {}
        local row=mkRow(panel,advance(56),50,true)
        rowTxt(row,config.Title or "Button",config.Description)
        local button=B({text=config.ButtonText or "Run",parent=row,sz=UDim2.fromOffset(90,28),pos=UDim2.new(1,-102,0.5,-14)})
        button.ZIndex=9; corner(button,6)
        button.Activated:Connect(function() invoke(config.Callback) end)
        return button
    end
    function tab:AddToggle(config)
        config=config or {}
        self._count=self._count+1
        local key=id..":"..self._count
        local row=mkRow(panel,advance(56),50,true)
        rowTxt(row,config.Title or "Toggle",config.Description)
        mkToggle(row,key,function(value) invoke(config.Callback,value) end)
        local handle={}
        function handle:GetValue() return toggleStates[key] end
        function handle:SetValue(value,silent)
            assert(type(value)=="boolean","Toggle value must be boolean")
            toggleStates[key]=value
            applyTheme(selectedTheme)
            if not silent then invoke(config.Callback,value) end
        end
        handle:SetValue(config.Default==true,true)
        return handle
    end
    function tab:AddDropdown(config)
        config=config or {}
        local items=config.Options or {}
        local value=config.Default or ""
        local _,update=mkDrop(panel,advance(52),config.Title or "Select",function() return items end,value,function(selected)
            value=selected; invoke(config.Callback,selected)
        end,config.Width or 150,config.Multi==true)
        return {
            GetValue=function() return value end,
            SetOptions=function(_,newItems) items=newItems; update(value) end,
        }
    end
    window.Tabs[id]=tab
end
function window:GetTab(id) return self.Tabs[id] end
function window:SelectTab(id)
    assert(panelMap[id],"Unknown tab: "..tostring(id))
    switchPanel(id)
end
function window:SetTheme(name)
    assert(THEME_PRESETS[name],"Unknown theme: "..tostring(name))
    applyTheme(name)
end
function window:Toggle() if sg.Parent then toggleHub() end end
function window:Destroy() cleanUp(); sg:Destroy() end
sg.Destroying:Connect(cleanUp)
if options.Theme then window:SetTheme(options.Theme) end
return window
end
return Library