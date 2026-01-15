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

-- Fixed timer (50 seconds for first attempt)
local fixedTimerActive = true
local fixedTimeRemaining = 50

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
		
		-- Check if server has space
		if tonumber(v.maxPlayers) > tonumber(v.playing) then
			for _,Existing in pairs(AllIDs) do
				if num ~= 0 then
					if ID == tostring(Existing) then
						Possible = false
						break
					end
				else
					if tonumber(actualHour) ~= tonumber(Existing) then
						local delFile = pcall(function()
							delfile("NotSameServers.json")
							AllIDs = {}
							table.insert(AllIDs, actualHour)
						end)
					end
				end
			end
			
			if Possible == true then
				table.insert(AllIDs, ID)
				wait()
				
				local tp_success = pcall(function()
					writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
					wait(0.5)
					game:GetService("TeleportService"):TeleportToPlaceInstance(GAME_ID, ID, game.Players.LocalPlayer)
				end)
				
				if tp_success then
					return true
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
	local max_attempts = 15
	local hopSuccess = false
	
	while attempts < max_attempts do
		local hop_success = pcall(function()
			if TPReturner() then
				print("Server hop initiated successfully")
				hopSuccess = true
				return
			end
		end)
		
		if hopSuccess then
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
		
		-- Attempt to rejoin the current game with retries
		local rejoin_attempts = 0
		local max_rejoin_attempts = 5
		local rejoin_success = false
		
		while rejoin_attempts < max_rejoin_attempts and not rejoin_success do
			timerLabel.Text = "Rejoin attempt... (" .. rejoin_attempts + 1 .. "/" .. max_rejoin_attempts .. ")"
			
			local rejoin_result = pcall(function()
				game:GetService("TeleportService"):Teleport(GAME_ID, game.Players.LocalPlayer)
			end)
			
			if rejoin_result then
				print("Rejoin initiated")
				rejoin_success = true
				break
			else
				warn("Rejoin failed (Error 772), retrying...")
				rejoin_attempts = rejoin_attempts + 1
				if rejoin_attempts < max_rejoin_attempts then
					timerLabel.Text = "Retrying rejoin... (" .. rejoin_attempts .. "/" .. max_rejoin_attempts .. ")"
					wait(3)
				end
			end
		end
		
		if not rejoin_success then
			timerLabel.Text = "Rejoin failed - manual intervention needed"
			wait(2)
		end
	end
	
	return hopSuccess
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

-- Beli Tracker Section
local beliTrackerActive = true
local totalEarned = 0
local webhookUrl = ""
local trackingTimer = 0
local lastKnownBeli = 0
local earnedSinceLast = 0

-- Expand main frame to accommodate beli tracker
mainFrame.Size = UDim2.new(0, 250, 0, 230)

-- Divider
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(1, 0, 0, 2)
divider.Position = UDim2.new(0, 0, 0, 135)
divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
divider.BorderSizePixel = 0
divider.Parent = mainFrame

-- Beli Tracker Title
local beliTitle = Instance.new("TextLabel")
beliTitle.Name = "BeliTitle"
beliTitle.Size = UDim2.new(1, 0, 0, 20)
beliTitle.Position = UDim2.new(0, 0, 0, 140)
beliTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
beliTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
beliTitle.TextSize = 12
beliTitle.Text = "Beli Tracker"
beliTitle.BorderSizePixel = 0
beliTitle.Parent = mainFrame

-- Webhook URL Input
local webhookInputLabel = Instance.new("TextLabel")
webhookInputLabel.Name = "WebhookLabel"
webhookInputLabel.Size = UDim2.new(1, 0, 0, 15)
webhookInputLabel.Position = UDim2.new(0, 5, 0, 165)
webhookInputLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
webhookInputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
webhookInputLabel.TextSize = 10
webhookInputLabel.Text = "Webhook URL:"
webhookInputLabel.BorderSizePixel = 0
webhookInputLabel.TextXAlignment = Enum.TextXAlignment.Left
webhookInputLabel.Parent = mainFrame

