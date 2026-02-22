  
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

-- Evitar crear duplicados si ya existe la UI
local existing = player:WaitForChild("PlayerGui"):FindFirstChild("MiMenuUI")
if existing then
    -- Si ya existe, no crear otra; opcionalmente podrías actualizarla aquí
    return
end

-- ScreenGui (persistente al morir)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MiMenuUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Contenedor grande (arrastrable)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 360)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
mainFrame.Parent = screenGui
mainFrame.Active = true

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Barra superior para arrastrar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
topBar.Parent = mainFrame
topBar.Active = true
topBar.ZIndex = 2

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 12)
barCorner.Parent = topBar


-- ScrollingFrame dentro del contenedor grande (lista desplazable)
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -20, 1, -50)
scrollingFrame.Position = UDim2.new(0, 10, 0, 46)
scrollingFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
scrollingFrame.ScrollBarThickness = 8
scrollingFrame.Parent = mainFrame
scrollingFrame.Active = true
scrollingFrame.Selectable = false
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollingFrame.CanvasSize = UDim2.new(0,0,0,0)
scrollingFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always
scrollingFrame.ZIndex = 1

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 12)
scrollCorner.Parent = scrollingFrame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 85, 170))
}
gradient.Rotation = 90
gradient.Parent = scrollingFrame

-- UIListLayout para ordenar los elementos dentro del ScrollingFrame
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.Parent = scrollingFrame

-- Ajustar CanvasSize automáticamente cuando cambie el contenido
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
end)

-- Función para arrastrar el frame grande (PC y móvil)
-- Solo arrastra si el input comenzó en topBar, así no interfiere con el ScrollingFrame
local function makeDraggable(guiObject, dragHandle)
    dragHandle.Active = true
    guiObject.Active = true

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragInput = nil
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input ~= dragInput then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(mainFrame, topBar)

-- Texto en la barra superior
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0) -- ocupa casi toda la barra
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Boot Hub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 20 -- más alto que el botón de minimizar
titleLabel.Parent = topBar


local Players = game:GetService("Players")

-- Label dentro del ScrollingFrame, último elemento
local chanceLabel = Instance.new("TextLabel")
chanceLabel.Size = UDim2.new(0.95, 0, 0, 70) -- tamaño actual
chanceLabel.BackgroundTransparency = 1
chanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
chanceLabel.Font = Enum.Font.SourceSansBold
chanceLabel.TextSize = 18
chanceLabel.TextXAlignment = Enum.TextXAlignment.Center
chanceLabel.TextYAlignment = Enum.TextYAlignment.Center
chanceLabel.TextScaled = true
chanceLabel.TextWrapped = true
chanceLabel.Text = "Calculando..."
chanceLabel.Parent = scrollingFrame -- se añade último, queda abajo

