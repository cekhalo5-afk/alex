-- language: Luau, file: NoacHub_v2.lua, target: Roblox Executor (Solara / KRNL+)
-- Noa Hub v2.0 | Steal An Egg Only [PlaceId: 10563114921]
-- FIX LOG:
--   [1] makeDropdown Desc.Position: extra closing paren removed  (UDim2.fromOffset(10, 56))  → (10, 56))
--   [2] makeInfoRow: KL.Padding = UDim.new(0,10) removed — TextLabel has no .Padding property
--   [3] Auto steal loop: goto continue / ::continue:: replaced with if/else (Luau has no goto)
--   [4] Dead variable `tread` in auto treadmill block removed

-- ── GAME GUARD ──────────────────────────────────────────────────────────────
if game.PlaceId ~= 107778070777162 then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Noa Hub", Text = "Hanya bisa di Steal An Egg!", Duration = 5
    })
    return
end

-- ── SERVICES ────────────────────────────────────────────────────────────────
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- ── ENV FLAGS ───────────────────────────────────────────────────────────────
local G = getgenv()
G.NOA_RUNNING     = true
G.NOA_NOCLIP      = false
G.NOA_INFJUMP     = false
G.NOA_ANTIAAFK    = true
G.NOA_AUTOSTEAL   = false
G.NOA_AUTODROP    = false
G.NOA_AUTOTREAD   = false
G.NOA_EGGCHECK    = false
G.NOA_EGGPREDICT  = false
G.NOA_KILLGUARD   = false
G.NOA_ANTIGUARD   = false
G.NOA_AUTOHOP     = false
G.NOA_EGGESP      = false
G.NOA_GUARDESP    = false
G.NOA_PLAYERESP   = false
G.NOA_STEALMETHOD = "zigzag"   -- "zigzag" | "tween" | "instant" | "fly"
G.NOA_STEALSPEED  = 200

-- ── HELPERS ─────────────────────────────────────────────────────────────────
local function getChar()  return LocalPlayer.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHuman()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end

-- ── GUI BUILD ───────────────────────────────────────────────────────────────
if PlayerGui:FindFirstChild("NoaHub") then
    PlayerGui.NoaHub:Destroy()
end

local Screen = Instance.new("ScreenGui")
Screen.Name           = "NoaHub"
Screen.ResetOnSpawn   = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent         = PlayerGui

local Bg = Instance.new("Frame", Screen)
Bg.Size                    = UDim2.fromScale(1, 1)
Bg.BackgroundColor3        = Color3.fromRGB(0, 0, 0)
Bg.BackgroundTransparency  = 0.5
Bg.BorderSizePixel         = 0

local Main = Instance.new("Frame", Screen)
Main.Size              = UDim2.fromOffset(540, 380)
Main.Position          = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint       = Vector2.new(0.5, 0.5)
Main.BackgroundColor3  = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel   = 0
Main.ClipsDescendants  = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local TitleBar = Instance.new("Frame", Main)
TitleBar.Size             = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
TitleBar.BorderSizePixel  = 0

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size                   = UDim2.new(1, -80, 1, 0)
TitleLabel.Position               = UDim2.fromOffset(14, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text                   = "Noa Hub  ·  Steal An Egg"
TitleLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
TitleLabel.Font                   = Enum.Font.GothamBold
TitleLabel.TextSize               = 13
TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size             = UDim2.fromOffset(28, 28)
CloseBtn.Position         = UDim2.new(1, -34, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 12
CloseBtn.BorderSizePixel  = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    Screen:Destroy()
    G.NOA_RUNNING = false
end)

-- Drag logic
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = i.Position
        startPos  = Main.Position
    end
end)
TitleBar.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
TitleBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Sidebar
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size             = UDim2.new(0, 130, 1, -36)
Sidebar.Position         = UDim2.fromOffset(0, 36)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
Sidebar.BorderSizePixel  = 0
local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding    = UDim.new(0, 2)
local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop = UDim.new(0, 8)

-- Content area
local Content = Instance.new("Frame", Main)
Content.Size             = UDim2.new(1, -130, 1, -36)
Content.Position         = UDim2.fromOffset(130, 36)
Content.BackgroundTransparency = 1
Content.BorderSizePixel  = 0
Content.ClipsDescendants = true

-- ── SIDEBAR NAV ─────────────────────────────────────────────────────────────
local PAGES      = {}
local currentPage = nil
local navBtns    = {}