local webhookInput = Instance.new("TextBox")
webhookInput.Name = "WebhookInput"
webhookInput.Size = UDim2.new(1, -10, 0, 20)
webhookInput.Position = UDim2.new(0, 5, 0, 182)
webhookInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
webhookInput.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookInput.TextSize = 10
webhookInput.Text = "https://discord.com/api/webhooks/1461353952384913641/wCO45Ykl6u14CsEjyn1s1Sjrx4i1W0g5V27RasctRzgjHxe_l-_1tpMLrCdWiUXlae6D"
webhookInput.BorderSizePixel = 1
webhookInput.BorderColor3 = Color3.fromRGB(100, 100, 100)
webhookInput.ClearTextOnFocus = false
webhookInput.Parent = mainFrame

-- Tracker Status Label
local trackerStatusLabel = Instance.new("TextLabel")
trackerStatusLabel.Name = "TrackerStatus"
trackerStatusLabel.Size = UDim2.new(1, 0, 0, 15)
trackerStatusLabel.Position = UDim2.new(0, 5, 0, 205)
trackerStatusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
trackerStatusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
trackerStatusLabel.TextSize = 10
trackerStatusLabel.Text = "Status: Tracking..."
trackerStatusLabel.BorderSizePixel = 0
trackerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
trackerStatusLabel.Parent = mainFrame

local function getBeliFromGui()
	-- Try to find total Beli in PlayerGui (the persistent money display)
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Search for the money label that shows your total beli
	for _, child in pairs(playerGui:GetDescendants()) do
		if child and child:IsA("TextLabel") then
			local success, text = pcall(function() return child.Text end)
			if not success or not text then continue end
			
			-- Remove HTML/font tags to get clean text
			local cleanText = text:gsub("<[^>]+>", "")
			
			-- Look for just "$XXXX" format (the total beli display)
			-- This pattern matches a $ followed by numbers with optional commas
			local number = cleanText:match("^%$%s*([%d,]+)$")
			
			if number then
				number = number:gsub(",", "")
				local beli = tonumber(number)
				if beli and beli > 100000 then  -- Only accept reasonable amounts
					return beli
				end
			end
		end
	end
	
	return 0
end

local function getEarnedFromGui()
	-- Try to find Earned money in PlayerGui
	local playerGui = player:WaitForChild("PlayerGui")
	
	local highestEarned = 0
	
	-- Search all descendants for "Earned $" text
	for _, child in pairs(playerGui:GetDescendants()) do
		-- Safety check: make sure child still exists
		if child and child:IsA("TextLabel") then
			local success, text = pcall(function() return child.Text end)
			if not success or not text then continue end
			
			-- Remove HTML/font tags to get clean text
			local cleanText = text:gsub("<[^>]+>", "")
			
			-- Try multiple patterns to find earned amounts
			local number = nil
			
			-- Pattern 1: "Earned $XXXX"
			number = cleanText:match("[Ee]arned%s+%$%s*([%d,]+)")
			
			-- Pattern 2: "Earned$XXXX" (no space)
			if not number then
				number = cleanText:match("[Ee]arned%$([%d,]+)")
			end
			
			if number then
				number = number:gsub(",", "")
				local earned = tonumber(number)
				if earned and earned > 0 then
					-- Get the highest earned amount (in case there are multiple)
					if earned > highestEarned then
						highestEarned = earned
						print("Tracking earned: $" .. earned)
					end
				end
			end
		end
	end
	
	if highestEarned > 0 then
		return highestEarned
	end
	
	return 0
end

local function sendWebhook(message)
	if webhookUrl == "" or webhookUrl:find("YOUR_ID") then
		print("Webhook URL not set or invalid")
		return false
	end
	
	print("Attempting to send webhook to: " .. webhookUrl:sub(1, 50) .. "...")
	
	local payload = {
		content = message,
		username = "Beli Tracker"
	}
	
	local jsonPayload = HttpService:JSONEncode(payload)
	
	local success, response = pcall(function()
		HttpService:PostAsync(webhookUrl, jsonPayload, Enum.HttpContentType.ApplicationJson)
		return true
	end)
	
	if success and response == true then
		print("Webhook sent successfully!")
		return true
	else
		print("Webhook error: " .. tostring(response))
		return false
	end
end

