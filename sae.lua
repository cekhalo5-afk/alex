-- language: Luau, file: NoacHub_v3.lua, target: Roblox Executor (Solara / KRNL+ / Delta)
-- Noa Hub v3.0 | Steal An Egg Only
-- FIXES v2→v3:
--   [1] PlaceId diperbaiki ke nilai asli yang valid
--   [2] GUI tidak muncul di v2 karena Bg Frame menutupi seluruh layar dengan hitbox
--       → Bg.BackgroundTransparency diubah ke 1 (invisible), tidak ada MouseButton1Click block
--   [3] Egg Checkers sekarang scan REAL egg di workspace server, tampilkan panel dengan
--       rarity per nama egg, bisa multi-pilih, bisa ditutup
--   [4] Anti-ban / anti-detect layer ditambahkan
--   [5] Data egg & rarity lengkap dari semua biome SAE

-- ── GAME GUARD ──────────────────────────────────────────────────────────────
local VALID_PLACES = {
    [10563114921] = true,  -- Steal An Egg (utama)
    [107778070777162] = true, -- versi alternatif jika ada
}

if not VALID_PLACES[game.PlaceId] then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Noa Hub",
        Text  = "Hanya bisa di Steal An Egg!",
        Duration = 5,
    })
    return
end

-- ── SERVICES ────────────────────────────────────────────────────────────────
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
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
G.NOA_STEALMETHOD = "zigzag"
G.NOA_STEALSPEED  = 200
G.NOA_ANTIBAN     = true
G.NOA_SMOOTHTP    = true        -- pakai tween TP bukan instant CFrame = agar lebih alami
G.NOA_FAKELATENCY = false       -- simulasi latency normal
G.NOA_SELECTED_EGGS = {}        -- table nama egg yang dipilih di Egg Checkers

-- ── EGG DATABASE ─────────────────────────────────────────────────────────────
-- Data lengkap dari semua biome Steal An Egg (Sept 2026)
-- Format: { name, rarity, income, biome, rarityTier }
-- rarityTier: 1=Common 2=Uncommon 3=Rare 4=Epic 5=Legendary 6=Mythic 7=Cosmic 8=Secret 9=Eternal 10=Divine
local EGG_DB = {
    -- FOREST
    { name="Chicken",         rarity="Common",    income="$1/s",        biome="Forest",        tier=1 },
    { name="Dog",             rarity="Common",    income="$2/s",        biome="Forest",        tier=1 },
    { name="Bird",            rarity="Uncommon",  income="$8/s",        biome="Forest",        tier=2 },
    { name="Owl",             rarity="Rare",      income="$35/s",       biome="Forest",        tier=3 },
    { name="Raccoon",         rarity="Rare",      income="$45/s",       biome="Forest",        tier=3 },
    { name="Fox",             rarity="Epic",      income="$180/s",      biome="Forest",        tier=4 },
    { name="Bear",            rarity="Epic",      income="$240/s",      biome="Forest",        tier=4 },
    { name="Brr Brr Patapim", rarity="Legendary", income="$1.8K/s",     biome="Forest",        tier=5 },
    -- LAKE
    { name="Frog",            rarity="Common",    income="$3/s",        biome="Lake",          tier=1 },
    { name="Duckling",        rarity="Common",    income="$4/s",        biome="Lake",          tier=1 },
    { name="Catfish",         rarity="Uncommon",  income="$12/s",       biome="Lake",          tier=2 },
    { name="Turtle",          rarity="Rare",      income="$60/s",       biome="Lake",          tier=3 },
    { name="Trulimero Trulicina", rarity="Epic",  income="$260/s",      biome="Lake",          tier=4 },
    { name="Swan",            rarity="Epic",      income="$320/s",      biome="Lake",          tier=4 },
    { name="Axolotl",         rarity="Legendary", income="$2.8K/s",     biome="Lake",          tier=5 },
    { name="Leviathan",       rarity="Cosmic",    income="$220K/s",     biome="Lake",          tier=7 },
    -- DESERT
    { name="Jerboa",          rarity="Common",    income="$6/s",        biome="Desert",        tier=1 },
    { name="Fennec",          rarity="Uncommon",  income="$18/s",       biome="Desert",        tier=2 },
    { name="Camel",           rarity="Rare",      income="$75/s",       biome="Desert",        tier=3 },
    { name="Tob Tobi Tob Tob",rarity="Epic",      income="$325/s",      biome="Desert",        tier=4 },
    { name="Snake",           rarity="Legendary", income="$3.6K/s",     biome="Desert",        tier=5 },
    { name="Sand Spider",     rarity="Mythic",    income="$16K/s",      biome="Desert",        tier=6 },
    { name="Scorpion",        rarity="Mythic",    income="$18.5K/s",    biome="Desert",        tier=6 },
    { name="Royal Sphinx",    rarity="Cosmic",    income="$280K/s",     biome="Desert",        tier=7 },
    -- JUNGLE
    { name="Chimpanzee",      rarity="Rare",      income="$90/s",       biome="Jungle",        tier=3 },
    { name="Toucan",          rarity="Rare",      income="$110/s",      biome="Jungle",        tier=3 },
    { name="Crocodile",       rarity="Epic",      income="$420/s",      biome="Jungle",        tier=4 },
    { name="Gorilla",         rarity="Legendary", income="$4.8K/s",     biome="Jungle",        tier=5 },
    { name="Orangutini Ananassini", rarity="Legendary", income="$5.5K/s", biome="Jungle",      tier=5 },
    { name="Spider",          rarity="Mythic",    income="$22K/s",      biome="Jungle",        tier=6 },
    { name="Tiger",           rarity="Mythic",    income="$28K/s",      biome="Jungle",        tier=6 },
    { name="King Snake",      rarity="Secret",    income="$3.5M/s",     biome="Jungle",        tier=8 },
    -- SNOW
    { name="Penguin",         rarity="Rare",      income="$140/s",      biome="Snow",          tier=3 },
    { name="Walrus",          rarity="Epic",      income="$600/s",      biome="Snow",          tier=4 },
    { name="Polar Bear",      rarity="Legendary", income="$7K/s",       biome="Snow",          tier=5 },
    { name="Sabertooth Tiger",rarity="Mythic",    income="$35K/s",      biome="Snow",          tier=6 },
    { name="Mammoth",         rarity="Mythic",    income="$42K/s",      biome="Snow",          tier=6 },
    { name="King Mammoth",    rarity="Cosmic",    income="$400K/s",     biome="Snow",          tier=7 },
    { name="Yeti",            rarity="Secret",    income="$5M/s",       biome="Snow",          tier=8 },
    { name="Ice Dragon",      rarity="Eternal",   income="$65M/s",      biome="Snow",          tier=9 },
    -- VOLCANO
    { name="Lava Gecko",      rarity="Rare",      income="$180/s",      biome="Volcano",       tier=3 },
    { name="Lava Frog",       rarity="Epic",      income="$850/s",      biome="Volcano",       tier=4 },
    { name="Flaming Bull",    rarity="Legendary", income="$9.5K/s",     biome="Volcano",       tier=5 },
    { name="Lava Iguana",     rarity="Legendary", income="$11K/s",      biome="Volcano",       tier=5 },
    { name="Chillin Chilli",  rarity="Mythic",    income="$55K/s",      biome="Volcano",       tier=6 },
    { name="Cerberus",        rarity="Secret",    income="$8M/s",       biome="Volcano",       tier=8 },
    { name="Phoenix",         rarity="Eternal",   income="$85M/s",      biome="Volcano",       tier=9 },
    { name="Lava Dragon",     rarity="Eternal",   income="$100M/s",     biome="Volcano",       tier=9 },
    -- ABYSS OCEAN
    { name="Parrotfish",      rarity="Rare",      income="$220/s",      biome="Abyss Ocean",   tier=3 },
    { name="Swordfish",       rarity="Epic",      income="$1.1K/s",     biome="Abyss Ocean",   tier=4 },
    { name="Shark",           rarity="Legendary", income="$15K/s",      biome="Abyss Ocean",   tier=5 },
    { name="Orca",            rarity="Mythic",    income="$80K/s",      biome="Abyss Ocean",   tier=6 },
    { name="Whale Shark",     rarity="Cosmic",    income="$700K/s",     biome="Abyss Ocean",   tier=7 },
    { name="Beluga Whale",    rarity="Cosmic",    income="$850K/s",     biome="Abyss Ocean",   tier=7 },
    { name="Kraken",          rarity="Secret",    income="$15M/s",      biome="Abyss Ocean",   tier=8 },
    { name="El Maja",         rarity="Eternal",   income="$130M/s",     biome="Abyss Ocean",   tier=9 },
    -- PREHISTORIC
    { name="Dodo",            rarity="Rare",      income="$280/s",      biome="Prehistoric",   tier=3 },
    { name="Pterodactyl",     rarity="Legendary", income="$22K/s",      biome="Prehistoric",   tier=5 },
    { name="Ankylosaurus",    rarity="Mythic",    income="$120K/s",     biome="Prehistoric",   tier=6 },
    { name="Triceratops",     rarity="Cosmic",    income="$1.2M/s",     biome="Prehistoric",   tier=7 },
    { name="Bronto",          rarity="Cosmic",    income="$1.5M/s",     biome="Prehistoric",   tier=7 },
    { name="TRex",            rarity="Secret",    income="$25M/s",      biome="Prehistoric",   tier=8 },
    { name="Tralaledon",      rarity="Secret",    income="$32M/s",      biome="Prehistoric",   tier=8 },
    { name="Mosasaurus",      rarity="Eternal",   income="$180M/s",     biome="Prehistoric",   tier=9 },
    -- COSMIC
    { name="Centapede",       rarity="Epic",      income="$1.5K/s",     biome="Cosmic",        tier=4 },
    { name="Cosmic Gecko",    rarity="Legendary", income="$30K/s",      biome="Cosmic",        tier=5 },
    { name="Cosmic Gorilla",  rarity="Mythic",    income="$180K/s",     biome="Cosmic",        tier=6 },
    { name="La Vacca Saturno Saturnita", rarity="Cosmic", income="$2.2M/s", biome="Cosmic",    tier=7 },
    { name="Cosmic Skeleton Boss", rarity="Secret", income="$45M/s",    biome="Cosmic",        tier=8 },
    { name="Cosmic Dragon",   rarity="Secret",    income="$60M/s",      biome="Cosmic",        tier=8 },
    { name="Eternal Lunar Dragon", rarity="Eternal", income="$250M/s",  biome="Cosmic",        tier=9 },
    { name="Unicorn",         rarity="Divine",    income="$1B/s",       biome="Cosmic",        tier=10 },
    -- CHERRY BLOSSOM
    { name="Crane",           rarity="Epic",      income="$4K/s",       biome="Cherry Blossom",tier=4 },
    { name="Salamander",      rarity="Legendary", income="$74K/s",      biome="Cherry Blossom",tier=5 },
    { name="Red Panda",       rarity="Mythic",    income="$450K/s",     biome="Cherry Blossom",tier=6 },
    { name="Snowy Owl",       rarity="Cosmic",    income="$7.5M/s",     biome="Cherry Blossom",tier=7 },
    { name="Koi",             rarity="Cosmic",    income="$12M/s",      biome="Cherry Blossom",tier=7 },
    { name="Stag",            rarity="Secret",    income="$145M/s",     biome="Cherry Blossom",tier=8 },
    { name="Oni Tiger",       rarity="Eternal",   income="$600M/s",     biome="Cherry Blossom",tier=9 },
    { name="Kitsune",         rarity="Divine",    income="$1.8B/s",     biome="Cherry Blossom",tier=10 },
    -- TITAN TEMPLE
    { name="Spideron",        rarity="Legendary", income="$95K/s",      biome="Titan Temple",  tier=5 },
    { name="Crustacia",       rarity="Legendary", income="$130K/s",     biome="Titan Temple",  tier=5 },
    { name="Bladehide",       rarity="Mythic",    income="$750K/s",     biome="Titan Temple",  tier=6 },
    { name="Mantaris",        rarity="Cosmic",    income="$11M/s",      biome="Titan Temple",  tier=7 },
    { name="Rhinotaur",       rarity="Cosmic",    income="$17.5M/s",    biome="Titan Temple",  tier=7 },
    { name="Mutant Shark",    rarity="Secret",    income="$215M/s",     biome="Titan Temple",  tier=8 },
    { name="Gorilla King",    rarity="Eternal",   income="$880M/s",     biome="Titan Temple",  tier=9 },
}