local function makeSideBtn(icon, label, pageId, order)
    local Btn = Instance.new("TextButton", Sidebar)
    Btn.Size                    = UDim2.new(1, -8, 0, 32)
    Btn.Position                = UDim2.fromOffset(4, 0)
    Btn.BackgroundTransparency  = 1
    Btn.BorderSizePixel         = 0
    Btn.Text                    = ""
    Btn.LayoutOrder             = order
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local IconLabel = Instance.new("TextLabel", Btn)
    IconLabel.Size                    = UDim2.fromOffset(22, 22)
    IconLabel.Position                = UDim2.fromOffset(10, 5)
    IconLabel.BackgroundTransparency  = 1
    IconLabel.Text                    = icon
    IconLabel.TextColor3              = Color3.fromRGB(140, 140, 160)
    IconLabel.Font                    = Enum.Font.Gotham
    IconLabel.TextSize                = 14

    local NameLabel = Instance.new("TextLabel", Btn)
    NameLabel.Size                    = UDim2.new(1, -38, 1, 0)
    NameLabel.Position                = UDim2.fromOffset(36, 0)
    NameLabel.BackgroundTransparency  = 1
    NameLabel.Text                    = label
    NameLabel.TextColor3              = Color3.fromRGB(140, 140, 160)
    NameLabel.Font                    = Enum.Font.Gotham
    NameLabel.TextSize                = 12
    NameLabel.TextXAlignment          = Enum.TextXAlignment.Left

    local function setActive(active)
        Btn.BackgroundTransparency = active and 0 or 1
        Btn.BackgroundColor3       = Color3.fromRGB(30, 30, 40)
        IconLabel.TextColor3 = active and Color3.fromRGB(130, 160, 255) or Color3.fromRGB(140, 140, 160)
        NameLabel.TextColor3 = active and Color3.fromRGB(220, 225, 255) or Color3.fromRGB(140, 140, 160)
        NameLabel.Font       = active and Enum.Font.GothamBold or Enum.Font.Gotham
    end

    navBtns[pageId] = { btn = Btn, setActive = setActive }

    Btn.MouseButton1Click:Connect(function()
        if currentPage then
            PAGES[currentPage].Frame.Visible = false
            navBtns[currentPage].setActive(false)
        end
        currentPage          = pageId
        PAGES[pageId].Frame.Visible = true
        setActive(true)
    end)

    return Btn
end

-- ── PAGE FACTORY ─────────────────────────────────────────────────────────────
local function makePage(id)
    local F = Instance.new("ScrollingFrame", Content)
    F.Size                 = UDim2.fromScale(1, 1)
    F.BackgroundTransparency = 1
    F.BorderSizePixel      = 0
    F.ScrollBarThickness   = 3
    F.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
    F.CanvasSize           = UDim2.new(0, 0, 0, 0)
    F.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    F.Visible              = false

    local Pad = Instance.new("UIPadding", F)
    Pad.PaddingLeft   = UDim.new(0, 12)
    Pad.PaddingRight  = UDim.new(0, 12)
    Pad.PaddingTop    = UDim.new(0, 10)
    Pad.PaddingBottom = UDim.new(0, 12)

    local Layout = Instance.new("UIListLayout", F)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding    = UDim.new(0, 6)

    PAGES[id] = { Frame = F, Layout = Layout }
    return F, Layout
end

-- ── WIDGET HELPERS ───────────────────────────────────────────────────────────
local function makeLabel(parent, text, order)
    local L = Instance.new("TextLabel", parent)
    L.Size                    = UDim2.new(1, 0, 0, 14)
    L.BackgroundTransparency  = 1
    L.Text                    = text
    L.TextColor3              = Color3.fromRGB(100, 100, 130)
    L.Font                    = Enum.Font.GothamBold
    L.TextSize                = 10
    L.TextXAlignment          = Enum.TextXAlignment.Left
    L.LayoutOrder             = order or 0
    return L
end

local function makeRow(parent, labelText, subText, order)
    local Row = Instance.new("Frame", parent)
    Row.Size             = UDim2.new(1, 0, 0, subText and 44 or 34)
    Row.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order or 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 7)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size                    = UDim2.new(1, -60, 0, 18)
    Lbl.Position                = UDim2.fromOffset(10, subText and 7 or 8)
    Lbl.BackgroundTransparency  = 1
    Lbl.Text                    = labelText
    Lbl.TextColor3              = Color3.fromRGB(220, 220, 235)
    Lbl.Font                    = Enum.Font.Gotham
    Lbl.TextSize                = 12
    Lbl.TextXAlignment          = Enum.TextXAlignment.Left

    if subText then
        local Sub = Instance.new("TextLabel", Row)
        Sub.Size                    = UDim2.new(1, -60, 0, 14)
        Sub.Position                = UDim2.fromOffset(10, 24)
        Sub.BackgroundTransparency  = 1
        Sub.Text                    = subText
        Sub.TextColor3              = Color3.fromRGB(90, 90, 110)
        Sub.Font                    = Enum.Font.Gotham
        Sub.TextSize                = 10
        Sub.TextXAlignment          = Enum.TextXAlignment.Left
    end
    return Row
end

local function makeToggle(parent, labelText, subText, flag, order)
    local Row = makeRow(parent, labelText, subText, order)

    local Track = Instance.new("Frame", Row)
    Track.Size             = UDim2.fromOffset(34, 18)
    Track.Position         = UDim2.new(1, -44, 0.5, -9)
    Track.BackgroundColor3 = G[flag] and Color3.fromRGB(100, 130, 255) or Color3.fromRGB(55, 55, 75)
    Track.BorderSizePixel  = 0
    Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 9)

    local Thumb = Instance.new("Frame", Track)
    Thumb.Size             = UDim2.fromOffset(12, 12)
    Thumb.Position         = G[flag] and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3)
    Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Thumb.BorderSizePixel  = 0
    Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 6)

    local function refresh()
        local on = G[flag]
        Track.BackgroundColor3 = on and Color3.fromRGB(100, 130, 255) or Color3.fromRGB(55, 55, 75)
        TweenService:Create(Thumb, TweenInfo.new(0.12), {
            Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3)
        }):Play()
    end

    local Hitbox = Instance.new("TextButton", Row)
    Hitbox.Size                   = UDim2.fromScale(1, 1)
    Hitbox.BackgroundTransparency = 1
    Hitbox.Text                   = ""
    Hitbox.ZIndex                 = 5
    Hitbox.MouseButton1Click:Connect(function()
        G[flag] = not G[flag]
        refresh()
    end)

    return Row
end

