local statsGui = workspace:WaitForChild("StatsBoard"):WaitForChild("SurfaceGui")
local statsLabel = statsGui:WaitForChild("StatsLabel")

statsLabel.Text = ""

statsLabel.Size = UDim2.new(1, 0, 1, 0)
statsLabel.TextScaled = false
statsLabel.TextSize = 60
statsLabel.TextWrapped = true
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.TextXAlignment = Enum.TextXAlignment.Center
statsLabel.TextYAlignment = Enum.TextYAlignment.Center
