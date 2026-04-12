-- Auto-Reinject on Teleport --
local queueteleport = nil
pcall(function() queueteleport = queue_on_teleport end)

local TeleportCheck = false
game.Players.LocalPlayer.OnTeleport:Connect(function(State)
    if not TeleportCheck and queueteleport then
        TeleportCheck = true
        queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/CptnCat/rbx/main/windgate.lua'))()")
    end
end)

-- HILFSFUNKTIONEN --

-- Wartet bis eine Instanz existiert (mit Timeout)
local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or 15
    local child = parent:FindFirstChild(childName)
    if child then return child end
    local start = tick()
    repeat
        task.wait(0.1)
        child = parent:FindFirstChild(childName)
    until child or (tick() - start >= timeout)
    if not child then
        warn("[WINDGATE] Timeout: '" .. childName .. "' wurde in '" .. parent.Name .. "' nicht gefunden.")
    end
    return child
end

-- Führt eine Funktion mit Retry aus
local function retry(fn, maxAttempts, delay, label)
    maxAttempts = maxAttempts or 10
    delay = delay or 1
    label = label or "Operation"
    for i = 1, maxAttempts do
        local ok, result = pcall(fn)
        if ok and result ~= nil then
            print("[WINDGATE] " .. label .. " erfolgreich (Versuch " .. i .. ")")
            return true, result
        end
        warn("[WINDGATE] " .. label .. " fehlgeschlagen (Versuch " .. i .. "/" .. maxAttempts .. "): " .. tostring(result))
        if i < maxAttempts then task.wait(delay) end
    end
    return false, nil
end

-- Wartet bis das Spiel vollständig geladen ist
local function waitForGameLoaded()
    if not game:IsLoaded() then
        print("[WINDGATE] Warte auf vollständiges Laden des Spiels...")
        game.Loaded:Wait()
    end
    -- Zusätzlich auf wichtige Services warten
    game:GetService("ReplicatedStorage")
    game:GetService("Players")
    print("[WINDGATE] Spiel vollständig geladen ✓")
end

-- HAUPTLOGIK --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game.Players.LocalPlayer

print("[WINDGATE DEBUG] Script gestartet")

-- Spiel muss geladen sein
waitForGameLoaded()

-- Sicherstellen dass LocalPlayer vorhanden ist
if not LocalPlayer then
    warn("[WINDGATE] LocalPlayer nicht verfügbar. Script wird beendet.")
    return
end

-- Warte auf Character falls noch nicht gespawnt
if not LocalPlayer.Character then
    print("[WINDGATE] Warte auf Character...")
    LocalPlayer.CharacterAdded:Wait()
end

-- WorldInfoHandler_Client sicher laden (mit Timeout je Schritt)
print("[WINDGATE DEBUG] Lade WorldInfoHandler_Client Pfad...")

local ClientPackage   = safeWaitForChild(ReplicatedStorage, "ClientPackage", 20)
if not ClientPackage then
    warn("[WINDGATE] ClientPackage nicht gefunden. Script wird beendet.")
    return
end

local GameUtility     = safeWaitForChild(ClientPackage, "GameUtility", 15)
if not GameUtility then
    warn("[WINDGATE] GameUtility nicht gefunden. Script wird beendet.")
    return
end

local WorldUtil       = safeWaitForChild(GameUtility, "WorldUtil", 15)
if not WorldUtil then
    warn("[WINDGATE] WorldUtil nicht gefunden. Script wird beendet.")
    return
end

local WorldInfoHandler = safeWaitForChild(WorldUtil, "WorldInfoHandler", 15)
if not WorldInfoHandler then
    warn("[WINDGATE] WorldInfoHandler nicht gefunden. Script wird beendet.")
    return
end

local WorldInfoHandler_Client = safeWaitForChild(WorldInfoHandler, "WorldInfoHandler_Client", 15)
if not WorldInfoHandler_Client then
    warn("[WINDGATE] WorldInfoHandler_Client nicht gefunden. Script wird beendet.")
    return
end

print("[WINDGATE DEBUG] Referenz erhalten: " .. tostring(WorldInfoHandler_Client))

-- require() mit Retry
local ok, WorldInfo = retry(
    function() return require(WorldInfoHandler_Client) end,
    10, 1, "require(WorldInfoHandler_Client)"
)

if not ok or not WorldInfo then
    warn("[WINDGATE] WorldInfo konnte nicht geladen werden. Script wird beendet.")
    return
end

-- GetClientWorldInfo() aufrufen
print("[WINDGATE DEBUG] Rufe GetClientWorldInfo() auf...")
local ok2, result = retry(
    function()
        local r = WorldInfo.GetClientWorldInfo()
        -- Sicherstellen dass das Ergebnis sinnvolle Daten enthält
        assert(r and r.Cell and r.WorldStatic, "Unvollständige WorldInfo")
        return r
    end,
    5, 1, "GetClientWorldInfo()"
)