local function makeSlider(parent, labelText, flag, min, max, step, suffix, order)
    local Row = Instance.new("Frame", parent)
    Row.Size             = UDim2.new(1, 0, 0, 52)
    Row.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order or 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 7)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size                    = UDim2.new(1, -80, 0, 16)
    Lbl.Position                = UDim2.fromOffset(10, 8)
    Lbl.BackgroundTransparency  = 1
    Lbl.Text                    = labelText
    Lbl.TextColor3              = Color3.fromRGB(220, 220, 235)
    Lbl.Font                    = Enum.Font.Gotham
    Lbl.TextSize                = 12
    Lbl.TextXAlignment          = Enum.TextXAlignment.Left

    local ValLbl = Instance.new("TextLabel", Row)
    ValLbl.Size                   = UDim2.fromOffset(70, 16)
    ValLbl.Position               = UDim2.new(1, -78, 0, 8)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Text                   = tostring(G[flag])..(suffix or "")
    ValLbl.TextColor3             = Color3.fromRGB(130, 160, 255)
    ValLbl.Font                   = Enum.Font.GothamBold
    ValLbl.TextSize               = 12
    ValLbl.TextXAlignment         = Enum.TextXAlignment.Right

    local Track = Instance.new("Frame", Row)
    Track.Size             = UDim2.new(1, -20, 0, 4)
    Track.Position         = UDim2.fromOffset(10, 34)
    Track.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    Track.BorderSizePixel  = 0
    Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 2)

    local pct  = (G[flag] - min) / (max - min)
    local Fill = Instance.new("Frame", Track)
    Fill.Size             = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 130, 255)
    Fill.BorderSizePixel  = 0
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 2)

    local Hitbox = Instance.new("TextButton", Track)
    Hitbox.Size                   = UDim2.fromScale(1, 1)
    Hitbox.BackgroundTransparency = 1
    Hitbox.Text                   = ""

    local function setVal(x)
        local relX   = math.clamp(x - Track.AbsolutePosition.X, 0, Track.AbsoluteSize.X)
        local ratio  = relX / Track.AbsoluteSize.X
        local raw    = min + ratio * (max - min)
        local snapped = math.clamp(math.round(raw / step) * step, min, max)
        G[flag]       = snapped
        Fill.Size     = UDim2.new(ratio, 0, 1, 0)
        ValLbl.Text   = tostring(snapped)..(suffix or "")
    end

    local sliding = false
    Hitbox.MouseButton1Down:Connect(function(x, _) sliding = true; setVal(x) end)
    Hitbox.MouseButton1Up:Connect(function() sliding = false end)
    Hitbox.MouseMoved:Connect(function(x, _) if sliding then setVal(x) end end)

    return Row
end

local function makeDropdown(parent, labelText, options, optDescs, flag, order)
    local Row = Instance.new("Frame", parent)
    Row.Size             = UDim2.new(1, 0, 0, 68)
    Row.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order or 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 7)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size                    = UDim2.new(1, -20, 0, 16)
    Lbl.Position                = UDim2.fromOffset(10, 8)
    Lbl.BackgroundTransparency  = 1
    Lbl.Text                    = labelText
    Lbl.TextColor3              = Color3.fromRGB(220, 220, 235)
    Lbl.Font                    = Enum.Font.Gotham
    Lbl.TextSize                = 12
    Lbl.TextXAlignment          = Enum.TextXAlignment.Left

    local PillFrame = Instance.new("Frame", Row)
    PillFrame.Size                    = UDim2.new(1, -20, 0, 26)
    PillFrame.Position                = UDim2.fromOffset(10, 28)
    PillFrame.BackgroundTransparency  = 1
    local PL = Instance.new("UIListLayout", PillFrame)
    PL.FillDirection = Enum.FillDirection.Horizontal
    PL.Padding       = UDim.new(0, 5)

    local pills = {}
    for _, opt in ipairs(options) do
        local P = Instance.new("TextButton", PillFrame)
        P.Size             = UDim2.fromOffset(0, 22)
        P.AutomaticSize    = Enum.AutomaticSize.X
        P.BackgroundColor3 = G[flag] == opt and Color3.fromRGB(80, 100, 220) or Color3.fromRGB(38, 38, 52)
        P.BorderSizePixel  = 0
        P.Text             = opt:sub(1,1):upper()..opt:sub(2)
        P.TextColor3       = Color3.fromRGB(220, 220, 255)
        P.Font             = Enum.Font.Gotham
        P.TextSize         = 10
        Instance.new("UICorner", P).CornerRadius = UDim.new(0, 5)
        local PP = Instance.new("UIPadding", P)
        PP.PaddingLeft = UDim.new(0, 8); PP.PaddingRight = UDim.new(0, 8)
        pills[opt] = P

        P.MouseButton1Click:Connect(function()
            G[flag] = opt
            for k, v in pairs(pills) do
                v.BackgroundColor3 = (k == opt) and Color3.fromRGB(80, 100, 220) or Color3.fromRGB(38, 38, 52)
            end
        end)
    end

    -- FIX [1]: removed extra closing paren that was here
    local Desc = Instance.new("TextLabel", Row)
    Desc.Size                   = UDim2.new(1, -20, 0, 0)
    Desc.Position               = UDim2.fromOffset(10, 56)   -- was: (10, 56))
    Desc.BackgroundTransparency = 1
    Desc.Text                   = optDescs and (optDescs[G[flag]] or "") or ""
    Desc.TextColor3             = Color3.fromRGB(80, 80, 105)
    Desc.Font                   = Enum.Font.Gotham
    Desc.TextSize               = 10
    Desc.TextXAlignment         = Enum.TextXAlignment.Left
    Desc.TextWrapped            = true
    Desc.AutomaticSize          = Enum.AutomaticSize.Y

    if optDescs then
        for opt, pill in pairs(pills) do
            pill.MouseButton1Click:Connect(function()
                Desc.Text = optDescs[opt] or ""
                Row.Size  = UDim2.new(1, 0, 0, 60 + Desc.AbsoluteSize.Y + 4)
            end)
        end
    end

    return Row
