
if core.get_modpath("default") then
	for _, tool in ipairs({"sword", "pick", "axe", "shovel"}) do
		for _, material in ipairs({"wood", "stone", "steel", "bronze", "mese", "diamond"}) do
			toolranks.add_tool("default:" .. tool .. "_" .. material)
		end
	end
end

if core.get_modpath("mcl_tools") then
	for _, tool in ipairs({"sword", "pick", "axe", "shovel"}) do
		for _, material in ipairs({"wood", "stone", "iron", "gold", "netherite", "diamond"}) do
			toolranks.add_tool("mcl_tools:" .. tool .. "_" .. material)
		end
	end

	-- shears
	toolranks.add_tool("mcl_tools:shears")
end
