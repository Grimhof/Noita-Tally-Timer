obs = obslua

local source_name = ""
local sound_source_name = ""
local total_seconds = 300
local cur_seconds = 0.1
local timer_active = false

function set_time_text()
    local seconds = math.floor(cur_seconds % 60)
    local minutes = math.floor(cur_seconds / 60)
    local text = string.format("%02d:%02d", minutes, seconds)

    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local settings = obs.obs_data_create_from_json('{"text": "' .. text .. '"}')
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

function play_sound()
    local sound_source = obs.obs_get_source_by_name(sound_source_name)
    if sound_source ~= nil then
        obs.obs_source_media_restart(sound_source)
        obs.obs_source_release(sound_source)
    end
end

function timer_callback()
    if not timer_active then
        return
    end

    if cur_seconds > 0 then
        cur_seconds = cur_seconds - 1
        set_time_text()
    elseif cur_seconds == 0 then
        play_sound()
        timer_active = false
    end
end

function toggle_timer()
    timer_active = not timer_active
end

function reset_timer()
    cur_seconds = total_seconds
    set_time_text()
	timer_active = true
end

function zero_timer()
    cur_seconds = 0.1
    set_time_text()
	timer_active = false
end

function script_properties()
    local props = obs.obs_properties_create()

    obs.obs_properties_add_text(props, "source_name", "Text Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "sound_source_name", "Sound Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_button(props, "toggle_button", "Toggle Timer", toggle_timer)
    obs.obs_properties_add_button(props, "reset_button", "Reset Timer", reset_timer)

    return props
end

function script_description()
    return "Sets a text source to become a timer and a media source to act as a notification for when that timer is done.\n\nMade by Grimhof"
end

function script_update(settings)
    source_name = obs.obs_data_get_string(settings, "source_name")
    sound_source_name = obs.obs_data_get_string(settings, "sound_source_name")
    set_time_text()
end

local toggle_hotkey_id = nil
local reset_hotkey_id = nil
local zero_hotkey_id = nil

function script_save(settings)
    local toggle_hotkey_save_array = obs.obs_hotkey_save(toggle_hotkey_id)
    obs.obs_data_set_array(settings, "toggle_timer_hotkey", toggle_hotkey_save_array)
    obs.obs_data_array_release(toggle_hotkey_save_array)

    local reset_hotkey_save_array = obs.obs_hotkey_save(reset_hotkey_id)
    obs.obs_data_set_array(settings, "reset_timer_hotkey", reset_hotkey_save_array)
    obs.obs_data_array_release(reset_hotkey_save_array)

    local zero_hotkey_save_array = obs.obs_hotkey_save(zero_hotkey_id)
    obs.obs_data_set_array(settings, "zero_timer_hotkey", zero_hotkey_save_array)
    obs.obs_data_array_release(zero_hotkey_save_array)
end

function script_load(settings)
    obs.timer_add(timer_callback, 1000)
    
    -- Register custom actions for hotkeys
    toggle_hotkey_id = obs.obs_hotkey_register_frontend("toggle_timer_action", "Toggle Timer", toggle_timer)
    reset_hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_action", "Reset Timer", reset_timer)
    zero_hotkey_id = obs.obs_hotkey_register_frontend("zero_timer_action", "Zero Timer", zero_timer)

    -- Load the hotkey settings from the script settings
    local toggle_hotkey_save_array = obs.obs_data_get_array(settings, "toggle_timer_hotkey")
    obs.obs_hotkey_load(toggle_hotkey_id, toggle_hotkey_save_array)
    obs.obs_data_array_release(toggle_hotkey_save_array)

    local reset_hotkey_save_array = obs.obs_data_get_array(settings, "reset_timer_hotkey")
    obs.obs_hotkey_load(reset_hotkey_id, reset_hotkey_save_array)
    obs.obs_data_array_release(reset_hotkey_save_array)

    local zero_hotkey_save_array = obs.obs_data_get_array(settings, "zero_timer_hotkey")
    obs.obs_hotkey_load(zero_hotkey_id, zero_hotkey_save_array)
    obs.obs_data_array_release(zero_hotkey_save_array)
end


function script_unload()
    if toggle_hotkey_id ~= nil then
        obs.obs_hotkey_unregister(toggle_hotkey_id)
    end
    if reset_hotkey_id ~= nil then
        obs.obs_hotkey_unregister(reset_hotkey_id)
    end
    if zero_hotkey_id ~= nil then
        obs.obs_hotkey_unregister(zero_hotkey_id)
    end
end