end

local function makeButton(parent, labelText, color, callback, order)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size             = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = color or Color3.fromRGB(38, 38, 52)
    Btn.BorderSizePixel  = 0
    Btn.Text             = labelText
    Btn.TextColor3       = Color3.fromRGB(220, 220, 255)
    Btn.Font             = Enum.Font.GothamBold
    Btn.TextSize         = 12
    Btn.LayoutOrder      = order or 0
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 7)
    if callback then Btn.MouseButton1Click:Connect(callback) end
    return Btn
end

-- FIX [2]: removed KL.Padding = UDim.new(0,10) — TextLabel has no .Padding property
local function makeInfoRow(parent, key, val, order)
    local Row = Instance.new("Frame", parent)
    Row.Size             = UDim2.new(1, 0, 0, 28)
    Row.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order or 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)

    local KL = Instance.new("TextLabel", Row)
    KL.Size                    = UDim2.fromScale(0.5, 1)
    KL.BackgroundTransparency  = 1
    KL.Text                    = key
    KL.TextColor3              = Color3.fromRGB(110, 110, 130)
    KL.Font                    = Enum.Font.Gotham
    KL.TextSize                = 11
    -- KL.Padding removed: TextLabel has no .Padding; UIPadding below handles it
    local KP = Instance.new("UIPadding", KL); KP.PaddingLeft = UDim.new(0, 10)
    KL.TextXAlignment = Enum.TextXAlignment.Left

    local VL = Instance.new("TextLabel", Row)
    VL.Size                    = UDim2.fromScale(0.5, 1)
    VL.Position                = UDim2.fromScale(0.5, 0)
    VL.BackgroundTransparency  = 1
    VL.Text                    = tostring(val)
    VL.TextColor3              = Color3.fromRGB(200, 205, 255)
    VL.Font                    = Enum.Font.GothamBold
    VL.TextSize                = 11
    VL.TextXAlignment          = Enum.TextXAlignment.Right
    local VP = Instance.new("UIPadding", VL); VP.PaddingRight = UDim.new(0, 10)

    return Row, VL
end

-- ── PAGE: INFORMATION ────────────────────────────────────────────────────────
makeSideBtn("ℹ", "Information", "info", 1)
local InfoF = makePage("info")
makeInfoRow(InfoF, "Script",   "Noa Hub v2.0",    1)
makeInfoRow(InfoF, "Game",     "Steal An Egg",     2)
makeInfoRow(InfoF, "PlaceId",  "10563114921",      3)
makeInfoRow(InfoF, "Status",   "Active",           4)
makeInfoRow(InfoF, "Executor", "Solara / KRNL+",   5)
makeLabel(InfoF, "CATATAN", 6)
local InfoNote = Instance.new("TextLabel", InfoF)
InfoNote.Size             = UDim2.new(1, 0, 0, 50)
InfoNote.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
InfoNote.BorderSizePixel  = 0
InfoNote.Text             = "Script hanya jalan di PlaceId 10563114921. Fitur: Auto Steal, Move Methods, Treadmill auto, Egg Predictor (Divine & Eternal), ESP, Config save/load."
InfoNote.TextColor3       = Color3.fromRGB(110, 110, 140)
InfoNote.Font             = Enum.Font.Gotham
InfoNote.TextSize         = 11
InfoNote.TextWrapped      = true
InfoNote.TextXAlignment   = Enum.TextXAlignment.Left
InfoNote.AutomaticSize    = Enum.AutomaticSize.Y
InfoNote.LayoutOrder      = 7
local INP = Instance.new("UIPadding", InfoNote)
INP.PaddingLeft = UDim.new(0, 8); INP.PaddingRight  = UDim.new(0, 8)
INP.PaddingTop  = UDim.new(0, 6); INP.PaddingBottom = UDim.new(0, 6)
Instance.new("UICorner", InfoNote).CornerRadius = UDim.new(0, 7)

-- ── PAGE: MAIN ───────────────────────────────────────────────────────────────
makeSideBtn("⚡", "Main", "main", 2)
local MainF = makePage("main")
makeLabel(MainF, "MOVEMENT", 1)
makeSlider(MainF, "Walk Speed", "NOA_STEALSPEED", 16, 600, 1, "", 2)
makeToggle(MainF, "Noclip",         "Menembus semua objek",              "NOA_NOCLIP",    3)
makeToggle(MainF, "Infinite Jump",  "Bisa loncat terus",                 "NOA_INFJUMP",   4)
makeLabel(MainF, "TREADMILL", 5)
makeToggle(MainF, "Auto Treadmill", "Langsung ke treadmill setelah steal", "NOA_AUTOTREAD", 6)

-- ── PAGE: AUTO ───────────────────────────────────────────────────────────────
makeSideBtn("🤖", "Auto", "auto", 3)
local AutoF = makePage("auto")

