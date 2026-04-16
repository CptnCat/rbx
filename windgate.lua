local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game.Players.LocalPlayer

-- Wait until the client has surely been loaded
local rootPart
local i = 0

while not rootPart do
    i = i + 1
    task.wait(0.5)
    rootPart = LocalPlayer.Character and LocalPlayer.Character.Parent and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

print("[WINDGATE] Client bereit – starte Script...")

-- WorldInfo mit Retry laden
local WorldInfoHandler_Client = ReplicatedStorage
    :WaitForChild("ClientPackage")
    :WaitForChild("GameUtility")
    :WaitForChild("WorldUtil")
    :WaitForChild("WorldInfoHandler")
    :WaitForChild("WorldInfoHandler_Client")
print("[WINDGATE DEBUG] Referenz erhalten: " .. tostring(WorldInfoHandler_Client))

print("[WINDGATE DEBUG] Rufe GetClientWorldInfo() auf...")
local ok, result = pcall(function()
    return WorldInfoHandler_Client.GetClientWorldInfo()
end)

if not ok then
    warn("[WINDGATE] GetClientWorldInfo() Error: " .. tostring(result))
    return
end

local CELL_NAMES = {
    ["1,1,1"] = "NNWW",
    ["2,1,1"] = "NNW",
    ["3,1,1"] = "NN",
    ["4,1,1"] = "NNE",
    ["5,1,1"] = "NNEE",
    ["1,2,1"] = "NWW",
    ["2,2,1"] = "NW",
    ["3,2,1"] = "N",
    ["4,2,1"] = "NE",
    ["5,2,1"] = "NEE",
    ["1,3,1"] = "WW",
    ["2,3,1"] = "W",
    ["3,3,1"] = "Center",
    ["4,3,1"] = "E",
    ["5,3,1"] = "EE",
    ["1,4,1"] = "SWW",
    ["2,4,1"] = "SW",
    ["3,4,1"] = "S",
    ["4,4,1"] = "SE",
    ["5,4,1"] = "SEE",
    ["1,5,1"] = "SSWW",
    ["2,5,1"] = "SSW",
    ["3,5,1"] = "SS",
    ["4,5,1"] = "SSE",
    ["5,5,1"] = "SSEE",
}

local cellLocation = result.Cell and result.Cell.CellLocation or "?"
local worldVersion = result.WorldStatic and result.WorldStatic.Version or "?"
local worldId = result.WorldStatic and result.WorldStatic.Id or "?"
local worldDisplay = tostring(worldVersion) .. "." .. tostring(worldId)

local cellKey = tostring(cellLocation):gsub("[{}%s]", ""):gsub(",", ",")
local cellDisplay = CELL_NAMES[cellKey] or tostring(cellLocation)

print("[WINDGATE] World: " .. worldDisplay .. " | Cell: " .. cellDisplay)

-- GENERAL UI --
print("[WINDGATE DEBUG] Lade WindUI...")
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
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

Window:Tag({
    Title = "World: " .. worldDisplay,
    Icon = "earth",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 7,
})
Window:Tag({
    Title = "Cell: " .. cellDisplay,
    Icon = "columns-4",
    Color = Color3.fromHex("#fcff30"),
    Radius = 7,
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
    Locked = true,
})

local WorldTab = Window:Tab({
    Title = "World",
    Icon = "sun",
    Locked = false,
})

local Slider = WorldTab:Slider({
    Title = "Time Offsetter",
    Desc = "Change the time locally",
    Step = 0.01,
    Value = {
        Min = 0,
        Max = 1,
        Default = 0,
    },
    Callback = function(value)
        print("[WINDGATE DEBUG] Time Slider geändert: " .. tostring(value))
        game.ReplicatedStorage.DayTimeOffset.Value = value
    end
})