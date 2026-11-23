/// @desc obj_game Create Event
var boot_t0 = get_timer();
randomize(); // without this GameMaker deals the same decks, shop offers and aliens every launch
autotest_boot();
game_audio_init();
autotest_log("audio ready in " + string(round((get_timer() - boot_t0) / 1000)) + " ms");
network_configure();

// Borderless fullscreen by default; the GUI is always laid out at 1920x1080 and scaled
game_apply_display_settings("borderless", 1920, 1080);
display_set_gui_size(1920, 1080);

game_state = game_init_state(4);
game_state.screen = "title";
game_state.modal = undefined;
game_state.title_sel = 0;
game_state.transition = 1.0;

// Automated tests run in a small window so they don't take over the screen
if (autotest_active()) {
    game_state.settings.display_mode = "windowed";
    game_apply_display_settings("windowed", 960, 540);
}
