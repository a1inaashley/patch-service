-- PatchService.lua

local PatchService = {}
PatchService.__index = PatchService

-- Constructor for creating a new PatchService object.
-- @param initialVersion (number, optional): The starting version of the software from which patches will be applied. Defaults to 0 if not provided.
function PatchService.new(initialVersion)
    return setmetatable({
        patches = {}, -- Table to store version patch functions.
        currentVersion = initialVersion or 0, -- Current software version.
        appliedPatches = {}, -- Table to keep track of applied patches.
        rollbackStack = {}, -- Stack to support rollback functionality.
        dependencies = {}, -- Precomputed patch dependencies.
    }, PatchService)
end

-- Adds a patch function to be applied for a specific version.
-- @param version (number): The version number this patch should apply to. Must be greater than the current version.
-- @param patchFunction (function): A function that encapsulates the changes to apply in the patch.
-- @param rollbackFunction (function, optional): A function that undoes the changes made by the patchFunction. Useful for rollback functionality.
-- @param dependencies (table, optional): A table containing the version numbers of patches that must be applied before this patch.
function PatchService:addPatch(version, patchFunction, rollbackFunction, dependencies)
    assert(type(patchFunction) == "function", "Patch function must be a function")
    assert(version > self.currentVersion, "Patch version must be greater than current version")
    if dependencies then
        for _, depVersion in ipairs(dependencies) do
            assert(depVersion <= version, "Dependency version must be less than or equal to patch version")
            assert(self.patches[depVersion], "Dependency patch not found for version " .. depVersion)
        end
    end
    self.patches[version] = { patchFunction = patchFunction, rollbackFunction = rollbackFunction }
    self:computeDependencies() -- Recompute dependencies when a new patch is added
end

-- Computes patch dependencies and stores them in the 'dependencies' table.
function PatchService:computeDependencies()
    self.dependencies = {}
    for version, patchData in pairs(self.patches) do
        local deps = patchData.dependencies
        if deps then
            self.dependencies[version] = {}
            for _, depVersion in ipairs(deps) do
                self.dependencies[version][depVersion] = true
            end
        end
    end
end

-- Applies all applicable patches in order of their version number.
function PatchService:patch()
    local sortedVersions = self:getSortedVersions()
    for _, version in ipairs(sortedVersions) do
        if version > self.currentVersion and not self:hasUnsatisfiedDependencies(version) then
            self:tryApplyPatch(version)
        end
    end
end

-- Checks if a patch has any unsatisfied dependencies.
-- @param version (number): The version number of the patch to check.
-- @return (boolean): True if all dependencies are satisfied, otherwise false.
function PatchService:hasUnsatisfiedDependencies(version)
    local deps = self.dependencies[version]
    if not deps then
        return false
    end
    for depVersion in pairs(deps) do
        if not self.appliedPatches[depVersion] then
            return true
        end
    end
    return false
end

-- Attempts to apply a single patch. If the patch is applied successfully, updates the current version.
-- @param version (number): The version number of the patch to apply.
function PatchService:tryApplyPatch(version)
    local patchData = self.patches[version]
    local success, err = pcall(patchData.patchFunction)
    if success then
        table.insert(self.appliedPatches, version)
        self.currentVersion = version
        print("Patch applied for version:", version)
    else
        self:rollbackAppliedPatches()  -- Rollback all previously applied patches
        error("Failed to apply patch for version " .. version .. ": " .. err)
    end
end

-- Rolls back all patches that were successfully applied.
function PatchService:rollbackAppliedPatches()
    for i = #self.appliedPatches, 1, -1 do
        local version = self.appliedPatches[i]
        local patchData = self.patches[version]
        if patchData and patchData.rollbackFunction then
            local success, err = pcall(patchData.rollbackFunction)
            if not success then
                print("Failed to rollback patch for version " .. version .. ": " .. err)
            end
        end
    end
    self.appliedPatches = {}  -- Clear applied patches
    self.currentVersion = 0  -- Reset current version
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
function PatchService:getLatestVersion()
    return self.currentVersion
end

return PatchService
