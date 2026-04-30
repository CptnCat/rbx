-- AUTO-RERUN AFTER TELEPORT --
local queueteleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

local TeleportCheck = false
Players.LocalPlayer.OnTeleport:Connect(function(State)
	if (not TeleportCheck) and queueteleport then
		TeleportCheck = true
		queueteleport(game:HttpGet("https://raw.githubusercontent.com/CptnCat/rbx/main/windgate.lua"))
	end
end)
-- END OF AUTO-RERUN --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = game.Players.LocalPlayer
local Objects = workspace:WaitForChild("Objects")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- WAIT UNTIL WINDGATE PLAYER IS READY --
local rootPart
local i = 0

while not rootPart do
    i = i + 1
    task.wait(0.5)
    rootPart = LocalPlayer.Character and LocalPlayer.Character.Parent and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- CLIENT READY --
print("[WINDGATE] Client bereit – starte Script...")
-- --

-- CONFIGURATION --
if not isfolder("WindGate_Menu") then
    makefolder("WindGate_Menu")
end

local SETTINGS_FILE = "WindGate/Settings.json"

local function loadSettings()
    if isfile(SETTINGS_FILE) then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(SETTINGS_FILE))
        end)
        if ok and data then return data end
    end
    return {}
end

local function saveSetting(key, value)
    local settings = loadSettings()
    settings[key] = value
    writefile(SETTINGS_FILE, game:GetService("HttpService"):JSONEncode(settings))
end

local settings = loadSettings()
-- END OF CONFIGURATION --

-- GET WINDGATE FRAMEWORK --
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
-- END OF WINDGATE FRAMEWORK -- 

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
local HttpService = game:GetService("HttpService")

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
-- Window:Tag({
--     Title = "Xh, Xm",
--     Icon = "moon",
--     Color = Color3.fromHex("#ff3030"),
--     Radius = 9,
-- })

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
    Locked = false,
})

-- CLICK TELEPORT --
local mouse = LocalPlayer:GetMouse()
local cooldown = false
local TPconnection = nil

local function ClickTeleport()
    TPconnection = mouse.Button1Down:Connect(function()
        if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or cooldown then return end

        local hitPos = mouse.Hit.Position
        if (hitPos - root.Position).Magnitude > 1000 then return end

        cooldown = true

        local tween = TweenService:Create(root,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            { CFrame = CFrame.new(hitPos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, root.CFrame.Y, 0) }
        )
        tween:Play()
        tween.Completed:Connect(function()
            cooldown = false
        end)
    end)
end

if settings["SafeClickTeleport"] then
    ClickTeleport()
end

PlayerTab:Toggle({
    Title = "Safe Click Teleport",
    Desc = "CTRL + Mouseclick",
    Type = "Toggle",
    Value = settings["SafeClickTeleport"] or false,
    Callback = function(state)
        saveSetting("SafeClickTeleport", state)

        if state then
            ClickTeleport()
        else
            if TPconnection then
                TPconnection:Disconnect()
                TPconnection = nil
            end
        end
    end
})

Window:OnDestroy(function()
    if TPconnection then
        TPconnection:Disconnect()
        TPconnection = nil
    end
end)
-- END OF CLICK TELEPORT --

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