-- Función para actualizar el label con top 3
local function updateChanceLabel()
    local playersWithChance = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local chanceVal = plr:FindFirstChild("Chance")
        if chanceVal and chanceVal:IsA("NumberValue") then
            table.insert(playersWithChance, {player = plr, value = chanceVal.Value})
        end
    end

    table.sort(playersWithChance, function(a, b)
        return a.value > b.value
    end)

    local textLines = {}
    for i = 1, math.min(3, #playersWithChance) do
        local entry = playersWithChance[i]
        table.insert(textLines, entry.player.Name .. " probably is the Next Homer with " .. entry.value .. " of chance")
    end

    if #textLines > 0 then
        chanceLabel.Text = table.concat(textLines, "\n")
    else
        chanceLabel.Text = "No Chance values found"
    end
end

-- Conectar cambios en tiempo real
for _, plr in ipairs(Players:GetPlayers()) do
    local chanceVal = plr:FindFirstChild("Chance")
    if chanceVal then
        chanceVal:GetPropertyChangedSignal("Value"):Connect(updateChanceLabel)
    end
end
Players.PlayerAdded:Connect(function(plr)
    plr.ChildAdded:Connect(function(child)
        if child.Name == "Chance" and child:IsA("NumberValue") then
            child:GetPropertyChangedSignal("Value"):Connect(updateChanceLabel)
            updateChanceLabel()
        end
    end)
end)

-- Actualizar al inicio
updateChanceLabel()


-- =========================
-- Funciones para crear UI
-- =========================
local function createToggle(name, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.95, 0, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 16
    button.Text = name .. ": OFF"
    button.Parent = scrollingFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local isOn = false
    button.MouseButton1Click:Connect(function()
        isOn = not isOn
        if isOn then
            button.Text = name .. ": ON"
            button.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
        else
            button.Text = name .. ": OFF"
            button.BackgroundColor3 = Color3.fromRGB(170, 0, 85)
        end
        callback(function() return isOn end)
    end)

    return button
end

local function createButton(name, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.95, 0, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 16
    button.Text = name
    button.Parent = scrollingFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    button.MouseButton1Click:Connect(function()
        callback()
    end)

    return button
end


-- =========================
-- Funciones de juego (Auto Farm, Get Lora, FullBright, Doors/Buttons)
-- =========================

-- Guardar settings normales de Lighting
_G.NormalLightingSettings = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient
}
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- funciones getWinpad y getTargetCFrame tal como las tenías
local function getWinpad()
    local ok, build = pcall(function()
        return workspace:FindFirstChild("lobby") and workspace.lobby:FindFirstChild("Obby") and workspace.lobby.Obby:FindFirstChild("build")
    end)
    if not ok or not build then return nil end

    for _, child in ipairs(build:GetChildren()) do
        local subBuild = child:FindFirstChild("build")
        if subBuild and subBuild:FindFirstChild("Winpad") then
            return subBuild.Winpad
        end
    end
    return nil
end

local function getTargetCFrame(obj)
    if not obj then return nil end
    if obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.CFrame
        else
            return obj:GetModelCFrame()
        end
    elseif obj:IsA("BasePart") then
        return obj.CFrame
    end
    return nil
end

-- Estado para controlar el tween activo
local activeTween = nil
local stopFlag = false

local function cancelActiveTween()
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
end

-- Plataforma de seguridad y conexiones
local safetyPlatform = nil
local safetyHeartbeatConn = nil
local safetyAncestryConn = nil

local function destroySafetyPlatform()
    if safetyHeartbeatConn then
        pcall(function() safetyHeartbeatConn:Disconnect() end)
        safetyHeartbeatConn = nil
    end
    if safetyAncestryConn then
        pcall(function() safetyAncestryConn:Disconnect() end)
        safetyAncestryConn = nil
    end
    if safetyPlatform and safetyPlatform.Parent then
        pcall(function() safetyPlatform:Destroy() end)
        safetyPlatform = nil
    end
end

-- crea la plataforma y la hace seguir al winpad; si el winpad se elimina, destruye la plataforma
local function createSafetyPlatformUnderWinpad(winpad)
    if not winpad then return end
    destroySafetyPlatform()

    local targetCFrame = getTargetCFrame(winpad)
    if not targetCFrame then return end

    local part = Instance.new("Part")
    part.Name = "AutoFarmSafetyPlatform_" .. player.Name
    part.Size = Vector3.new(6, 1, 6)
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 0.4
    part.Material = Enum.Material.Neon
    part.CFrame = targetCFrame * CFrame.new(0, -3, 0)
    part.Parent = workspace
    safetyPlatform = part

    -- seguir al winpad cada frame si se mueve
    safetyHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not safetyPlatform or not safetyPlatform.Parent then
            destroySafetyPlatform()
            return
        end
        -- si el winpad dejó de existir, limpiar
        if not winpad.Parent then
            destroySafetyPlatform()
            return
        end
        local newCFrame = getTargetCFrame(winpad)
        if newCFrame then
            safetyPlatform.CFrame = newCFrame * CFrame.new(0, -3, 0)
        end
    end)

    -- si el winpad es removido de la jerarquía, destruir la plataforma
    safetyAncestryConn = winpad.AncestryChanged:Connect(function(child, parent)
        if not winpad.Parent then
            destroySafetyPlatform()
        end
    end)
end

-- función para mover con tween como tenías
local function moveToCFrameWithTween(hrp, targetCFrame)
    if not hrp or not targetCFrame then return end

    -- obtener humanoid y velocidad base
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local baseSpeed = 16
    if humanoid and humanoid.WalkSpeed and type(humanoid.WalkSpeed) == "number" then
        baseSpeed = humanoid.WalkSpeed
    end
    local velocidad = baseSpeed * 70

    local distancia = (hrp.Position - targetCFrame.Position).Magnitude
    local duracion = math.max(0.01, distancia / velocidad)

    cancelActiveTween()
    local tweenInfo = TweenInfo.new(duracion, Enum.EasingStyle.Linear)
    activeTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    activeTween:Play()

    local finished = false
    local con
    con = activeTween.Completed:Connect(function()
        finished = true
        pcall(function() con:Disconnect() end)
    end)

    local elapsed = 0
    while not finished and elapsed < duracion + 0.1 and not stopFlag do
        task.wait(0.05)
        elapsed = elapsed + 0.05
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            break
        end
    end
    cancelActiveTween()
end

-- Auto Farm toggle con plataforma que se recrea
createToggle("Auto Farm", function(getState)
    task.spawn(function()
        stopFlag = false
        local lastWinpad = nil
        while getState() and not stopFlag do
            local winpad = getWinpad()
            local char = player.Character
            if winpad ~= lastWinpad then
                -- si cambió el winpad, recrear plataforma o destruir si nil
                if winpad then
                    createSafetyPlatformUnderWinpad(winpad)
                else
                    destroySafetyPlatform()
                end
                lastWinpad = winpad
            end

            if winpad and char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                -- si existe plataforma, posicionar objetivo encima de la plataforma para no caerte
                local targetCFrame = nil
                if safetyPlatform and safetyPlatform.Parent then
                    targetCFrame = safetyPlatform.CFrame * CFrame.new(0, 2.5, 0)
                else
                    targetCFrame = getTargetCFrame(winpad)
                end

                if targetCFrame then
                    -- desanclar HRP por si quedó anclado
                    pcall(function() hrp.Anchored = false end)
                    moveToCFrameWithTween(hrp, targetCFrame)
                end
            end

            task.wait(0.2)
        end

        -- limpieza al salir
        cancelActiveTween()
        destroySafetyPlatform()
    end)
end,
function()
    stopFlag = true
    cancelActiveTween()
    destroySafetyPlatform()
end)
-- Get Lora (botón)
createButton("Get Lora", function()
    local ok, lora = pcall(function()
        return workspace:FindFirstChild("lobby") and workspace.lobby:FindFirstChild("Secrets") and workspace.lobby.Secrets:FindFirstChild("LORA")
    end)
    if ok and lora and lora:FindFirstChild("ClickDetector") then
        pcall(function() fireclickdetector(lora.ClickDetector) end)
    end
end)

-- FullBright (toggle)
createToggle("FullBright", function(getState)
    task.spawn(function()
        if getState() then
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 786543
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        else
            Lighting.Brightness = _G.NormalLightingSettings.Brightness
            Lighting.ClockTime = _G.NormalLightingSettings.ClockTime
            Lighting.FogEnd = _G.NormalLightingSettings.FogEnd
            Lighting.GlobalShadows = _G.NormalLightingSettings.GlobalShadows
            Lighting.Ambient = _G.NormalLightingSettings.Ambient
        end
    end)
end)

-- Loop Open All Doors Spaceship (toggle)
createToggle("Loop Open All Doors Spaceship", function(getState)
    task.spawn(function()
        local ok, model = pcall(function()
            return workspace.map and workspace.map["Bart Spaceship"] and workspace.map["Bart Spaceship"].Model
        end)
        if not ok or not model then return end

        while getState() do
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                task.wait(1)
                continue
            end
            local hrp = player.Character.HumanoidRootPart
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    local name = part.Name or ""
                    if name == "BartDoor" or string.find(name, "Airlock") then
                        for _, child in ipairs(part:GetChildren()) do
                            if child:IsA("TouchTransmitter") then
                                pcall(function()
                                    firetouchinterest(hrp, part, 0)
                                    firetouchinterest(hrp, part, 1)
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(2)
        end
    end)
end)

-- Press All Buttons Spaceship (botón)
createButton("Press All Buttons Spaceship", function()
    local ok, model = pcall(function()
        return workspace.map and workspace.map["Bart Spaceship"] and workspace.map["Bart Spaceship"].Model
    end)
    if not ok or not model then return end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("ClickDetector") then
            pcall(function() fireclickdetector(descendant) end)
        end
    end -- cierre del for
end) -- cierre de la función del botón


-- Botón "-" circular
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 36, 0, 36)
minimizeButton.Position = UDim2.new(1, -40, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 20
minimizeButton.Text = "-"
minimizeButton.ZIndex = 10
minimizeButton.Parent = topBar

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = minimizeButton

-- Botón flotante cuadrado con decal
local floatButton = Instance.new("ImageButton")
floatButton.Size = UDim2.new(0, 60, 0, 60) -- más grande
floatButton.Position = UDim2.new(0, 10, 0.5, -30)
floatButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
floatButton.Visible = false
floatButton.ZIndex = 10
floatButton.Parent = screenGui

-- Imagen del decal
floatButton.Image = "rbxassetid://126921135407649"

-- Funcionalidad
minimizeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    floatButton.Visible = true
end)

floatButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    floatButton.Visible = false
end)

