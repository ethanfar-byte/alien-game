/// @desc obj_game Draw GUI Event
var mx = ui_mouse_x();
var my = ui_mouse_y();
var cap = autotest_capture_begin();
ui_draw_gui(game_state, mx, my);
autotest_capture_end(cap);
