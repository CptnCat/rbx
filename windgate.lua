if getgenv().WINDGATE_LOADED then return end
getgenv().WINDGATE_LOADED = true

local queueteleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Objects = workspace:WaitForChild("Objects")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

repeat task.wait() until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

local TeleportConnection
local TeleportCheck = false
TeleportConnection = LocalPlayer.OnTeleport:Connect(function()
    if not TeleportCheck and queueteleport then
        TeleportCheck = true
        TeleportConnection:Disconnect()
        queueteleport(game:HttpGet("https://raw.githubusercontent.com/CptnCat/rbx/main/windgate.lua"))
    end
end)

-- WAIT UNTIL WINDGATE PLAYER IS READY --
local rootPart
repeat
    task.wait(0.5)
    local char = LocalPlayer.Character
    rootPart = char and char:FindFirstChild("HumanoidRootPart")
until rootPart

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
Window:Close()

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

-- BLOODMOON --
local LUNAR = 90000
local BLOOD_CYCLE = 2340000

local function formatBloodMoon()
    local serverTime = workspace:GetServerTimeNow()
    local bloodPhase = serverTime % BLOOD_CYCLE
    local timeToBloodMoon = BLOOD_CYCLE - bloodPhase
    local lunarPhase = serverTime % LUNAR / LUNAR
    local isFullMoon = math.abs(lunarPhase - 0.5) < 0.008333
    local isBloodMoon = (serverTime % BLOOD_CYCLE / LUNAR < 1) and isFullMoon

    if isBloodMoon then
        return "NOW"
    end

    local days = math.floor(timeToBloodMoon / 86400)
    local hours = math.floor(timeToBloodMoon % 86400 / 3600)
    local minutes = math.floor(timeToBloodMoon % 3600 / 60)
    return string.format("%dd %dh %dm", days, hours, minutes)
end

local bloodMoonTag = Window:Tag({
    Title = formatBloodMoon(),
    Icon = "moon",
    Color = Color3.fromHex("#ff3030"),
    Radius = 9,
})

task.spawn(function()
    while task.wait(60) do
        if bloodMoonTag and bloodMoonTag.ElementFrame and bloodMoonTag.ElementFrame.Parent then
            print("refreshed BLOOD")
            bloodMoonTag.ElementFrame:Destroy()
            bloodMoonTag = Window:Tag({
                Title = formatBloodMoon(),
                Icon = "moon",
                Color = Color3.fromHex("#ff3030"),
                Radius = 9,
            })
        end
    end
end)
-- END BLOODMOON TIMER --

local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "user",
    Locked = false,
})

-- CLICK TELEPORT --
local mouse = LocalPlayer:GetMouse()
local cooldown = false
local TPconnection = nil

local function getPlayerVehicle(root)
    for _, part in pairs(root:GetConnectedParts(true)) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= root.Parent and model:IsDescendantOf(workspace.Objects) then
            local isPropelled = model:FindFirstChild("PropellerForce", true)
                             or model:FindFirstChildOfClass("VectorForce")
                             or model:FindFirstChild("Rudder", true)
                             or model:FindFirstChild("Mast", true)
            if isPropelled then
                local topModel = model
                while topModel.Parent ~= workspace.Objects do
                    topModel = topModel.Parent
                    if not topModel or not topModel:IsA("Model") then
                        topModel = model
                        break
                    end
                end
                return topModel
            end
        end
    end
    return nil
end