-- Arrastrable en PC y móvil
local function makeButtonDraggable(button)
    local dragging = false
    local dragStart, startPos

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = button.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeButtonDraggable(floatButton)


-- =========================
-- Botones y toggles extra
-- =========================

-- Activate Lighthouse Once
createButton("Activate Lighthouse Once", function()
    local ok, button = pcall(function()
        return workspace.map["Island Bar"].Model.lighthouse:FindFirstChild("button")
    end)
    if ok and button and button:FindFirstChild("ClickDetector") then
        pcall(function() fireclickdetector(button.ClickDetector) end)
    end
end)

-- Loop Activate Lighthouse
createToggle("Loop Activate Lighthouse", function(getState)
    task.spawn(function()
        while getState() do
            local ok, button = pcall(function()
                return workspace.map["Island Bar"].Model.lighthouse:FindFirstChild("button")
            end)
            if ok and button and button:FindFirstChild("ClickDetector") then
                pcall(function() fireclickdetector(button.ClickDetector) end)
            end
            task.wait(2) -- intervalo de 2 segundos
        end
    end)
end)

-- Grab 1 Random Bottle
createButton("Grab 1 Random Bottle", function()
    local ok, bottlesFolder = pcall(function()
        return workspace.map["Island Bar"].Model.bar:FindFirstChild("bottles")
    end)
    if not ok or not bottlesFolder then return end

    local candidates = {}
    for _, child in ipairs(bottlesFolder:GetChildren()) do
        if child:FindFirstChild("ClickDetector") then
            table.insert(candidates, child.ClickDetector)
        end
    end

    if #candidates > 0 then
        local randomDetector = candidates[math.random(1, #candidates)]
        pcall(function() fireclickdetector(randomDetector) end)
    end
end)

-- =========================
-- Fling Nearest (Lobby)
-- =========================
createToggle("Fling Nearest (Lobby)", function(getState)
    task.spawn(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local LocalPlayer = Players.LocalPlayer
        local Workspace = game:GetService("Workspace")

        -- Configuración
        local config = {
            radius = 5,
            height = 100,
            rotationSpeed = 10,
            attractionStrength = 1000,
        }

        -- Network exploit style
        if not getgenv().Network then
            getgenv().Network = {
                BaseParts = {},
                Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
            }

            Network.RetainPart = function(Part)
                if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
                    table.insert(Network.BaseParts, Part)
                    -- Seguridad: solo desactivar colisión para el LocalPlayer
                    if LocalPlayer.Character and Part:IsDescendantOf(LocalPlayer.Character) then
                        Part.CanCollide = false
                    end
                end
            end

            local function EnablePartControl()
                LocalPlayer.ReplicationFocus = Workspace
                RunService.Heartbeat:Connect(function()
                    sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                    for _, Part in pairs(Network.BaseParts) do
                        if Part:IsDescendantOf(Workspace) then
                            Part.Velocity = Network.Velocity
                        end
                    end
                end)
            end

            EnablePartControl()
        end

        -- Lista de partes válidas
        local parts = {}

        local function addPart(part)
            if part:IsA("BasePart") and part.Name == "Marble" and part:IsDescendantOf(Workspace.lobby.Fun) then
                table.insert(parts, part)
            elseif part:IsA("BasePart") and part:IsDescendantOf(Workspace.map) and not part.Anchored then
                table.insert(parts, part)
            end
        end

        local function removePart(part)
            local index = table.find(parts, part)
            if index then
                table.remove(parts, index)
            end
        end

        for _, part in pairs(Workspace:GetDescendants()) do
            addPart(part)
        end

        Workspace.DescendantAdded:Connect(addPart)
        Workspace.DescendantRemoving:Connect(removePart)

        local ringPartsEnabled = true

        local function getClosestPlayer()
            local closestPlayer = nil
            local closestDistance = math.huge
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            if myRoot then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local otherRoot = player.Character.HumanoidRootPart
                        local dist = (otherRoot.Position - myRoot.Position).Magnitude
                        if dist < closestDistance then
                            closestDistance = dist
                            closestPlayer = player
                        end
                    end
                end
            end

            return closestPlayer
        end

        -- Loop principal
        RunService.Heartbeat:Connect(function()
            if not getState() then return end
            
            local closestPlayer = getClosestPlayer()
            if closestPlayer and closestPlayer.Character then
                local humanoidRootPart = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local tornadoCenter = humanoidRootPart.Position
                    for _, part in pairs(parts) do
                        if part.Parent and not part.Anchored then
                            -- Seguridad: colisión desactivada solo para el LocalPlayer
                            if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then
                                part.CanCollide = false
                            end

                            local pos = part.Position
                            local distance = (Vector3.new(pos.X, tornadoCenter.Y, pos.Z) - tornadoCenter).Magnitude
                            local angle = math.atan2(pos.Z - tornadoCenter.Z, pos.X - tornadoCenter.X)
                            local newAngle = angle + math.rad(config.rotationSpeed)
                            local targetPos = Vector3.new(
                                tornadoCenter.X + math.cos(newAngle) * math.min(config.radius, distance),
                                tornadoCenter.Y + (config.height * (math.abs(math.sin((pos.Y - tornadoCenter.Y) / config.height)))),
                                tornadoCenter.Z + math.sin(newAngle) * math.min(config.radius, distance)
                            )
                            local directionToTarget = (targetPos - part.Position).unit
                            part.Velocity = directionToTarget * config.attractionStrength
                        end
                    end
                end
            end
        end)
    end)
end)
-- =========================
-- Auto Bang Bart Team (funciona bien)
-- =========================
createToggle("Kill Barts", function(getState)
    task.spawn(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local currentSession = nil
        local running = true

        local function r15(plr)
            local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            return hum and hum.RigType == Enum.HumanoidRigType.R15
        end

        local function cleanupSession()
            if currentSession then
                if currentSession.anim then currentSession.anim:Stop() end
                if currentSession.animObj then currentSession.animObj:Destroy() end
                if currentSession.loop then currentSession.loop:Disconnect() end
                if currentSession.died then currentSession.died:Disconnect() end
                currentSession = nil
            end
        end

        local function playBangOnPlayer(speaker, target)
            if not target.Character then return nil end
            local humanoid = speaker.Character and speaker.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return nil end

            local bangAnim = Instance.new("Animation")
            bangAnim.AnimationId = not r15(speaker) and "rbxassetid://148840371" or "rbxassetid://5918726674"
            local bang = humanoid:LoadAnimation(bangAnim)
            bang:Play(0.1, 1, 1)
            bang:AdjustSpeed(3)

            local offset = CFrame.new(0, 0, 1.1)
            local loopConn = RunService.Stepped:Connect(function()
                if not running then return end
                pcall(function()
                    local otherRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    local myRoot = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
                    if otherRoot and myRoot then
                        myRoot.CFrame = otherRoot.CFrame * offset
                    end
                end)
            end)

            local diedConn
            local hum = target.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                diedConn = hum.Died:Connect(function()
                    cleanupSession()
                end)
            end

            return {anim=bang, animObj=bangAnim, loop=loopConn, died=diedConn}
        end

        while getState() do
            running = true
            local speaker = Players.LocalPlayer
            if not speaker or not speaker.Character then
                task.wait(1)
                continue
            end

            -- Buscar jugadores en equipo Bart/Barts
            local target = nil
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= speaker and plr.Team and (plr.Team.Name == "Bart" or plr.Team.Name == "Barts") then
                    target = plr
                    break
                end
            end

            if target then
                currentSession = playBangOnPlayer(speaker, target)
                -- Esperar a que muera o que se apague el toggle
                while getState() and currentSession do
                    task.wait(0.5)
                end
                -- Cuando muere, cleanupSession ya se ejecutó y el loop vuelve a buscar otro jugador
            else
                task.wait(2)
            end
        end

        -- Al desactivar el toggle: limpiar todo
        running = false
        cleanupSession()
    end)
end)


local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local gui = LocalPlayer:WaitForChild("PlayerGui")

-- Forzar texto en un label
local function forceEpic(label)
    if label then
        label.Text = "IM EPIC"
        label:GetPropertyChangedSignal("Text"):Connect(function()
            label.Text = "IM EPIC"
        end)
    end
end

-- Parche principal
local function patchLeaderboard()
    local leaderboard = gui:WaitForChild("Leaderboard"):WaitForChild("Leaderboard")

    local userFrame = leaderboard:WaitForChild("User"):WaitForChild("frame")
    forceEpic(userFrame:WaitForChild("Username"))

    local usersFrame = leaderboard:WaitForChild("Users")
    local localUserFrame = usersFrame:FindFirstChild(LocalPlayer.Name)
    if localUserFrame then
        local itemsFrame = localUserFrame:WaitForChild("items")
        forceEpic(itemsFrame:WaitForChild("Username"))
    end
end

-- Ciclo 3-3-4 en 3 segundos
local function ejecutarParche(origen)
    print(">>> ejecutarParche lanzado por: " .. origen)

    for i = 1, 3 do patchLeaderboard() end
    task.wait(1)

    for i = 1, 3 do patchLeaderboard() end
    task.wait(1)

    for i = 1, 4 do patchLeaderboard() end
end

-- ✅ Parche inicial
patchLeaderboard()

-- Evitar que se vea tu nombre ni por un frame
local leaderboard = gui:WaitForChild("Leaderboard"):WaitForChild("Leaderboard")
leaderboard.DescendantAdded:Connect(function(desc)
    if desc:IsA("TextLabel") and desc.Name == "Username" then
        forceEpic(desc)
    end
end)

-- Detectar cambio de equipo
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    local team = LocalPlayer.Team and LocalPlayer.Team.Name
    if team == "Perished" or team == "Barts" or team == "Bart" or team == "Homer" then
        ejecutarParche("cambio de equipo")
    end
end)

-- Detectar ForceField al respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    print("CharacterAdded: nuevo personaje")
    local ff = char:WaitForChild("ForceField", 5)
    if ff then
        print(">>> ForceField detectado, lanzando parche")
        ejecutarParche("forcefield")
    end
end)

