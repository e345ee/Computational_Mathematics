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
local defaultStartY = 0.25
local resultStartY = 0.85 
local buttonConns  = {}

local userInput = {
	n = nil,
	A = {},
	b = {},
	epsilon = nil
}

local inputStage = 0
local matrixRow = 1
local matrixCol = 1
local vectorIndex = 1
local inputMode = "manual"



local function clearButtonConns()
	for i, c in ipairs(buttonConns) do
		if c then c:Disconnect() end
		buttonConns[i] = nil
	end
end

local function resetState()
	userInput = {n=nil, A={}, b={}, epsilon=nil}
	inputStage = 0
	matrixRow, matrixCol, vectorIndex = 1, 1, 1

	for _, child in ipairs(surfaceGui:GetChildren()) do
		if child.Name == "InputFrame" then
			child:Destroy()
		end
	end

	clearButtonConns()
	questionLabel.Text = ""
	for _, b in ipairs(buttons) do
		b.Visible = false
	end

	nextStep()
end

local function calculateNorm(A)
	local maxRowSum = 0
	for i = 1, #A do
		local rowSum = 0
		for j = 1, #A[i] do
			rowSum = rowSum + math.abs(A[i][j])
		end
		if rowSum > maxRowSum then maxRowSum = rowSum end
	end
	return maxRowSum
end

local function transformAnswerOrder(x, order)
	local orderedX = {}
	for i = 1, #order do
		orderedX[order[i] + 1] = x[i]
	end
	return orderedX
end

local function isDiagonallyDominant(A)
	local n = #A
	if n == 1 then return true end
	local strict = false
	for i = 1, n do
		local diag = math.abs(A[i][i])
		local rowSum = 0
		for j = 1, n do
			if j ~= i then rowSum += math.abs(A[i][j]) end
		end
		if diag < rowSum then return false end
		if not strict and diag > rowSum then strict = true end
	end
	return strict
end

local function swapColumns(order, A, i, j)
	order[i+1], order[j+1] = order[j+1], order[i+1]
	for r = 1, #A do
		A[r][i+1], A[r][j+1] = A[r][j+1], A[r][i+1]
	end
end

local function makeDiagonallyDominant(A)
	local order = {}
	for i = 1, #A do order[i] = i - 1 end

	for rowIndex = 1, #A do
		local maxVal, maxIdx = -math.huge, nil
		for i = 1, #A[rowIndex] do
			if math.abs(A[rowIndex][i]) > maxVal then
				maxVal = math.abs(A[rowIndex][i])
				maxIdx = i - 1
			end
		end
		if maxIdx == nil then return nil end
		swapColumns(order, A, rowIndex - 1, maxIdx)
	end

	if isDiagonallyDominant(A) then
		return order, A
	end
	return nil
end

local function showOptions(options, callback, yOffset)
	clearButtonConns()
	for i, btn in ipairs(buttons) do
		local opt = options[i]
		if opt then
			btn.Text       = opt.text
			btn.Visible    = true
			btn.TextScaled = true
			btn.Size       = UDim2.new(0.9,0,buttonHeight,0)
			local y = yOffset or startY 
			btn.Position = UDim2.new(0.05,0, y + (buttonHeight+spacing)*(i-1), 0)
			btn.BackgroundColor3 = Color3.new(1,1,1)
			buttonConns[i] = btn.MouseButton1Click:Connect(function()
				callback(opt.value)
			end)
		else
			btn.Visible = false
		end
	end
end

local function showRepeatPrompt()
	clearButtonConns()

	questionLabel.Text = questionLabel.Text .. "\nПовторить?"

	
	local yesBtn = buttons[1]
	yesBtn.Text = "Да"
	yesBtn.Visible = true
	yesBtn.TextScaled = true
	yesBtn.Size = UDim2.new(0.4, 0, buttonHeight, 0)
	yesBtn.Position = UDim2.new(0.05, 0, startY, 0)
	buttonConns[1] = yesBtn.MouseButton1Click:Connect(function()
		startY = defaultStartY
		questionLabel.Size = UDim2.new(0.9, 0, 0.2, 0)

		
		for i, b in ipairs(buttons) do
			b.Position = UDim2.new(0.05, 0, defaultStartY + (buttonHeight + spacing) * (i - 1), 0)
			b.Size = UDim2.new(0.9, 0, buttonHeight, 0)
		end

		resetState()
	end)

	
	local noBtn = buttons[2]
	noBtn.Text = "Нет"
	noBtn.Visible = true
	noBtn.TextScaled = true
	noBtn.Size = UDim2.new(0.4, 0, buttonHeight, 0)
	noBtn.Position = UDim2.new(0.55, 0, startY, 0)
	buttonConns[2] = noBtn.MouseButton1Click:Connect(function()
		questionLabel.Text = "Завершено."
		for _, b in ipairs(buttons) do b.Visible = false end
	end)

	
	for i = 3, #buttons do
		buttons[i].Visible = false
	end
end





local function promptNumberInput(promptText, onConfirm)
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
				local num = tonumber(current)
				if num then
					print(promptText, num)
					frame:Destroy()
					onConfirm(num)
				else
					display.Text = "Ошибка!"
				end
			else
				current = current .. key
			end
			display.Text = current
		end)
	end
end



