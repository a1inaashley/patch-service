local PatchService = require(script.Parent.ModuleScript)

local testCases = {
	{
		name = "Basic functionality test",
		patches = {
			{ version = 1, patchFunction = function() print("Patch 1 applied") end },
			{ version = 2, patchFunction = function() print("Patch 2 applied") end },
			{ version = 3, patchFunction = function() print("Patch 3 applied") end },
		},
		expectedVersion = 3,
	},

	{
		name = "Test with dependencies",
		patches = {
			{ version = 1, patchFunction = function() print("Patch 1 applied") end },
			{ version = 2, patchFunction = function() print("Patch 2 applied") end, dependencies = { 1 } },
			{ version = 3, patchFunction = function() print("Patch 3 applied") end, dependencies = { 2 } },
		},
		expectedVersion = 3,
	},

	{
		name = "Test with failed patch and rollback",
		patches = {
			{ version = 1, patchFunction = function() print("Patch 1 applied") end },
			{ version = 2, patchFunction = function() error("Failed to apply patch 2") end },
			{ version = 3, patchFunction = function() print("Patch 3 applied") end },
		},
		expectedVersion = 1, -- Expected version after rollback
	},

	{
		name = "Test with cyclic dependencies",
		patches = {
			{ version = 1, patchFunction = function() print("Patch 1 applied") end, dependencies = { 3 } },
			{ version = 2, patchFunction = function() print("Patch 2 applied") end, dependencies = { 1 } },
			{ version = 3, patchFunction = function() print("Patch 3 applied") end, dependencies = { 2 } },
		},
		expectedVersion = 3,
	},

	{
		name = "Test with random patches and dependencies",
		generatePatches = function()
			local patches = {}
			for i = 1, 10 do
				local version = math.random(1, 20)
				local dependencies = {}
				for j = 1, math.random(0, 5) do
					table.insert(dependencies, math.random(1, version - 1))
				end
				table.insert(patches, { version = version, patchFunction = function() print("Patch " .. version .. " applied") end, dependencies = dependencies })
			end
			return patches
		end,
	},
}

for _, testCase in ipairs(testCases) do
	print("Running test case:", testCase.name)
	local patchService = PatchService.new()

	local patches = testCase.patches
	if testCase.generatePatches then
		patches = testCase.generatePatches()
	end

	for _, patch in ipairs(patches) do
		patchService:addPatch(patch.version, patch.patchFunction, nil, patch.dependencies)
	end

	local success, err = pcall(patchService.patch, patchService)

	if success then
		local latestVersion = patchService:getLatestVersion()
		if latestVersion == testCase.expectedVersion then
			print("Test Passed: Current version is as expected:", latestVersion)
		else
			print("Test Failed: Current version mismatch. Expected:", testCase.expectedVersion, "Actual:", latestVersion)
		end
	else
		print("Test Failed: Error occurred while applying patches:", err)
	end

	print("---------------------------------------")
end
