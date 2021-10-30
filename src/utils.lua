local function splitText(text, splitAt, onLinebreak)
	local slices = {}

	if onLinebreak then
		local index = 1

		while #text - index + 1 > splitAt do
			local slice = text:sub(index, index + splitAt - 1):reverse()
			local slice = slice:sub(slice:find("\n") + 1):reverse()
			slices[#slices + 1] = slice

			index = index + #slice + 1
		end

		if #text - index > 0 then
			slices[#slices + 1] = text:sub(index)
		end
	else
		for index = 1, #text, splitAt do
			slices[#slices + 1] = text:sub(index, index + splitAt - 1)
		end
	end

	return slices
end

return {
	splitText = splitText,
}