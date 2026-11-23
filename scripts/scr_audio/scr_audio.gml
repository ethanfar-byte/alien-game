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
    
    game_audio_init_extra();
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
    if (instance_exists(obj_game) && variable_instance_exists(obj_game, "game_state")) {
        var gs = obj_game.game_state;
        if (is_struct(gs) && variable_struct_exists(gs, "settings")) {
            master_vol = gs.settings.sfx_volume;
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

// =============================================================================
// EXTRA SFX + PROCEDURAL MUSIC
// =============================================================================

/// @desc Generic tone/noise synth into a 16-bit mono buffer. fn(t, pct) returns a sample in [-1, 1].
function audio_synth_make(sound_name, dur, sample_rate, fn) {
    var n = floor(sample_rate * dur);
    var b = buffer_create(n * 2, buffer_fixed, 1);
    for (var i = 0; i < n; i++) {
        var v = fn(i / sample_rate, i / n);
        buffer_write(b, buffer_s16, clamp(round(v * 32767.0), -32767, 32767));
    }
    audio_synth_register_sound(sound_name, b, sample_rate, n * 2);
}

function game_audio_init_extra() {
    var sr = 44100;
    // Error: two low descending buzzy blips
    audio_synth_make("error", 0.22, sr, function(t, pct) {
        var f = (t < 0.1) ? 220 : 165;
        var seg = (t < 0.1) ? (t / 0.1) : ((t - 0.11) / 0.11);
        var env = (t > 0.1 && t < 0.11) ? 0 : (1 - clamp(seg, 0, 1));
        var sq = (sin(2 * pi * f * t) > 0) ? 1 : -1;
        return (sq * 0.35 + sin(2 * pi * f * 2 * t) * 0.2) * env * 0.55;
    });
    // Hover: tiny soft tick
    audio_synth_make("hover", 0.025, sr, function(t, pct) {
        return sin(2 * pi * 2400 * t) * (1 - pct) * (1 - pct) * 0.25;
    });
    // Step: soft thump + click
    audio_synth_make("step", 0.09, sr, function(t, pct) {
        var env = power(1 - pct, 3);
        return (sin(2 * pi * (180 - pct * 90) * t) * 0.8 + random_range(-1, 1) * 0.15 * (pct < 0.15)) * env * 0.6;
    });
    // Turn change: rising two-note chime
    audio_synth_make("turn", 0.26, sr, function(t, pct) {
        var f = (t < 0.11) ? 587.33 : 880.0;
        var env = (t < 0.11) ? (1 - t / 0.11 * 0.5) : (1 - pct);
        return (sin(2 * pi * f * t) + 0.25 * sin(4 * pi * f * t)) * env * 0.4;
    });
    // Alarm: wobbling siren for the defense phase
    audio_synth_make("alarm", 0.7, sr, function(t, pct) {
        var f = 520 + sin(2 * pi * 3.2 * t) * 160;
        var env = min(1, t / 0.04) * (1 - pct);
        var saw = 2 * frac(f * t) - 1;
        return (sin(2 * pi * f * t) * 0.5 + saw * 0.18) * env * 0.5;
    });
    // Zap: electric crackle
    audio_synth_make("zap", 0.3, sr, function(t, pct) {
        var env = power(1 - pct, 1.5);
        var buzz = sin(2 * pi * (90 + random(40)) * t * 10);
        return (buzz * 0.4 + random_range(-1, 1) * 0.35) * env * 0.55;
    });
    // Kill: punchy pop + sparkle
    audio_synth_make("kill", 0.32, sr, function(t, pct) {
        var env = power(1 - pct, 2);
        var thump = sin(2 * pi * (220 - pct * 160) * t) * 0.7;
        var sparkle = sin(2 * pi * 1760 * t) * 0.25 * (pct > 0.3);
        return (thump + random_range(-1, 1) * 0.25 * (pct < 0.2) + sparkle) * env * 0.6;
    });
    // Join: friendly arpeggio
    audio_synth_make("join", 0.35, sr, function(t, pct) {
        var f = (t < 0.1) ? 523.25 : ((t < 0.2) ? 659.25 : 783.99);
        return (sin(2 * pi * f * t) + 0.3 * sin(4 * pi * f * t)) * (1 - pct) * 0.4;
    });
    // Chat: soft blip
    audio_synth_make("chat", 0.12, sr, function(t, pct) {
        var f = (t < 0.05) ? 1046.5 : 1318.5;
        return sin(2 * pi * f * t) * (1 - pct) * 0.35;
    });
    // Defeat: falling minor chord
    audio_synth_make("defeat", 1.2, sr, function(t, pct) {
        var bend = 1 - pct * 0.25;
        var s = sin(2 * pi * 220 * bend * t) + sin(2 * pi * 261.63 * bend * t) * 0.8 + sin(2 * pi * 329.63 * bend * t) * 0.6;
        return s * (1 - pct) * 0.22;
    });

    game_music_init();
}

// -----------------------------------------------------------------------------
// MUSIC: two seamless synthesized loops ("ambient" for planning, "combat" for defense)
// -----------------------------------------------------------------------------
global.music = { initialized: false, cur: "", inst: -1, inst_name: "" };

function game_music_init() {
    var sr = 11025;
    // Ambient pad: Am - F - C - G (2s each), soft detuned sines with smooth crossfades. 8s loop.
    // Frequencies are rounded to multiples of 1/8 Hz so every partial completes whole cycles in 8s (seamless loop).
    var q = function(f) { return round(f * 8) / 8; };
    global.music_chords = [
        [q(110.0), q(220.0), q(261.63), q(329.63)],
        [q(87.31), q(174.61), q(220.0), q(261.63)],
        [q(130.81), q(196.0), q(261.63), q(329.63)],
        [q(98.0), q(196.0), q(246.94), q(293.66)]
    ];
    audio_synth_make("music_ambient", 8.0, sr, function(t, pct) {
        var seg = floor(t / 2) mod 4;
        var local = (t - seg * 2) / 2;
        var nxt = (seg + 1) mod 4;
        var fade = clamp((local - 0.8) / 0.2, 0, 1);
        var a = global.music_chords[seg];
        var b = global.music_chords[nxt];
        var s = 0;
        for (var k = 0; k < 4; k++) {
            var amp = (k == 0) ? 0.34 : 0.2;
            s += sin(2 * pi * a[k] * t) * amp * (1 - fade);
            s += sin(2 * pi * b[k] * t) * amp * fade;
        }
        var shimmer = sin(2 * pi * 0.25 * t) * 0.5 + 0.5;
        s += sin(2 * pi * 880 * t) * 0.015 * shimmer;
        return s * 0.32;
    });
    // Combat pulse: driving bass + kick + hats at 120 BPM, 4s loop
    audio_synth_make("music_combat", 4.0, sr, function(t, pct) {
        var beat = t * 2;                // 120 BPM -> 2 beats per second
        var bf = frac(beat);
        var eighth = frac(beat * 2);
        var bar = floor(beat) mod 8;
        var root = (bar < 4) ? 55.0 : 49.0;
        var kick = sin(2 * pi * (120 - bf * 80) * bf * 0.5) * power(1 - bf, 6) * 0.9;
        var bass = sin(2 * pi * root * t) * 0.35 * (1 - eighth * 0.6) + sin(2 * pi * root * 2 * t) * 0.12;
        var hat = (eighth < 0.12) ? random_range(-1, 1) * 0.18 * (1 - eighth / 0.12) : 0;
        var stab = (bar == 3 || bar == 7) ? sin(2 * pi * root * 4 * t) * 0.12 * (1 - bf) : 0;
        return (kick + bass + hat + stab) * 0.5;
    });
    global.music.initialized = true;
}

/// @desc Called every step: picks the right loop for the current situation and crossfades
function game_music_update(state) {
    if (!global.music.initialized) return;
    var vol = state.settings[$ "music_volume"] ?? 0.5;
    var want = "music_ambient";
    if (state.screen == "game" && (state.phase == "combat_weapons" || state.phase == "combat_aliens")) want = "music_combat";
    if (state.screen == "game" && (state.phase == "game_over")) want = "";

    if (want != global.music.cur) {
        if (global.music.inst != -1 && audio_is_playing(global.music.inst)) {
            audio_sound_gain(global.music.inst, 0, 600);
            var old = global.music.inst;
            call_later(40, time_source_units_frames, method({ inst: old }, function() { audio_stop_sound(inst); }));
        }
        global.music.inst = -1;
        global.music.cur = want;
        if (want != "" && vol > 0.001) {
            var snd = global.sfx_sounds[$ want];
            if (!is_undefined(snd) && snd != -1) {
                global.music.inst = audio_play_sound(snd, 1, true);
                audio_sound_gain(global.music.inst, 0, 0);
                audio_sound_gain(global.music.inst, vol * 0.55, 900);
            }
        }
    } else if (global.music.inst != -1) {
        if (vol <= 0.001) {
            audio_stop_sound(global.music.inst);
            global.music.inst = -1;
            global.music.cur = "";
        } else if (abs(audio_sound_get_gain(global.music.inst) - vol * 0.55) > 0.02 && !state.settings.slider_dragging) {
            audio_sound_gain(global.music.inst, vol * 0.55, 200);
        } else if (state.settings.slider_dragging) {
            audio_sound_gain(global.music.inst, vol * 0.55, 0);
        }
    } else if (want != "" && vol > 0.001) {
        global.music.cur = ""; // restart on next update
    }
}