makeLabel(AutoF, "STEAL METHOD", 1)
local stealDescs = {
    zigzag  = "Gerak zigzag kanan-kiri saat kabur — sulit dikejar guardian.",
    tween   = "Jalan lurus saja, langsung ke base — cepat tapi mudah diprediksi.",
    instant = "Karakter berhenti di safe zone dekat toko. Clone mencuri egg, lalu menghampiri dan menyerahkan egg.",
    fly     = "Terbang saat mencuri — melewati semua rintangan di ground.",
}
makeDropdown(AutoF, "Move Style", {"zigzag","tween","instant","fly"}, stealDescs, "NOA_STEALMETHOD", 2)
makeSlider(AutoF, "Steal Speed", "NOA_STEALSPEED", 16, 600, 1, "", 3)

makeLabel(AutoF, "AUTO ACTIONS", 4)
makeToggle(AutoF, "Auto Steal Egg",    "Curi telur otomatis dari nest",          "NOA_AUTOSTEAL",  5)
makeToggle(AutoF, "Auto Drop ke Base", "Antar ke pen setelah dapat egg",         "NOA_AUTODROP",   6)
makeToggle(AutoF, "Auto Treadmill",    "Langsung ke treadmill setelah steal",    "NOA_AUTOTREAD",  7)

makeLabel(AutoF, "EGG TOOLS", 8)
makeToggle(AutoF, "Egg Checkers",  "Cek rarity egg sebelum diambil", "NOA_EGGCHECK",   9)
makeToggle(AutoF, "Egg Predictor", "Divine & Eternal saja",           "NOA_EGGPREDICT", 10)

local PredNote = Instance.new("TextLabel", AutoF)
PredNote.Size             = UDim2.new(1, 0, 0, 36)
PredNote.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
PredNote.BorderSizePixel  = 0
PredNote.Text             = "Predictor hanya aktif untuk Divine & Eternal. Rarity lain diabaikan — tidak akan di-steal kalau Predictor aktif dan telur bukan Divine/Eternal."
PredNote.TextColor3       = Color3.fromRGB(160, 140, 220)
PredNote.Font             = Enum.Font.Gotham
PredNote.TextSize         = 10
PredNote.TextWrapped      = true
PredNote.TextXAlignment   = Enum.TextXAlignment.Left
PredNote.AutomaticSize    = Enum.AutomaticSize.Y
PredNote.LayoutOrder      = 11
local PNP = Instance.new("UIPadding", PredNote)
PNP.PaddingLeft = UDim.new(0, 8); PNP.PaddingRight  = UDim.new(0, 8)
PNP.PaddingTop  = UDim.new(0, 5); PNP.PaddingBottom = UDim.new(0, 5)
Instance.new("UICorner", PredNote).CornerRadius = UDim.new(0, 7)

-- ── PAGE: ESP ─────────────────────────────────────────────────────────────────
makeSideBtn("👁", "ESP", "esp", 4)
local EspF = makePage("esp")
makeLabel(EspF, "VISIBILITY", 1)
makeToggle(EspF, "Egg ESP",     "Highlight egg — kuning",        "NOA_EGGESP",    2)
makeToggle(EspF, "Guardian ESP","Highlight guardian — merah",    "NOA_GUARDESP",  3)
makeToggle(EspF, "Player ESP",  "Highlight pemain lain — biru",  "NOA_PLAYERESP", 4)

-- ── PAGE: PRIVATE SERVERS ─────────────────────────────────────────────────────
makeSideBtn("🖥", "Private Servers", "servers", 5)
local SrvF = makePage("servers")
makeLabel(SrvF, "SERVER LIST", 1)

local serverCodes = {}
local SrvListFrame = Instance.new("Frame", SrvF)
SrvListFrame.Size                    = UDim2.new(1, 0, 0, 0)
SrvListFrame.BackgroundTransparency  = 1
SrvListFrame.AutomaticSize           = Enum.AutomaticSize.Y
SrvListFrame.LayoutOrder             = 2
local SrvLL = Instance.new("UIListLayout", SrvListFrame)
SrvLL.Padding = UDim.new(0, 4)

local function renderServerList()
    for _, c in ipairs(SrvListFrame:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
    if #serverCodes == 0 then
        local Empty = Instance.new("TextLabel", SrvListFrame)
        Empty.Size                    = UDim2.new(1, 0, 0, 28)
        Empty.BackgroundTransparency  = 1
        Empty.Text                    = "Belum ada server — tambah kode dulu"
        Empty.TextColor3              = Color3.fromRGB(80, 80, 100)
        Empty.Font                    = Enum.Font.Gotham
        Empty.TextSize                = 11
    end
    for i, code in ipairs(serverCodes) do
        local R = Instance.new("Frame", SrvListFrame)
        R.Size             = UDim2.new(1, 0, 0, 32)
        R.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
        R.BorderSizePixel  = 0
        Instance.new("UICorner", R).CornerRadius = UDim.new(0, 6)

        local LB = Instance.new("TextLabel", R)
        LB.Size                    = UDim2.new(1, -90, 1, 0)
        LB.Position                = UDim2.fromOffset(10, 0)
        LB.BackgroundTransparency  = 1
        LB.Text                    = "Server #"..i.." — "..code:sub(1,12).."..."
        LB.TextColor3              = Color3.fromRGB(200, 200, 220)
        LB.Font                    = Enum.Font.Gotham
        LB.TextSize                = 11
        LB.TextXAlignment          = Enum.TextXAlignment.Left

        local JoinBtn = Instance.new("TextButton", R)
        JoinBtn.Size             = UDim2.fromOffset(60, 22)
        JoinBtn.Position         = UDim2.new(1, -68, 0.5, -11)
        JoinBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
        JoinBtn.BorderSizePixel  = 0
        JoinBtn.Text             = "Join"
        JoinBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
        JoinBtn.Font             = Enum.Font.GothamBold
        JoinBtn.TextSize         = 11
        Instance.new("UICorner", JoinBtn).CornerRadius = UDim.new(0, 5)

        JoinBtn.MouseButton1Click:Connect(function()
            local TS = game:GetService("TeleportService")
            local success, err = pcall(function()
                TS:TeleportToPrivateServer(game.PlaceId, code, {LocalPlayer})
            end)
            if not success then
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title="Noa Hub", Text="Gagal join: "..tostring(err), Duration=4
                })
            end
        end)
    end