-- Si ya tiene Character al inicio
if LocalPlayer.Character then
    local ff = LocalPlayer.Character:FindFirstChild("ForceField")
    if ff then
        print(">>> ForceField inicial detectado, lanzando parche")
        ejecutarParche("forcefield (inicio)")
    end
end

-- =========================
-- Toggle Wallhop (ajustado)
-- =========================
local lastHop = 0
local flickAngle = 90
local pushForce = 52
local cooldown = 0.4

local function doWallhop(root)
    if tick() - lastHop < cooldown then return end
    lastHop = tick()
    root.AssemblyLinearVelocity = Vector3.new(
        root.AssemblyLinearVelocity.X,
        pushForce,
        root.AssemblyLinearVelocity.Z
    )
    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(flickAngle), 0)
end

createToggle("Wallhop", function(getState)
    task.spawn(function()
        while getState() do
            local char = player.Character
            local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
            if torso then
                torso.Touched:Connect(function(hit)
                    if not getState() then return end
                    -- Ignorar si es parte de un jugador
                    local parentModel = hit:FindFirstAncestorOfClass("Model")
                    if parentModel and Players:GetPlayerFromCharacter(parentModel) then
                        return
                    end
                    -- Aceptar MeshPart, BasePart y colisionables
                    if hit:IsA("BasePart") and hit.CanCollide then
                        doWallhop(torso)
                    end
                end)
            end
            task.wait(0.5)
        end
    end)
end)