local function beliTracker()
	wait(1) -- Give GUI time to load
	lastKnownBeli = getBeliFromGui()
	totalEarned = 0
	trackingTimer = 10
	
	trackerStatusLabel.Text = "Status: Tracking (Total: $0)"
	
	while beliTrackerActive do
		wait(1)
		trackingTimer = trackingTimer - 1
		
		local currentBeli = getBeliFromGui()
		
		-- Calculate earnings (difference from last check)
		if currentBeli > lastKnownBeli then
			earnedSinceLast = currentBeli - lastKnownBeli
			totalEarned = totalEarned + earnedSinceLast
			print("Earned: $" .. earnedSinceLast .. " | Total this cycle: $" .. totalEarned)
			lastKnownBeli = currentBeli
		end
		
		trackerStatusLabel.Text = "Status: Tracking (Total: $" .. tostring(totalEarned) .. ")"
		
		-- Send webhook every 10 seconds OR if reached 50k earned
		if trackingTimer <= 0 or totalEarned >= 50000 then
			if totalEarned > 0 then
				local webhookMessage = "💰 **Earnings Report!** 💰\nTotal Earned: **$" .. tostring(totalEarned) .. "**"
				
				webhookUrl = webhookInput.Text
				print("Webhook URL from input: " .. webhookUrl)
				
				if sendWebhook(webhookMessage) then
					print("Webhook sent - Earned: $" .. tostring(totalEarned))
				else
					print("Failed to send webhook")
				end
			end
			
			-- Reset for next cycle
			totalEarned = 0
			trackingTimer = 10
		end
	end
	
	trackerStatusLabel.Text = "Status: Stopped"
end

-- Start tracker automatically
task.spawn(beliTracker)

-- Fixed Timer Loop with 3-attempt cycle (50s, 30s, 10s)
task.spawn(function()
	local attemptCount = 0
	local timers = {50, 30, 10} -- Timer durations for each attempt

	while fixedTimerActive do
		if fixedTimeRemaining > 0 then
			local minutes = math.floor(fixedTimeRemaining / 60)
			local seconds = fixedTimeRemaining % 60
			
			if not hopActive then
				timerLabel.Text = string.format("Attempt %d - Timer: %d:%02d", attemptCount + 1, minutes, seconds)
			end
			
			fixedTimeRemaining = fixedTimeRemaining - 1
			wait(1)
		else
			-- Timer finished - attempt server hop
			hopActive = true
			local hopSuccess = hopServer()
			hopActive = false
			
			if hopSuccess then
				-- Server hop successful, reset cycle
				attemptCount = 0
				fixedTimeRemaining = timers[1]
				timerLabel.Text = "Ready"
			else
				-- Server hop failed, move to next attempt
				attemptCount = attemptCount + 1
				
				if attemptCount < #timers then
					-- Set timer for next attempt
					fixedTimeRemaining = timers[attemptCount + 1]
					timerLabel.Text = "Ready"
				else
					-- All 3 attempts failed, reset cycle
					attemptCount = 0
					fixedTimeRemaining = timers[1]
					timerLabel.Text = "Cycle complete - restarting"
					wait(2)
					timerLabel.Text = "Ready"
				end
			end
			
			wait(1)
		end
	end
end)

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

-- Start Tracker button clicked
startTrackerButton.MouseButton1Click:Connect(function()
	webhookUrl = webhookInput.Text
	
	if webhookUrl == "" or webhookUrl:find("YOUR_ID") then
		trackerStatusLabel.Text = "Status: Invalid webhook URL"
		wait(2)
		trackerStatusLabel.Text = "Status: Tracking..."
		return
	end
	
	beliTrackerActive = true
	webhookInput.Visible = false
	webhookInputLabel.Visible = false
	startTrackerButton.Size = UDim2.new(0, 0, 0, 25)
	startTrackerButton.Visible = false
	stopTrackerButton.Size = UDim2.new(1, -10, 0, 25)
	stopTrackerButton.Visible = true
	
	task.spawn(beliTracker)
end)

-- Stop Tracker button clicked
stopTrackerButton.MouseButton1Click:Connect(function()
	beliTrackerActive = false
	stopTrackerButton.Visible = false
	startTrackerButton.Size = UDim2.new(1, -10, 0, 25)
	startTrackerButton.Visible = true
	webhookInput.Visible = true
	webhookInputLabel.Visible = true
	trackerStatusLabel.Text = "Status: Idle"
end)
