-- Mod header
local mod = {
    name = "Lite Environment",
    id = "LiteEnvironmentMod",
    version = "2.0.0",
    author = "HolographicWings",
    settings = settings
}
_G[mod.id] = mod -- Globalize mod header
log.info(string.format("%s v%s is loading", mod.name, mod.version))

local config_path = "lite_environment.json" -- Stored in \MonsterHunterWilds\reframework\data

local wind_manager = sdk.get_managed_singleton("app.WindManager")
local environment_manager = sdk.get_managed_singleton("app.EnvironmentManager")
local graphics_manager = sdk.get_managed_singleton("app.GraphicsManager")

local settings =
{
    wind_simulation = false, -- Disabled by default
    global_illumination = true, -- Enabled by default
    volumetric_fog = true -- Enabled by default
}


-- Write to the configuration file
local function save_config()
    json.dump_file(config_path, settings)
end

-- Read the configuration file
local function load_config()
    local loadedTable = json.load_file(config_path)
    if loadedTable ~= nil then
        for key, val in pairs(loadedTable) do
            settings[key] = loadedTable[key]
        end
    end
end

-- Apply the wind simulation setting
local function apply_ws_setting()
	if not wind_manager then return end
	
	local wind_manager_base = sdk.to_managed_object(wind_manager):call("get_Instance")
	
	if wind_manager_base then
		wind_manager_base:set_field("_Stop", not settings.wind_simulation) -- Enable or disable wind simulation
	end
end

-- Apply the global illumination setting
local function apply_gi_setting()
	if not environment_manager then return end

    local dpgi_component = environment_manager:call("get_DPGIComponent")

    if dpgi_component then
        dpgi_component:call("set_Enabled", settings.global_illumination) -- Enable or disable global illumination
    end
end

-- Apply the volumetric fog setting
local function apply_vf_setting()
	if not graphics_manager then return end

	local graphics_setting = graphics_manager:call("get_NowGraphicsSetting")

    if graphics_setting then
		graphics_setting:call("set_VolumetricFogControl_Enable", settings.volumetric_fog) -- Enable or disable volumetric fog
		graphics_manager:call("setGraphicsSetting", graphics_setting) -- Apply setting change
    end
end

load_config() -- Load the configuration file on startup
apply_ws_setting() -- Apply wind simulation setting immediately after loading config
apply_gi_setting() -- Apply global illumination setting immediately after loading config
apply_vf_setting() -- Apply volumetric fog setting immediately after loading config

-- Hook the game's cacheEnvironment method (to apply the Global Illumination setting after loaded a save)
sdk.hook(
    sdk.find_type_definition("app.EnvironmentManager"):get_method("cacheEnvironment"),
    function() end,
    apply_gi_setting
)

-- REFramework UI rendering
re.on_draw_ui(function()
    local ws_changed, gi_changed, vf_changed = false

	-- Create new REFramework UI Node
    if imgui.tree_node(string.format("%s v%s", mod.name, mod.version)) then
        ws_changed = imgui.checkbox("Disable Wind Simulation", not settings.wind_simulation) -- Add a checkbox to disable the wind simulation
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Huge performance improvement.\n\nThe vegetation and tissues sway will not longer\ndepend of the wind intensity and direction.")
        end
		
        gi_changed = imgui.checkbox("Disable Global Illumination", not settings.global_illumination) -- Add a checkbox to disable the global illumination
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Medium performance improvement.\n\nHighly deteriorate the visual quality.")
        end
		
        vf_changed = imgui.checkbox("Disable Volumetric Fog", not settings.volumetric_fog) -- Add a checkbox to disable the volumetric fog
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Medium performance improvement.\n\nHighly deteriorate the visual quality.")
        end
        
		-- On wind simulation toggled
        if ws_changed then
			settings.wind_simulation = not settings.wind_simulation
            apply_ws_setting()
            save_config()
        end
		-- On global illumination toggled
        if gi_changed then
			settings.global_illumination = not settings.global_illumination
            apply_gi_setting()
            save_config()
        end
		-- On volumetric fog toggled
        if vf_changed then
			settings.volumetric_fog = not settings.volumetric_fog
			apply_vf_setting()
            save_config()
        end

        imgui.tree_pop()
    end
end)

log.info(string.format("%s v%s is loaded", mod.name, mod.version))