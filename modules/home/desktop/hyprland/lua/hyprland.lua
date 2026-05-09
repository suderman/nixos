local features = require("generated.features")
local host = require("generated.host")
local feature_list = require("generated.feature-list")

local function load_feature(name)
    local ok, mod = pcall(require, name)
    if ok and mod and mod.apply then
        mod.apply(host, features)
    end
end

require("conf.session").apply(host, features)
require("conf.look").apply(host, features)
require("conf.input").apply(host, features)
require("conf.layouts").apply(host, features)
require("conf.group").apply(host, features)
require("binds.main").apply(host, features)
require("rules.windows").apply(host, features)

for _, feature in ipairs(feature_list) do
    load_feature("features." .. feature)
end

pcall(require, "local.init")
