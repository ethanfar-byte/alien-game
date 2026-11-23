/// @desc scr_audio - sound effects and music, loaded at startup from the included files in audio/
/// (effects: <name>.wav, music: music_<name>.ogg).

global.game_audio_initialized = false;
global.sfx_sounds = {};
global.sfx_last_play = {};
global.music_sounds = {};
global.music = { cur: "", kind: "", inst: -1, amb: 0, mult: 0.45 };

function game_sfx_names() {
    return ["click", "hover", "modal_open", "modal_close", "error", "turn", "chat", "join",
            "coin", "sell", "buy", "reroll", "deposit",
            "gather", "gather_wood", "gather_stone", "gather_crystal", "repair", "forge", "demolish",
            "step", "move",
            "shoot", "fire_turret", "fire_gatling_gun", "fire_cannon", "fire_makeshift_cannon", "fire_railgun", "fire_lazer_gun",
            "fire_flamethrower", "fire_plasma_mortar", "fire_cryo_emitter", "zap",
            "hit", "kill", "alien", "alien_arrive", "tower_hit", "tower_down", "shield",
            "wave", "day", "alarm", "victory", "defeat"];
}

function game_music_names() {
    return ["music_menu", "music_ambient_1", "music_ambient_2", "music_ambient_3", "music_combat"];
}

/// @desc Loads every sound from the included files in audio/ (WAV effects into memory, OGG music as streams)
function game_audio_init() {
    if (global.game_audio_initialized) return;
    global.sfx_buffers = [];
    var names = game_sfx_names();
    for (var i = 0; i < array_length(names); i++) global.sfx_sounds[$ names[i]] = audio_load_wav("audio/" + names[i] + ".wav");
    var mus = game_music_names();
    for (var i = 0; i < array_length(mus); i++) {
        var f = "audio/" + mus[i] + ".ogg";
        global.music_sounds[$ mus[i]] = file_exists(f) ? audio_create_stream(f) : -1;
    }
    global.music.amb = irandom(2);
    global.game_audio_initialized = true;
}

/// @desc Loads a 16-bit PCM WAV file into a buffer sound. Returns the sound or -1.
function audio_load_wav(path) {
    if (!file_exists(path)) return -1;
    var b = buffer_load(path);
    if (b < 0) return -1;
    var size = buffer_get_size(b);
    var ch = 1, sr = 44100, bits = 16, data_off = -1, data_len = 0;
    var pos = 12;
    while (pos + 8 <= size) {
        var id0 = buffer_peek(b, pos, buffer_u8), id1 = buffer_peek(b, pos + 1, buffer_u8), id2 = buffer_peek(b, pos + 2, buffer_u8), id3 = buffer_peek(b, pos + 3, buffer_u8);
        var tag = chr(id0) + chr(id1) + chr(id2) + chr(id3);
        var len = buffer_peek(b, pos + 4, buffer_u32);
        if (tag == "fmt ") {
            ch = buffer_peek(b, pos + 10, buffer_u16);
            sr = buffer_peek(b, pos + 12, buffer_u32);
            bits = buffer_peek(b, pos + 22, buffer_u16);
        } else if (tag == "data") {
            data_off = pos + 8;
            data_len = min(len, size - data_off);
            break;
        }
        pos += 8 + len + (len mod 2);
    }
    if (data_off < 0 || bits != 16 || data_len <= 0) { buffer_delete(b); return -1; }
    // Buffer sounds need a fixed buffer: copy the PCM data out of the loaded (growable) file buffer
    var pcm = buffer_create(data_len, buffer_fixed, 1);
    buffer_copy(b, data_off, data_len, pcm, 0);
    buffer_delete(b);
    var snd = audio_create_buffer_sound(pcm, buffer_s16, sr, 0, data_len, (ch == 2) ? audio_stereo : audio_mono);
    if (snd < 0) { buffer_delete(pcm); return -1; }
    array_push(global.sfx_buffers, pcm); // the buffer must stay alive while the sound exists
    return snd;
}