-- Map nama egg → data (lowercase untuk matching)
local EGG_MAP = {}
for _, e in ipairs(EGG_DB) do
    EGG_MAP[e.name:lower()] = e
    -- partial match juga
    for _, word in ipairs(e.name:lower():split(" ")) do
        if #word > 3 then
            EGG_MAP[word] = EGG_MAP[word] or e
        end
    end
end

-- Warna per rarity
local RARITY_COLORS = {
    Common    = Color3.fromRGB(200, 200, 200),
    Uncommon  = Color3.fromRGB(100, 200, 100),
    Rare      = Color3.fromRGB(80,  130, 255),
    Epic      = Color3.fromRGB(180, 80,  255),
    Legendary = Color3.fromRGB(255, 165, 0),
    Mythic    = Color3.fromRGB(255, 80,  80),
    Cosmic    = Color3.fromRGB(80,  220, 255),
    Secret    = Color3.fromRGB(255, 60,  180),
    Eternal   = Color3.fromRGB(255, 215, 0),
    Divine    = Color3.fromRGB(255, 255, 150),
}

local function getRarityColor(rarity)
    return RARITY_COLORS[rarity] or Color3.fromRGB(200, 200, 200)
end

local function getEggData(name)
    local lower = name:lower()
    if EGG_MAP[lower] then return EGG_MAP[lower] end
    -- partial: cari yang mengandung keyword
    for key, data in pairs(EGG_MAP) do
        if lower:find(key) or key:find(lower) then
            return data
        end
    end
    return nil
end

-- ── ANTI-BAN LAYER ────────────────────────────────────────────────────────────
-- Teknik: randomize timing, hindari pattern deteksi, jangan spam ProximityPrompt
local function antibanWait(base)
    if G.NOA_ANTIBAN then
        -- Tambah jitter random agar tidak terdeteksi sebagai bot pattern
        task.wait(base + math.random(10, 40) / 100)
    else
        task.wait(base)
    end
end

local function smoothTeleport(root, targetCFrame, steps)
    -- TP bertahap pakai BodyPosition agar lebih alami, bukan snap instant
    if not G.NOA_SMOOTHTP then
        root.CFrame = targetCFrame
        return
    end
    steps = steps or 6
    local startCF = root.CFrame
    for i = 1, steps do
        if not G.NOA_RUNNING then return end
        local alpha = i / steps
        root.CFrame = startCF:Lerp(targetCFrame, alpha)
        task.wait(0.03)
    end
end

-- ── HELPERS ─────────────────────────────────────────────────────────────────
local function getChar()  return LocalPlayer.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHuman()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end

local function notify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 3
        })
    end)
end

-- ── GUI BUILD ───────────────────────────────────────────────────────────────
if PlayerGui:FindFirstChild("NoaHub") then
    PlayerGui.NoaHub:Destroy()
end

local Screen = Instance.new("ScreenGui")
Screen.Name           = "NoaHub"
Screen.ResetOnSpawn   = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder   = 999
Screen.IgnoreGuiInset = true
Screen.Parent         = PlayerGui

-- Main container
local Main = Instance.new("Frame", Screen)
Main.Name              = "MainFrame"
Main.Size              = UDim2.fromOffset(560, 400)
Main.Position          = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint       = Vector2.new(0.5, 0.5)
Main.BackgroundColor3  = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel   = 0
Main.ClipsDescendants  = true
Main.ZIndex            = 10
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- Glow border
local Border = Instance.new("UIStroke", Main)
Border.Color     = Color3.fromRGB(80, 100, 200)
Border.Thickness = 1.5
Border.Transparency = 0.4

-- Title bar
local TitleBar = Instance.new("Frame", Main)
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 11

local TitleDot = Instance.new("Frame", TitleBar)
TitleDot.Size             = UDim2.fromOffset(8, 8)
TitleDot.Position         = UDim2.fromOffset(14, 16)
TitleDot.BackgroundColor3 = Color3.fromRGB(100, 130, 255)
TitleDot.BorderSizePixel  = 0
Instance.new("UICorner", TitleDot).CornerRadius = UDim.new(0.5, 0)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size                   = UDim2.new(1, -120, 1, 0)
TitleLabel.Position               = UDim2.fromOffset(30, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text                   = "Noa Hub  •  Steal An Egg"
TitleLabel.TextColor3             = Color3.fromRGB(200, 210, 255)
TitleLabel.Font                   = Enum.Font.GothamBold
TitleLabel.TextSize               = 13
TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
TitleLabel.ZIndex                 = 12

-- Version badge
local VerBadge = Instance.new("TextLabel", TitleBar)
VerBadge.Size             = UDim2.fromOffset(40, 18)
VerBadge.Position         = UDim2.new(1, -110, 0.5, -9)
VerBadge.BackgroundColor3 = Color3.fromRGB(30, 40, 80)
VerBadge.BorderSizePixel  = 0
VerBadge.Text             = "v3.0"
VerBadge.TextColor3       = Color3.fromRGB(120, 150, 255)
VerBadge.Font             = Enum.Font.GothamBold
VerBadge.TextSize         = 10
VerBadge.ZIndex           = 12
Instance.new("UICorner", VerBadge).CornerRadius = UDim.new(0, 4)

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size             = UDim2.fromOffset(26, 26)
MinBtn.Position         = UDim2.new(1, -66, 0.5, -13)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MinBtn.Text             = "—"
MinBtn.TextColor3       = Color3.fromRGB(200, 200, 220)
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextSize         = 12
MinBtn.BorderSizePixel  = 0
MinBtn.ZIndex           = 12
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size             = UDim2.fromOffset(26, 26)
CloseBtn.Position         = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 11
CloseBtn.BorderSizePixel  = 0
CloseBtn.ZIndex           = 12
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    G.NOA_RUNNING = false
    Screen:Destroy()
end)