end
renderServerList()

local AddInput = Instance.new("TextBox", SrvF)
AddInput.Size              = UDim2.new(1, 0, 0, 30)
AddInput.BackgroundColor3  = Color3.fromRGB(24, 24, 32)
AddInput.BorderSizePixel   = 0
AddInput.PlaceholderText   = "Paste server code di sini..."
AddInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
AddInput.Text              = ""
AddInput.TextColor3        = Color3.fromRGB(220, 220, 240)
AddInput.Font              = Enum.Font.Gotham
AddInput.TextSize          = 11
AddInput.LayoutOrder       = 3
Instance.new("UICorner", AddInput).CornerRadius = UDim.new(0, 7)
local AIP = Instance.new("UIPadding", AddInput)
AIP.PaddingLeft = UDim.new(0, 8); AIP.PaddingRight = UDim.new(0, 8)

makeButton(SrvF, "Tambah Server Code", Color3.fromRGB(38, 38, 55), function()
    local code = AddInput.Text:gsub("%s", "")
    if code ~= "" then
        table.insert(serverCodes, code)
        AddInput.Text = ""
        renderServerList()
    end
end, 4)

makeLabel(SrvF, "OPTIONS", 5)
makeToggle(SrvF, "Auto Hop ke Server Sepi", "Pindah server kalau terlalu ramai", "NOA_AUTOHOP", 6)

-- ── PAGE: MISC ───────────────────────────────────────────────────────────────
makeSideBtn("🔧", "Misc", "misc", 6)
local MiscF = makePage("misc")
makeLabel(MiscF, "GUARDIAN", 1)
makeToggle(MiscF, "Anti Guardian",       "Noclip bypass saat dikejar",        "NOA_ANTIGUARD", 2)
makeToggle(MiscF, "Kill Guardian (NPC)", "Set HP guardian ke 0 saat dekat",   "NOA_KILLGUARD", 3)
makeLabel(MiscF, "UTILITY", 4)
makeToggle(MiscF, "Anti AFK", "Cegah kick AFK otomatis", "NOA_ANTIAAFK", 5)
makeButton(MiscF, "Rejoin Server", Color3.fromRGB(38, 38, 55), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end, 6)
makeButton(MiscF, "Reset Karakter", Color3.fromRGB(38, 38, 55), function()
    local h = getHuman(); if h then h.Health = 0 end
end, 7)
makeButton(MiscF, "Tutup Hub", Color3.fromRGB(70, 30, 30), function()
    Screen:Destroy(); G.NOA_RUNNING = false
end, 8)

-- ── PAGE: CONFIG ──────────────────────────────────────────────────────────────
makeSideBtn("⚙", "Config", "config", 7)
local CfgF = makePage("config")
makeLabel(CfgF, "SAVE / LOAD", 1)

local CONFIG_KEYS = {
    "NOA_NOCLIP","NOA_INFJUMP","NOA_ANTIAAFK","NOA_AUTOSTEAL","NOA_AUTODROP",
    "NOA_AUTOTREAD","NOA_EGGCHECK","NOA_EGGPREDICT","NOA_KILLGUARD",
    "NOA_ANTIGUARD","NOA_AUTOHOP","NOA_EGGESP","NOA_GUARDESP","NOA_PLAYERESP",
    "NOA_STEALMETHOD","NOA_STEALSPEED"
}

makeButton(CfgF, "💾  Save Config", Color3.fromRGB(38, 38, 55), function()
    local data = {}
    for _, k in ipairs(CONFIG_KEYS) do data[k] = G[k] end
    local ok, err = pcall(writefile, "NoaHub_SAE.json", game:GetService("HttpService"):JSONEncode(data))
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Noa Hub",
        Text  = ok and "Config disimpan!" or ("Gagal simpan: "..tostring(err)),
        Duration = 4
    })
end, 2)

makeButton(CfgF, "📂  Load Config", Color3.fromRGB(38, 38, 55), function()
    local ok, raw = pcall(readfile, "NoaHub_SAE.json")
    if ok then
        local data = game:GetService("HttpService"):JSONDecode(raw)
        for _, k in ipairs(CONFIG_KEYS) do
            if data[k] ~= nil then G[k] = data[k] end
        end
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title="Noa Hub", Text="Config berhasil dimuat!", Duration=4
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title="Noa Hub", Text="Belum ada config tersimpan.", Duration=4
        })
    end
end, 3)

makeButton(CfgF, "🗑  Reset ke Default", Color3.fromRGB(50, 25, 25), function()
    G.NOA_NOCLIP=false; G.NOA_INFJUMP=false; G.NOA_AUTOSTEAL=false
    G.NOA_AUTODROP=false; G.NOA_AUTOTREAD=false; G.NOA_EGGCHECK=false
    G.NOA_EGGPREDICT=false; G.NOA_KILLGUARD=false; G.NOA_ANTIGUARD=false
    G.NOA_STEALMETHOD="zigzag"; G.NOA_STEALSPEED=200
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title="Noa Hub", Text="Reset ke default selesai.", Duration=3
    })
