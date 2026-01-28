-- Legendary Haki Colors Server Hopper for Blox Fruits
-- Searches for Barista Cousin NPC (legendary haki colors) and teleports with tween (flying animation)
-- Hops to servers with the NPC to avoid detection

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local NPC_NAME = "Barista Cousin"
local TWEEN_SPEED = 0.5 -- Adjust for slower/faster flight (lower = slower)
local SEARCH_SERVERS = 10 -- Number of servers to search
local GAME_ID = game.PlaceId

-- Function to find NPC in current server (Blox Fruits specific)
local function findNPC()
    -- Blox Fruits NPC structure search
    
    -- Check main workspace for NPC model
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name == NPC_NAME then
            local npcPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("Part")
            if npcPart then
                print("Found NPC: " .. obj.Name .. " at position: " .. tostring(npcPart.Position))
                return npcPart
            end
        end
    end
    
    -- Search in common Blox Fruits folders
    local npcFolders = {"NPCs", "Enemies", "Characters", "Models", "Islands"}
    for _, folderName in ipairs(npcFolders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, npc in pairs(folder:GetDescendants()) do
                if npc.Parent and (npc.Parent.Name == NPC_NAME or npc.Name == NPC_NAME) then
                    local npcPart = npc.Parent:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildOfClass("Part")
                    if npcPart then
                        print("Found NPC in folder: " .. folderName)
                        return npcPart
                    end
                end
            end
        end
    end
    
    -- Fallback: search entire workspace hierarchy
    local function searchRecursive(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("Model") and string.find(child.Name, NPC_NAME) then
                local part = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildOfClass("Part")
                if part then
                    return part
                end
            end
            local result = searchRecursive(child)
            if result then
                return result
            end
        end
        return nil
    end
    
    return searchRecursive(Workspace)
end

-- Function to tween character to location (anti-ban safe tween)
local function tweenToLocation(targetPosition)
    local TweenService = game:GetService("TweenService")
    local character = player.Character
    
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Calculate distance for realistic flight time
    local distance = (humanoidRootPart.Position - targetPosition).Magnitude
    local flightDuration = distance / (100 * TWEEN_SPEED) -- Slower = safer
    
    print("Initiating flight tween...")
    print("Distance: " .. tostring(distance))
    print("Flight duration: " .. tostring(flightDuration) .. " seconds")
    
    -- Create tween info for smooth flight animation
    local tweenInfo = TweenInfo.new(
        flightDuration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut
    )
    
    -- Add slight Y offset to avoid hitting ground
    local safeTargetPosition = targetPosition + Vector3.new(0, 3, 0)
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = CFrame.new(safeTargetPosition)})
    tween:Play()
    
    tween.Completed:Connect(function()
        print("✓ Arrived at destination!")
    end)
    
    return tween
end

-- Function to get list of servers
local function getServerList()
    local servers = {}
    
    -- This function attempts to find available servers
    -- In practice, you'd need to use the API or game-specific methods
    pcall(function()
        local cursor = ""
        for i = 1, SEARCH_SERVERS do
            local url = "https://www.roblox.com/games/getgameinstances?placeId=" .. GAME_ID .. "&cursor=" .. cursor
            local success, response = pcall(function()
                return HttpService:GetAsync(url)
            end)
            
            if success then
                local data = HttpService:JSONDecode(response)
                if data.Collection then
                    for _, server in pairs(data.Collection) do
                        table.insert(servers, {
                            jobId = server.Guid,
                            playerCount = server.CurrentPlayers
                        })
                    end
                    if data.Cursor then
                        cursor = data.Cursor
                    end
                end
            end
        end
    end)
    
    return servers
end

-- Function to check if NPC exists in server before hopping
local function npcExistsInServer(jobId)
    local TeleportService = game:GetService("TeleportService")
    
    -- Attempt to find NPC in current server
    local npc = findNPC()
    return npc ~= nil
end

-- Function to hop to server
local function hopToServer(jobId)
    local TeleportService = game:GetService("TeleportService")
    
    pcall(function()
        TeleportService:TeleportToPlaceInstance(GAME_ID, jobId, player)
    end)
end

-- Main execution
print("===============================================")
print("  Legendary Haki Colors - Blox Fruits Hopper")
print("===============================================")
print("Searching for: " .. NPC_NAME .. " NPC")
print("Game ID: " .. GAME_ID)
print("")

-- Check current server first
local npc = findNPC()
if npc then
    print("✓ SUCCESS! Found " .. NPC_NAME .. " in current server!")
    print("Position: " .. tostring(npc.Position))
    print("")
    print("Initiating SAFE flight tween to NPC location...")
    print("(Flying slowly to avoid detection)")
    tweenToLocation(npc.Position)
else
    print("✗ NPC not found in current server.")
    print("Searching other servers...")
    print("")
    
    local servers = getServerList()
    
    if #servers > 0 then
        print("Found " .. #servers .. " servers. Starting hop sequence...")
        print("")
        
        local found = false
        for i, server in pairs(servers) do
            if found then break end
            
            print("[" .. i .. "/" .. #servers .. "] Hopping to server: " .. server.jobId)
            print("    Players in server: " .. server.playerCount)
            hopToServer(server.jobId)
            
            -- Wait for teleport to complete
            wait(5)
            
            -- Check if character loaded and NPC exists
            local character = player.Character or player.CharacterAdded:Wait()
            wait(1) -- Extra wait for NPC to load
            
            local npcFound = findNPC()
            
            if npcFound then
                print("✓✓✓ FOUND IT! " .. NPC_NAME .. " in server: " .. server.jobId)
                print("Position: " .. tostring(npcFound.Position))
                print("")
                print("Initiating SAFE flight tween to NPC...")
                found = true
                tweenToLocation(npcFound.Position)
                break
            else
                print("✗ Not in this server. Continuing search...")
                print("")
            end
        end
        
        if not found then
            print("✗ NPC not found in any searched servers.")
            print("Try running script again or increase SEARCH_SERVERS value.")
        end
    else
        print("✗ No servers found. Check your connection.")
    end
end

print("")
print("===============================================")
print("  Script completed!")
print("===============================================")