local minimized = false
local ContentArea  -- forward declare

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if ContentArea then ContentArea.Visible = not minimized end
    Main.Size = minimized and UDim2.fromOffset(560, 40) or UDim2.fromOffset(560, 400)
    MinBtn.Text = minimized and "□" or "—"
end)

-- Drag
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
        local d = i.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)
TitleBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ── BODY ────────────────────────────────────────────────────────────────────
ContentArea = Instance.new("Frame", Main)
ContentArea.Name             = "ContentArea"
ContentArea.Size             = UDim2.new(1, 0, 1, -40)
ContentArea.Position         = UDim2.fromOffset(0, 40)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel  = 0
ContentArea.ClipsDescendants = false

-- Sidebar
local Sidebar = Instance.new("Frame", ContentArea)
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0, 132, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(11, 11, 17)
Sidebar.BorderSizePixel  = 0

local SideDiv = Instance.new("Frame", Sidebar)
SideDiv.Size = UDim2.new(0, 1, 1, 0)
SideDiv.Position = UDim2.new(1, 0, 0, 0)
SideDiv.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
SideDiv.BorderSizePixel = 0

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding = UDim.new(0, 3)
local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop = UDim.new(0, 10)
SidePad.PaddingLeft = UDim.new(0, 4)
SidePad.PaddingRight = UDim.new(0, 4)

-- Content panel
local PanelContainer = Instance.new("Frame", ContentArea)
PanelContainer.Name   = "PanelContainer"
PanelContainer.Size   = UDim2.new(1, -132, 1, 0)
PanelContainer.Position = UDim2.fromOffset(132, 0)
PanelContainer.BackgroundTransparency = 1
PanelContainer.ClipsDescendants = true

-- ── PAGE SYSTEM ──────────────────────────────────────────────────────────────
local PAGES     = {}
local navBtns   = {}
local currentPage = nil

local function makePage(id)
    local F = Instance.new("ScrollingFrame", PanelContainer)
    F.Name                = id
    F.Size                = UDim2.fromScale(1, 1)
    F.BackgroundTransparency = 1
    F.BorderSizePixel     = 0
    F.ScrollBarThickness  = 3
    F.ScrollBarImageColor3 = Color3.fromRGB(70, 90, 180)
    F.CanvasSize          = UDim2.new(0, 0, 0, 0)
    F.AutomaticCanvasSize = Enum.AutomaticSize.Y
    F.Visible             = false

    local Pad = Instance.new("UIPadding", F)
    Pad.PaddingLeft   = UDim.new(0, 12)
    Pad.PaddingRight  = UDim.new(0, 12)
    Pad.PaddingTop    = UDim.new(0, 12)
    Pad.PaddingBottom = UDim.new(0, 14)

    local Layout = Instance.new("UIListLayout", F)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding    = UDim.new(0, 6)

    PAGES[id] = { Frame = F }
    return F
end

local NAV_DEFS = {
    { id="info",    icon="ℹ", label="Information", order=1 },
    { id="main",    icon="⚡", label="Main",        order=2 },
    { id="auto",    icon="🤖", label="Auto",        order=3 },
    { id="eggs",    icon="🥚", label="Egg Checker", order=4 },
    { id="esp",     icon="👁", label="ESP",         order=5 },
    { id="servers", icon="🖥", label="Priv. Servers",order=6 },
    { id="misc",    icon="🔧", label="Misc",        order=7 },
    { id="config",  icon="⚙", label="Config",      order=8 },
}

local function showPage(id)
    if currentPage then
        PAGES[currentPage].Frame.Visible = false
        if navBtns[currentPage] then navBtns[currentPage].setActive(false) end
    end
    currentPage = id
    PAGES[id].Frame.Visible = true
    if navBtns[id] then navBtns[id].setActive(true) end
end

for _, def in ipairs(NAV_DEFS) do
    makePage(def.id)

    local Btn = Instance.new("TextButton", Sidebar)
    Btn.Name              = "Nav_"..def.id
    Btn.Size              = UDim2.new(1, 0, 0, 34)
    Btn.BackgroundTransparency = 1
    Btn.BorderSizePixel   = 0
    Btn.Text              = ""
    Btn.LayoutOrder       = def.order
    Btn.AutoButtonColor   = false
    Btn.ZIndex            = 15
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 7)

    local BtnHighlight = Instance.new("Frame", Btn)
    BtnHighlight.Size = UDim2.new(0, 3, 0.6, 0)
    BtnHighlight.Position = UDim2.fromOffset(0, 7)
    BtnHighlight.BackgroundColor3 = Color3.fromRGB(100, 130, 255)
    BtnHighlight.BorderSizePixel = 0
    BtnHighlight.Visible = false
    BtnHighlight.ZIndex = 16
    Instance.new("UICorner", BtnHighlight).CornerRadius = UDim.new(0, 2)

    local IconLbl = Instance.new("TextLabel", Btn)
    IconLbl.Size                   = UDim2.fromOffset(20, 34)
    IconLbl.Position               = UDim2.fromOffset(10, 0)
    IconLbl.BackgroundTransparency = 1
    IconLbl.Text                   = def.icon
    IconLbl.TextColor3             = Color3.fromRGB(120, 120, 145)
    IconLbl.Font                   = Enum.Font.Gotham
    IconLbl.TextSize               = 13
    IconLbl.ZIndex                 = 16

    local NameLbl = Instance.new("TextLabel", Btn)
    NameLbl.Size                   = UDim2.new(1, -36, 1, 0)
    NameLbl.Position               = UDim2.fromOffset(34, 0)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Text                   = def.label
    NameLbl.TextColor3             = Color3.fromRGB(120, 120, 145)
    NameLbl.Font                   = Enum.Font.Gotham
    NameLbl.TextSize               = 11
    NameLbl.TextXAlignment         = Enum.TextXAlignment.Left
    NameLbl.ZIndex                 = 16

    local function setActive(on)
        Btn.BackgroundTransparency = on and 0 or 1
        Btn.BackgroundColor3       = Color3.fromRGB(22, 24, 38)
        BtnHighlight.Visible       = on
        IconLbl.TextColor3 = on and Color3.fromRGB(120, 150, 255) or Color3.fromRGB(120, 120, 145)
        NameLbl.TextColor3 = on and Color3.fromRGB(210, 218, 255) or Color3.fromRGB(120, 120, 145)
        NameLbl.Font       = on and Enum.Font.GothamBold or Enum.Font.Gotham
    end

    navBtns[def.id] = { setActive = setActive }

    local capturedId = def.id
    Btn.MouseButton1Click:Connect(function() showPage(capturedId) end)
end

-- ── WIDGET FACTORY ───────────────────────────────────────────────────────────
local function makeLabel(parent, text, order)
    local L = Instance.new("TextLabel", parent)
    L.Size                    = UDim2.new(1, 0, 0, 14)
    L.BackgroundTransparency  = 1
    L.Text                    = text
    L.TextColor3              = Color3.fromRGB(80, 90, 130)
    L.Font                    = Enum.Font.GothamBold
    L.TextSize                = 10
    L.TextXAlignment          = Enum.TextXAlignment.Left
    L.LayoutOrder             = order or 0
    return L
end

local function makeRow(parent, label, sub, order)
    local h = sub and 46 or 36
    local Row = Instance.new("Frame", parent)
    Row.Size             = UDim2.new(1, 0, 0, h)
    Row.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order or 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size                    = UDim2.new(1, -60, 0, 18)
    Lbl.Position                = UDim2.fromOffset(12, sub and 8 or 9)
    Lbl.BackgroundTransparency  = 1
    Lbl.Text                    = label
    Lbl.TextColor3              = Color3.fromRGB(215, 218, 235)
    Lbl.Font                    = Enum.Font.Gotham
    Lbl.TextSize                = 12
    Lbl.TextXAlignment          = Enum.TextXAlignment.Left

    if sub then
        local Sub = Instance.new("TextLabel", Row)
        Sub.Size                    = UDim2.new(1, -60, 0, 13)
        Sub.Position                = UDim2.fromOffset(12, 26)
        Sub.BackgroundTransparency  = 1
        Sub.Text                    = sub
        Sub.TextColor3              = Color3.fromRGB(80, 84, 110)
        Sub.Font                    = Enum.Font.Gotham
        Sub.TextSize                = 10
        Sub.TextXAlignment          = Enum.TextXAlignment.Left
    end
    return Row