/// @desc Plays a sound effect by name at the current SFX volume, with a little pitch variety on repeated sounds
function game_play_sfx(sound_name, vol_mult = 1.0) {
    if (sim_active()) return;
    if (!global.game_audio_initialized) game_audio_init();

    var master_vol = 0.8;
    if (instance_exists(obj_game) && variable_instance_exists(obj_game, "game_state")) {
        var gs = obj_game.game_state;
        if (is_struct(gs) && variable_struct_exists(gs, "settings")) master_vol = gs.settings.sfx_volume;
    }
    var final_vol = clamp(master_vol * vol_mult, 0.0, 1.0);
    if (final_vol <= 0.001) return;

    var snd = global.sfx_sounds[$ sound_name] ?? -1;
    if (snd == -1 && string_pos("fire_", sound_name) == 1) snd = global.sfx_sounds[$ "shoot"] ?? -1;
    if (snd == -1 || !audio_exists(snd)) return;

    // The same sound twice in one frame just gets louder - skip the duplicate
    var now = current_time;
    if (now - (global.sfx_last_play[$ sound_name] ?? -1000) < 30) return;
    global.sfx_last_play[$ sound_name] = now;

    var pitch = 1.0;
    switch (sound_name) {
        case "click": case "hover": pitch = random_range(0.97, 1.03); break;
        case "step": case "move": case "hit": case "kill": case "tower_hit": case "gather_wood": case "gather_stone":
        case "shoot": case "fire_turret": case "fire_gatling_gun": case "fire_cannon": case "fire_makeshift_cannon":
        case "fire_lazer_gun": case "fire_plasma_mortar": case "alien": case "coin":
            pitch = random_range(0.92, 1.08); break;
    }
    audio_play_sound(snd, 10, false, final_vol, 0, pitch);
}

// -----------------------------------------------------------------------------
// MUSIC
// menu: faint looping theme. In game: three ambient themes that rotate (a new one each day after the
// night's defense, or when one finishes). Defense: looping combat track. Silence on the end screens.
// -----------------------------------------------------------------------------
function game_music_update(state) {
    if (!global.game_audio_initialized) return;
    var M = global.music;
    var vol = state.settings[$ "music_volume"] ?? 0.5;

    var kind = "ambient", mult = 0.7;
    if (state.screen != "game") { kind = "menu"; mult = 0.5; }
    else if (state.phase == "combat_weapons" || state.phase == "combat_aliens") { kind = "combat"; mult = 0.75; }
    else if (state.phase == "game_over" || state.phase == "victory") kind = "";

    var playing = (M.inst != -1 && audio_is_playing(M.inst));
    var name = "";
    if (kind == "menu") name = "music_menu";
    else if (kind == "combat") name = "music_combat";
    else if (kind == "ambient") {
        if (M.kind == "ambient") {
            if (playing) name = M.cur;
            else { M.amb = (M.amb + 1) mod 3; name = "music_ambient_" + string(M.amb + 1); } // theme finished: next one
        } else {
            if (M.kind == "combat") M.amb = (M.amb + 1) mod 3; // a new theme each morning
            name = "music_ambient_" + string(M.amb + 1);
        }
    }
    if (vol <= 0.001) name = "";

    if (name != M.cur || (name != "" && !playing)) {
        if (playing) {
            audio_sound_gain(M.inst, 0, 1400);
            var old = M.inst;
            call_later(90, time_source_units_frames, method({ inst: old }, function() { audio_stop_sound(inst); }));
        }
        M.inst = -1;
        M.cur = name;
        M.kind = kind;
        M.mult = mult;
        if (name != "") {
            var snd = global.music_sounds[$ name] ?? -1;
            if (snd != -1) {
                M.inst = audio_play_sound(snd, 1, kind != "ambient", 0);
                audio_sound_gain(M.inst, vol * mult, (kind == "combat") ? 900 : 2500);
            }
        }
    } else if (playing) {
        var target = vol * mult;
        if (state.settings[$ "slider_dragging"] ?? false) audio_sound_gain(M.inst, target, 0);
        else if (abs(audio_sound_get_gain(M.inst) - target) > 0.05 && audio_sound_get_gain(M.inst) > target) audio_sound_gain(M.inst, target, 300);
    }
}
