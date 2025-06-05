local RectangleType = {
	LEFT   = 1,
	MIDDLE = 2,
	RIGHT  = 3,
}


local resetState 

local function hasConverged(I_old, I_new, order, tolerance)
	return math.abs(I_new - I_old) / (2^order - 1) < tolerance
end


local function integrateRect(fx, startX, endX, tol, mode, maxSteps)
	maxSteps = maxSteps or 1e6
	local intervals = 4

	local function estimate(n)
		local step = (endX - startX) / n
		local offset = (mode == RectangleType.LEFT and 0)
			or (mode == RectangleType.CENTER and step / 2)
			or (mode == RectangleType.RIGHT and step)

		local area = 0
		for j = 0, n - 1 do
			area = area + fx(startX + offset + j * step)
		end
		return area * step
	end

	local result_prev = estimate(intervals)
	intervals = intervals * 2

	while true do
		local result_next = estimate(intervals)
		if hasConverged(result_prev, result_next, 2, tol) then
			return result_next, intervals
		end
		if intervals >= maxSteps then
			error("integrateRect: превышено число шагов (" .. maxSteps .. ")")
		end
		result_prev = result_next
		intervals = intervals * 2
	end
end


local function trapezoidMethod(fx, startX, endX, tol, maxSteps)
	maxSteps = maxSteps or 1e6
	local parts = 4

	local function trapArea(n)
		local step = (endX - startX) / n
		local total = 0.5 * (fx(startX) + fx(endX))
		for i = 1, n - 1 do
			total = total + fx(startX + i * step)
		end
		return total * step
	end

	local prevApprox = trapArea(parts)
	parts = parts * 2
	local nextApprox = trapArea(parts)

	while true do
		if hasConverged(prevApprox, nextApprox, 2, tol) then
			return nextApprox, parts
		end
		if parts >= maxSteps then
			error("integrateTrap: не достигнута сходимость за " .. maxSteps .. " итераций")
		end
		prevApprox = nextApprox
		parts = parts * 2
		nextApprox = trapArea(parts)
	end
end

local function simpsonMethod(fx, startX, endX, tol, maxSteps)
	maxSteps = maxSteps or 1e6
	local count = 4

	local function simpsonArea(n)
		local step = (endX - startX) / n
		local sum = fx(startX) + fx(endX)
		for i = 1, n - 1 do
			local multiplier = (i % 2 == 0) and 2 or 4
			sum = sum + multiplier * fx(startX + i * step)
		end
		return sum * step / 3
	end

	local estimate_old = simpsonArea(count)
	count = count * 2
	local estimate_new = simpsonArea(count)

	while true do
		if hasConverged(estimate_old, estimate_new, 4, tol) then
			return estimate_new, count
		end
		if count >= maxSteps then
			error("integrateSimpson: достигнут лимит итераций (" .. maxSteps .. ")")
		end
		estimate_old = estimate_new
		count = count * 2
		estimate_new = simpsonArea(count)
	end
end


local surfaceGui    = script.Parent
local questionLabel = surfaceGui:WaitForChild("QuestionLabel")

local buttons = {
	surfaceGui:WaitForChild("Option1"),
	surfaceGui:WaitForChild("Option2"),
	surfaceGui:WaitForChild("Option3"),
	surfaceGui:WaitForChild("Option4"),
	surfaceGui:WaitForChild("Option5")
}

local buttonHeight = 0.1
local spacing      = 0.015
local startY       = 0.25

local functionsList = {
	{ text = "f(x) = x^2 - 0.6",            func = function(x) return x^2 - 0.6 end },
	{ text = "f(x) = x^3 - 3x + 2",         func = function(x) return x^3 - 3*x + 2 end },
	{ text = "f(x) = 2^x - 3",              func = function(x) return 2^x - 3 end },
	{ text = "f(x) = 2x^3 - 2x^2 + 7x -14", func = function(x) return 2*x^3 - 2*x^2 + 7*x -14 end },
}

local methodsList = {
	{ text = "Левые прямоугольники" },
	{ text = "Правые прямоугольники" },
	{ text = "Средние прямоугольники" },
	{ text = "Метод трапеций" },
	{ text = "Метод Симпсона" },
}

local userAnswers = {
	selectedFunction = nil,
	selectedMethod   = nil,
	lowerLimit       = nil,
	upperLimit       = nil,
	epsilon          = nil,
}

local inputStage = 1
local buttonConns = {}

local function clearButtonConns()
	for i, c in ipairs(buttonConns) do
		if c then c:Disconnect() end
		buttonConns[i] = nil
	end
end

local function showOptions(options, callback)
	clearButtonConns()
	for i, btn in ipairs(buttons) do
		local opt = options[i]
		if opt then
			btn.Text       = opt.text
			btn.Visible    = true
			btn.TextScaled = true
			btn.Size       = UDim2.new(0.9,0,buttonHeight,0)
			btn.Position   = UDim2.new(0.05,0, startY + (buttonHeight+spacing)*(i-1), 0)
			btn.BackgroundColor3 = Color3.new(1,1,1)
			buttonConns[i] = btn.MouseButton1Click:Connect(function()
				callback(opt)
			end)
		else
			btn.Visible = false
		end
	end
end