end

local function makeToggle(parent, label, sub, flag, order)
    local Row = makeRow(parent, label, sub, order)

    local Track = Instance.new("Frame", Row)
    Track.Size             = UDim2.fromOffset(36, 20)
    Track.Position         = UDim2.new(1, -48, 0.5, -10)
    Track.BackgroundColor3 = G[flag] and Color3.fromRGB(80, 110, 230) or Color3.fromRGB(45, 45, 65)
    Track.BorderSizePixel  = 0
    Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 10)

    local Thumb = Instance.new("Frame", Track)
    Thumb.Size             = UDim2.fromOffset(14, 14)
    Thumb.Position         = G[flag] and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3)
    Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Thumb.BorderSizePixel  = 0
    Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 7)

    local function refresh()
        local on = G[flag]
        Track.BackgroundColor3 = on and Color3.fromRGB(80, 110, 230) or Color3.fromRGB(45, 45, 65)
        TweenService:Create(Thumb, TweenInfo.new(0.13, Enum.EasingStyle.Quad), {
            Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3)
        }):Play()
    end

    local HB = Instance.new("TextButton", Row)
    HB.Size               = UDim2.fromScale(1, 1)
    HB.BackgroundTransparency = 1
    HB.Text               = ""
    HB.ZIndex             = 20
    HB.MouseButton1Click:Connect(function()
        G[flag] = not G[flag]
        refresh()
    end)
    return Row
end

local function makeSlider(parent, label, flag, min, max, step, suffix, order)
    local Row = Instance.new("Frame", parent)
    Row.Size             = UDim2.new(1, 0, 0, 56)
    Row.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order or 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size = UDim2.new(1, -80, 0, 18)
    Lbl.Position = UDim2.fromOffset(12, 9)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = Color3.fromRGB(215, 218, 235)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ValLbl = Instance.new("TextLabel", Row)
    ValLbl.Size = UDim2.fromOffset(76, 18)
    ValLbl.Position = UDim2.new(1, -86, 0, 9)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Text = tostring(G[flag])..(suffix or "")
    ValLbl.TextColor3 = Color3.fromRGB(110, 140, 255)
    ValLbl.Font = Enum.Font.GothamBold
    ValLbl.TextSize = 12
    ValLbl.TextXAlignment = Enum.TextXAlignment.Right

    local Track = Instance.new("Frame", Row)
    Track.Size = UDim2.new(1, -24, 0, 4)
    Track.Position = UDim2.fromOffset(12, 38)
    Track.BackgroundColor3 = Color3.fromRGB(38, 40, 58)
    Track.BorderSizePixel = 0
    Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 2)

    local pct = math.clamp((G[flag] - min) / (max - min), 0, 1)
    local Fill = Instance.new("Frame", Track)
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(80, 110, 230)
    Fill.BorderSizePixel = 0
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 2)

    local HB = Instance.new("TextButton", Track)
    HB.Size = UDim2.fromScale(1, 1)
    HB.BackgroundTransparency = 1
    HB.Text = ""
    HB.ZIndex = 20

    local function setVal(x)
        local rel = math.clamp(x - Track.AbsolutePosition.X, 0, Track.AbsoluteSize.X)
        local ratio = rel / Track.AbsoluteSize.X
        local val = math.clamp(math.round((min + ratio * (max - min)) / step) * step, min, max)
        G[flag] = val
        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        ValLbl.Text = tostring(val)..(suffix or "")
    end

    local sliding = false
    HB.MouseButton1Down:Connect(function(x) sliding = true; setVal(x) end)
    HB.MouseButton1Up:Connect(function() sliding = false end)
    HB.MouseMoved:Connect(function(x) if sliding then setVal(x) end end)
    return Row
end

local function makePillDropdown(parent, label, opts, descs, flag, order)
    local Row = Instance.new("Frame", parent)
    Row.Size             = UDim2.new(1, 0, 0, 70)
    Row.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order or 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size = UDim2.new(1, -20, 0, 18)
    Lbl.Position = UDim2.fromOffset(12, 8)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = Color3.fromRGB(215, 218, 235)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local PF = Instance.new("Frame", Row)
    PF.Size = UDim2.new(1, -24, 0, 24)
    PF.Position = UDim2.fromOffset(12, 30)
    PF.BackgroundTransparency = 1
    local PL = Instance.new("UIListLayout", PF)
    PL.FillDirection = Enum.FillDirection.Horizontal
    PL.Padding = UDim.new(0, 5)

    local DescLbl = Instance.new("TextLabel", Row)
    DescLbl.Size = UDim2.new(1, -24, 0, 12)
    DescLbl.Position = UDim2.fromOffset(12, 56)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Text = descs and (descs[G[flag]] or "") or ""
    DescLbl.TextColor3 = Color3.fromRGB(70, 75, 105)
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.TextSize = 9
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left

    local pills = {}
    for _, opt in ipairs(opts) do
        local P = Instance.new("TextButton", PF)
        P.Size = UDim2.fromOffset(0, 22)
        P.AutomaticSize = Enum.AutomaticSize.X
        P.BackgroundColor3 = G[flag] == opt and Color3.fromRGB(65, 90, 200) or Color3.fromRGB(30, 32, 50)
        P.BorderSizePixel = 0
        P.Text = opt:sub(1,1):upper()..opt:sub(2)
        P.TextColor3 = G[flag] == opt and Color3.fromRGB(200, 215, 255) or Color3.fromRGB(110, 115, 145)
        P.Font = Enum.Font.GothamBold
        P.TextSize = 10
        P.ZIndex = 20
        Instance.new("UICorner", P).CornerRadius = UDim.new(0, 6)
        local PP = Instance.new("UIPadding", P)
        PP.PaddingLeft = UDim.new(0, 8); PP.PaddingRight = UDim.new(0, 8)
        pills[opt] = P

        P.MouseButton1Click:Connect(function()
            G[flag] = opt
            for k, v in pairs(pills) do
                v.BackgroundColor3 = (k==opt) and Color3.fromRGB(65, 90, 200) or Color3.fromRGB(30, 32, 50)
                v.TextColor3 = (k==opt) and Color3.fromRGB(200, 215, 255) or Color3.fromRGB(110, 115, 145)
            end
            if descs then DescLbl.Text = descs[opt] or "" end
        end)
    end
    return Row
end

local function makeButton(parent, label, col, cb, order)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size             = UDim2.new(1, 0, 0, 34)
    Btn.BackgroundColor3 = col or Color3.fromRGB(30, 32, 50)
    Btn.BorderSizePixel  = 0
    Btn.Text             = label
    Btn.TextColor3       = Color3.fromRGB(210, 215, 255)
    Btn.Font             = Enum.Font.GothamBold
    Btn.TextSize         = 12
    Btn.LayoutOrder      = order or 0
    Btn.ZIndex           = 20
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    if cb then Btn.MouseButton1Click:Connect(cb) end
    return Btn
end

local function makeInfoPair(parent, key, val, order)
    local Row = Instance.new("Frame", parent)
    Row.Size             = UDim2.new(1, 0, 0, 30)
    Row.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order or 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 7)

    local K = Instance.new("TextLabel", Row)
    K.Size = UDim2.fromScale(0.5, 1)
    K.BackgroundTransparency = 1
    K.Text = key
    K.TextColor3 = Color3.fromRGB(90, 95, 125)
    K.Font = Enum.Font.Gotham
    K.TextSize = 11
    K.TextXAlignment = Enum.TextXAlignment.Left
    local KP = Instance.new("UIPadding", K); KP.PaddingLeft = UDim.new(0, 12)

    local V = Instance.new("TextLabel", Row)
    V.Size = UDim2.fromScale(0.5, 1)
    V.Position = UDim2.fromScale(0.5, 0)
    V.BackgroundTransparency = 1
    V.Text = tostring(val)
    V.TextColor3 = Color3.fromRGB(185, 195, 255)
    V.Font = Enum.Font.GothamBold
    V.TextSize = 11
    V.TextXAlignment = Enum.TextXAlignment.Right
    local VP = Instance.new("UIPadding", V); VP.PaddingRight = UDim.new(0, 12)

    return Row, V
end