-- =========================
-- Toggle Infinite Jump
-- =========================
local jumpCooldown = 0.1
local lastJump = 0

local function doInfiniteJump()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if not root or not hum then return end
    if tick() - lastJump < jumpCooldown then return end
    lastJump = tick()

    hum.UseJumpPower = true
    hum.JumpPower = 50
    root.AssemblyLinearVelocity = Vector3.new(
        root.AssemblyLinearVelocity.X,
        52,
        root.AssemblyLinearVelocity.Z
    )
    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(90), 0)
end

createToggle("Infinite Jump", function(getState)
    task.spawn(function()
        local conn
        conn = UserInputService.JumpRequest:Connect(function()
            if getState() then
                doInfiniteJump()
            end
        end)

        while getState() do
            task.wait(0.2)
        end

        if conn then
            pcall(function() conn:Disconnect() end)
        end
    end)
end)

-- =========================
-- Toggle ESP por equipos (crea y borra todos juntos)
-- =========================
createToggle("ESP", function(getState)
    task.spawn(function()
        local espObjects = {} -- tabla global de objetos ESP

        local function applyESP(plr)
            if plr == player then return end
            local char = plr.Character
            if not char then return end
            local humRoot = char:FindFirstChild("HumanoidRootPart")
            if not humRoot then return end

            -- Highlight
            local hl = Instance.new("Highlight")
            hl.OutlineColor = Color3.fromRGB(255,255,255)
            hl.FillTransparency = 0.5
            hl.Parent = char

            -- Billboard
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0,200,0,50)
            bb.Adornee = humRoot
            bb.AlwaysOnTop = true
            bb.Parent = char

            local text = Instance.new("TextLabel", bb)
            text.Size = UDim2.new(1,0,1,0)
            text.BackgroundTransparency = 1
            text.TextColor3 = Color3.new(1,1,1)
            text.Font = Enum.Font.GothamBold
            text.TextScaled = true

            -- Actualizar color según equipo
            local function updateTeam()
                local team = plr.Team and plr.Team.Name or "Sin equipo"
                text.Text = team
                if team == "Bart" or team == "Barts" then
                    hl.FillColor = Color3.fromRGB(255, 255, 0) -- amarillo
                elseif team == "Homer" then
                    hl.FillColor = Color3.fromRGB(255, 0, 0) -- rojo
                else
                    hl.FillColor = Color3.fromRGB(255, 0, 0) -- rojo por defecto
                end
            end
            updateTeam()
            plr:GetPropertyChangedSignal("Team"):Connect(updateTeam)

            -- guardar referencias
            table.insert(espObjects, hl)
            table.insert(espObjects, bb)
        end

        -- Crear ESP para todos los jugadores actuales
        for _,plr in ipairs(Players:GetPlayers()) do
            applyESP(plr)
        end

        -- Mantener mientras esté ON
        while getState() do
            task.wait(0.5)
        end

        -- Al apagar: borrar todos juntos
        for _,obj in ipairs(espObjects) do
            if obj and obj.Parent then
                pcall(function() obj:Destroy() end)
            end
        end
        espObjects = {}
    end)
