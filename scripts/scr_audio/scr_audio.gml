/// @desc scr_audio - Procedural SFX engine and audio manager for Alien Game

global.game_audio_initialized = false;
global.sfx_buffers = {};
global.sfx_sounds = {};

/// @desc Helper to safely register a sound from a fixed PCM buffer
function audio_synth_register_sound(sound_name, buf, sample_rate, num_bytes) {
    global.sfx_buffers[$ sound_name] = buf;
    buffer_seek(buf, buffer_seek_start, 0);
    try {
        var snd = audio_create_buffer_sound(buf, buffer_s16, sample_rate, 0, num_bytes, audio_mono);
        global.sfx_sounds[$ sound_name] = snd;
    } catch (e) {
        show_debug_message("Audio sound creation failed for '" + sound_name + "': " + string(e));
        global.sfx_sounds[$ sound_name] = -1;
    }
}

/// @desc Initializes all procedural sound effect buffers and audio instances
function game_audio_init() {
    if (global.game_audio_initialized) return;
    
    var sample_rate = 44100;
    
    // 1. CLICK (Crisp subtle UI blip ~0.04s)
    var dur1 = 0.04;
    var n1 = floor(sample_rate * dur1);
    var b1 = buffer_create(n1 * 2, buffer_fixed, 1);
    for (var i = 0; i < n1; i++) {
        var t = i / sample_rate;
        var env = 1.0 - (i / n1);
        var freq = 900.0 - (i / n1) * 300.0;
        var s = sin(2.0 * pi * freq * t) * env * 0.7;
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b1, buffer_s16, val);
    }
    audio_synth_register_sound("click", b1, sample_rate, n1 * 2);
    
    // 2. COIN / TRADE (Double high chime ~0.14s)
    var dur2 = 0.14;
    var n2 = floor(sample_rate * dur2);
    var b2 = buffer_create(n2 * 2, buffer_fixed, 1);
    for (var i = 0; i < n2; i++) {
        var t = i / sample_rate;
        var env = 1.0 - (i / n2);
        var freq = (t < 0.06) ? 1320.0 : 1760.0;
        var s = (sin(2.0 * pi * freq * t) + 0.3 * sin(4.0 * pi * freq * t)) * env * 0.6;
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b2, buffer_s16, val);
    }
    audio_synth_register_sound("coin", b2, sample_rate, n2 * 2);

    // 3. BUY / LEVELUP (Ascending pleasant triad ~0.22s)
    var dur3 = 0.22;
    var n3 = floor(sample_rate * dur3);
    var b3 = buffer_create(n3 * 2, buffer_fixed, 1);
    for (var i = 0; i < n3; i++) {
        var t = i / sample_rate;
        var env = 1.0 - (i / n3);
        var freq = 523.25; // C5
        if (t > 0.14) freq = 783.99; // G5
        else if (t > 0.07) freq = 659.25; // E5
        var s = (sin(2.0 * pi * freq * t) + 0.2 * sin(6.0 * pi * freq * t)) * env * 0.6;
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b3, buffer_s16, val);
    }
    audio_synth_register_sound("buy", b3, sample_rate, n3 * 2);

    // 4. GATHER / PICKUP (Organic wooden thud ~0.08s)
    var dur4 = 0.08;
    var n4 = floor(sample_rate * dur4);
    var b4 = buffer_create(n4 * 2, buffer_fixed, 1);
    for (var i = 0; i < n4; i++) {
        var t = i / sample_rate;
        var env = power(1.0 - (i / n4), 2);
        var freq = 360.0 - (i / n4) * 200.0;
        var s = sin(2.0 * pi * freq * t) * env * 0.8;
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b4, buffer_s16, val);
    }
    audio_synth_register_sound("gather", b4, sample_rate, n4 * 2);

    // 5. REPAIR (Metallic clink ~0.12s)
    var dur5 = 0.12;
    var n5 = floor(sample_rate * dur5);
    var b5 = buffer_create(n5 * 2, buffer_fixed, 1);
    for (var i = 0; i < n5; i++) {
        var t = i / sample_rate;
        var env = power(1.0 - (i / n5), 2.5);
        var s = (sin(2.0 * pi * 880.0 * t) + 0.5 * sin(2.0 * pi * 1440.0 * t) + 0.3 * sin(2.0 * pi * 2300.0 * t)) * env * 0.7;
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b5, buffer_s16, val);
    }
    audio_synth_register_sound("repair", b5, sample_rate, n5 * 2);

    // 6. SHOOT / LASER (Punchy laser downsweep ~0.15s)
    var dur6 = 0.15;
    var n6 = floor(sample_rate * dur6);
    var b6 = buffer_create(n6 * 2, buffer_fixed, 1);
    for (var i = 0; i < n6; i++) {
        var pct = i / n6;
        var env = 1.0 - pct;
        var freq = 1200.0 * (1.0 - pct * 0.85); // 1200 -> 180 Hz
        var t = i / sample_rate;
        var s = (sin(2.0 * pi * freq * t) + 0.25 * ((pct % 0.05 > 0.025) ? 1.0 : -1.0)) * env * 0.7;
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b6, buffer_s16, val);
    }
    audio_synth_register_sound("shoot", b6, sample_rate, n6 * 2);

    // 7. HIT / EXPLODE (Deep punchy noise/thud ~0.16s)
    var dur7 = 0.16;
    var n7 = floor(sample_rate * dur7);
    var b7 = buffer_create(n7 * 2, buffer_fixed, 1);
    for (var i = 0; i < n7; i++) {
        var pct = i / n7;
        var env = power(1.0 - pct, 1.8);
        var t = i / sample_rate;
        var noise = (random_range(-1.0, 1.0)) * 0.4;
        var sub = sin(2.0 * pi * (140.0 - pct * 90.0) * t) * 0.7;
        var s = (sub + noise) * env * 0.8;
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b7, buffer_s16, val);
    }
    audio_synth_register_sound("hit", b7, sample_rate, n7 * 2);

    // 8. ALIEN (Menacing sci-fi FM screech ~0.20s)
    var dur8 = 0.20;
    var n8 = floor(sample_rate * dur8);
    var b8 = buffer_create(n8 * 2, buffer_fixed, 1);
    for (var i = 0; i < n8; i++) {
        var pct = i / n8;
        var env = sin(pct * pi); // swells and decays
        var t = i / sample_rate;
        var lfo = sin(2.0 * pi * 45.0 * t) * 120.0;
        var s = sin(2.0 * pi * (320.0 + lfo) * t) * env * 0.7;
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b8, buffer_s16, val);
    }
    audio_synth_register_sound("alien", b8, sample_rate, n8 * 2);

    // 9. WAVE START (Resonant alert horn ~0.35s)
    var dur9 = 0.35;
    var n9 = floor(sample_rate * dur9);
    var b9 = buffer_create(n9 * 2, buffer_fixed, 1);
    for (var i = 0; i < n9; i++) {
        var pct = i / n9;
        var env = (pct < 0.1) ? (pct / 0.1) : (1.0 - (pct - 0.1) / 0.9);
        var t = i / sample_rate;
        var s = (sin(2.0 * pi * 293.66 * t) + 0.6 * sin(2.0 * pi * 440.0 * t)) * env * 0.6; // D4 + A4
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b9, buffer_s16, val);
    }
    audio_synth_register_sound("wave", b9, sample_rate, n9 * 2);

    // 10. VICTORY FANFARE (~0.45s)
    var dur10 = 0.45;
    var n10 = floor(sample_rate * dur10);
    var b10 = buffer_create(n10 * 2, buffer_fixed, 1);
    for (var i = 0; i < n10; i++) {
        var t = i / sample_rate;
        var env = 1.0 - (i / n10);
        var freq = 523.25; // C5
        if (t > 0.28) freq = 1046.50; // C6
        else if (t > 0.18) freq = 783.99; // G5
        else if (t > 0.09) freq = 659.25; // E5
        var s = (sin(2.0 * pi * freq * t) + 0.2 * sin(4.0 * pi * freq * t)) * env * 0.6;
        var val = clamp(round(s * 32767.0), -32767, 32767);
        buffer_write(b10, buffer_s16, val);
    }
    audio_synth_register_sound("victory", b10, sample_rate, n10 * 2);

    global.game_audio_initialized = true;
}

/// @desc Plays a sound effect by name with current volume settings
/// @param {string} sound_name ("click", "coin", "buy", "gather", "repair", "shoot", "hit", "alien", "wave", "victory")
/// @param {real} [vol_mult=1.0]
function game_play_sfx(sound_name, vol_mult = 1.0) {
    if (!global.game_audio_initialized) {
        game_audio_init();
    }
    
    var master_vol = 0.8;
    // Check if game_state settings exist
    if (instance_exists(obj_game)) {
        if (!is_undefined(obj_game.game_state) && variable_struct_exists(obj_game.game_state, "settings")) {
            master_vol = obj_game.game_state.settings.sfx_volume;
        }
    }
    
    var final_vol = clamp(master_vol * vol_mult, 0.0, 1.0);
    if (final_vol <= 0.001) return; // Muted
    
    if (variable_struct_exists(global.sfx_sounds, sound_name)) {
        var snd = global.sfx_sounds[$ sound_name];
        if (snd != undefined && snd != -1 && audio_exists(snd)) {
            var inst = audio_play_sound(snd, 10, false);
            audio_sound_gain(inst, final_vol, 0);
        }
    }
}
