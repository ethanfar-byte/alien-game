/// @desc obj_game Create Event
game_audio_init();

// Initialize display in Fullscreen Borderless by default
game_apply_display_settings("borderless", 1920, 1080);
display_set_gui_size(1920, 1080);

// Initialize game state starting at Title Screen
game_state = game_init_state(4);
game_state.screen = "title";
game_state.modal = undefined;