end)


-- =========================
-- Restaurar UI con /restore
-- =========================
local initialFramePos = UDim2.new(0.5, -130, 0.5, -180)
local initialFloatPos = UDim2.new(0, 10, 0.5, -20) -- posición inicial del botón flotante

player.Chatted:Connect(function(msg)
    if msg:lower() == "/restore" then
        -- Restaurar frame principal
        mainFrame.Position = initialFramePos
        mainFrame.Visible = true

        -- Restaurar botón flotante
        if floatButton then
            floatButton.Position = initialFloatPos
            floatButton.Visible = false
        end

        print("UI restaurada a la posición inicial.")
    end
end)


local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 150, 1, 0) -- ancho fijo
titleLabel.Position = UDim2.new(0, 10, 0, 0) -- margen a la izquierda
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Boot Hub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar



-- =========================
-- Toggle CFrame Fly
-- =========================
local CFloop = nil
local CFspeed = 35 -- velocidad inicial

local function startCFrameFly()
    local char = player.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    hum.PlatformStand = true
    local Head = char:WaitForChild("Head")
    Head.Anchored = true

    if CFloop then CFloop:Disconnect() end
    CFloop = RunService.Heartbeat:Connect(function(deltaTime)
        local moveDirection = hum.MoveDirection * (CFspeed * deltaTime)
        local headCFrame = Head.CFrame
        local camera = workspace.CurrentCamera
        local cameraCFrame = camera.CFrame
        local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
        cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
        local cameraPosition = cameraCFrame.Position
        local headPosition = headCFrame.Position

        local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
        Head.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
    end)