end, 4)

makeLabel(CfgF, "CATATAN", 5)
local CfgNote = Instance.new("TextLabel", CfgF)
CfgNote.Size             = UDim2.new(1,0,0,36)
CfgNote.BackgroundColor3 = Color3.fromRGB(24,24,32)
CfgNote.BorderSizePixel  = 0
CfgNote.Text             = "Config disimpan ke file NoaHub_SAE.json via writefile(). Perlu executor yang support filesystem (Solara, KRNL)."
CfgNote.TextColor3       = Color3.fromRGB(80,80,110)
CfgNote.Font             = Enum.Font.Gotham
CfgNote.TextSize         = 10
CfgNote.TextWrapped      = true
CfgNote.AutomaticSize    = Enum.AutomaticSize.Y
CfgNote.TextXAlignment   = Enum.TextXAlignment.Left
CfgNote.LayoutOrder      = 6
local CNP = Instance.new("UIPadding", CfgNote)
CNP.PaddingLeft = UDim.new(0,8); CNP.PaddingRight  = UDim.new(0,8)
CNP.PaddingTop  = UDim.new(0,5); CNP.PaddingBottom = UDim.new(0,5)
Instance.new("UICorner", CfgNote).CornerRadius = UDim.new(0,7)

-- ── DEFAULT PAGE ─────────────────────────────────────────────────────────────
PAGES["main"].Frame.Visible = true
currentPage = "main"
navBtns["main"].setActive(true)

-- ══════════════════════════════════════════════════════════════════════════════
-- LOGIC LOOPS
-- ══════════════════════════════════════════════════════════════════════════════

-- Noclip + Anti Guardian
RunService.Stepped:Connect(function()
    if G.NOA_NOCLIP or G.NOA_ANTIGUARD then
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- Infinite Jump
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").StateChanged:Connect(function(_, new)
        if G.NOA_INFJUMP and new == Enum.HumanoidStateType.Freefall then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end)
