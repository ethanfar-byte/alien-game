/// @desc Async Networking Event
if (variable_instance_exists(id, "game_state") && !is_undefined(game_state)) {
    network_handle_async(game_state, async_load);
}
