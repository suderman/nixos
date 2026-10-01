local features = require("generated.features")
local host = require("generated.host")
local feature_list = require("generated.feature-list")

-- Shared compositor behavior first...
require("conf.session").apply(host, features)
require("conf.look").apply(host, features)
require("conf.input").apply(host, features)
require("conf.layouts").apply(host, features)
require("conf.group").apply(host, features)
require("binds.main").apply(host, features)
require("rules.windows").apply(host, features)

-- ...then feature-local extensions contributed from Nix modules.
for _, feature in ipairs(feature_list) do
	require("features." .. feature).apply(host, features)
end

-- Colors refresh independently of binds, layouts, and local overrides.
require("lib.appearance").apply()

-- Writable local scratch hook for one-off experiments outside the repo.
-- Only absence is optional. Syntax and runtime errors belong in configerrors.
if package.searchpath("local.init", package.path) then
	require("local.init")
end