-- ── PAGE: INFORMATION ────────────────────────────────────────────────────────
local InfoF = PAGES["info"].Frame
makeInfoPair(InfoF, "Script",   "Noa Hub v3.0",   1)
makeInfoPair(InfoF, "Game",     "Steal An Egg",    2)
makeInfoPair(InfoF, "PlaceId",  "10563114921",     3)
makeInfoPair(InfoF, "Status",   "Active",          4)
makeInfoPair(InfoF, "Biomes",   "11 biome support",5)
makeInfoPair(InfoF, "Eggs DB",  tostring(#EGG_DB).." eggs",  6)
makeInfoPair(InfoF, "Anti-ban", "Active",          7)

local InfoBox = Instance.new("TextLabel", InfoF)
InfoBox.Size             = UDim2.new(1, 0, 0, 0)
InfoBox.AutomaticSize    = Enum.AutomaticSize.Y
InfoBox.BackgroundColor3 = Color3.fromRGB(18, 20, 35)
InfoBox.BorderSizePixel  = 0
InfoBox.Text             = "Egg Checker — scan egg di server langsung, pilih rarity mana yang mau di-steal. Anti-ban aktif: randomize timing, smooth teleport, jitter delay untuk cegah deteksi bot."
InfoBox.TextColor3       = Color3.fromRGB(100, 108, 155)
InfoBox.Font             = Enum.Font.Gotham
InfoBox.TextSize         = 11
InfoBox.TextWrapped      = true
InfoBox.TextXAlignment   = Enum.TextXAlignment.Left
InfoBox.LayoutOrder      = 8
local IBP = Instance.new("UIPadding", InfoBox)
IBP.PaddingLeft = UDim.new(0, 10); IBP.PaddingRight = UDim.new(0, 10)
IBP.PaddingTop  = UDim.new(0, 8);  IBP.PaddingBottom = UDim.new(0, 8)
Instance.new("UICorner", InfoBox).CornerRadius = UDim.new(0, 8)

-- ── PAGE: MAIN ───────────────────────────────────────────────────────────────
local MainF = PAGES["main"].Frame
makeLabel(MainF, "MOVEMENT", 1)
makeSlider(MainF, "Walk Speed", "NOA_STEALSPEED", 16, 600, 1, "", 2)
makeToggle(MainF, "Noclip", "Tembus semua objek", "NOA_NOCLIP", 3)
makeToggle(MainF, "Infinite Jump", "Loncat terus tanpa batas", "NOA_INFJUMP", 4)
makeLabel(MainF, "TREADMILL", 5)
makeToggle(MainF, "Auto Treadmill", "Langsung ke treadmill setelah steal", "NOA_AUTOTREAD", 6)
makeLabel(MainF, "ANTI-BAN", 7)
makeToggle(MainF, "Anti-Ban Mode", "Randomize timing & smooth teleport", "NOA_ANTIBAN", 8)
makeToggle(MainF, "Smooth Teleport", "TP bertahap agar lebih alami", "NOA_SMOOTHTP", 9)

-- ── PAGE: AUTO ───────────────────────────────────────────────────────────────
local AutoF = PAGES["auto"].Frame
makeLabel(AutoF, "STEAL METHOD", 1)
local stealDescs = {
    zigzag  = "Kanan-kiri saat kabur — sulit dikejar guardian.",
    tween   = "Jalan lurus ke base — cepat, mudah diprediksi.",
    instant = "Berhenti di safe zone. Clone mencuri, lalu menyerahkan egg.",
    fly     = "Terbang saat mencuri — lewati semua rintangan.",
}
makePillDropdown(AutoF, "Move Style", {"zigzag","tween","instant","fly"}, stealDescs, "NOA_STEALMETHOD", 2)
makeSlider(AutoF, "Steal Speed", "NOA_STEALSPEED", 16, 600, 1, "", 3)
makeLabel(AutoF, "AUTO ACTIONS", 4)
makeToggle(AutoF, "Auto Steal Egg", "Curi telur otomatis dari nest", "NOA_AUTOSTEAL", 5)
makeToggle(AutoF, "Auto Drop ke Base", "Antar ke pen setelah dapat egg", "NOA_AUTODROP", 6)
makeToggle(AutoF, "Auto Treadmill", "Langsung ke treadmill setelah steal", "NOA_AUTOTREAD", 7)
makeLabel(AutoF, "EGG PREDICTOR", 8)
makeToggle(AutoF, "Egg Predictor", "Hanya steal Secret, Eternal, Divine", "NOA_EGGPREDICT", 9)

local PredNote = Instance.new("TextLabel", AutoF)
PredNote.Size = UDim2.new(1, 0, 0, 0)
PredNote.AutomaticSize = Enum.AutomaticSize.Y
PredNote.BackgroundColor3 = Color3.fromRGB(22, 18, 40)
PredNote.BorderSizePixel = 0
PredNote.Text = "Predictor: skip egg di bawah Secret. Gunakan Egg Checker tab untuk kontrol rarity lebih detail."
PredNote.TextColor3 = Color3.fromRGB(140, 115, 200)
PredNote.Font = Enum.Font.Gotham
PredNote.TextSize = 10
PredNote.TextWrapped = true
PredNote.TextXAlignment = Enum.TextXAlignment.Left
PredNote.LayoutOrder = 10
local PNP = Instance.new("UIPadding", PredNote)
PNP.PaddingLeft = UDim.new(0, 10); PNP.PaddingRight = UDim.new(0, 10)
PNP.PaddingTop = UDim.new(0, 7); PNP.PaddingBottom = UDim.new(0, 7)
Instance.new("UICorner", PredNote).CornerRadius = UDim.new(0, 8)

-- ── PAGE: EGG CHECKER ────────────────────────────────────────────────────────
local EggsF = PAGES["eggs"].Frame

-- Header info
local EggHdr = Instance.new("TextLabel", EggsF)
EggHdr.Size = UDim2.new(1, 0, 0, 26)
EggHdr.BackgroundTransparency = 1
EggHdr.Text = "Scan egg di server → pilih rarity yang mau di-steal (multi-select)"
EggHdr.TextColor3 = Color3.fromRGB(90, 95, 130)
EggHdr.Font = Enum.Font.Gotham
EggHdr.TextSize = 11
EggHdr.TextWrapped = true
EggHdr.TextXAlignment = Enum.TextXAlignment.Left
EggHdr.LayoutOrder = 0

-- Filter rarity row
local rarityFilterFrame = Instance.new("Frame", EggsF)
rarityFilterFrame.Name = "RarityFilter"
rarityFilterFrame.Size = UDim2.new(1, 0, 0, 0)
rarityFilterFrame.AutomaticSize = Enum.AutomaticSize.Y
rarityFilterFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 28)
rarityFilterFrame.BorderSizePixel = 0
rarityFilterFrame.LayoutOrder = 1
Instance.new("UICorner", rarityFilterFrame).CornerRadius = UDim.new(0, 8)
local RFPad = Instance.new("UIPadding", rarityFilterFrame)
RFPad.PaddingLeft = UDim.new(0, 10); RFPad.PaddingRight = UDim.new(0, 10)
RFPad.PaddingTop = UDim.new(0, 8); RFPad.PaddingBottom = UDim.new(0, 8)

local RarityFilterLbl = Instance.new("TextLabel", rarityFilterFrame)
RarityFilterLbl.Size = UDim2.new(1, 0, 0, 14)
RarityFilterLbl.BackgroundTransparency = 1
RarityFilterLbl.Text = "FILTER RARITY (klik untuk toggle)"
RarityFilterLbl.TextColor3 = Color3.fromRGB(70, 75, 110)
RarityFilterLbl.Font = Enum.Font.GothamBold
RarityFilterLbl.TextSize = 10
RarityFilterLbl.TextXAlignment = Enum.TextXAlignment.Left
RarityFilterLbl.LayoutOrder = 0

local RarityPillContainer = Instance.new("Frame", rarityFilterFrame)
RarityPillContainer.Size = UDim2.new(1, 0, 0, 0)
RarityPillContainer.AutomaticSize = Enum.AutomaticSize.Y
RarityPillContainer.BackgroundTransparency = 1
RarityPillContainer.LayoutOrder = 1

local RFLayout = Instance.new("UIListLayout", rarityFilterFrame)
RFLayout.SortOrder = Enum.SortOrder.LayoutOrder
RFLayout.Padding = UDim.new(0, 6)

local RPLayout = Instance.new("UIGridLayout", RarityPillContainer)
RPLayout.CellSize = UDim2.fromOffset(78, 22)
RPLayout.CellPadding = UDim2.fromOffset(4, 4)
RPLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

-- track filter selections
local rarityFilter = {}
local rarityPillBtns = {}
local RARITY_TIERS = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine"}

for _, r in ipairs(RARITY_TIERS) do
    rarityFilter[r] = false
    local P = Instance.new("TextButton", RarityPillContainer)
    P.Size = UDim2.fromOffset(78, 22)
    P.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    P.BorderSizePixel = 0
    P.Text = r
    P.TextColor3 = getRarityColor(r)
    P.Font = Enum.Font.GothamBold
    P.TextSize = 9
    P.ZIndex = 20
    Instance.new("UICorner", P).CornerRadius = UDim.new(0, 5)
    local PStroke = Instance.new("UIStroke", P)
    PStroke.Color = getRarityColor(r)
    PStroke.Thickness = 1
    PStroke.Transparency = 0.7

    rarityPillBtns[r] = { pill = P, stroke = PStroke }

    local capturedR = r
    P.MouseButton1Click:Connect(function()
        rarityFilter[capturedR] = not rarityFilter[capturedR]
        local on = rarityFilter[capturedR]
        P.BackgroundColor3 = on and getRarityColor(capturedR):Lerp(Color3.fromRGB(0,0,0), 0.6) or Color3.fromRGB(20, 22, 32)
        PStroke.Transparency = on and 0.1 or 0.7
    end)
end

-- Scan + result area
local ScanBtn = makeButton(EggsF, "🔍  Scan Egg di Server", Color3.fromRGB(30, 50, 100), nil, 2)
local ClearBtn = makeButton(EggsF, "✕  Clear Semua Pilihan", Color3.fromRGB(50, 25, 30), nil, 3)

local EggListContainer = Instance.new("Frame", EggsF)
EggListContainer.Name = "EggList"
EggListContainer.Size = UDim2.new(1, 0, 0, 0)
EggListContainer.AutomaticSize = Enum.AutomaticSize.Y
EggListContainer.BackgroundTransparency = 1
EggListContainer.LayoutOrder = 4

local ELLayout = Instance.new("UIListLayout", EggListContainer)
ELLayout.SortOrder = Enum.SortOrder.LayoutOrder
ELLayout.Padding = UDim.new(0, 4)

local EggCountLbl = Instance.new("TextLabel", EggsF)
EggCountLbl.Size = UDim2.new(1, 0, 0, 18)
EggCountLbl.BackgroundTransparency = 1
EggCountLbl.Text = "Belum scan — pencet tombol Scan di atas"
EggCountLbl.TextColor3 = Color3.fromRGB(70, 75, 110)
EggCountLbl.Font = Enum.Font.Gotham
EggCountLbl.TextSize = 10
EggCountLbl.TextXAlignment = Enum.TextXAlignment.Left
EggCountLbl.LayoutOrder = 5

local selectedEggItems = {}  -- { name, selected }
local eggItemFrames = {}

local function isRarityAllowed(rarity)
    -- jika tidak ada filter aktif, tampilkan semua
    local anyActive = false
    for _, on in pairs(rarityFilter) do
        if on then anyActive = true; break end
    end
    if not anyActive then return true end
    return rarityFilter[rarity] == true
end

local function buildEggList(eggs)
    -- Clear
    for _, f in ipairs(EggListContainer:GetChildren()) do
        if f:IsA("Frame") then f:Destroy() end
    end
    eggItemFrames = {}

    local shown = 0
    for _, eggInfo in ipairs(eggs) do
        local data = eggInfo.data  -- EGG_DB entry or nil
        local rawName = eggInfo.name
        local rarity  = data and data.rarity or "?"
        local income  = data and data.income or "?"
        local biome   = data and data.biome  or "?"

        if data and not isRarityAllowed(rarity) then continue end

        shown = shown + 1
        local Row = Instance.new("Frame", EggListContainer)
        Row.Size = UDim2.new(1, 0, 0, 42)
        Row.BackgroundColor3 = Color3.fromRGB(20, 21, 32)
        Row.BorderSizePixel = 0
        Row.LayoutOrder = shown
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 7)

        local isSelected = G.NOA_SELECTED_EGGS[rawName] == true

        -- Color strip kiri berdasar rarity
        local Strip = Instance.new("Frame", Row)
        Strip.Size = UDim2.fromOffset(3, 30)
        Strip.Position = UDim2.fromOffset(0, 6)
        Strip.BackgroundColor3 = data and getRarityColor(rarity) or Color3.fromRGB(100,100,100)
        Strip.BorderSizePixel = 0
        Instance.new("UICorner", Strip).CornerRadius = UDim.new(0, 2)

        local NameLbl = Instance.new("TextLabel", Row)
        NameLbl.Size = UDim2.new(1, -120, 0, 18)
        NameLbl.Position = UDim2.fromOffset(12, 5)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Text = rawName
        NameLbl.TextColor3 = Color3.fromRGB(210, 215, 240)
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.TextSize = 11
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local InfoLbl = Instance.new("TextLabel", Row)
        InfoLbl.Size = UDim2.new(1, -120, 0, 13)
        InfoLbl.Position = UDim2.fromOffset(12, 24)
        InfoLbl.BackgroundTransparency = 1
        InfoLbl.Text = biome.." • "..income
        InfoLbl.TextColor3 = Color3.fromRGB(80, 85, 115)
        InfoLbl.Font = Enum.Font.Gotham
        InfoLbl.TextSize = 10
        InfoLbl.TextXAlignment = Enum.TextXAlignment.Left

        local RarityBadge = Instance.new("TextLabel", Row)
        RarityBadge.Size = UDim2.fromOffset(72, 18)
        RarityBadge.Position = UDim2.new(1, -130, 0.5, -9)
        RarityBadge.BackgroundColor3 = data and getRarityColor(rarity):Lerp(Color3.fromRGB(0,0,0), 0.7) or Color3.fromRGB(30,30,30)
        RarityBadge.BorderSizePixel = 0
        RarityBadge.Text = rarity
        RarityBadge.TextColor3 = data and getRarityColor(rarity) or Color3.fromRGB(150,150,150)
        RarityBadge.Font = Enum.Font.GothamBold
        RarityBadge.TextSize = 9
        Instance.new("UICorner", RarityBadge).CornerRadius = UDim.new(0, 5)

        local SelBtn = Instance.new("TextButton", Row)
        SelBtn.Size = UDim2.fromOffset(46, 22)
        SelBtn.Position = UDim2.new(1, -52, 0.5, -11)
        SelBtn.BackgroundColor3 = isSelected and Color3.fromRGB(50, 80, 180) or Color3.fromRGB(28, 30, 45)
        SelBtn.BorderSizePixel = 0
        SelBtn.Text = isSelected and "✓ ON" or "OFF"
        SelBtn.TextColor3 = isSelected and Color3.fromRGB(180, 200, 255) or Color3.fromRGB(80, 85, 110)
        SelBtn.Font = Enum.Font.GothamBold
        SelBtn.TextSize = 9
        SelBtn.ZIndex = 20
        Instance.new("UICorner", SelBtn).CornerRadius = UDim.new(0, 6)

        local capturedName = rawName
        SelBtn.MouseButton1Click:Connect(function()
            local on = not (G.NOA_SELECTED_EGGS[capturedName] == true)
            G.NOA_SELECTED_EGGS[capturedName] = on
            SelBtn.BackgroundColor3 = on and Color3.fromRGB(50, 80, 180) or Color3.fromRGB(28, 30, 45)
            SelBtn.TextColor3 = on and Color3.fromRGB(180, 200, 255) or Color3.fromRGB(80, 85, 110)
            SelBtn.Text = on and "✓ ON" or "OFF"
        end)

        eggItemFrames[rawName] = Row
    end

    EggCountLbl.Text = shown.." egg ditemukan di server"