local function ClickTeleport()
    TPconnection = mouse.Button1Down:Connect(function()
        if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or cooldown then return end
        local hitPos = mouse.Hit.Position
        if (hitPos - root.Position).Magnitude > 1500 then return end
        cooldown = true

        -- Kamera-Blickrichtung (nur Y-Achse) für Spieler und Boot
        local camLookVector = workspace.CurrentCamera.CFrame.LookVector
        local yaw = math.atan2(-camLookVector.X, -camLookVector.Z)

        local vehicle = getPlayerVehicle(root)

        if vehicle and vehicle.PrimaryPart then
            local vehicleRoot = vehicle.PrimaryPart

            -- Boot schaut in Kamera-Richtung + 90° Korrektur
            local destination = CFrame.new(hitPos + Vector3.new(0, 3, 0))
                            * CFrame.Angles(0, yaw + math.rad(90), 0)

            local parts = {}
            local offsets = {}
            for _, part in pairs(vehicle:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    table.insert(parts, part)
                    table.insert(offsets, vehicleRoot.CFrame:ToObjectSpace(part.CFrame))
                end
            end

            local tweenCount = 0
            for idx, part in pairs(parts) do
                TweenService:Create(part,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    { CFrame = destination * offsets[idx] }
                ):Play()
                task.delay(0.3, function()
                    tweenCount += 1
                    if tweenCount >= #parts then
                        cooldown = false
                    end
                end)
            end
        else
            -- Kein Boot — Spieler schaut in Kamera-Richtung
            local destination = CFrame.new(hitPos + Vector3.new(0, 3, 0))
                              * CFrame.Angles(0, yaw, 0)

            TweenService:Create(root,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                { CFrame = destination }
            ):Play()
            task.delay(0.3, function() cooldown = false end)
        end
    end)
end

TeleportTab:Toggle({
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
--

-- CELL TELEPORT --
local CellTeleportConnection = nil
local lastCellPosition = nil

local function CellTeleport()
    CellTeleportConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- Numpad5 = Zurück zur letzten Position
        if input.KeyCode == Enum.KeyCode.KeypadFive then
            local character = LocalPlayer.Character
            local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
            if rootPart and lastCellPosition then
                rootPart.CFrame = lastCellPosition
                print("[CellTeleport] BACK → " .. tostring(lastCellPosition.Position))
                lastCellPosition = nil
            else
                print("[CellTeleport] Keine gespeicherte Position vorhanden.")
            end
            return
        end

        local directionMap = {
            [Enum.KeyCode.KeypadEight] = "N",
            [Enum.KeyCode.KeypadNine]  = "NE",
            [Enum.KeyCode.KeypadSix]   = "E",
            [Enum.KeyCode.KeypadThree] = "SE",
            [Enum.KeyCode.KeypadTwo]   = "S",
            [Enum.KeyCode.KeypadOne]   = "SW",
            [Enum.KeyCode.KeypadFour]  = "W",
            [Enum.KeyCode.KeypadSeven] = "NW",
        }

        local DIRECTION = directionMap[input.KeyCode]
        if not DIRECTION then return end

        local planeSettings = ok and result
            and result.WorldStatic
            and result.WorldStatic.WorldSettings
            and result.WorldStatic.WorldSettings.PlaneSettings

        local worldSettings = ok and result
            and result.WorldStatic
            and result.WorldStatic.WorldSettings

        local cellSize   = planeSettings and planeSettings[1] and planeSettings[1].CellSize
        local HALF_X     = cellSize and cellSize.X / 2 or 4096
        local HALF_Z     = cellSize and cellSize.Z / 2 or 4096
        local OUT_BUFFER = worldSettings and worldSettings.TeleportOutBuffer and worldSettings.TeleportOutBuffer + 10 or 400

        local TRIGGER_X = HALF_X + OUT_BUFFER
        local TRIGGER_Z = HALF_Z + OUT_BUFFER

        local directions = {
            N  = Vector3.new(0,          0, -TRIGGER_Z),
            S  = Vector3.new(0,          0,  TRIGGER_Z),
            W  = Vector3.new(-TRIGGER_X, 0,  0),
            E  = Vector3.new( TRIGGER_X, 0,  0),
            NE = Vector3.new( TRIGGER_X, 0, -TRIGGER_Z),
            NW = Vector3.new(-TRIGGER_X, 0, -TRIGGER_Z),
            SE = Vector3.new( TRIGGER_X, 0,  TRIGGER_Z),
            SW = Vector3.new(-TRIGGER_X, 0,  TRIGGER_Z),
        }

        local lookDirs = {
            N  = Vector3.new( 0, 0, -1),
            S  = Vector3.new( 0, 0,  1),
            W  = Vector3.new(-1, 0,  0),
            E  = Vector3.new( 1, 0,  0),
            NE = Vector3.new( 1, 0, -1),
            NW = Vector3.new(-1, 0, -1),
            SE = Vector3.new( 1, 0,  1),
            SW = Vector3.new(-1, 0,  1),
        }

        local targetXZ = directions[DIRECTION]
        local character = LocalPlayer.Character
        local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        -- Position vor dem Teleport speichern
        lastCellPosition = rootPart.CFrame

        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local rayResult = workspace:Raycast(
            Vector3.new(targetXZ.X, 500, targetXZ.Z),
            Vector3.new(0, -1000, 0),
            raycastParams
        )
        local groundY = rayResult and rayResult.Position.Y + 3 or rootPart.Position.Y
        local targetPos = Vector3.new(targetXZ.X, groundY, targetXZ.Z)
        local lookDir = lookDirs[DIRECTION]

        rootPart.CFrame = CFrame.new(targetPos, targetPos + lookDir)
        print(string.format("[CellTeleport] %s → (%.0f, %.0f, %.0f)", DIRECTION, targetPos.X, targetPos.Y, targetPos.Z))
    end)
end

TeleportTab:Toggle({
    Title = "Cell Teleport",
    Desc = "Use numpad for cell teleport directions",
    Type = "Toggle",
    Value = settings["CellTeleport"] or false,
    Callback = function(state)
        saveSetting("CellTeleport", state)

        if state then
            CellTeleport()
        else
            if CellTeleportConnection then
                CellTeleportConnection:Disconnect()
                CellTeleportConnection = nil
            end
        end
    end
})
-- END OF CLICK TELEPORT --

local WorldTab = Window:Tab({
    Title = "World",
    Icon = "sun",
    Locked = false,
})

-- CONTAINER INSPECTOR --
local ContainerInspectorConnection = nil
local currentInterface = nil
local currentModel = nil

local InspectorTemplate = ReplicatedStorage
    :WaitForChild("ClientPackage")
    :WaitForChild("Objects")
    :WaitForChild("Items")
    :WaitForChild("_ToolClasses")
    :WaitForChild("AdminContainerInspector")
    :WaitForChild("AdminContainerInspector_Client")
    :WaitForChild("InspectorInterface")

local MainUI = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainUI"):WaitForChild("Main")
local HttpService = game:GetService("HttpService")

local function isContainer(model)
    for _, obj in pairs(model:GetDescendants()) do
        if (obj:IsA("PrismaticConstraint") and obj.Name == "DrawerSlide")
        or (obj:IsA("MeshPart") and obj.Name == "BagStraps")
        or (obj:IsA("HingeConstraint") and obj.Name == "DoorHinge")
        or (obj:IsA("BasePart") and obj.Name == "HumanoidRootPart")
        or (obj:IsA("BasePart") and obj.Name == "KeyHole") then
            return true
        end
    end
    return false
end

local function getContainerModel(part)
    local current = part
    while current and current ~= Objects do
        if current:IsA("Model") and current.Parent == Objects then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function tableSize(t)
    local n = 0
    for _ in pairs(t) do n += 1 end
    return n
end

local function closeInspector()
    if currentInterface then
        currentInterface:Destroy()
        currentInterface = nil
        currentModel = nil
    end
end

local ObjectInterfaceFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ObjectInterfaceFunction")

local FILTER_KEYS = {
    Owner = true, Id = true, LastOwnerRefresh = true, LastInteraction = true,
    PropertyId = true, PlacementInfo = true, ResizePositive = true,
    ResizeNegative = true, RenderId = true, AttachCFrame = true,
    FlameBehavior = true, Size = true, Scale = true, AdminHistoryLog = true, StateStack = true, 
}

local function filterState(state)
    for k in pairs(FILTER_KEYS) do
        state[k] = nil
    end
    if type(state.Contents) == "table" then
        for _, item in pairs(state.Contents) do
            if type(item) == "table" then
                local stack = item.StateStack
                if type(stack) == "table" then
                    for _, s in pairs(stack) do
                        if type(s) == "table" then
                            filterState(s)
                        end
                    end
                end
            end
        end
    end
end

local function showInspector(model)
    local ok2, result2
    
    closeInspector()

    if worldVersion < 2 then
        ok2, result2 = pcall(function()
            return ObjectInterfaceFunction:InvokeServer(model, "x{3")
        end)
    else
        ok2, result2 = pcall(function()
            return ObjectInterfaceFunction:InvokeServer({Model = model}, "QTE")
        end)
    end

    if not ok2 or not result2 then
        warn("[Inspector] Failed: " .. tostring(result2))
        return
    end

    local capacity = result2.Capacity or 0
    local rawContents = result2.Contents or {}

    local interface = InspectorTemplate:Clone()
    interface.Parent = MainUI
    currentInterface = interface
    currentModel = model

    -- Maus nicht blockieren
    for _, obj in pairs(interface:GetDescendants()) do
        if obj:IsA("ScrollingFrame") or obj:IsA("Frame") or obj:IsA("TextButton") then
            obj.Active = false
        end
        if obj:IsA("ScrollingFrame") then
            obj.ScrollingEnabled = true
        end
    end
    if interface:IsA("ScreenGui") then
        interface.Modal = false
    end

    interface.Title.ObjectName.TextLabel.Text = model.Name ~= "" and model.Name or "Container"
    interface.Title.History.TextLabel.Text = "Detailed Metadata"

    local listItem = interface.Elements.Entry
    local deleteTemplate = listItem:FindFirstChild("Delete")
    if deleteTemplate then deleteTemplate:Destroy() end

    local contentsList = interface.Elements.List:Clone()
    contentsList.Name = "ContentsList"

    local metaList = interface.Elements.List:Clone()
    metaList.Name = "MetaList"

    local contentsEntries = {}
    local metaEntries = {}

    for i = 1, capacity do
        local containerItem = rawContents[i] or rawContents[tostring(i)]

        -- CONTENTS ENTRY --
        do
            local entryText = i .. ":"

            if containerItem and type(containerItem) == "table" then
                local stack = containerItem.StateStack
                local firstState = type(stack) == "table" and (stack[1] or stack["1"])

                local itemName = tostring(containerItem.Name or "?")
                if firstState and type(firstState) == "table" then
                    if itemName == "Plank" and firstState.Wood then
                        itemName = tostring(firstState.Wood) .. " Plank"
                    elseif itemName == "Slab" and firstState.Stone then
                        itemName = tostring(firstState.Stone) .. " Slab"
                    end
                end

                entryText = entryText .. " " .. itemName .. " |"

                if type(stack) == "table" then
                    local stackSize = tableSize(stack)
                    if stackSize > 1 then
                        entryText = entryText .. " (" .. stackSize .. "x) | "
                    end

                    if firstState and type(firstState) == "table" then
                        local state = {}
                        for k, v in pairs(firstState) do
                            state[k] = v
                        end

                        filterState(state)

                        if state.Pages then
                            local allowed = {
                                Barrel = true, Bell = true, Dynamite = true,
                                PenutScepter = true, Backpack3 = true, DivingHelmet = true,
                                MetalTopHat = true, PenutCrown = true, StoneTopHat = true,
                                WoodTopHat = true, AirTank = true, DivingBelt = true,
                                Trunk2 = true, Helicopter = true, Helicopter1 = true,
                                Helicopter2 = true, DispenserChest = true, BarberChair = true,
                                Bin1 = true, MarketStand = true, MetalBarDoor = true,
                                Mirror1 = true, Pallisade = true, Well = true, Safe1 = true
                            }
                            local filteredNames = {}
                            for _, page in pairs(state.Pages) do
                                for _, category in pairs(page) do
                                    if category.Blueprints then
                                        for _, item in pairs(category.Blueprints) do
                                            if item.Name and allowed[item.Name] then
                                                table.insert(filteredNames, item.Name)
                                            end
                                        end
                                    end
                                end
                            end
                            state.Pages = filteredNames
                        end

                        local encOk, encoded = pcall(HttpService.JSONEncode, HttpService, state)
                        if encOk and encoded ~= "{}" then
                            entryText = entryText .. " " .. encoded
                        end
                    end
                end
            end

            local entry = listItem:Clone()
            entry.TextLabel.Text = entryText
            entry.TextLabel.TextScaled = false
            entry.TextLabel.TextWrapped = true
            entry.TextLabel.TextSize = 18
            entry.TextLabel.AutomaticSize = Enum.AutomaticSize.Y
            entry.AutomaticSize = Enum.AutomaticSize.Y
            entry.LayoutOrder = i
            entry.Parent = contentsList
            contentsEntries[i] = entry
        end

        -- DETAILED METADATA ENTRY --
        do
            local metaText = ""

            if containerItem and type(containerItem) == "table" then
                local stack = containerItem.StateStack
                local firstState = stack and (stack[1] or stack["1"])
                if firstState and type(firstState) == "table" then
                    local id = firstState.Id

                    local metaState = {}
                    if id ~= nil then metaState.Id = id end

                    local encOk, encoded = pcall(HttpService.JSONEncode, HttpService, metaState)
                    if encOk and encoded ~= "{}" then
                        metaText = encoded
                    end
                end
            end

            local entry = listItem:Clone()
            entry.TextLabel.Text = metaText
            entry.TextLabel.TextScaled = false
            entry.TextLabel.TextWrapped = true
            entry.TextLabel.TextSize = 18
            entry.TextLabel.AutomaticSize = Enum.AutomaticSize.Y
            entry.AutomaticSize = Enum.AutomaticSize.Y
            entry.LayoutOrder = i
            entry.Parent = metaList
            metaEntries[i] = entry
        end
    end

    contentsList.Parent = interface.ListFrames.Contents
    metaList.Parent = interface.ListFrames.History

    task.wait()
    task.wait()

    -- Höhen synchronisieren
    for i = 1, capacity do
        local cEntry = contentsEntries[i]
        local mEntry = metaEntries[i]
        if cEntry and mEntry then
            local maxHeight = math.max(cEntry.AbsoluteSize.Y, mEntry.AbsoluteSize.Y)
            cEntry.AutomaticSize = Enum.AutomaticSize.None
            mEntry.AutomaticSize = Enum.AutomaticSize.None
            cEntry.Size = UDim2.new(1, 0, 0, maxHeight)
            mEntry.Size = UDim2.new(1, 0, 0, maxHeight)
        end
    end

    -- Resize Contents
    local layoutC = contentsList:FindFirstChildWhichIsA("UIListLayout")
    if layoutC then
        local len = layoutC.AbsoluteContentSize.Y
        contentsList.Size = UDim2.new(1, 0, 0, len)
        interface.ListFrames.Contents.CanvasSize = UDim2.new(0, 0, 0, len)
    end

    -- Resize Metadata
    local layoutM = metaList:FindFirstChildWhichIsA("UIListLayout")
    if layoutM then
        local len = layoutM.AbsoluteContentSize.Y
        metaList.Size = UDim2.new(1, 0, 0, len)
        interface.ListFrames.History.CanvasSize = UDim2.new(0, 0, 0, len)
    end

    print(string.format("[Inspector] %s | Capacity: %d", model:GetFullName(), capacity))
end

local function ContainerInspector()
    local isInspecting = false
    ContainerInspectorConnection = mouse.Button1Down:Connect(function()
        if not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and
           not UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
            return
        end

        if isInspecting then return end

        local target = mouse.Target
        if not target then
            closeInspector()
            return
        end

        local model = getContainerModel(target)

        if not model or not isContainer(model) then
            closeInspector()
            return
        end

        if model == currentModel then
            closeInspector()
            return
        end

        isInspecting = true
        showInspector(model)
        isInspecting = false
    end)
end

WorldTab:Toggle({
    Title = "Container Inspector",
    Desc = "Inspect Backpacks, Dressers, Vaults [LALT+Click]",
    Type = "Toggle",
    Value = settings["ContainerInspector"] or false,
    Callback = function(state)
        saveSetting("ContainerInspector", state)

        if state then
            ContainerInspector()
        else
            if ContainerInspectorConnection then
                ContainerInspectorConnection:Disconnect()
                ContainerInspectorConnection = nil
                if currentInterface then
                    currentInterface:Destroy()
                    currentInterface = nil
                    currentModel = nil
                end
            end
        end
    end
})
-- END OF CONTAINER INSPECTOR --

WorldTab:Slider({
    Title = "Time Offsetter",
    Desc = "Change the time locally",
    Step = 0.01,
    Value = {
        Min = 0,
        Max = 1,
        Default = game.ReplicatedStorage.DayTimeOffset.Value,
    },
    Callback = function(value)
        game.ReplicatedStorage.DayTimeOffset.Value = value
    end
})

local ObjectsTab = Window:Tab({
    Title = "Objects",
    Icon = "folder-git-2",
    Locked = false,
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

    -- FRUIT (UNOBTAINABLE)
    ["5423237725"] = "Molen",
    ["447115748"] = "Perrep",
    ["5423237716"] = "Corrat",
    ["5423237726"] = "Penaeppla",
    ["5952993683"] = "Luttece",
    ["6250815948"] = "Penut",

    -- DICS (UNOBTAINABLE)
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

-- Auto Reactivate
if settings["SafeClickTeleport"] then
    ClickTeleport()
end

if settings["CellTeleport"] then
    CellTeleport()
end

if settings["ContainerInspector"] then
    ContainerInspector()
end

-- On Menu Exit
Window:OnDestroy(function()
    if TPconnection then
        TPconnection:Disconnect()
        TPconnection = nil
    end
    if TeleportConnection then
        TeleportConnection:Disconnect()
        TeleportConnection = nil
    end
    if CellTeleportConnection then
        CellTeleportConnection:Disconnect()
        CellTeleportConnection = nil
    end
    if ContainerInspectorConnection then
        ContainerInspectorConnection:Disconnect()
        ContainerInspectorConnection = nil 
    end
    if currentInterface then
        currentInterface:Destroy()
        currentInterface = nil
        currentModel = nil
    end
    getgenv().WINDGATE_LOADED = nil
end)