-- PatchService.lua
-- A utility class to manage and apply version patches to software or systems dynamically.

local PatchService = {}
PatchService.__index = PatchService

-- Constructor for creating a new PatchService object.
-- @param initialVersion (number, optional): The starting version of the software from which patches will be applied. Defaults to 0 if not provided.
function PatchService.new(initialVersion)
    return setmetatable({
        patches = {}, -- Table to store version patch functions.
        currentVersion = initialVersion or 0, -- Current software version.
    }, PatchService)
end

-- Adds a patch function to be applied for a specific version.
-- @param version (number): The version number this patch should apply to. Must be greater than the current version.
-- @param patchFunction (function): A function that encapsulates the changes to apply in the patch.
function PatchService:addPatch(version, patchFunction)
    assert(type(patchFunction) == "function", "Patch function must be a function")
    assert(version > self.currentVersion, "Patch version must be greater than current version")
    self.patches[version] = patchFunction
end

-- Applies all applicable patches in order of their version number.
function PatchService:applyPatches()
    local sortedVersions = self:getSortedVersions()
    
    for _, version in ipairs(sortedVersions) do
        if version > self.currentVersion then
            self:tryApplyPatch(version)
        end
    end
end

-- Adds and immediately attempts to apply a patch if it is applicable.
-- @param version (number): The version number this patch should apply to. Must be greater than the current version.
-- @param patchFunction (function): A function that encapsulates the changes to apply in the patch.
function PatchService:patch(version, patchFunction)
    self:addPatch(version, patchFunction)
    if version > self.currentVersion then
        self:tryApplyPatch(version)
    end
end

-- Attempts to apply a single patch. If the patch is applied successfully, updates the current version.
-- @param version (number): The version number of the patch to apply.
function PatchService:tryApplyPatch(version)
    local success, err = pcall(self.patches[version])
    if success then
        self.currentVersion = version
        print("Patch applied for version:", version)
    else
        error("Failed to apply patch for version " .. version .. ": " .. err)
    end
end

-- Retrieves a sorted list of versions that have patches.
-- @return (table): A table of version numbers sorted in ascending order.
function PatchService:getSortedVersions()
    local versions = {}
    for version in pairs(self.patches) do
        table.insert(versions, version)
    end
    table.sort(versions)
    return versions
end

-- Returns the current version of the software after patches have been applied.
-- @return (number): The current software version.
function PatchService:getCurrentVersion()
    return self.currentVersion
end

return PatchService