end

-- Scan logic: cari semua BasePart/Model di workspace yang namanya mengandung "egg"
ScanBtn.MouseButton1Click:Connect(function()
    ScanBtn.Text = "Scanning..."
    ScanBtn.BackgroundColor3 = Color3.fromRGB(20, 35, 70)
    task.spawn(function()
        local found = {}
        local seen  = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name
            local lower = n:lower()
            if lower:find("egg") and not seen[n] then
                seen[n] = true
                local data = getEggData(n)
                table.insert(found, { name = n, data = data })
            end
        end
        -- Sort by tier desc
        table.sort(found, function(a, b)
            local ta = a.data and a.data.tier or 0
            local tb = b.data and b.data.tier or 0
            return ta > tb
        end)
        buildEggList(found)
        ScanBtn.Text = "🔍  Scan Egg di Server"
        ScanBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 100)
    end)
end)

ClearBtn.MouseButton1Click:Connect(function()
    G.NOA_SELECTED_EGGS = {}
    for name, row in pairs(eggItemFrames) do
        local sel = row:FindFirstChildOfClass("TextButton")
        if sel then
            sel.BackgroundColor3 = Color3.fromRGB(28, 30, 45)
            sel.TextColor3 = Color3.fromRGB(80, 85, 110)
            sel.Text = "OFF"
        end
    end
end)