local function gaussSeidel(A, b, epsilon, maxIter)
	local n = #A
	local order, newA = makeDiagonallyDominant(table.clone(A))
	if not order then
		return false, "Невозможно привести матрицу к диагональному преобладанию"
	end
	A = newA

	local x, xOld = {}, {}
	for i = 1, n do x[i], xOld[i] = 0, 0 end

	for iter = 1, maxIter do
		for i = 1, n do xOld[i] = x[i] end

		for i = 1, n do
			local sumNew, sumOld = 0, 0
			for j = 1, i - 1 do sumNew += A[i][j] * x[j] end
			for j = i + 1, n do sumOld += A[i][j] * xOld[j] end
			x[i] = (b[i] - sumNew - sumOld) / A[i][i]
		end

		local eVector, maxDiff = {}, 0
		for i = 1, n do
			local diff = math.abs(x[i] - xOld[i])
			eVector[i] = diff
			if diff > maxDiff then maxDiff = diff end
		end

		if maxDiff < epsilon then
			local norm = calculateNorm(A)
			return true, transformAnswerOrder(x, order), iter, eVector, norm
		end
	end

	return false, "Метод не сошелся за заданное количество итераций"
end

local function loadMatrixFromText(text)
	local lines = text:split("\n")
	local header = lines[1]:split(" ")
	local n = tonumber(header[1])
	local epsilon = tonumber(header[2])

	if not n or not epsilon or n <= 0 or n > 20 or epsilon <= 0 then
		questionLabel.Text = "Ошибка в первой строке файла"
		return
	end

	local A, b = {}, {}

	for i = 1, n do
		local line = lines[i+1]
		if not line then
			questionLabel.Text = "Ошибка: недостаточно строк"
			return
		end

		local values = line:split(" ")
		if #values ~= n + 1 then
			questionLabel.Text = "Ошибка в строке " .. tostring(i+1)
			return
		end

		A[i] = {}
		for j = 1, n do
			A[i][j] = tonumber(values[j])
			if not A[i][j] then
				questionLabel.Text = "Ошибка: не число в строке " .. tostring(i+1)
				return
			end
		end
		b[i] = tonumber(values[n+1])
	end

	userInput.n = n
	userInput.epsilon = epsilon
	userInput.A = A
	userInput.b = b
	inputStage = 5
	nextStep()
end


function nextStep()
	clearButtonConns()
	if inputStage == 0 then
		questionLabel.Text = "Откуда вводить матрицу?"
		showOptions({
			{text = "Ввести вручную", value = "manual"},
			{text = "Загрузить из файла", value = "file"},
		}, function(choice)
			inputMode = choice
			if inputMode == "file" then
				local fileValue = surfaceGui:FindFirstChild("MatrixFileData")
				if not fileValue then
					questionLabel.Text = "MatrixFileData не найден"
					return
				end

				local text = fileValue.Value
				loadMatrixFromText(text)
				return
			end

			inputStage = 1
			nextStep()
		end)
	elseif inputStage == 1 then
		questionLabel.Text = "Введите размерность матрицы (n <= 20):"
		promptNumberInput(questionLabel.Text, function(n)
			if n <= 0 or n > 20 then
				questionLabel.Text = "Ошибка! n должно быть от 1 до 20"
				task.wait(2)
				nextStep()
				return
			end
			userInput.n = n
			inputStage = 2
			nextStep()
		end)
	elseif inputStage == 2 then
		questionLabel.Text = string.format("Введите A[%d][%d]:", matrixRow, matrixCol)
		promptNumberInput(questionLabel.Text, function(val)
			userInput.A[matrixRow] = userInput.A[matrixRow] or {}
			userInput.A[matrixRow][matrixCol] = val
			matrixCol += 1
			if matrixCol > userInput.n then
				matrixCol = 1
				matrixRow += 1
			end
			if matrixRow > userInput.n then
				inputStage = 3
			end
			nextStep()
		end)
	elseif inputStage == 3 then
		questionLabel.Text = string.format("Введите b[%d]:", vectorIndex)
		promptNumberInput(questionLabel.Text, function(val)
			userInput.b[vectorIndex] = val
			vectorIndex += 1
			if vectorIndex > userInput.n then
				inputStage = 4
			end
			nextStep()
		end)
	elseif inputStage == 4 then
		questionLabel.Text = "Введите точность (ε > 0):"
		promptNumberInput(questionLabel.Text, function(val)
			if val <= 0 then
				questionLabel.Text = "Ошибка: ε должно быть положительным"
				task.wait(2)
				nextStep()
				return
			end
			userInput.epsilon = val
			inputStage = 5
			nextStep()
		end)
	elseif inputStage == 5 then
		local success, solution, iters, errors, norm = gaussSeidel(userInput.A, userInput.b, userInput.epsilon, 1000)
		if success then
			local str = "Диагональное преобладание: достигнуто\n"
			str = str .. string.format("Норма матрицы: %.15f\n", norm)
			str = str .. string.format("Решение найдено за %d итераций:\n", iters)
			for i, v in ipairs(solution) do
				str = str .. string.format("x[%d] = %.15f\n", i, v)
			end
			str = str .. "Вектор погрешностей:\n"
			for i, err in ipairs(errors) do
				str = str .. string.format("|Δx[%d]| = %.15f\n", i, err)
			end
			questionLabel.Size = UDim2.new(0.9, 0, 0.85, 0)
			questionLabel.Text = str
			startY = resultStartY
			showRepeatPrompt()
		else
			questionLabel.Text = "Ошибка: " .. solution
			task.delay(10, showRepeatPrompt)
		end
	end
end





questionLabel.Size = UDim2.new(0.9,0,0.2,0)
questionLabel.Position = UDim2.new(0.05,0,0.05,0)
questionLabel.TextScaled = true
questionLabel.TextWrapped = true


nextStep()
