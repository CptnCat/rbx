local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game.Players.LocalPlayer
local Players = game:GetService("Players")
local Objects = workspace:WaitForChild("Objects")

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

local WorldInfo = require(WorldInfoHandler_Client)

if not WorldInfo then
    warn("[WINDGATE] WorldInfo konnte nach 10 Versuchen nicht geladen werden. Script wird beendet.")
    return
end

print("[WINDGATE DEBUG] Rufe GetClientWorldInfo() auf...")
local ok, result = pcall(function()
    return WorldInfo.GetClientWorldInfo()
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
    Title = worldDisplay,
    Icon = "earth",
    Color = Color3.fromHex("#24a348"),
    Radius = 9,
})
Window:Tag({
    Title = cellDisplay,
    Icon = "columns-4",
    Color = Color3.fromHex("#30e7ff"),
    Radius = 9,
})
Window:Tag({
    Title = "Xh, Xm",
    Icon = "moon",
    Color = Color3.fromHex("#ff3030"),
    Radius = 9,
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
    Locked = false,
})

Window:Divider()

local WorldTab = Window:Tab({
    Title = "World",
    Icon = "sun",
    Locked = false,
})

local ObjectsTab = Window:Tab({
    Title = "Objects",
    Icon = "folder-git-2",
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

-- Mesh ID -> Hat Name Lookup
local MESH_NAMES = {
    ["29713272"] = "AmericanCowboy",
    ["1241066615"] = "BallNose",
    ["5423237764"] = "Cone",
    ["402220572"] = "FoolHat",
    ["107551400"] = "FruitHat",
    ["4556265726"] = "HeadFrog",

    ["6167779428"] = "NewYearsGlasses1",
    ["8101317363 "] = "NewYearsGlasses2",
    ["11957028822 "] = "NewYearsGlasses3",
    -- ["X "] = "NewYearsGlasses4",
    -- ["X "] = "NewYearsGlasses5",
    -- ["X "] = "NewYearsGlasses6",
    ["140451612"] = "NewYearsHat",

    ["1028848"] = "PirateHat",
    ["10684744"] = "PropellerBeanie",
    ["5423237797"] = "PumpkinHead",
    ["5423237786"] = "Scoobis",
    ["18464516"] = "Turkey",
    ["5423237767"] = "Cake",
    ["5423237781"] = "SantaHat",
    ["3744844343"] = "WizardHat",
}

local function getMeshId(part)
    -- SpecialMesh child
    local mesh = part:FindFirstChildOfClass("SpecialMesh")
    if mesh then
        local id = mesh.MeshId:match("%d+")
        if id then return id end
    end
    -- MeshPart direkt
    if part:IsA("MeshPart") then
        local id = part.MeshId:match("%d+")
        if id then return id end
    end
    return nil
end

local ObjectButtons = {}

ObjectsTab:Dropdown({
    Title = "List Objects from Workspace",
    Desc = "Click items to teleport",
    Values = {
        {
            Title = "List Hats",
            Icon = "hat-glasses",
            Callback = function()
                for _, btn in pairs(ObjectButtons) do
                    btn.ElementFrame:Destroy()
                end
                table.clear(ObjectButtons)

                local hats = {}

                for _, obj in pairs(Objects:GetDescendants()) do
                    if obj:IsA("Attachment") and (obj.Name == "HatAttachment" or obj.Name == "FaceFrontAttachment") then
                        local hatPart = obj.Parent

                        if hatPart then
                            local meshId = getMeshId(hatPart)
                            local hatName = meshId and MESH_NAMES[meshId] or nil
                            local displayName = hatName or (meshId and ("ID: " .. meshId))

                            local syncOwner = hatPart:GetAttribute("SYNCOwner")
                            local ownerName = "Unknown"

                            if syncOwner then
                                local ok, name = pcall(function()
                                    return Players:GetNameFromUserIdAsync(syncOwner)
                                end)
                                ownerName = ok and name or ("ID: " .. tostring(syncOwner))
                            end

                            local priority = hatName and 1 or (meshId and 2 or 3)


                            if displayName then
                                table.insert(hats, {
                                    displayName = displayName,
                                    ownerName = ownerName,
                                    hatPart = hatPart,
                                    priority = priority
                                })
                            end
                        end
                    end
                end

                table.sort(hats, function(a, b)
                    return a.priority < b.priority
                end)

                -- Divider vor dem ersten Button
                local divider = ObjectsTab:Divider()
                table.insert(ObjectButtons, divider)

                for _, hat in pairs(hats) do
                    local btn = ObjectsTab:Button({
                        Title = hat.displayName,
                        Desc = "Owner: " .. hat.ownerName,
                        IconAlign = "Left",
                        Icon = "mouse-pointer-click",
                        Callback = function()
                            character = LocalPlayer.Character
                            rootPart = character and character:FindFirstChild("HumanoidRootPart")
                            if rootPart and hat.hatPart then
                                rootPart.CFrame = CFrame.new(hat.hatPart.Position + Vector3.new(0, 5, 0))
                            end
                        end
                    })
                    table.insert(ObjectButtons, btn)
                end
            end
        },
        {
            Title = "List Unclaimed Properties",
            Icon = "circle-off",
            Callback = function()
                for _, btn in pairs(ObjectButtons) do
                    btn.ElementFrame:Destroy()
                end
                table.clear(ObjectButtons)

                local properties = {}

                for _, obj in pairs(Objects:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name == "Main" then
                        local syncActive = obj:GetAttribute("SYNCActive")

                        if syncActive ~= nil and syncActive == false then
                            table.insert(properties, {
                                active = syncActive,
                                part = obj,
                            })
                        end
                    end
                end

                -- Divider vor dem ersten Button
                local divider = ObjectsTab:Divider()
                table.insert(ObjectButtons, divider)

                for _, property in pairs(properties) do
                    local btn
                    btn = ObjectsTab:Button({
                        Title = 'Unclaimed Property',
                        IconAlign = "Left",
                        Icon = "mouse-pointer-click",
                        Callback = function()
                            character = LocalPlayer.Character
                            rootPart = character and character:FindFirstChild("HumanoidRootPart")
                            if rootPart and property.part then
                                rootPart.CFrame = CFrame.new(property.part.Position + Vector3.new(0, 5, 0))

                                task.defer(function()
                                    if btn.ElementFrame then
                                        btn.ElementFrame.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
                                        btn.ElementFrame.BackgroundTransparency = 0
                                    end
                                end)
                            end
                        end
                    })
                    table.insert(ObjectButtons, btn)
                end
            end
        },
    }
})