-- SCAN World Objects
local function runCameraScanner(callback)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local planeSettings = ok and result
        and result.WorldStatic
        and result.WorldStatic.WorldSettings
        and result.WorldStatic.WorldSettings.PlaneSettings

    local cellSize = planeSettings and planeSettings[1] and planeSettings[1].CellSize
    local CELL_X = cellSize and cellSize.X or 8192
    local CELL_Z = cellSize and cellSize.Z or 8192

    print(string.format("[Scanner] CellSize: X=%.0f Z=%.0f", CELL_X, CELL_Z))

    local SCAN_HEIGHT = 90
    local STEP_SIZE = 400

    local originalCameraType = camera.CameraType
    local originalCFrame = camera.CFrame

    camera.CameraType = Enum.CameraType.Scriptable

    local points = {}
    local stepsX = math.ceil(CELL_X / STEP_SIZE)
    local stepsZ = math.ceil(CELL_Z / STEP_SIZE)

    for xi = 0, stepsX - 1 do
        for zi = 0, stepsZ - 1 do
            table.insert(points, Vector3.new(
                -CELL_X / 2 + xi * STEP_SIZE + STEP_SIZE / 2,
                0,
                -CELL_Z / 2 + zi * STEP_SIZE + STEP_SIZE / 2
            ))
        end
    end

    print(string.format("[Scanner] %d Punkte", #points))

    for idx, point in ipairs(points) do
        camera.CFrame = CFrame.new(point.X, SCAN_HEIGHT, point.Z)

        -- In eigenem Thread spawnen damit es den Scanner nicht blockiert
        task.spawn(function()
            pcall(function()
                player:RequestStreamAroundAsync(point)
            end)
        end)

        print(string.format("[Scanner] %d/%d", idx, #points))
        task.wait(0.065)
    end

    camera.CameraType = originalCameraType
    camera.CFrame = originalCFrame
    print("[Scanner] Fertig.")

    if callback then
        callback()
    end
end

-- Mesh ID -> Hat Name Lookup
local MESH_NAMES = {
    -- EVENT
    ["29713272"] = "AmericanCowboy",
    ["5423237797"] = "PumpkinHead",
    ["18464516"] = "Turkey",
    ["5423237767"] = "Cake",
    ["5423237781"] = "SantaHat",
    ["402220572"] = "FoolHat",

    ["140451612"] = "NewYearsHat",
    ["6167779428"] = "NewYearsGlasses1",
    ["8101317363"] = "NewYearsGlasses2",
    ["11957028822"] = "NewYearsGlasses3",
    ["15811786362"] = "NewYearsGlasses4",
    -- ["X"] = "NewYearsGlasses5",
    -- ["X"] = "NewYearsGlasses6",

    -- UNOBTAINABLE
    ["93050267"] = "Namdama1",
    ["74969506"] = "Eyepatch1",
    ["81700098"] = "InventorGoggles",
    ["39198836"] = "InspectorGoggles",
    ["22053998"] = "RoundGlasses",
    ["29809807"] = "Monocle",
    ["3833719719"] = "SkullMask",
    ["6565217371"] = "DeerSkull",
    ["26937865"] = "SteamHat",
    ["5423237813"] = "Wreath",
    ["1241066615"] = "BallNose",
    ["107574947"] = "GreenCap",
    ["112614545"] = "VacationHat",
    ["108923810"] = "BucketHat",
    ["5423237764"] = "Cone",
    ["13157704"] = "SpikedHelm",
    ["38114318"] = "FishieHat",
    ["10684744"] = "PropellerBeanie",
    ["107551400"] = "FruitHat",
    ["5423237786"] = "Scoobis",
    ["26768567"] = "LadysPicnicHat",
    ["255580072"] = "YarnDonut",
    ["4556265726"] = "HeadFrog",
    ["335129529"] = "FlatCap",
    ["125752899"] = "Investigator",
    ["5423237765"] = "StoneTopHat",
    ["5423237765"] = "MetalTopHat",
    ["5423237765"] = "WoodTopHat",
    ["13827689"] = "Alien1",
    ["3744844343"] = "WizardHat",
    ["163537933 "] = "Tophat",
    ["13642205"] = "PorkiePie",
    ["1051560"] = "PicnicHat",
    ["101094974"] = "FancyTophat",
    ["31740452"] = "Durag",
    ["24102243"] = "Socialite",
    ["1028848"] = "PirateHat",

    -- FRUIT (UNOBTAINABLE) - TESTING REQUIRED!!
    ["5423237725"] = "Molen",
    ["447115748"] = "Perrep",
    ["5423237716"] = "Corrat",
    ["5423237726"] = "Penaeppla",
    ["5952993683"] = "Luttece",
    ["6250815948"] = "Penut",

    -- DICS (UNOBTAINABLE) - TESTING REQUIRED!!
    ["6458705381"] = "RecordSpookyScarySkeletons",
}

local BLACKLISTED_MESH = {
    9419831, -- Duck
    3684587340, -- CandleHat
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

local function isBlacklisted(meshId)
    for _, blist in pairs(BLACKLISTED_MESH) do
        if tonumber(meshId) == tonumber(blist) then
            return true
        end
    end
    return false
end

local ObjectButtons = {}

ObjectsTab:Dropdown({
    Title = "List Objects from Workspace",
    Values = {
        {
            Title = "Load all Objects",
            Icon = "refresh-ccw",
            Callback = function()
                runCameraScanner()
            end
        },
        {
            Title = "List RARES",
            Icon = "hat-glasses",
            Callback = function()
                for _, btn in pairs(ObjectButtons) do
                    btn.ElementFrame:Destroy()
                end
                table.clear(ObjectButtons)

                local rares = {}

                for _, obj in pairs(Objects:GetDescendants()) do
                    local isFruit = false

                    if obj:IsA("Attachment") and obj.Name == "Interact_Grab" then
                        local part = obj.Parent
                        local model = part and part.Parent

                        if model then
                            -- Disc check
                            local labelUnion = model:FindFirstChild("Label")
                            if labelUnion and labelUnion:IsA("UnionOperation") then
                                local decal = labelUnion:FindFirstChildWhichIsA("Decal")
                                if decal then
                                    local meshId = decal.Texture:match("%d+")
                                    if meshId and MESH_NAMES[meshId] and not isBlacklisted(meshId) then
                                        local syncOwner = part:GetAttribute("SYNCOwner")
                                        local ownerName = "Unknown"
                                        if syncOwner then
                                            local ok, name = pcall(function()
                                                return Players:GetNameFromUserIdAsync(syncOwner)
                                            end)
                                            ownerName = ok and name or ("ID: " .. tostring(syncOwner))
                                        end
                                        table.insert(rares, {
                                            displayName = MESH_NAMES[meshId],
                                            ownerName = ownerName,
                                            rarePart = model,
                                            priority = 1
                                        })
                                    end
                                end
                            end

                            -- Fruit check
                            local meshId = getMeshId(part)
                            if meshId and MESH_NAMES[meshId] and not isBlacklisted(meshId) then
                                local syncOwner = part:GetAttribute("SYNCOwner")
                                local ownerName = "Unknown"
                                if syncOwner then
                                    local ok, name = pcall(function()
                                        return Players:GetNameFromUserIdAsync(syncOwner)
                                    end)
                                    ownerName = ok and name or ("ID: " .. tostring(syncOwner))
                                end
                                table.insert(rares, {
                                    displayName = MESH_NAMES[meshId],
                                    ownerName = ownerName,
                                    rarePart = part,
                                    priority = 1
                                })
                            end
                        end
                    end

                    if obj:IsA("Attachment") and (obj.Name == "HatAttachment" or obj.Name == "FaceFrontAttachment" or obj.Name == "NeckAttachment") then
                        local rarePart = obj.Parent
                        if rarePart then
                            local meshId = getMeshId(rarePart)
                            local hatName = meshId and MESH_NAMES[meshId] or nil
                            local displayName = hatName or (meshId and ("ID: " .. meshId))

                            local syncOwner = rarePart:GetAttribute("SYNCOwner")
                            local ownerName = "Unknown"
                            if syncOwner then
                                local ok, name = pcall(function()
                                    return Players:GetNameFromUserIdAsync(syncOwner)
                                end)
                                ownerName = ok and name or ("ID: " .. tostring(syncOwner))
                            end

                            local priority = hatName and 1 or (meshId and 2 or 3)

                            if displayName and not isBlacklisted(meshId) then
                                table.insert(rares, {
                                    displayName = displayName,
                                    ownerName = ownerName,
                                    rarePart = rarePart,
                                    priority = priority
                                })
                            end
                        end
                    end
                end

                table.sort(rares, function(a, b)
                    return a.priority < b.priority
                end)

                local divider = ObjectsTab:Divider()
                table.insert(ObjectButtons, divider)

                for _, hat in pairs(rares) do
                    local btn
                    btn = ObjectsTab:Button({
                        Title = hat.displayName,
                        Desc = "Owner: " .. hat.ownerName,
                        IconAlign = "Left",
                        Icon = "mouse-pointer-click",
                        Callback = function()
                            character = LocalPlayer.Character
                            rootPart = character and character:FindFirstChild("HumanoidRootPart")
                            if rootPart and hat.rarePart then
                                rootPart.CFrame = CFrame.new(hat.rarePart.Position + Vector3.new(0, 5, 0))
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
        {
            Title = "Check Metite",
            Icon = "stone",
            Callback = function()
                for _, btn in pairs(ObjectButtons) do
                    btn.ElementFrame:Destroy()
                end
                table.clear(ObjectButtons)

                local stones = {}

                for _, obj in pairs(Objects:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name == "Main" then
                        local brickColor = obj.BrickColor
                        local material = obj.Material

                        if material == Enum.Material.Granite and tostring(brickColor) == "Cyan" then
                            table.insert(stones, {
                                part = obj,
                            })
                        end
                    end
                end

                local divider = ObjectsTab:Divider()
                table.insert(ObjectButtons, divider)

                for _, stone in pairs(stones) do
                    local btn
                    btn = ObjectsTab:Button({
                        Title = 'Metite',
                        Desc = "Click to teleport to object",
                        IconAlign = "Left",
                        Icon = "mouse-pointer-click",
                        Callback = function()
                            character = LocalPlayer.Character
                            rootPart = character and character:FindFirstChild("HumanoidRootPart")
                            if rootPart and stone.part then
                                rootPart.CFrame = CFrame.new(stone.part.Position + Vector3.new(0, 5, 0))
                            end
                        end
                    })
                    table.insert(ObjectButtons, btn)
                end
            end
        },
    }
})