if not ok2 or not result then
    warn("[WINDGATE] GetClientWorldInfo() lieferte keine gültigen Daten. Script wird beendet.")
    return
end

print("[WINDGATE DEBUG] GetClientWorldInfo() erfolgreich ✓")

-- Zellname-Tabelle
local CELL_NAMES = {
    ["1,1,1"] = "NNWW", ["2,1,1"] = "NNW",  ["3,1,1"] = "NN",     ["4,1,1"] = "NNE",  ["5,1,1"] = "NNEE",
    ["1,2,1"] = "NWW",  ["2,2,1"] = "NW",   ["3,2,1"] = "N",      ["4,2,1"] = "NE",   ["5,2,1"] = "NEE",
    ["1,3,1"] = "WW",   ["2,3,1"] = "W",    ["3,3,1"] = "Center", ["4,3,1"] = "E",    ["5,3,1"] = "EE",
    ["1,4,1"] = "SWW",  ["2,4,1"] = "SW",   ["3,4,1"] = "S",      ["4,4,1"] = "SE",   ["5,4,1"] = "SEE",
    ["1,5,1"] = "SSWW", ["2,5,1"] = "SSW",  ["3,5,1"] = "SS",     ["4,5,1"] = "SSE",  ["5,5,1"] = "SSEE",
}

-- Werte sicher auslesen (mit Fallbacks)
local cellLocation  = (result.Cell and result.Cell.CellLocation) or "?"
local worldVersion  = (result.WorldStatic and result.WorldStatic.Version) or "?"
local worldId       = (result.WorldStatic and result.WorldStatic.Id) or "?"
local worldDisplay  = tostring(worldVersion) .. "." .. tostring(worldId)

local cellKey       = tostring(cellLocation):gsub("[{}%s]", "")
local cellDisplay   = CELL_NAMES[cellKey] or tostring(cellLocation)

print("[WINDGATE] World: " .. worldDisplay .. " | Cell: " .. cellDisplay)

-- WindUI sicher laden
print("[WINDGATE DEBUG] Lade WindUI...")
local WindUI
local ok3, err3 = pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not ok3 or not WindUI then
    warn("[WINDGATE] WindUI konnte nicht geladen werden: " .. tostring(err3))
    return
end
print("[WINDGATE DEBUG] WindUI geladen ✓")

-- Window erstellen
local Window
local ok4, err4 = pcall(function()
    Window = WindUI:CreateWindow({
        Title = "WINDGATE",
        Icon = "ship",
        Author = "made in peace",
        Folder = "MySuperHub",
        Size = UDim2.fromOffset(780, 500),
        MinSize = Vector2.new(560, 350),
        MaxSize = Vector2.new(850, 560),
        ToggleKey = Enum.KeyCode.K,
        Transparent = true,
        Theme = "Dark",
        Resizable = true,
        SideBarWidth = 200,
        BackgroundImageTransparency = 0.42,
        HideSearchBar = true,
        ScrollBarEnabled = false,
        User = {
            Enabled = false,
            Anonymous = true,
            Callback = function() end,
        },
    })
end)

if not ok4 or not Window then
    warn("[WINDGATE] Window konnte nicht erstellt werden: " .. tostring(err4))
    return
end
print("[WINDGATE DEBUG] Window erstellt ✓")

-- Tags setzen
pcall(function()
    Window:Tag({ Title = "World: " .. worldDisplay, Icon = "earth",     Color = Color3.fromHex("#30ff6a"), Radius = 7 })
    Window:Tag({ Title = "Cell: "  .. cellDisplay,  Icon = "columns-4", Color = Color3.fromHex("#fcff30"), Radius = 7 })
end)

-- Tabs erstellen
local PlayerTab, WorldTab

pcall(function()
    PlayerTab = Window:Tab({ Title = "Player", Icon = "user", Locked = true })
end)

pcall(function()
    WorldTab = Window:Tab({ Title = "World", Icon = "sun", Locked = false })
end)

-- Slider nur erstellen wenn WorldTab existiert
if WorldTab then
    pcall(function()
        WorldTab:Slider({
            Title = "Time Offsetter",
            Desc = "Change the time locally",
            Step = 0.01,
            Value = { Min = 0, Max = 1, Default = 0 },
            Callback = function(value)
                -- DayTimeOffset nur setzen wenn es existiert
                local offset = ReplicatedStorage:FindFirstChild("DayTimeOffset")
                if offset then
                    offset.Value = value
                else
                    warn("[WINDGATE] DayTimeOffset nicht gefunden.")
                end
            end
        })
    end)
else
    warn("[WINDGATE] WorldTab nicht verfügbar, Slider wird übersprungen.")
end

print("[WINDGATE DEBUG] Script vollständig geladen ✓")