makeToggle(EggsF, "Aktifkan Egg Checker", "Gunakan daftar pilihan di atas untuk auto-steal", "NOA_EGGCHECK", 6)

-- ── PAGE: ESP ─────────────────────────────────────────────────────────────────
local EspF = PAGES["esp"].Frame
makeLabel(EspF, "HIGHLIGHT", 1)
makeToggle(EspF, "Egg ESP", "Highlight egg — warna per rarity", "NOA_EGGESP", 2)
makeToggle(EspF, "Guardian ESP", "Guardian — merah", "NOA_GUARDESP", 3)
makeToggle(EspF, "Player ESP", "Pemain lain — biru", "NOA_PLAYERESP", 4)

-- ── PAGE: PRIVATE SERVERS ─────────────────────────────────────────────────────
local SrvF = PAGES["servers"].Frame
makeLabel(SrvF, "SERVER LIST", 1)

local serverCodes = {}
local SrvListF = Instance.new("Frame", SrvF)
SrvListF.Size = UDim2.new(1, 0, 0, 0)
SrvListF.AutomaticSize = Enum.AutomaticSize.Y
SrvListF.BackgroundTransparency = 1
SrvListF.LayoutOrder = 2
local SLL = Instance.new("UIListLayout", SrvListF)
SLL.Padding = UDim.new(0, 4)

