local features = require("generated.features")
local host = require("generated.host")
local feature_list = require("generated.feature-list")

-- Feature modules are optional. Missing files should not brick the session.
local function load_feature(name)
	local ok, mod = pcall(require, name)
	if ok and mod and mod.apply then
		mod.apply(host, features)
	end
end

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
	load_feature("features." .. feature)
end

-- Writable local scratch hook for one-off experiments outside the repo.
pcall(require, "local.init")