local function promptNumberInputWithButtons(promptText, onConfirm)
	clearButtonConns()
	for _, b in ipairs(buttons) do b.Visible = false end
	for _, c in ipairs(surfaceGui:GetChildren()) do
		if c.Name == "InputFrame" then c:Destroy() end
	end

	local frame = Instance.new("Frame", surfaceGui)
	frame.Name = "InputFrame"
	frame.Size = UDim2.new(0.9,0,0.5,0)
	frame.Position = UDim2.new(0.05,0,0.3,0)
	frame.BackgroundTransparency = 1

	local display = Instance.new("TextLabel", frame)
	display.Size = UDim2.new(1,0,0.2,0)
	display.Position = UDim2.new(0,0,0,0)
	display.TextScaled = true
	display.BackgroundColor3 = Color3.fromRGB(230,230,230)
	display.TextColor3 = Color3.new(0,0,0)
	display.Text = ""

	local current = ""
	local keys = {"1","2","3","4","5","6","7","8","9","-","0",".","←","Сохранить"}
	for idx, key in ipairs(keys) do
		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(0.3,0,0.15,0)
		local row = math.floor((idx-1)/3)
		local col = (idx-1)%3
		btn.Position = UDim2.new(0.01+0.33*col,0, 0.25+0.17*row, 0)
		btn.TextScaled = true
		btn.Text = key
		btn.BackgroundColor3 = Color3.new(1,1,1)
		btn.TextColor3 = Color3.new(0,0,0)
		btn.MouseButton1Click:Connect(function()
			if key == "←" then
				current = current:sub(1,-2)
			elseif key == "Сохранить" then
				local clean = tostring(current):gsub(",", "."):gsub("%s", "")
				local num = tonumber(clean)
				if num then
					frame:Destroy()
					onConfirm(num)
				else
					current = ""
					display.Text = "Ошибка!"
				end
			else
				current = current .. key
			end
			display.Text = current
		end)
	end
end

local function nextStep()
	clearButtonConns()
	if inputStage == 1 then
		questionLabel.Text = "Выберите функцию:"
		showOptions(functionsList, function(opt)
			userAnswers.selectedFunction = opt.text
			print("Выбрана функция:", opt.text)
			inputStage = 2
			nextStep()
		end)
	elseif inputStage == 2 then
		questionLabel.Text = "Выберите метод:"
		showOptions(methodsList, function(opt)
			userAnswers.selectedMethod = opt.text
			print("Выбран метод:", opt.text)
			inputStage = 3
			nextStep()
		end)
	elseif inputStage == 3 then
		questionLabel.Text = "Введите нижний предел (a):"
		promptNumberInputWithButtons(questionLabel.Text, function(val)
			userAnswers.lowerLimit = val
			print("Введён a:", val)
			inputStage = 4
			nextStep()
		end)
	elseif inputStage == 4 then
		questionLabel.Text = "Введите верхний предел (b):"
		promptNumberInputWithButtons(questionLabel.Text, function(val)
			if val <= userAnswers.lowerLimit then
				questionLabel.Text = "Ошибка: b должно быть больше a!"
				task.wait(2)
				nextStep()
				return
			end
			userAnswers.upperLimit = val
			print("Введён b:", val)
			inputStage = 5
			nextStep()
		end)
	elseif inputStage == 5 then
		questionLabel.Text = "Введите точность (ε):"
		promptNumberInputWithButtons(questionLabel.Text, function(val)
			if val <= 0 then
				questionLabel.Text = "Ошибка: ε должно быть > 0!"
				task.wait(2)
				nextStep()
				return
			end
			userAnswers.epsilon = val
			print("Введено ε:", val)
			inputStage = 6
			nextStep()
		end)
	elseif inputStage == 6 then
		for _, b in ipairs(buttons) do b.Visible = false end
		local a, b_, eps = userAnswers.lowerLimit, userAnswers.upperLimit, userAnswers.epsilon
		local f
		for _, v in ipairs(functionsList) do
			if v.text == userAnswers.selectedFunction then
				f = v.func break
			end
		end
		local success, resultOrError, finalN = pcall(function()
			if userAnswers.selectedMethod == "Левые прямоугольники" then
				return integrateRect(f, a, b_, eps, RectangleType.LEFT)
			elseif userAnswers.selectedMethod == "Правые прямоугольники" then
				return integrateRect(f, a, b_, eps, RectangleType.RIGHT)
			elseif userAnswers.selectedMethod == "Средние прямоугольники" then
				return integrateRect(f, a, b_, eps, RectangleType.MIDDLE)
			elseif userAnswers.selectedMethod == "Метод трапеций" then
				return trapezoidMethod(f, a, b_, eps)
			else
				return simpsonMethod(f, a, b_, eps)
			end
		end)
		if success then
			local result, n = resultOrError, finalN
			questionLabel.Text = string.format("Интеграл = %.6f\nРазбиений = %d\n\nХотите повторить?", result, n)
		else
			questionLabel.Text = resultOrError .. "\n\nПовторить?"
			print("Ошибка:", resultOrError)
		end
		inputStage = 7
		task.wait(0.3)
		buttons[1].Text, buttons[1].Visible = "Да", true
		buttons[2].Text, buttons[2].Visible = "Нет", true
		buttons[3].Visible, buttons[4].Visible = false, false
		buttonConns[1] = buttons[1].MouseButton1Click:Connect(function()
			for k in pairs(userAnswers) do userAnswers[k] = nil end
			inputStage = 1
			nextStep()
		end)
		buttonConns[2] = buttons[2].MouseButton1Click:Connect(function()
			surfaceGui.Parent:Destroy()
			surfaceGui:Destroy()
		end)
	end
end

questionLabel.Size = UDim2.new(0.9,0,0.2,0)
questionLabel.Position = UDim2.new(0.05,0,0.05,0)
questionLabel.TextScaled = true
questionLabel.TextWrapped = true

nextStep()