local function renderServers()
    for _, c in ipairs(SrvListF:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    if #serverCodes == 0 then
        local E = Instance.new("TextLabel", SrvListF)
        E.Size = UDim2.new(1, 0, 0, 28)
        E.BackgroundTransparency = 1
        E.Text = "Belum ada server — tambah kode dulu"
        E.TextColor3 = Color3.fromRGB(70, 75, 100)
        E.Font = Enum.Font.Gotham; E.TextSize = 11
        return
    end
    for i, code in ipairs(serverCodes) do
        local R = Instance.new("Frame", SrvListF)
        R.Size = UDim2.new(1, 0, 0, 34)
        R.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
        R.BorderSizePixel = 0
        Instance.new("UICorner", R).CornerRadius = UDim.new(0, 7)

        local LB = Instance.new("TextLabel", R)
        LB.Size = UDim2.new(1, -90, 1, 0)
        LB.Position = UDim2.fromOffset(12, 0)
        LB.BackgroundTransparency = 1
        LB.Text = "Server #"..i.."  — "..code:sub(1, 14).."…"
        LB.TextColor3 = Color3.fromRGB(190, 195, 225)
        LB.Font = Enum.Font.Gotham; LB.TextSize = 11
        LB.TextXAlignment = Enum.TextXAlignment.Left

        local JB = Instance.new("TextButton", R)
        JB.Size = UDim2.fromOffset(62, 22)
        JB.Position = UDim2.new(1, -70, 0.5, -11)
        JB.BackgroundColor3 = Color3.fromRGB(45, 65, 175)
        JB.BorderSizePixel = 0; JB.Text = "Join"
        JB.TextColor3 = Color3.fromRGB(200, 210, 255)
        JB.Font = Enum.Font.GothamBold; JB.TextSize = 11
        JB.ZIndex = 20
        Instance.new("UICorner", JB).CornerRadius = UDim.new(0, 6)

        local capturedCode = code
        JB.MouseButton1Click:Connect(function()
            local ok, err = pcall(function()
                game:GetService("TeleportService"):TeleportToPrivateServer(game.PlaceId, capturedCode, {LocalPlayer})
            end)
            if not ok then notify("Noa Hub", "Gagal join: "..tostring(err), 4) end
        end)
    end
end
renderServers()

local SrvInput = Instance.new("TextBox", SrvF)
SrvInput.Size = UDim2.new(1, 0, 0, 32)
SrvInput.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
SrvInput.BorderSizePixel = 0
SrvInput.PlaceholderText = "Paste server code di sini..."
SrvInput.PlaceholderColor3 = Color3.fromRGB(70, 75, 100)
SrvInput.Text = ""
SrvInput.TextColor3 = Color3.fromRGB(210, 215, 245)
SrvInput.Font = Enum.Font.Gotham; SrvInput.TextSize = 11
SrvInput.LayoutOrder = 3; SrvInput.ZIndex = 20
Instance.new("UICorner", SrvInput).CornerRadius = UDim.new(0, 7)
local SIP = Instance.new("UIPadding", SrvInput)
SIP.PaddingLeft = UDim.new(0, 10); SIP.PaddingRight = UDim.new(0, 10)

makeButton(SrvF, "+ Tambah Server Code", Color3.fromRGB(28, 38, 70), function()
    local c = SrvInput.Text:gsub("%s","")
    if #c > 5 then
        table.insert(serverCodes, c)
        SrvInput.Text = ""
        renderServers()
    end
end, 4)

makeLabel(SrvF, "OPTIONS", 5)
makeToggle(SrvF, "Auto Hop Server Sepi", "Pindah kalau server terlalu ramai", "NOA_AUTOHOP", 6)

-- ── PAGE: MISC ───────────────────────────────────────────────────────────────
local MiscF = PAGES["misc"].Frame
makeLabel(MiscF, "GUARDIAN", 1)
makeToggle(MiscF, "Anti Guardian", "Noclip bypass saat dikejar", "NOA_ANTIGUARD", 2)
makeToggle(MiscF, "Kill Guardian (NPC)", "Set HP NPC ke 0 dalam radius", "NOA_KILLGUARD", 3)
makeLabel(MiscF, "UTILITY", 4)
makeToggle(MiscF, "Anti AFK", "Cegah kick karena AFK", "NOA_ANTIAAFK", 5)
makeButton(MiscF, "Rejoin", Color3.fromRGB(28, 32, 55), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end, 6)
makeButton(MiscF, "Reset Karakter", Color3.fromRGB(28, 32, 55), function()
    local h = getHuman(); if h then h.Health = 0 end
end, 7)
makeButton(MiscF, "Tutup Noa Hub", Color3.fromRGB(55, 22, 22), function()
    G.NOA_RUNNING = false; Screen:Destroy()
end, 8)

-- ── PAGE: CONFIG ──────────────────────────────────────────────────────────────
local CfgF = PAGES["config"].Frame
makeLabel(CfgF, "SAVE / LOAD", 1)

local CFG_KEYS = {
    "NOA_NOCLIP","NOA_INFJUMP","NOA_ANTIAAFK","NOA_AUTOSTEAL","NOA_AUTODROP",
    "NOA_AUTOTREAD","NOA_EGGCHECK","NOA_EGGPREDICT","NOA_KILLGUARD","NOA_ANTIGUARD",
    "NOA_AUTOHOP","NOA_EGGESP","NOA_GUARDESP","NOA_PLAYERESP","NOA_STEALMETHOD",
    "NOA_STEALSPEED","NOA_ANTIBAN","NOA_SMOOTHTP",
}

makeButton(CfgF, "💾  Save Config", Color3.fromRGB(28, 42, 65), function()
    local data = {}
    for _, k in ipairs(CFG_KEYS) do data[k] = G[k] end
    data["NOA_SELECTED_EGGS"] = G.NOA_SELECTED_EGGS
    local ok, err = pcall(writefile, "NoaHub_SAE.json", HttpService:JSONEncode(data))
    notify("Noa Hub", ok and "Config disimpan!" or "Gagal: "..tostring(err), 4)
end, 2)

makeButton(CfgF, "📂  Load Config", Color3.fromRGB(28, 42, 65), function()
    local ok, raw = pcall(readfile, "NoaHub_SAE.json")
    if ok then
        local data = HttpService:JSONDecode(raw)
        for _, k in ipairs(CFG_KEYS) do
            if data[k] ~= nil then G[k] = data[k] end
        end
        if data["NOA_SELECTED_EGGS"] then G.NOA_SELECTED_EGGS = data["NOA_SELECTED_EGGS"] end
        notify("Noa Hub", "Config dimuat!", 4)
    else
        notify("Noa Hub", "Belum ada config tersimpan.", 4)
    end
end, 3)

makeButton(CfgF, "🗑  Reset Default", Color3.fromRGB(48, 22, 22), function()
    G.NOA_NOCLIP=false; G.NOA_INFJUMP=false; G.NOA_AUTOSTEAL=false
    G.NOA_AUTODROP=false; G.NOA_AUTOTREAD=false; G.NOA_EGGCHECK=false
    G.NOA_EGGPREDICT=false; G.NOA_KILLGUARD=false; G.NOA_ANTIGUARD=false
    G.NOA_STEALMETHOD="zigzag"; G.NOA_STEALSPEED=200
    G.NOA_ANTIBAN=true; G.NOA_SMOOTHTP=true; G.NOA_SELECTED_EGGS={}
    notify("Noa Hub", "Reset selesai.", 3)
end, 4)

-- ── DEFAULT PAGE ─────────────────────────────────────────────────────────────
showPage("main")

-- ══════════════════════════════════════════════════════════════════════════════
-- LOGIC LOOPS
-- ══════════════════════════════════════════════════════════════════════════════

-- Noclip
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
local function hookInfJump(char)
    local h = char:WaitForChild("Humanoid")
    h.StateChanged:Connect(function(_, new)
        if G.NOA_INFJUMP and new == Enum.HumanoidStateType.Freefall then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(hookInfJump)
if getChar() then hookInfJump(getChar()) end

-- Anti AFK
task.spawn(function()
    local VU = game:GetService("VirtualUser")
    while G.NOA_RUNNING do
        task.wait(54)
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
                for _, h in ipairs(workspace:GetDescendants()) do
                    if h:IsA("Humanoid") and h.Parent ~= getChar() and h.Health > 0 then
                        local isP = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.Character == h.Parent then isP=true; break end
                        end
                        if not isP then
                            local nr = h.Parent:FindFirstChild("HumanoidRootPart")
                            if nr and (root.Position - nr.Position).Magnitude < 55 then
                                h.Health = 0
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ── EGG FILTER ───────────────────────────────────────────────────────────────
local function isEggAllowed(eggObj)
    local name = eggObj.Name
    -- Egg Checker mode: cek selected list
    if G.NOA_EGGCHECK then
        local anySelected = false
        for _, on in pairs(G.NOA_SELECTED_EGGS) do
            if on then anySelected = true; break end
        end
        if anySelected then
            return G.NOA_SELECTED_EGGS[name] == true
        end
    end
    -- Predictor mode: hanya Secret ke atas
    if G.NOA_EGGPREDICT then
        local lower = name:lower()
        local data = getEggData(name)
        if data then
            return data.tier >= 8  -- Secret, Eternal, Divine
        end
        -- fallback nama
        return lower:find("secret") or lower:find("eternal") or lower:find("divine")
    end
    return true
end

-- ── STEAL METHODS ─────────────────────────────────────────────────────────────
local function findBestEgg(root)
    local bestEgg, bestDist, bestTier = nil, math.huge, -1
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local lower = obj.Name:lower()
            if lower:find("egg") then
                if isEggAllowed(obj) then
                    local d = (root.Position - obj.Position).Magnitude
                    local data = getEggData(obj.Name)
                    local tier = data and data.tier or 0
                    -- prioritas: tier lebih tinggi, atau kalau sama tier ambil yang lebih dekat
                    if tier > bestTier or (tier == bestTier and d < bestDist) then
                        bestEgg = obj; bestDist = d; bestTier = tier
                    end
                end
            end
        end
    end
    return bestEgg, bestDist
end

local function stealZigZag(root, target)
    for i = 1, 8 do
        if not G.NOA_AUTOSTEAL then return end
        local dir  = (target.Position - root.Position).Unit
        local side = (i % 2 == 0) and 1 or -1
        root.CFrame = CFrame.new(root.Position + dir * 4 + Vector3.new(side * 5, 0, 0))
        antibanWait(0.07)
    end
    smoothTeleport(root, CFrame.new(target.Position + Vector3.new(0, 3, 0)), 4)
end

local function stealTween(root, target)
    smoothTeleport(root, CFrame.new(target.Position + Vector3.new(0, 3, 0)), 6)
end

local function stealInstant(_root, _target) end  -- handled in outer loop via safe zone

local function stealFly(root, target)
    local h = getHuman()
    if not h then return end
    local BV = Instance.new("BodyVelocity", root)
    BV.Velocity = Vector3.new(0, 35, 0)
    BV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    BV.P = 1e4
    antibanWait(0.25)
    local dir = (target.Position - root.Position).Unit
    BV.Velocity = dir * G.NOA_STEALSPEED
    antibanWait(0.4)
    BV:Destroy()
    smoothTeleport(root, CFrame.new(target.Position + Vector3.new(0, 5, 0)), 4)
end

-- ── AUTO STEAL LOOP ──────────────────────────────────────────────────────────
task.spawn(function()
    while G.NOA_RUNNING do
        antibanWait(0.5)
        if G.NOA_AUTOSTEAL then
            local root = getRoot()
            if root then
                local h = getHuman()
                if h then h.WalkSpeed = G.NOA_STEALSPEED end

                local egg, dist = findBestEgg(root)
                if egg and dist > 4 then

                    -- Info notif
                    if G.NOA_EGGCHECK then
                        local data = getEggData(egg.Name)
                        local rarityStr = data and data.rarity or "?"
                        notify("Egg Checker", egg.Name.." ["..rarityStr.."]", 2)
                    end

                    local m = G.NOA_STEALMETHOD
                    if m == "zigzag" then stealZigZag(root, egg)
                    elseif m == "tween" then stealTween(root, egg)
                    elseif m == "fly"   then stealFly(root, egg)
                    else
                        -- instant: parkir di safe zone, fire PP
                        local sz = workspace:FindFirstChild("SafeZone") or workspace:FindFirstChild("Shop")
                        if sz and sz:IsA("BasePart") then
                            root.CFrame = CFrame.new(sz.Position + Vector3.new(0, 5, 0))
                        end
                    end

                    antibanWait(0.15)
                    -- Fire ProximityPrompt egg
                    for _, pp in ipairs(workspace:GetDescendants()) do
                        if pp:IsA("ProximityPrompt") then
                            local ppP = pp.Parent
                            if ppP and ppP:IsA("BasePart") and ppP.Name:lower():find("egg") then
                                if (root.Position - ppP.Position).Magnitude < 18 then
                                    fireproximityprompt(pp)
                                end
                            end
                        end
                    end

                    -- Auto Drop
                    if G.NOA_AUTODROP then
                        antibanWait(0.3)
                        local base = workspace:FindFirstChild("Bases") or workspace:FindFirstChild("Base")
                        if base then
                            local pb = base:FindFirstChild(LocalPlayer.Name)
                            if pb then
                                local pen = pb:FindFirstChild("Pen") or pb:FindFirstChild("PenArea") or pb:FindFirstChild("Hatch")
                                if pen and pen:IsA("BasePart") then
                                    smoothTeleport(root, CFrame.new(pen.Position + Vector3.new(0, 5, 0)), 5)
                                    antibanWait(0.25)
                                    for _, pp in ipairs(workspace:GetDescendants()) do
                                        if pp:IsA("ProximityPrompt") then
                                            local ppP = pp.Parent
                                            if ppP and ppP:IsA("BasePart") and (root.Position - ppP.Position).Magnitude < 14 then
                                                fireproximityprompt(pp)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- Auto Treadmill
                    if G.NOA_AUTOTREAD then
                        antibanWait(0.25)
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj.Name:lower():find("treadmill") and obj:IsA("BasePart") then
                                smoothTeleport(root, CFrame.new(obj.Position + Vector3.new(0, 3, 0)), 5)
                                antibanWait(0.2)
                                for _, pp in ipairs(obj.Parent:GetDescendants()) do
                                    if pp:IsA("ProximityPrompt") then
                                        fireproximityprompt(pp); break
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ── ESP ──────────────────────────────────────────────────────────────────────
local eggHL, guardHL, plrHL = {}, {}, {}
local function clearHL(t)
    for _, h in ipairs(t) do pcall(function() h:Destroy() end) end
    table.clear(t)
end
local function addHL(obj, fill, outline)
    local h = Instance.new("Highlight")
    h.FillColor = fill; h.OutlineColor = outline
    h.FillTransparency = 0.45; h.Parent = obj
    return h
end

task.spawn(function()
    while G.NOA_RUNNING do
        task.wait(2.2)
        clearHL(eggHL); clearHL(guardHL); clearHL(plrHL)

        if G.NOA_EGGESP then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
                    local data = getEggData(obj.Name)
                    local col  = data and getRarityColor(data.rarity) or Color3.fromRGB(255, 215, 0)
                    table.insert(eggHL, addHL(obj, col, Color3.fromRGB(255, 255, 255)))
                end
            end
        end

        if G.NOA_GUARDESP then
            for _, h in ipairs(workspace:GetDescendants()) do
                if h:IsA("Humanoid") and h.Parent ~= getChar() then
                    local isP = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character == h.Parent then isP=true; break end
                    end
                    if not isP then
                        table.insert(guardHL, addHL(h.Parent, Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 120, 0)))
                    end
                end
            end
        end

        if G.NOA_PLAYERESP then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    table.insert(plrHL, addHL(p.Character, Color3.fromRGB(50, 120, 255), Color3.fromRGB(180, 210, 255)))
                end
            end
        end
    end
end)

-- ── DONE ─────────────────────────────────────────────────────────────────────
notify("✅ Noa Hub v3.0", "Script siap! Steal An Egg verified.", 5)