end

local function stopCFrameFly()
    if CFloop then
        CFloop:Disconnect()
        CFloop = nil
    end
    local char = player.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
    local Head = char and char:FindFirstChild("Head")
    if Head then
        Head.Anchored = false
    end
end

-- Toggle en la UI
createToggle("CFly", function(getState)
    task.spawn(function()
        if getState() then
            startCFrameFly()
        else
            stopCFrameFly()
        end
    end)
end)


local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Funciones de alternancia
local function enableLegacy()
    local backpackScript = player:WaitForChild("PlayerGui"):FindFirstChild("BackpackScript")
    if backpackScript then
        backpackScript.Parent = ReplicatedStorage
    end
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
end

local function enableCustom()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    local storedScript = ReplicatedStorage:FindFirstChild("BackpackScript")
    if storedScript then
        storedScript.Parent = player:WaitForChild("PlayerGui")
    end
end

-- Crear el toggle dentro de tu menú
createToggle("Legacy Backpack", function(getState)
    if getState() then
        -- Toggle ON → Legacy
        enableLegacy()
    else
        -- Toggle OFF → Custom
        enableCustom()
    end
end)



-- =========================
-- Botón Homer ritual
-- =========================
local function startRitual()
    local Character = player.Character or player.CharacterAdded:Wait()
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end

    -- Crear el Part del ritual
    local Part = Instance.new("Part")
    Part.Size = Vector3.new(8, 1, 8)
    Part.CFrame = HRP.CFrame * CFrame.new(0, -3.5, 0)
    Part.Anchored = true
    Part.BrickColor = BrickColor.new("Bright red")
    Part.Material = Enum.Material.Neon
    Part.Parent = workspace

    -- Velocidad fija de giro
    local spinSpeed = 10

    -- Rotación constante del personaje
    local RotateConnection = RunService.RenderStepped:Connect(function()
        if Character and HRP then
            HRP.CFrame = HRP.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
        end
    end)

    -- Tween para subir el Part (efecto visual)
    local Tween = TweenService:Create(Part, TweenInfo.new(10, Enum.EasingStyle.Linear), {
        Position = Part.Position + Vector3.new(0, 16, 0),
    })
    Tween:Play()

    -- Esperar y finalizar ritual
    task.wait(10)
    RotateConnection:Disconnect()
    if Humanoid.Health > 0 then
        Humanoid:TakeDamage(Humanoid.Health) -- mata al jugador
    end
    Part:Destroy()
