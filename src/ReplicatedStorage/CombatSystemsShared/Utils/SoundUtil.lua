local module = {}

-- PUBLIC API
function module.play(soundName: string, soundParent: Instance)
	local sound = soundParent:FindFirstChild(soundName) :: Sound?
	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

return module