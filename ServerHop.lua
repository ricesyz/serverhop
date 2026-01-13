local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Load via: loadstring(game:HttpGet("https://raw.githubusercontent.com/ricesyz/serverhop/refs/heads/main/ServerHop.lua"))()

-- Ensure this runs only on the client (LocalScript)
if not game:GetService("RunService"):IsClient() then
	error("This script must be a LocalScript running on the client!")
end

local GAME_ID = game.PlaceId
local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour

-- Load previous server IDs
local File = pcall(function()
	AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
end)
if not File then
	table.insert(AllIDs, actualHour)
	writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
end

local hopActive = false
local timeRemaining = 10

-- Fixed timer (1:30 minutes)
local fixedTimerActive = true
local fixedTimeRemaining = 90

-- Create GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Text = "Server Hop"
title.BorderSizePixel = 0
title.Parent = mainFrame

-- Timer Label
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 0, 40)
timerLabel.Position = UDim2.new(0, 0, 0, 35)
timerLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
timerLabel.TextSize = 14
timerLabel.Text = "Ready"
timerLabel.BorderSizePixel = 0
timerLabel.Parent = mainFrame

-- Start Button
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(1, -10, 0, 35)
startButton.Position = UDim2.new(0, 5, 0, 110)
startButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 14
startButton.Text = "Start Hop"
startButton.BorderSizePixel = 0
startButton.Parent = mainFrame

-- Stop Button
local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0, 0, 0, 35)
stopButton.Position = UDim2.new(0, 5, 0, 110)
stopButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextSize = 14
stopButton.Text = "Stop"
stopButton.BorderSizePixel = 0
stopButton.Visible = false
stopButton.Parent = mainFrame

-- Server hopping function (defined after GUI creation so timerLabel exists)
local function TPReturner()
	local Site
	local success = false
	
	local function fetchServers()
		if foundAnything == "" then
			return game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. GAME_ID .. '/servers/Public?sortOrder=Asc&limit=100'))
		else
			return game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. GAME_ID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
		end
	end
	
	local fetch_success = pcall(function()
		Site = fetchServers()
	end)
	
	if not fetch_success or not Site or not Site.data then
		warn("Failed to fetch servers from API")
		return false
	end
	
	if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
		foundAnything = Site.nextPageCursor
	end
	
	local num = 0
	for i,v in pairs(Site.data) do
		if not v.id or not v.maxPlayers or not v.playing then
			continue
		end
		
		local Possible = true
		local ID = tostring(v.id)
		
		if tonumber(v.maxPlayers) > tonumber(v.playing) then
			for _,Existing in pairs(AllIDs) do
				if num ~= 0 then
					if ID == tostring(Existing) then
						Possible = false
						break
					end
				else
					if tonumber(actualHour) ~= tonumber(Existing) then
						pcall(function()
							delfile("NotSameServers.json")
							AllIDs = {}
							table.insert(AllIDs, actualHour)
						end)
					end
				end
			end
			
			if Possible == true then
				table.insert(AllIDs, ID)
				pcall(function()
					writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
				end)
				
				timerLabel.Text = "Hopping to: " .. ID:sub(1, 8) .. "..."
				wait(0.5)
				
				local tp_success = pcall(function()
					game:GetService("TeleportService"):TeleportToPlaceInstance(GAME_ID, ID, game.Players.LocalPlayer)
				end)
				
				if tp_success then
					print("Successfully teleported to server: " .. ID)
					return true
				else
					warn("Failed to teleport to server: " .. ID)
				end
			end
		end
		num = num + 1
	end
	
	return false
end

local function hopServer()
	print("Attempting to server hop...")
	timerLabel.Text = "Finding server..."
	
	local attempts = 0
	local max_attempts = 3
	
	while attempts < max_attempts do
		local hop_success = pcall(function()
			if TPReturner() then
				print("Server hop initiated successfully")
				return
			end
		end)
		
		if hop_success then
			break
		end
		
		attempts = attempts + 1
		if attempts < max_attempts then
			timerLabel.Text = "Retrying... (" .. attempts .. "/" .. max_attempts .. ")"
			wait(2)
		end
	end
	
	if attempts >= max_attempts then
		warn("Failed to find available server after " .. max_attempts .. " attempts")
		timerLabel.Text = "No servers available"
	end
end

-- Start button clicked
startButton.MouseButton1Click:Connect(function()
	hopActive = true
	timeRemaining = 10
	startButton.Visible = false
	stopButton.Visible = true
	
	for i = 10, 0, -1 do
		if not hopActive then break end
		timeRemaining = i
		local minutes = math.floor(i / 60)
		local seconds = i % 60
		timerLabel.Text = string.format("Hopping in: %d:%02d", minutes, seconds)
		wait(1)
	end
	
	if hopActive then
		hopServer()
		hopActive = false
		startButton.Visible = true
		stopButton.Visible = false
		timerLabel.Text = "Ready"
	end
end)

-- Stop button clicked
stopButton.MouseButton1Click:Connect(function()
	hopActive = false
	startButton.Visible = true
	stopButton.Visible = false
	timerLabel.Text = "Cancelled"
	wait(1)
	timerLabel.Text = "Ready"
end)

-- Fixed Timer Loop (1:30 minutes, starts immediately)
while fixedTimerActive do
	if fixedTimeRemaining > 0 then
		local minutes = math.floor(fixedTimeRemaining / 60)
		local seconds = fixedTimeRemaining % 60
		
		if not hopActive then
			timerLabel.Text = string.format("Timer: %d:%02d", minutes, seconds)
		end
		
		fixedTimeRemaining = fixedTimeRemaining - 1
		wait(1)
	else
		-- Timer finished
		fixedTimeRemaining = 90
		if not hopActive then
			timerLabel.Text = "Time's up!"
		end
		wait(2)
	end
end