if getChar() then
    local h = getHuman()
    if h then
        h.StateChanged:Connect(function(_, new)
            if G.NOA_INFJUMP and new == Enum.HumanoidStateType.Freefall then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

-- Anti AFK
task.spawn(function()
    local VU = game:GetService("VirtualUser")
    while G.NOA_RUNNING do
        task.wait(55)
        if G.NOA_ANTIAAFK then
            VU:CaptureController(); VU:ClickButton2(Vector2.new())
        end
    end
end)

-- Kill Guardian
task.spawn(function()
    while G.NOA_RUNNING do
        task.wait(0.15)
        if G.NOA_KILLGUARD then
            local root = getRoot()
            if root then
                local radius = G.NOA_STEALSPEED > 0 and 50 or 40
                for _, h in ipairs(workspace:GetDescendants()) do
                    if h:IsA("Humanoid") and h.Parent ~= getChar() and h.Health > 0 then
                        local isPlayer = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.Character == h.Parent then isPlayer = true; break end
                        end
                        if not isPlayer then
                            local nr = h.Parent:FindFirstChild("HumanoidRootPart")
                            if nr and (root.Position - nr.Position).Magnitude < radius then
                                h.Health = 0
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ── STEAL METHODS ─────────────────────────────────────────────────────────────
local function findNearestEgg(root)
    local best, bestD = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("egg") or n:find("nest") then
                local d = (root.Position - obj.Position).Magnitude
                if d < bestD then best = obj; bestD = d end
            end
        end
    end
    return best, bestD
end

local function isPredictorPass(eggObj)
    if not G.NOA_EGGPREDICT then return true end
    local n = eggObj.Name:lower()
    return n:find("divine") or n:find("eternal")
end

local function stealZigZag(root, target)
    local steps = 8
    for i = 1, steps do
        if not G.NOA_AUTOSTEAL then return end
        local dir  = (target.Position - root.Position).Unit
        local side = (i % 2 == 0) and 1 or -1
        root.CFrame = CFrame.new(root.Position + dir * 3 + Vector3.new(side * 4, 0, 0))
        task.wait(0.08)
    end
    root.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
end

local function stealTween(root, target)
    root.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
end

local function stealInstant(root, target)
    local safeZone = workspace:FindFirstChild("SafeZone")
        or workspace:FindFirstChild("Shop")
        or workspace:FindFirstChild("Store")
    if safeZone and safeZone:IsA("BasePart") then
        root.CFrame = CFrame.new(safeZone.Position + Vector3.new(0, 5, 0))
    end
    task.spawn(function()
        local cloneChar = getChar():Clone()
        cloneChar.Parent = workspace
        local cloneRoot  = cloneChar:FindFirstChild("HumanoidRootPart")
        if cloneRoot then
            cloneRoot.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
            task.wait(1.5)
            for _, pp in ipairs(target.Parent:GetDescendants()) do
                if pp:IsA("ProximityPrompt") then fireproximityprompt(pp); break end
            end
            task.wait(1)
            cloneRoot.CFrame = root.CFrame
            task.wait(0.5)
        end
        cloneChar:Destroy()
    end)
end

local function stealFly(root, target)
    local h = getHuman()
    if h then
        h.PlatformStand = false
        local BV = Instance.new("BodyVelocity", root)
        BV.Velocity  = Vector3.new(0, 30, 0)
        BV.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
        BV.P         = 1e4
        task.wait(0.3)
        local dir = (target.Position - root.Position).Unit
        BV.Velocity = dir * G.NOA_STEALSPEED
        task.wait(0.5)
        BV:Destroy()
        root.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
    end
end

-- ── AUTO STEAL LOOP ──────────────────────────────────────────────────────────
-- FIX [3]: goto / ::continue:: replaced with if/else — Luau has no goto
task.spawn(function()
    while G.NOA_RUNNING do
        task.wait(0.6)
        if G.NOA_AUTOSTEAL then
            local root = getRoot()
            if root then
                local h = getHuman()
                if h then h.WalkSpeed = G.NOA_STEALSPEED end

                local egg, dist = findNearestEgg(root)
                if egg and dist > 4 then
                    -- skip egg yang tidak lolos predictor
                    if not (G.NOA_EGGPREDICT and not isPredictorPass(egg)) then

                        if G.NOA_EGGCHECK then
                            game:GetService("StarterGui"):SetCore("SendNotification", {
                                Title="Egg Checker", Text=egg.Name, Duration=2
                            })
                        end

                        local m = G.NOA_STEALMETHOD
                        if     m == "zigzag"  then stealZigZag(root, egg)
                        elseif m == "tween"   then stealTween(root, egg)
                        elseif m == "instant" then stealInstant(root, egg)
                        elseif m == "fly"     then stealFly(root, egg)
                        end

                        task.wait(0.2)
                        for _, pp in ipairs(workspace:GetDescendants()) do
                            if pp:IsA("ProximityPrompt") then
                                local ppRoot = pp.Parent
                                if ppRoot and ppRoot:IsA("BasePart") then
                                    local pn = ppRoot.Name:lower()
                                    if (pn:find("egg") or pn:find("nest")) and
                                       (root.Position - ppRoot.Position).Magnitude < 15 then
                                        fireproximityprompt(pp)
                                    end
                                end
                            end
                        end

                        if G.NOA_AUTODROP then
                            task.wait(0.3)
                            local base = workspace:FindFirstChild("Bases") or workspace:FindFirstChild("Base")
                            if base then
                                local playerBase = base:FindFirstChild(LocalPlayer.Name)
                                if playerBase then
                                    local pen = playerBase:FindFirstChild("Pen")
                                        or playerBase:FindFirstChild("PenArea")
                                        or playerBase:FindFirstChild("Hatch")
                                    if pen and pen:IsA("BasePart") then
                                        root.CFrame = CFrame.new(pen.Position + Vector3.new(0, 5, 0))
                                        task.wait(0.3)
                                        for _, pp in ipairs(workspace:GetDescendants()) do
                                            if pp:IsA("ProximityPrompt") then
                                                local ppR = pp.Parent
                                                if ppR and ppR:IsA("BasePart") and
                                                   (root.Position - ppR.Position).Magnitude < 12 then
                                                    fireproximityprompt(pp)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        -- FIX [4]: dead `local tread = ...` variable removed
                        if G.NOA_AUTOTREAD then
                            task.wait(0.3)
                            for _, obj in ipairs(workspace:GetDescendants()) do
                                if obj.Name:lower():find("treadmill") and obj:IsA("BasePart") then
                                    root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                                    task.wait(0.2)
                                    for _, pp in ipairs(obj.Parent:GetDescendants()) do
                                        if pp:IsA("ProximityPrompt") then
                                            fireproximityprompt(pp); break
                                        end
                                    end
                                    break
                                end
                            end
                        end

                    end -- end predictor gate
                end
            end
        end
    end
end)

-- ── ESP LOOPS ─────────────────────────────────────────────────────────────────
local eggHL, guardHL, plrHL = {}, {}, {}

local function clearHL(t)
    for _, h in ipairs(t) do pcall(function() h:Destroy() end) end
    table.clear(t)
end

local function addHL(obj, fill, outline)
    local h = Instance.new("Highlight")
    h.FillColor          = fill
    h.OutlineColor       = outline
    h.FillTransparency   = 0.5
    h.Parent             = obj
    return h
end

task.spawn(function()
    while G.NOA_RUNNING do
        task.wait(2)
        clearHL(eggHL); clearHL(guardHL); clearHL(plrHL)

        if G.NOA_EGGESP then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and
                   (obj.Name:lower():find("egg") or obj.Name:lower():find("nest")) then
                    table.insert(eggHL, addHL(obj,
                        Color3.fromRGB(255, 215, 0),
                        Color3.fromRGB(255, 255, 255)))
                end
            end
        end

        if G.NOA_GUARDESP then
            for _, h in ipairs(workspace:GetDescendants()) do
                if h:IsA("Humanoid") and h.Parent ~= getChar() then
                    local isP = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character == h.Parent then isP = true; break end
                    end
                    if not isP then
                        table.insert(guardHL, addHL(h.Parent,
                            Color3.fromRGB(255, 50, 50),
                            Color3.fromRGB(255, 150, 0)))
                    end
                end
            end
        end

        if G.NOA_PLAYERESP then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    table.insert(plrHL, addHL(p.Character,
                        Color3.fromRGB(60, 130, 255),
                        Color3.fromRGB(200, 220, 255)))
                end
            end
        end
    end
end)

-- ── NOTIF SELESAI ────────────────────────────────────────────────────────────
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "✅ Noa Hub", Text = "Siap! PlaceId Steal An Egg verified.", Duration = 4
})