end

-- Botón en la UI
createButton("Homer ritual", function()
    startRitual()
end)





-- =========================
-- Botón TP forward (con tween y hover, sin tecla F)
-- =========================
local function tpForward(buttonRef)
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local lookDirection = hrp.CFrame.LookVector
    local dashDistance = 20
    local currentPosition = hrp.Position
    local newPosition = currentPosition + (lookDirection * dashDistance)
    
    -- Desactivar colisiones temporales
    local bodyParts = {}
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            bodyParts[part] = part.CanCollide
            part.CanCollide = false
        end
    end
    
    -- Teleportar hacia adelante
    hrp.CFrame = CFrame.new(newPosition, newPosition + lookDirection)
    
    -- Restaurar colisiones
    task.wait(0.1)
    for part, originalCanCollide in pairs(bodyParts) do
        if part and part.Parent then
            part.CanCollide = originalCanCollide
        end
    end

    -- Efecto visual en el botón
    if buttonRef then
        local originalSize = buttonRef.Size
        local scaleInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local scaleTween = TweenService:Create(buttonRef, scaleInfo, {Size = UDim2.new(0, 90, 0, 35)})
        scaleTween:Play()
        
        scaleTween.Completed:Connect(function()
            local returnTween = TweenService:Create(buttonRef, scaleInfo, {Size = originalSize})
            returnTween:Play()
        end)
    end
end

-- Botón en la UI
local tpButton = createButton("TP forward", function()
    tpForward(tpButton)
end)

-- Hover efecto
tpButton.MouseEnter:Connect(function()
    local hoverTween = TweenService:Create(tpButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.3, 0.6, 1)})
    hoverTween:Play()
end)

tpButton.MouseLeave:Connect(function()
    local leaveTween = TweenService:Create(tpButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.2, 0.5, 1)})
    leaveTween:Play()
end)

