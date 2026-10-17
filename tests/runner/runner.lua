local module = {}

local Packages = script.Parent.Packages
local Jest = require(Packages.Jest)
local runCLI = Jest.runCLI

function module.run()
    local status, result = runCLI(Packages.Project, {
        verbose = false,
        ci = false,
    }, { Packages.Project }):awaitStatus()

    if status == "Rejected" then
        print(result)
        error(result)
    end

    if not result.results.success then
        error("Tests failed")
    end
end

return module