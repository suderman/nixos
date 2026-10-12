local host = require("generated.host")

-- Shared compositor behavior first...
require("conf.session").apply(host)
require("conf.look").apply(host)
require("conf.input").apply()
require("conf.layouts").apply()
require("conf.group").apply()
require("binds.main").apply()
require("rules.windows").apply()

-- ...then feature-local extensions contributed from Nix modules.
for _, feature in ipairs(require("generated.feature-list")) do
	require("features." .. feature)
end

-- Colors refresh independently of binds, layouts, and local overrides.
require("lib.appearance").apply()

-- Writable local scratch hook for one-off experiments outside the repo.
-- Only absence is optional. Syntax and runtime errors belong in configerrors.
if package.searchpath("local.init", package.path) then
	require("local.init")
end
