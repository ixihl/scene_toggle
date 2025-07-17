-- Based heavily on voidlesity's scene toggler script
-- Not quite what I needed, so I modified it
-- original here: 
-- - https://obsproject.com/forum/resources/obs-toggle-scene-plugin.1768/
-- - https://github.com/voidlesity/obs-scene-toggler

obs = obslua

scene_a = ""
scene_b = ""
inclusive = true
hotkey_id = obs.OBS_INVALID_HOTKEY_ID
hotkey_pressed = false

function switch_scene(scene_n)
    local source = obs.obs_get_source_by_name(scene_n)
    if source ~= nil then
        obs.obs_frontend_set_current_scene(source)
        obs.obs_source_release(source)
    end
end

function toggle_scene(pressed)
    -- Logic goes as follows:
    -- if on scene A: swap to scene b
    -- if on anything but scene a, swap to scene a
    if pressed then
        if not hotkey_pressed then
            hotkey_pressed = true
            local current_scene = obs.obs_frontend_get_current_scene()
            if current_scene ~= nil then
                local scene_n = obs.obs_source_get_name(current_scene)
                obs.obs_source_release(current_scene)

                if scene_n == scene_b then
                    switch_scene(scene_a)
                elseif scene_n ~= scene_a and inclusive == true then
                    switch_scene(scene_a)
                elseif scene_n == scene_a then
                    switch_scene(scene_b)
                end
            end
        end
    else
        hotkey_pressed = false
    end
end

function script_description()
    return "Toggles between two specified scenes."
end

function script_properties()
    local props = obs.obs_properties_create()
    
    local scenes_o = obs.obs_frontend_get_scenes()
    local scenes = nil
    if scenes_o then
        scenes = {}
        for _, scene in ipairs(scenes_o) do
            local scene_n = obs.obs_source_get_name(scene)
            table.insert(scenes, scene_n)
            obs.obs_source_release(scene)
        end
    end

    -- Two big ones (dropdowns)
    local prop_a = obs.obs_properties_add_list(props, "scene_a", "Select scene A", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local prop_b = obs.obs_properties_add_list(props, "scene_b", "Select scene B", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local scenes = obs.obs_frontend_get_scenes()
    if scenes then
        for _, scene in ipairs(scenes) do
            local scene_n = obs.obs_source_get_name(scene)
            obs.obs_property_list_add_string(prop_a, scene_n, scene_n)
            obs.obs_property_list_add_string(prop_b, scene_n, scene_n)
            obs.obs_source_release(scene)
        end
    end
    obs.obs_properties_add_text(props, "inc-tooltip-a", "On -> Swap to scene A if on anything but scene A", obs.OBS_TEXT_INFO)
    obs.obs_properties_add_text(props, "inc-tooltip-b", "Off -> Swap to scene A only if on scene B", obs.OBS_TEXT_INFO)
    local prop_inc = obs.obs_properties_add_bool(props, "inclusive", "Inclusive scene switching")
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_bool(settings, "inclusive", true)
end

function script_update(settings)
    scene_a = obs.obs_data_get_string(settings, "scene_a")
    scene_b = obs.obs_data_get_string(settings, "scene_b")
    inclusive = obs.obs_data_get_bool(settings, "inclusive")
end

function script_save(settings)
    local hotkey_save_data = obs.obs_hotkey_save(hotkey_id)
    if hotkey_save_data then
        local wrapper = obs.obs_data_create()
        obs.obs_data_set_array(wrapper, "hotkey_data", hotkey_save_data)
        local json = obs.obs_data_get_json(wrapper)
        obs.obs_data_set_string(settings, "toggle_scene_hotkey_data", json)
        obs.obs_data_release(wrapper)
        obs.obs_data_array_release(hotkey_save_data)
    end
end

function script_load(settings)
    hotkey_id = obs.obs_hotkey_register_frontend("toggle_scene_hotkey", "Toggle Scenes Hotkey", toggle_scene)

    local json = obs.obs_data_get_string(settings, "toggle_scene_hotkey_data")
    if json and json ~= "" then
        local wrapper = obs.obs_data_create_from_json(json)
        local hotkey_save_data = obs.obs_data_get_array(wrapper, "hotkey_data")
        obs.obs_hotkey_load(hotkey_id, hotkey_save_data)
        obs.obs_data_array_release(hotkey_save_data)
        obs.obs_data_release(wrapper)
    end
end