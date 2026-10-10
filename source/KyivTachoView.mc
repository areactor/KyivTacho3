import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;
import Toybox.WatchUi;


// Original minimalist instrument-style face (inspired by car gauges in general).
// Main hands = home time (default Kyiv) computed from UTC. Same data slots & settings as Kyiv Chrono.
class KyivTachoView extends WatchUi.WatchFace {

    const T = Graphics.COLOR_TRANSPARENT;
    const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    // [dial, subdial, gauge track, window, dim, isLight, pattern]
    // [dial, subdial, gauge track, window, dim, isLight, pattern]
    const THEMES = [
        [0x0A1A33, 0x061022, 0x24395C, 0x040A16, 0x5A6B85, 0, 0x13294A], // Navy
        [0x0A0A0A, 0x000000, 0x2A2A2A, 0x000000, 0x6A6A6A, 0, 0x1C1C1C], // Black
        [0x0B2F66, 0x061D40, 0x2B4F88, 0x041530, 0x6F8FC0, 0, 0x14418A], // Ocean blue
        [0x0E2A1E, 0x07170F, 0x25503A, 0x04100A, 0x5E7F6C, 0, 0x17402C], // Green
        [0x2A0E14, 0x17070B, 0x552433, 0x100407, 0x85606A, 0, 0x421824], // Burgundy
        [0x1E2328, 0x121518, 0x3C454F, 0x0C0E10, 0x78828C, 0, 0x2C343C], // Slate grey
        [0xF2F2EE, 0xE0E0DA, 0xC8C8C0, 0xFFFFFF, 0x6A6A6A, 1, 0xE2E2DA], // Paper
        [0xEFE3C6, 0xE2D3AE, 0xC4B48C, 0xF7EFDC, 0x7A6A48, 1, 0xE5D7B8], // Cream
        [0x141414, 0x0A0A0A, 0x333333, 0x050505, 0x7A7A7A, 0, 0x202020], // Carbon
        [0x0C2B30, 0x061A1D, 0x1F4E55, 0x031013, 0x5E8E94, 0, 0x143E45], // Petrol
        [0x222A12, 0x141A0A, 0x455224, 0x0C1006, 0x7E8A5E, 0, 0x2F3A18], // Olive
        [0x241432, 0x150B1E, 0x452A5C, 0x0E0714, 0x8A6FA0, 0, 0x351E48]  // Plum
    ];
    const THEMES_MIP = [
        [0x000055, 0x000000, 0x0055AA, 0x000000, 0x5555AA, 0, 0x0000AA],
        [0x000000, 0x000000, 0x555555, 0x000000, 0xAAAAAA, 0, 0x555555],
        [0x0000AA, 0x000055, 0x0055FF, 0x000055, 0x55AAFF, 0, 0x0055AA],
        [0x005500, 0x000000, 0x00AA55, 0x000000, 0x55AA55, 0, 0x005555],
        [0x550000, 0x000000, 0xAA0055, 0x000000, 0xAA5555, 0, 0x550055],
        [0x555555, 0x000000, 0xAAAAAA, 0x000000, 0xAAAAAA, 0, 0x000000],
        [0xFFFFFF, 0xFFFFFF, 0xAAAAAA, 0xFFFFFF, 0x555555, 1, 0xAAAAAA],
        [0xFFFFAA, 0xFFFFAA, 0xAAAA55, 0xFFFFAA, 0x555500, 1, 0xFFFF55],
        [0x000000, 0x000000, 0x555555, 0x000000, 0xAAAAAA, 0, 0x555555],
        [0x005555, 0x000000, 0x00AAAA, 0x000000, 0x55AAAA, 0, 0x005555],
        [0x555500, 0x000000, 0xAAAA00, 0x000000, 0xAAAA55, 0, 0x555500],
        [0x550055, 0x000000, 0xAA00AA, 0x000000, 0xAA55AA, 0, 0x550055]
    ];
    const ACCENTS = [
        0xC9A24A, 0xD0D4DA, 0xD89A7E, 0x4A90E2, 0xFFD500, 0x4CC36A, 0xF08A24, 0xFFFFFF,
        0xE5483E, 0x35D6E0, 0xE060C0, 0x9CE04A, 0xFFB000, 0x2FA89B, 0xB87333, 0x8A9096
    ];
    const ACCENTS_MIP = [
        0xFFAA00, 0xAAAAAA, 0xFFAA55, 0x00AAFF, 0xFFFF00, 0x55FF00, 0xFF5500, 0xFFFFFF,
        0xFF0000, 0x00FFFF, 0xFF55FF, 0xAAFF55, 0xFFAA00, 0x00AAAA, 0xAA5500, 0x555555
    ];
    const LUMES = [
        0xF4F4F0, 0xCFE6FF, 0xC8CCD2, 0xFF7A1A, 0xF5E27A, 0x9EF0E0,
        0xFFB000, 0xE5483E, 0x5ED17A, 0x1A1A1A, 0xEFE3C6, 0x6FC3FF
    ];
    const LUMES_MIP = [
        0xFFFFFF, 0xAAFFFF, 0xAAAAAA, 0xFF5500, 0xFFFF55, 0x55FFFF,
        0xFFAA00, 0xFF0000, 0x55FF55, 0x000000, 0xFFFFAA, 0x55AAFF
    ];
    const TEXTS       = [0xD0D4DA, 0xFFFFFF];
    const TEXTS_MIP   = [0xAAAAAA, 0xFFFFFF];
    const SECONDS     = [0xFF7A1A, 0xE5483E, -2, -1, 0xFFD500, 0x35D6E0, 0x9CE04A, 0xFFFFFF];
    const SECONDS_MIP = [0xFF5500, 0xFF0000, -2, -1, 0xFFFF00, 0x00FFFF, 0xAAFF55, 0xFFFFFF];
    const TZ_COLS     = [-1, 0x4A90E2, 0xFF7A1A, 0xFFD500, 0x4CC36A, 0xE5483E, 0x35D6E0, 0xFFFFFF];

    // Ready-made looks: [theme, accent, hands, seconds, numerals, ring, pattern, handStyle]
    const PRESETS = [
        [7, 15,  9, 1, 0, 4, 0, 0],   // Retro cream gauge
        [1, 12,  6, 0, 1, 1, 0, 0],   // Amber night
        [6, 15,  9, 0, 0, 0, 0, 2],   // White sport
        [8,  1,  0, 5, 3, 4, 0, 1],   // Minimal dark
        [9, 14, 10, 0, 2, 1, 0, 0]    // Petrol tacho
    ];

    const FACES = [
        null,                                                               // System
        ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular"],
        ["RobotoRegular", "RobotoCondensedRegular"],
        ["BionicBold", "BionicSemiBold", "RobotoCondensedBold"],
        ["Swiss721Bold", "Swiss721Regular", "RobotoCondensedBold"],
        ["PridiBold", "PridiRegular", "RobotoRegular"],
        null,   // 6 Pixel (built-in, drawn by code)
        null,   // 7 Instrument (Barlow Semi Condensed)
        null,   // 8 Bauhaus (Jost)
        null,   // 9 Wide technical (Michroma)
        null,   // 10 Condensed (Oswald)
        null,   // 11 Techno (Orbitron)
        null,   // 12 Squarish (Rajdhani)
        null    // 13 Tall gauge (Teko)
    ];
    const FONT_PIXEL = 6;

    const K_HR = 0;
    const K_STEPS = 1;
    const K_KCAL = 2;
    const K_TEMP = 3;
    const K_BATT = 4;
    const K_OFF = 5;
    const K_SOLAR = 6;
    const K_BODY = 7;
    const K_STRESS = 8;
    const K_NOTIF = 9;
    const K_DATE = 10;
    const K_TZ2 = 11;
    const K_WEATHER = 12;
    const K_SUNRISE = 13;
    const K_SUNSET = 14;
    const K_SUN = 15;

    // weather condition icons
    const WX_SUN   = [0x92, 0x54, 0x38, 0xFE, 0x38, 0x54, 0x92, 0x00];
    const WX_CLOUD = [0x00, 0x30, 0x7C, 0xFE, 0xFF, 0x7E, 0x00, 0x00];
    const WX_RAIN  = [0x30, 0x7C, 0xFE, 0xFF, 0x7E, 0x00, 0x49, 0x92];
    const WX_SNOW  = [0x30, 0x7C, 0xFE, 0xFF, 0x7E, 0x00, 0xAA, 0x55];
    const WX_STORM = [0x30, 0x7C, 0xFE, 0xFF, 0x7E, 0x0C, 0x18, 0x10];
    const WX_FOG   = [0x00, 0xFF, 0x00, 0x7E, 0x00, 0xFF, 0x00, 0x7E];

    // bundled fonts (open licence, see LICENSES folder): pixel heights available
    const CUSTOM_SIZES = [12, 15, 18, 22, 27, 33, 40];
    const FONT_CUSTOM = 7;

    // 8x8 pixel icons, one byte per row, bit 7 = left
    const ICONS = [
        [0x66, 0xFF, 0xFF, 0xFF, 0x7E, 0x3C, 0x18, 0x00], // heart
        [0x00, 0x38, 0x38, 0x3C, 0x3E, 0xFF, 0xFF, 0x00], // shoe
        [0x10, 0x30, 0x34, 0x7C, 0x7E, 0xE7, 0x66, 0x3C], // flame
        [0x18, 0x24, 0x24, 0x3C, 0x3C, 0x7E, 0x7E, 0x3C], // thermometer
        [0x00, 0xFE, 0x83, 0xBB, 0xBB, 0x83, 0xFE, 0x00], // battery
        null,
        [0x92, 0x54, 0x38, 0xFE, 0x38, 0x54, 0x92, 0x00], // sun
        [0x0C, 0x18, 0x30, 0x7E, 0x0C, 0x18, 0x30, 0x20], // bolt
        [0x3C, 0x5A, 0x99, 0x99, 0x81, 0x99, 0x42, 0x3C], // stress
        [0x18, 0x3C, 0x7E, 0x7E, 0x7E, 0xFF, 0x00, 0x18], // bell
        [0x42, 0xFF, 0x81, 0xA9, 0x81, 0xA9, 0x81, 0xFF], // calendar
        [0x3C, 0x5A, 0x99, 0xFF, 0x99, 0x5A, 0x3C, 0x00], // globe
        [0x00, 0x30, 0x7C, 0xFE, 0xFF, 0x7E, 0x00, 0x00], // weather (replaced by condition icon)
        [0x10, 0x38, 0x7C, 0x00, 0x38, 0x7C, 0xFE, 0xFF], // sunrise
        [0x7C, 0x38, 0x10, 0x00, 0x38, 0x7C, 0xFE, 0xFF], // sunset
        [0x10, 0x38, 0x7C, 0x00, 0x38, 0x7C, 0xFE, 0xFF]  // sunrise + sunset
    ];
    const ICON_PHONE = [0x3C, 0x24, 0x24, 0x24, 0x24, 0x3C, 0x24, 0x3C];
    const ICON_ALARM = [0x18, 0x3C, 0x7E, 0x7E, 0x7E, 0xFF, 0x00, 0x18];

    // 5x7 pixel font, ASCII 32..95 (5 columns each, bit 0 = top row). '_' slot holds the degree sign.
    const GLYPHS = [
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x23, 0x13, 0x08, 0x64, 0x62, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x08, 0x3E, 0x08, 0x08,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x08, 0x08, 0x08, 0x08, 0x00, 0x60, 0x60, 0x00, 0x00, 0x20, 0x10, 0x08, 0x04, 0x02,
        0x3E, 0x51, 0x49, 0x45, 0x3E, 0x00, 0x42, 0x7F, 0x40, 0x00, 0x42, 0x61, 0x51, 0x49, 0x46, 0x21, 0x41, 0x45, 0x4B, 0x31,
        0x18, 0x14, 0x12, 0x7F, 0x10, 0x27, 0x45, 0x45, 0x45, 0x39, 0x3C, 0x4A, 0x49, 0x49, 0x30, 0x01, 0x71, 0x09, 0x05, 0x03,
        0x36, 0x49, 0x49, 0x49, 0x36, 0x06, 0x49, 0x49, 0x29, 0x1E, 0x00, 0x36, 0x36, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x7E, 0x11, 0x11, 0x11, 0x7E, 0x7F, 0x49, 0x49, 0x49, 0x36, 0x3E, 0x41, 0x41, 0x41, 0x22,
        0x7F, 0x41, 0x41, 0x22, 0x1C, 0x7F, 0x49, 0x49, 0x49, 0x41, 0x7F, 0x09, 0x09, 0x09, 0x01, 0x3E, 0x41, 0x49, 0x49, 0x7A,
        0x7F, 0x08, 0x08, 0x08, 0x7F, 0x00, 0x41, 0x7F, 0x41, 0x00, 0x20, 0x40, 0x41, 0x3F, 0x01, 0x7F, 0x08, 0x14, 0x22, 0x41,
        0x7F, 0x40, 0x40, 0x40, 0x40, 0x7F, 0x02, 0x0C, 0x02, 0x7F, 0x7F, 0x04, 0x08, 0x10, 0x7F, 0x3E, 0x41, 0x41, 0x41, 0x3E,
        0x7F, 0x09, 0x09, 0x09, 0x06, 0x3E, 0x41, 0x51, 0x21, 0x5E, 0x7F, 0x09, 0x19, 0x29, 0x46, 0x46, 0x49, 0x49, 0x49, 0x31,
        0x01, 0x01, 0x7F, 0x01, 0x01, 0x3F, 0x40, 0x40, 0x40, 0x3F, 0x1F, 0x20, 0x40, 0x20, 0x1F, 0x3F, 0x40, 0x38, 0x40, 0x3F,
        0x63, 0x14, 0x08, 0x14, 0x63, 0x07, 0x08, 0x70, 0x08, 0x07, 0x61, 0x51, 0x49, 0x45, 0x43, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x09, 0x09, 0x06
    ];

    var isMip = false;
    var awake = true;

    // colours
    var th, lume, accent, textCol, secCol, patCol;
    // style & sizes
    var fontStyle, usePixel, labelIcons, handStyle, pattern, pixelSize;
    var textScale, handScale, markerScale, subScale;
    var showSeconds, showMinuteTicks, dialLabel, tapToOpen;
    // time
    var homeOffset, homeDst, tz2Label, tz2Offset, tz2Dst;
    // slots
    var slotTop, slotLeft, slotRight, win3, win9, win6, slotDialText;
    var batteryMode, tempSource, calorieGoal;

    // geometry & cache
    var ringMode = 0;
    var showFrames = false;
    var dateNeighbors = true;
    var homeLocal = 0;
    var homeOff = 0;
    var cityIdx = 0;
    var sunMarks = 1;
    var tz2Hand = true;
    var tz2HandCol = 0;
    var sunDay = -1;
    var sunRise = null;
    var sunSet = null;
    var fontCache = {};
    var preset = 0;
    var hubStyle = 1;
    var dialLabel2 = "";
    var dialLabel3 = "";
    var statusIcons = 1;
    var nowSec = 0;
    var dataCache = {};
    var dataAt = 0;
    var timeCorrect = false;
    var numeralStyle = 0;
    var fNum = null;
    var geomR = -1;
    var bw = 0.0;
    var D = 0.0;
    var fValue, fWin, fLabel;
    var lastVector = false;
    var bg = null;
    var bgFailed = false;
    var regions = [];
    var homeInfo = null;
    var tzInfo = null;
    var compTemp = null; // complication data for temperature, weather fix 
    var compReady = false; // complication data ready flag

        // Subscribe to Garmin's temperature complication (fed by the phone / weather apps)
/*    function initComplications() {
        if (compReady || !(Toybox has :Complications)) {
            return;
        }
        compReady = true;
        try {
            Complications.registerComplicationChangeCallback(method(:onComplicationChanged));
            Complications.subscribeToUpdates(new Complications.Id(Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE));
        } catch (e) {
            compReady = false;
        }
    }
*/
        // Look through every published complication (built-in AND from installed apps)
    // and subscribe to the first whose label contains the hint, e.g. "ATMOS".
    function initComplications() {
        if (compReady || !(Toybox has :Complications)) {
            return;
        }
        compReady = true;
        try {
            Complications.registerComplicationChangeCallback(method(:onComplicationChanged));
            var it = Complications.getComplications();
            var comp = it.next();
            while (comp != null) {
                var label = (comp.longLabel != null) ? comp.longLabel : comp.shortLabel;
                if (label != null && label.toUpper().find("ATMOS") != null) {
                    Complications.subscribeToUpdates(comp.complicationId);
                    return;
                }
                comp = it.next();
            }
            // no Atmos complication found: fall back to Garmin's own temperature
            Complications.subscribeToUpdates(new Complications.Id(Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE));
        } catch (e) {
            compReady = false;
        }
    }

 /*   function onComplicationChanged(id) {
        try {
            var comp = Complications.getComplication(id);
            if (comp != null && comp.value != null) {
                compTemp = comp.value.toFloat();
                WatchUi.requestUpdate();
            }
        } catch (e) {
            compTemp = null;
        }
    } 
*/
    function onComplicationChanged(id as Complications.Id) as Void {
        try {
            var comp = Complications.getComplication(id);
            if (comp != null && comp.value != null) {
                compTemp = (comp.value instanceof Lang.String) ? comp.value.toFloat() : comp.value.toFloat();
                WatchUi.requestUpdate();
            }
        } catch (e) {
            compTemp = null;
        }
    }

    function initialize() {
        WatchFace.initialize();
        isMip = !System.getDeviceSettings().requiresBurnInProtection;
        loadSettings();
    }

    function prop(key, def) {
        var v = null;
        try {
            v = Application.Properties.getValue(key);
        } catch (e) {
            v = null;
        }
        return (v == null) ? def : v;
    }

    function clampIdx(v, size) {
        v = v.toNumber();
        return (v < 0 || v >= size) ? 0 : v;
    }

    function pick(list, listMip, idx) {
        var l = isMip ? listMip : list;
        return l[clampIdx(idx, l.size())];
    }

    function pct(key, def) {
        return prop(key, def).toFloat() / 100.0;
    }

    function c(col) {
        if (!isMip) { return col; }
        var r = (((col >> 16) & 0xFF) + 42) / 85 * 85;
        var g = (((col >> 8) & 0xFF) + 42) / 85 * 85;
        var b = ((col & 0xFF) + 42) / 85 * 85;
        return (r << 16) | (g << 8) | b;
    }

    function loadSettings() {
        var themes = isMip ? THEMES_MIP : THEMES;
        preset = clampIdx(prop("Preset", 0), PRESETS.size() + 1);

        var themeIdx = prop("Theme", 1).toNumber();
        var accIdx   = prop("Accent", 1).toNumber();
        var lumeIdx  = prop("LumeColor", 0).toNumber();
        var secIdx   = prop("SecondsColor", 1).toNumber();
        var numIdx   = prop("NumeralStyle", 0).toNumber();
        var ringIdx  = prop("RingMode", 0).toNumber();
        var patIdx   = prop("Pattern", 0).toNumber();
        var handIdx  = prop("HandStyle", 0).toNumber();
        if (preset > 0) {                      // a ready-made look overrides the colour settings
            var pr = PRESETS[preset - 1];
            themeIdx = pr[0]; accIdx = pr[1]; lumeIdx = pr[2]; secIdx = pr[3];
            numIdx = pr[4]; ringIdx = pr[5]; patIdx = pr[6]; handIdx = pr[7];
        }

        th = themes[clampIdx(themeIdx, themes.size())];
        var light = (th[5] == 1);
        lume = pick(LUMES, LUMES_MIP, lumeIdx);
        accent = pick(ACCENTS, ACCENTS_MIP, accIdx);
        if (light) {                            // white hands / pale accents vanish on a light dial
            if (lumeIdx == 0 || lumeIdx == 2) { lume = isMip ? 0x000000 : 0x1A1A1A; }
            if (accIdx == 1 || accIdx == 7) { accent = isMip ? 0x555555 : 0x4A4F55; }
        }

        var tc = prop("TextColor", 1).toNumber();
        if (tc == 2) {
            textCol = lume;
        } else if (tc == 3) {
            textCol = accent;
        } else if (light) {
            textCol = 0x000000;
        } else {
            textCol = pick(TEXTS, TEXTS_MIP, tc);
        }
        var sc = pick(SECONDS, SECONDS_MIP, secIdx);
        secCol = (sc == -1) ? accent : ((sc == -2) ? lume : sc);
        patCol = (prop("PatternContrast", 0).toNumber() == 1) ? th[4] : th[6];

        fontStyle  = clampIdx(prop("FontStyle", 7), FACES.size());
        usePixel   = (fontStyle == FONT_PIXEL);
        labelIcons = (prop("LabelStyle", 0).toNumber() == 0);
        handStyle  = clampIdx(handIdx, 3);
        pattern    = clampIdx(patIdx, 7);
        pixelSize  = prop("PixelSize", 3).toNumber();
        if (pixelSize < 1) { pixelSize = 1; }
        numeralStyle = clampIdx(numIdx, 4);
        ringMode     = clampIdx(ringIdx, 5);
        hubStyle     = clampIdx(prop("HubStyle", 1), 3);
        statusIcons  = clampIdx(prop("StatusIcons", 1), 3);

        textScale   = pct("TextScale", 90);
        handScale   = pct("HandScale", 100);
        markerScale = pct("MarkerScale", 100);
        subScale    = pct("SubdialScale", 100);

        showSeconds     = prop("ShowSeconds", true);
        showMinuteTicks = prop("ShowMinuteTicks", true);
        showFrames      = prop("ShowFrames", false);
        dateNeighbors   = prop("DateNeighbors", true);
        dialLabel       = prop("DialLabel", "KYIV").toString();
        dialLabel2      = prop("DialLabel2", "").toString();
        dialLabel3      = prop("DialLabel3", "").toString();
        tapToOpen       = prop("TapToOpen", true);
        timeCorrect     = prop("TimeCorrect", false);

        cityIdx  = prop("City", 0).toNumber();
        sunMarks = clampIdx(prop("SunMarks", 1), 3);
        tz2Hand  = prop("Tz2Hand", true);
        var hc = TZ_COLS[clampIdx(prop("Tz2HandColor", 0), TZ_COLS.size())];
        tz2HandCol = (hc == -1) ? accent : c(hc);

        homeOffset = prop("HomeOffset", 2).toNumber();
        homeDst    = prop("HomeDst", 1).toNumber();
        tz2Label   = prop("Tz2Label", "NY").toString();
        tz2Offset  = prop("Tz2Offset", -5).toNumber();
        tz2Dst     = prop("Tz2Dst", 2).toNumber();

        slotTop      = prop("SlotTop", K_OFF).toNumber();
        slotLeft     = prop("SlotLeft", K_BATT).toNumber();
        slotRight    = prop("SlotRight", K_STEPS).toNumber();
        win3         = prop("Window3", K_DATE).toNumber();
        win9         = prop("Window9", K_OFF).toNumber();
        win6         = prop("Window6", K_OFF).toNumber();
        slotDialText = prop("DialText", K_OFF).toNumber();

        batteryMode = prop("BatteryMode", 0).toNumber();
        tempSource  = prop("TempSource", 2).toNumber();
        calorieGoal = prop("CalorieGoal", 2500).toNumber();
        if (calorieGoal <= 0) { calorieGoal = 2500; }

        sunDay = -1;
        fontCache = {};
        dataCache = {};
        dataAt = 0;
        geomR = -1;
        bg = null;
        bgFailed = false;
    }

    function pickFont(px, minPx) {
        if (px < minPx) { px = minPx; }
        lastVector = false;
        if (usePixel) {
            var s = (px / 7.0 + 0.5).toNumber();
            return s < 1 ? 1 : s;               // pixel font: the "font" is its scale
        }
        if (fontStyle >= FONT_CUSTOM) {
            var best = 0;
            for (var j = 0; j < CUSTOM_SIZES.size(); j++) {
                if (CUSTOM_SIZES[j] <= px * 1.1) {
                    best = j;
                }
            }
            var key = fontStyle * 100 + best;
            if (!fontCache.hasKey(key)) {
                fontCache.put(key, WatchUi.loadResource(customFontIds()[best]));
            }
            return fontCache.get(key);
        }
        var faces = FACES[fontStyle];
        if (faces != null && (Graphics has :getVectorFont)) {
            var vf = Graphics.getVectorFont({ :face => faces, :size => px.toNumber() });
            if (vf != null) {
                lastVector = true;
                return vf;
            }
        }
        var list = [Graphics.FONT_XTINY, Graphics.FONT_TINY, Graphics.FONT_SMALL, Graphics.FONT_MEDIUM];
        var best = list[0];
        for (var i = 0; i < list.size(); i++) {
            if (Graphics.getFontHeight(list[i]) <= px * 1.2) {
                best = list[i];
            }
        }
        return best;
    }

    function customFontIds() {
        if (fontStyle == 8) {
            return [Rez.Fonts.jos12, Rez.Fonts.jos15, Rez.Fonts.jos18, Rez.Fonts.jos22, Rez.Fonts.jos27, Rez.Fonts.jos33, Rez.Fonts.jos40];
        }
        if (fontStyle == 9) {
            return [Rez.Fonts.mic12, Rez.Fonts.mic15, Rez.Fonts.mic18, Rez.Fonts.mic22, Rez.Fonts.mic27, Rez.Fonts.mic33, Rez.Fonts.mic40];
        }
        if (fontStyle == 10) {
            return [Rez.Fonts.osw12, Rez.Fonts.osw15, Rez.Fonts.osw18, Rez.Fonts.osw22, Rez.Fonts.osw27, Rez.Fonts.osw33, Rez.Fonts.osw40];
        }
        if (fontStyle == 11) {
            return [Rez.Fonts.orb12, Rez.Fonts.orb15, Rez.Fonts.orb18, Rez.Fonts.orb22, Rez.Fonts.orb27, Rez.Fonts.orb33, Rez.Fonts.orb40];
        }
        if (fontStyle == 12) {
            return [Rez.Fonts.raj12, Rez.Fonts.raj15, Rez.Fonts.raj18, Rez.Fonts.raj22, Rez.Fonts.raj27, Rez.Fonts.raj33, Rez.Fonts.raj40];
        }
        if (fontStyle == 13) {
            return [Rez.Fonts.tek12, Rez.Fonts.tek15, Rez.Fonts.tek18, Rez.Fonts.tek22, Rez.Fonts.tek27, Rez.Fonts.tek33, Rez.Fonts.tek40];
        }
        return [Rez.Fonts.bar12, Rez.Fonts.bar15, Rez.Fonts.bar18, Rez.Fonts.bar22, Rez.Fonts.bar27, Rez.Fonts.bar33, Rez.Fonts.bar40];
    }

    function setupGeometry(R) {
        bw = 0.0;
        D = R;
        var ts = textScale;
        fValue = pickFont(D * 0.16 * ts, isMip ? 16 : 0);
        fWin   = pickFont(D * 0.13 * ts, isMip ? 15 : 0);
        fLabel = pickFont(D * 0.085 * ts, isMip ? 11 : 0);
        fNum   = pickFont(D * 0.14 * ts * markerScale, isMip ? 16 : 0);
        geomR = R;
    }

    function subR() {
        return 0.18 * D * subScale;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var R = (w < h ? w : h) / 2;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(!isMip);
        }
        if (geomR != R) {
            setupGeometry(R);
            bg = null;
        }

        var now = Time.now().value();
        if (timeCorrect) {
            now -= clockDrift();     // use real internet time instead of the watch clock
        }
        nowSec = now;
        homeOff = zoneOffset(now, homeOffset, homeDst);
        homeLocal = now + homeOff;
        homeInfo = Gregorian.utcInfo(new Time.Moment(homeLocal), Time.FORMAT_MEDIUM);
        tzInfo = Gregorian.utcInfo(new Time.Moment(now + zoneOffset(now, tz2Offset, tz2Dst)), Time.FORMAT_SHORT);
        regions = [];
        initComplications();

        if (!awake && !isMip) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            drawLowPower(dc, cx, cy);
            return;
        }

        if (bg == null && !bgFailed) {
            buildBackground(w, h, cx, cy, R);
        }
        if (bg != null) {
            dc.drawBitmap(0, 0, bg);
        } else {
            drawStatic(dc, w, h, cx, cy, R, false);
        }

        drawRing(dc, cx, cy);
        drawSunMarks(dc, cx, cy);

        var r = subR();
        drawSubValue(dc, cx, cy - 0.40 * D, r, slotTop);
        drawSubValue(dc, cx - 0.36 * D, cy + 0.28 * D, r, slotLeft);
        drawSubValue(dc, cx + 0.36 * D, cy + 0.28 * D, r, slotRight);
        drawWindow(dc, win3, cx + 0.82 * D, cy, 1);
        drawWindow(dc, win9, cx - 0.82 * D, cy, 2);
        drawWindow(dc, win6, cx, cy + 0.82 * D, 3);
        drawDialText(dc, cx, cy - 0.40 * D + (slotTop == K_OFF ? 0 : r + 0.08 * D));
        drawStatusIcons(dc, cx, cy);

        drawHands(dc, cx, cy);
    }

    // ================= static dial (cached) =================

    function drawStatic(dc, w, h, cx, cy, R, cached) {
        dc.setColor(th[0], th[0]);
        dc.clear();
        if (cached) {
            drawPattern(dc, w, h);
        }
        drawDial(dc, cx, cy);

        var r = subR();
        drawSubFace(dc, cx, cy - 0.40 * D, r, slotTop);
        drawSubFace(dc, cx - 0.36 * D, cy + 0.28 * D, r, slotLeft);
        drawSubFace(dc, cx + 0.36 * D, cy + 0.28 * D, r, slotRight);

        drawDialLabels(dc, cx, cy);
    }

    // up to three lines of your own text under the centre
    function drawDialLabels(dc, cx, cy) {
        var lines = [dialLabel, dialLabel2, dialLabel3];
        var lh = textH(dc, fLabel);
        var y = cy + 0.19 * D;
        dc.setColor((th[5] == 1) ? textCol : th[4], T);
        for (var i = 0; i < 3; i++) {
            if (lines[i].length() > 0) {
                drawTextC(dc, cx, y, fLabel, lines[i]);
                y += lh * 1.05;
            }
        }
    }

    function labelBlockBottom(dc, cy) {
        var lines = [dialLabel, dialLabel2, dialLabel3];
        var lh = textH(dc, fLabel);
        var y = cy + 0.19 * D;
        for (var i = 0; i < 3; i++) {
            if (lines[i].length() > 0) {
                y += lh * 1.05;
            }
        }
        return y;
    }

    // alarm bell (and phone-disconnected icon) under the dial text
    function drawStatusIcons(dc, cx, cy) {
        if (statusIcons == 0) {
            return;
        }
        var ds = System.getDeviceSettings();
        var show = [];
        if (ds.alarmCount != null && ds.alarmCount > 0) {
            show.add([ICON_ALARM, accent]);
        }
        if (statusIcons == 2 && ds.phoneConnected != null && !ds.phoneConnected) {
            show.add([ICON_PHONE, c(0xE5483E)]);
        }
        if (show.size() == 0) {
            return;
        }
        var ip = iconPx(textH(dc, fLabel));
        var step = 10 * ip;
        var x = cx - (show.size() - 1) * step / 2;
        var y = labelBlockBottom(dc, cy) + 5 * ip;
        for (var i = 0; i < show.size(); i++) {
            dc.setColor(show[i][1], T);
            drawIconRows(dc, show[i][0], x + i * step, y, ip);
        }
    }

    // clock angle (degrees clockwise from 12) -> Garmin arc angle (degrees counter-clockwise from 3)
    function arcDeg(clockDeg) {
        var a = (90 - clockDeg).toNumber() % 360;
        return a < 0 ? a + 360 : a;
    }

    // Instrument-style scale: fine minute ticks, hour ticks, numerals, optional redline
    function drawDial(dc, cx, cy) {
        var ms = markerScale;
        var rOut = D * 0.975;
        var redline = (ringMode == 0);

        // outer track for the progress ring modes
        if (ringMode >= 1 && ringMode <= 3) {
            dc.setColor(th[2], T);
            dc.setPenWidth(penW(D * 0.012, 1));
            dc.drawCircle(cx, cy, D * 0.99);
            dc.setPenWidth(1);
        }
        if (redline) {
            dc.setColor(secCol, T);
            dc.setPenWidth(penW(D * 0.025 * ms, 2));
            dc.drawArc(cx, cy, D * 0.99, Graphics.ARC_CLOCKWISE, arcDeg(300), arcDeg(360));
            dc.setPenWidth(1);
        }

        for (var i = 0; i < 60; i++) {
            var a = i * Math.PI / 30;
            var sn = Math.sin(a);
            var cs = Math.cos(a);
            var inRed = redline && i >= 50;
            if (i % 5 == 0) {
                dc.setColor(inRed ? secCol : textCol, T);
                dc.setPenWidth(penW(D * 0.02 * ms, 2));
                var rIn = rOut - D * 0.09 * ms;
                dc.drawLine(cx + sn * rIn, cy - cs * rIn, cx + sn * rOut, cy - cs * rOut);
            } else if (showMinuteTicks) {
                dc.setColor(inRed ? secCol : th[4], T);
                dc.setPenWidth(isMip ? 2 : penW(D * 0.007 * ms, 1));
                var rIn2 = rOut - D * 0.045 * ms;
                dc.drawLine(cx + sn * rIn2, cy - cs * rIn2, cx + sn * rOut, cy - cs * rOut);
            }
        }
        dc.setPenWidth(1);

        // numerals
        if (numeralStyle == 3) {
            return;
        }
        var rn = rOut - D * 0.09 * ms - textH(dc, fNum) * 0.75;
        for (var hr = 1; hr <= 12; hr++) {
            if (numeralStyle == 1 && hr % 3 != 0) {
                continue;
            }
            if ((hr == 3 && win3 != K_OFF) || (hr == 6 && win6 != K_OFF) || (hr == 9 && win9 != K_OFF)) {
                continue;
            }
            var text = (numeralStyle == 2) ? (hr * 5).toString() : hr.toString();
            var a2 = hr * Math.PI / 6;
            dc.setColor((redline && hr >= 11) ? secCol : textCol, T);
            drawTextC(dc, cx + Math.sin(a2) * rn, cy - Math.cos(a2) * rn, fNum, text);
        }
    }

    // ================= dynamic ring =================
    // 1 = minutes of the hour, 2 = battery, 3 = step goal
    function drawRing(dc, cx, cy) {
        if (ringMode < 1 || ringMode > 3) {
            return;
        }
        var frac = 0.0;
        var col = secCol;
        if (ringMode == 1) {
            frac = (homeInfo.min + homeInfo.sec / 60.0) / 60.0;
        } else if (ringMode == 2) {
            var b = System.getSystemStats().battery;
            frac = b / 100.0;
            col = battColor(b);
        } else {
            var d = slotData(K_STEPS);
            frac = d[1];
            col = accent;
        }
        if (frac > 1.0) { frac = 1.0; }
        if (frac < 0.005) {
            return;
        }
        dc.setColor(col, T);
        dc.setPenWidth(penW(D * 0.025, 2));
        if (frac >= 0.999) {
            dc.drawCircle(cx, cy, D * 0.99);
        } else {
            dc.drawArc(cx, cy, D * 0.99, Graphics.ARC_CLOCKWISE, arcDeg(0), arcDeg(frac * 360));
        }
        dc.setPenWidth(1);
    }

    // ================= hands =================

    function drawHands(dc, cx, cy) {
        var t = homeInfo;
        var hs = handScale;
        var hourA = ((t.hour % 12) + t.min / 60.0) * Math.PI / 6;
        var minA = (t.min + t.sec / 60.0) * Math.PI / 30;
        if (tz2Hand) {
            drawTz2Hand(dc, cx, cy);
        }
        drawHand(dc, cx, cy, hourA, D * 0.52, D * 0.07 * hs, D * 0.10, false);
        drawHand(dc, cx, cy, minA, D * 0.84, D * 0.05 * hs, D * 0.12, false);

        var secOn = awake && showSeconds;
        if (secOn) {
            var a = t.sec * Math.PI / 30;
            var sn = Math.sin(a);
            var cs = Math.cos(a);
            var w = D * 0.022 * hs;
            dc.setColor(secCol, T);
            dc.fillPolygon(toScreen(cx, cy, sn, cs,
                [[-D * 0.22, w * 0.5], [0, w * 0.5], [D * 0.93, w * 0.15], [D * 0.93, -w * 0.15], [0, -w * 0.5], [-D * 0.22, -w * 0.5]]));
        }

        // hub: 0 none, 1 small dot, 2 instrument ring
        var hub = D * 0.075 * hs;
        if (hubStyle == 2) {
            dc.setColor(th[1], th[1]);
            dc.fillCircle(cx, cy, hub);
            dc.setColor(accent, T);
            dc.setPenWidth(penW(D * 0.012, 2));
            dc.drawCircle(cx, cy, hub);
            dc.setPenWidth(1);
        }
        if (hubStyle >= 1) {
            dc.setColor(secOn ? secCol : accent, T);
            dc.fillCircle(cx, cy, hub * (hubStyle == 2 ? 0.35 : 0.28));
        }
    }

    // style: 0 needle, 1 baton, 2 sword
    function drawHand(dc, cx, cy, a, L, W, tail, outlineOnly) {
        var sn = Math.sin(a);
        var cs = Math.cos(a);
        var pts;
        if (handStyle == 1) {
            pts = [[-tail, W / 2], [L, W / 2], [L, -W / 2], [-tail, -W / 2]];
        } else if (handStyle == 2) {
            pts = [[-tail, W * 0.25], [L * 0.72, W / 2], [L, 0], [L * 0.72, -W / 2], [-tail, -W * 0.25]];
        } else {
            pts = [[-tail, W * 0.35], [0, W / 2], [L, W * 0.12], [L, -W * 0.12], [0, -W / 2], [-tail, -W * 0.35]];
        }
        var poly = toScreen(cx, cy, sn, cs, pts);
        dc.setColor(lume, T);
        if (outlineOnly) {
            drawPolyOutline(dc, poly);
        } else {
            dc.fillPolygon(poly);
        }
    }

    // AMOLED always-on: hour dots + hand outlines, shifted each minute against burn-in
    function drawLowPower(dc, cx, cy) {
        var shifts = [[0, 0], [2, 0], [2, 2], [0, 2]];
        var s = shifts[homeInfo.min % 4];
        var x = cx + s[0];
        var y = cy + s[1];
        dc.setColor(th[4], T);
        for (var i = 0; i < 12; i++) {
            var a = i * Math.PI / 6;
            dc.fillCircle(x + Math.sin(a) * D * 0.93, y - Math.cos(a) * D * 0.93, i % 3 == 0 ? 3 : 1);
        }
        var t = homeInfo;
        drawHand(dc, x, y, ((t.hour % 12) + t.min / 60.0) * Math.PI / 6, D * 0.52, D * 0.07 * handScale, 0, true);
        drawHand(dc, x, y, t.min * Math.PI / 30, D * 0.84, D * 0.05 * handScale, 0, true);
    }

    function textW(dc, f, text) {
        return usePixel ? text.length() * 6 * f - f : dc.getTextWidthInPixels(text, f);
    }

    function textH(dc, f) {
        return usePixel ? 7 * f : dc.getFontHeight(f);
    }

    function drawTextC(dc, x, y, f, text) {
        if (usePixel) {
            pxDraw(dc, x, y, text, f);
        } else {
            dc.drawText(x, y, f, text, CENTER);
        }
    }

    function pxDraw(dc, x, y, text, sc) {
        var w = text.length() * 6 * sc - sc;
        var x0 = (x - w / 2.0).toNumber();
        var y0 = (y - 3.5 * sc).toNumber();
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var code = chars[i].toNumber();
            if (code >= 97 && code <= 122) { code -= 32; }
            if (code == 176) { code = 95; }
            if (code < 32 || code > 95) { code = 32; }
            var base = (code - 32) * 5;
            for (var col = 0; col < 5; col++) {
                var bits = GLYPHS[base + col];
                if (bits != 0) {
                    for (var row = 0; row < 7; row++) {
                        if ((bits & (1 << row)) != 0) {
                            dc.fillRectangle(x0 + col * sc, y0 + row * sc, sc, sc);
                        }
                    }
                }
            }
            x0 += 6 * sc;
        }
    }

    function drawIcon(dc, kind, x, y, px, col) {
        if (kind < 0 || kind >= ICONS.size() || ICONS[kind] == null) {
            return;
        }
        var rows = (kind == K_WEATHER) ? weatherIcon() : ICONS[kind];
        dc.setColor(col, T);
        drawIconRows(dc, rows, x, y, px);
    }

    function drawIconRows(dc, rows, x, y, px) {
        var x0 = (x - 4 * px).toNumber();
        var y0 = (y - 4 * px).toNumber();
        for (var r = 0; r < 8; r++) {
            var bits = rows[r];
            for (var k = 0; k < 8; k++) {
                if ((bits & (0x80 >> k)) != 0) {
                    dc.fillRectangle(x0 + k * px, y0 + r * px, px, px);
                }
            }
        }
    }

    function iconPx(h) {
        var p = (h * 0.11 + 0.5).toNumber();
        return p < 1 ? 1 : p;
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onExitSleep() as Void {
        awake = true;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        awake = false;
        WatchUi.requestUpdate();
    }

    function buildBackground(w, h, cx, cy, R) {
        if (!(Graphics has :createBufferedBitmap)) {
            bgFailed = true;
            return;
        }
        try {
            var ref = Graphics.createBufferedBitmap({ :width => w, :height => h });
            var bdc = ref.get().getDc();
            if (bdc has :setAntiAlias) {
                bdc.setAntiAlias(!isMip);
            }
            drawStatic(bdc, w, h, cx, cy, R, true);
            bg = ref;
        } catch (e) {
            bg = null;
            bgFailed = true;
        }
    }

    function drawPattern(dc, w, h) {
        if (pattern == 0) {
            return;
        }
        var cells = [];
        var tw = 1;
        var tht = 1;
        if (pattern == 1) {            // waves
            tw = 16; tht = 8;
            for (var x = 0; x < 16; x++) {
                cells.add([x, (3.5 + 2.5 * Math.sin(2 * Math.PI * x / 16.0)).toNumber()]);
            }
        } else if (pattern == 2) {     // grid
            tw = 6; tht = 6;
            for (var i = 0; i < 6; i++) {
                cells.add([i, 0]);
                if (i > 0) { cells.add([0, i]); }
            }
        } else if (pattern == 3) {     // checker (dither)
            tw = 2; tht = 2;
            cells = [[0, 0], [1, 1]];
        } else if (pattern == 4) {     // dots
            tw = 4; tht = 4;
            cells = [[1, 1]];
        } else if (pattern == 5) {     // bubbles
            tw = 16; tht = 16;
            cells = [[2, 3], [9, 1], [13, 6], [5, 9], [11, 12], [1, 14], [7, 5], [14, 15], [4, 12], [10, 8],
                     [6, 1], [7, 1], [6, 2], [7, 2]];
        } else {                       // diagonal
            tw = 4; tht = 4;
            cells = [[0, 0], [1, 1], [2, 2], [3, 3]];
        }
        var p = pixelSize;
        try {
            var tile = Graphics.createBufferedBitmap({ :width => tw * p, :height => tht * p });
            var tdc = tile.get().getDc();
            tdc.setColor(th[0], th[0]);
            tdc.clear();
            tdc.setColor(patCol, T);
            for (var k = 0; k < cells.size(); k++) {
                tdc.fillRectangle(cells[k][0] * p, cells[k][1] * p, p, p);
            }
            for (var y = 0; y < h; y += tht * p) {
                for (var x2 = 0; x2 < w; x2 += tw * p) {
                    dc.drawBitmap(x2, y, tile);
                }
            }
        } catch (e) {
            // not enough graphics memory: plain dial
        }
    }

    function drawSubFace(dc, x, y, r, kind) {
        if (kind == K_OFF) {
            return;
        }
        if (showFrames) {
            dc.setColor(th[1], th[1]);
            dc.fillCircle(x, y, r);
            dc.setColor(accent, T);
            dc.setPenWidth(penW(r * 0.06, 2));
            dc.drawCircle(x, y, r);
            dc.setPenWidth(1);
        }

        if (kind == K_TZ2) {
            for (var i = 0; i < 12; i++) {
                var a = i * Math.PI / 6;
                dc.setColor(i % 3 == 0 ? textCol : th[4], T);
                dc.setPenWidth(i % 3 == 0 ? 2 : 1);
                dc.drawLine(x + Math.sin(a) * r * 0.76, y - Math.cos(a) * r * 0.76,
                            x + Math.sin(a) * r * 0.92, y - Math.cos(a) * r * 0.92);
            }
            dc.setPenWidth(1);
            dc.setColor(accent, T);
            drawTextC(dc, x, y + r * 0.45, fLabel, tz2Label);
            return;
        }
        dc.setPenWidth(penW(r * 0.12, 3));
        dc.setColor(th[2], T);
        dc.drawArc(x, y, r * 0.76, Graphics.ARC_CLOCKWISE, 225, 315);
        dc.setPenWidth(1);
        if (labelIcons) {
            drawIcon(dc, kind, x, y + r * 0.60, iconPx(textH(dc, fLabel)), kindColor(kind));
        } else {
            dc.setColor(accent, T);
            drawTextC(dc, x, y + r * 0.62, fLabel, kindLabel(kind));
        }
    }

    function drawSubValue(dc, x, y, r, kind) {
        if (kind == K_OFF) {
            return;
        }
        regions.add([kind, x - r, y - r, x + r, y + r]);
        if (kind == K_TZ2) {
            var hA = ((tzInfo.hour % 12) + tzInfo.min / 60.0) * Math.PI / 6;
            var mA = tzInfo.min * Math.PI / 30;
            dc.setColor(lume, T);
            dc.setPenWidth(penW(r * 0.11, 3));
            dc.drawLine(x, y, x + Math.sin(hA) * r * 0.48, y - Math.cos(hA) * r * 0.48);
            dc.setPenWidth(penW(r * 0.06, 2));
            dc.drawLine(x, y, x + Math.sin(mA) * r * 0.78, y - Math.cos(mA) * r * 0.78);
            dc.setPenWidth(1);
            dc.setColor(accent, T);
            dc.fillCircle(x, y, r * 0.09);
            return;
        }
        var d = slotData(kind);
        if (d == null) {
            return;
        }
        var p = d[1];
        if (p > 1.0) { p = 1.0; }
        if (p > 0.01) {
            var endA = (225 - 270 * p).toNumber();
            if (endA < 0) { endA += 360; }
            dc.setPenWidth(penW(r * 0.12, 3));
            dc.setColor(d[3], T);
            dc.drawArc(x, y, r * 0.76, Graphics.ARC_CLOCKWISE, 225, endA);
            dc.setPenWidth(1);
        }
        // shrink the value if it would not fit inside the subdial
        var f = fValue;
        var maxW = r * 1.85;
        if (textW(dc, f, d[0]) > maxW) {
            f = fWin;
            if (textW(dc, f, d[0]) > maxW) {
                f = fLabel;
                if (usePixel && f > 1 && textW(dc, f, d[0]) > maxW) {
                    f = f - 1;
                }
            }
        }
        dc.setColor(textCol, T);
        drawTextC(dc, x, y - r * 0.06, f, d[0]);
    }

    function drawWindow(dc, kind, ax, ay, anchor) {
        var d = slotData(kind);
        if (d == null) {
            return;
        }
        var plain = (kind == K_DATE || kind == K_TZ2);
        var txt = (labelIcons || plain) ? d[0] : d[2] + " " + d[0];
        var fh = textH(dc, fWin);
        var ip = iconPx(fh);
        var iw = (labelIcons && !plain) ? 8 * ip + ip * 2 : 0;
        var tw = textW(dc, fWin, txt);
        var pad = fh * 0.22;
        if (pad < 3) { pad = 3; }
        var W = iw + tw + pad * 2;
        var H = fh + pad;
        var x0 = ax - W / 2;
        var y0 = ay - H / 2;
        if (anchor == 1) { x0 = ax - W; }
        if (anchor == 2) { x0 = ax; }
        if (anchor == 3) { y0 = ay - H; }

        if (showFrames) {
            dc.setColor(th[3], th[3]);
            dc.fillRoundedRectangle(x0, y0, W, H, 3);
            dc.setColor(accent, T);
            dc.setPenWidth(isMip ? 2 : penW(D * 0.008, 1));
            dc.drawRoundedRectangle(x0, y0, W, H, 3);
            dc.setPenWidth(1);
        }
        if (iw > 0) {
            drawIcon(dc, kind, x0 + pad + 4 * ip, y0 + H / 2, ip, d[3]);
        }
        dc.setColor(textCol, T);
        drawTextC(dc, x0 + pad + iw + tw / 2, y0 + H / 2, fWin, txt);
        if (kind == K_DATE && dateNeighbors) {
            drawDateNeighbors(dc, x0, y0, W, H, x0 + pad + tw, anchor);
        }
        regions.add([kind, x0, y0, x0 + W, y0 + H]);
    }

    // Yesterday and tomorrow in dim text, like a date wheel peeking out of the window.
    // Windows at 3 and 9: above and below the day number. Window at 6: left and right.
    function drawDateNeighbors(dc, x0, y0, W, H, textRight, anchor) {
        var prev = Gregorian.utcInfo(new Time.Moment(homeLocal - 86400), Time.FORMAT_SHORT).day.toString();
        var next = Gregorian.utcInfo(new Time.Moment(homeLocal + 86400), Time.FORMAT_SHORT).day.toString();
        var lh = textH(dc, fLabel);
        dc.setColor(th[4], T);
        if (anchor == 3) {
            var gap = lh * 0.5;
            var pw = textW(dc, fLabel, prev);
            var nw = textW(dc, fLabel, next);
            drawTextC(dc, x0 - gap - pw / 2, y0 + H / 2, fLabel, prev);
            drawTextC(dc, x0 + W + gap + nw / 2, y0 + H / 2, fLabel, next);
        } else {
            var dayW = textW(dc, fWin, homeInfo.day.toString());
            var dx = textRight - dayW / 2;
            drawTextC(dc, dx, y0 - lh * 0.55, fLabel, prev);
            drawTextC(dc, dx, y0 + H + lh * 0.55, fLabel, next);
        }
    }

    function drawDialText(dc, x, y) {
        var d = slotData(slotDialText);
        if (d == null) {
            return;
        }
        var fh = textH(dc, fLabel);
        var ip = iconPx(fh);
        var plain = (slotDialText == K_DATE || slotDialText == K_TZ2);
        var iw = (labelIcons && !plain) ? 10 * ip : 0;
        var txt = (labelIcons || plain) ? d[0] : d[2] + " " + d[0];
        var tw = textW(dc, fLabel, txt);
        var left = x - (iw + tw) / 2;
        if (iw > 0) {
            drawIcon(dc, slotDialText, left + 4 * ip, y, ip, d[3]);
        }
        dc.setColor(textCol, T);
        drawTextC(dc, left + iw + tw / 2, y, fLabel, txt);
        regions.add([slotDialText, left, y - fh / 2, left + iw + tw, y + fh / 2]);
    }

    function toScreen(cx, cy, sn, cs, pts) {
        var out = new [pts.size()];
        for (var i = 0; i < pts.size(); i++) {
            var t = pts[i][0];
            var o = pts[i][1];
            out[i] = [cx + sn * t + cs * o, cy - cs * t + sn * o];
        }
        return out;
    }

    function penW(v, minW) {
        var n = v.toNumber();
        return n < minW ? minW : n;
    }

    function radialQuad(cx, cy, a, rOut, rIn, width, off) {
        var sn = Math.sin(a);
        var cs = Math.cos(a);
        var hw = width / 2;
        return [[cx + sn * rOut + cs * (off + hw), cy - cs * rOut + sn * (off + hw)],
                [cx + sn * rOut + cs * (off - hw), cy - cs * rOut + sn * (off - hw)],
                [cx + sn * rIn + cs * (off - hw), cy - cs * rIn + sn * (off - hw)],
                [cx + sn * rIn + cs * (off + hw), cy - cs * rIn + sn * (off + hw)]];
    }

    function drawPolyOutline(dc, pts) {
        var n = pts.size();
        for (var i = 0; i < n; i++) {
            var p1 = pts[i];
            var p2 = pts[(i + 1) % n];
            dc.drawLine(p1[0], p1[1], p2[0], p2[1]);
        }
    }

    function kindLabel(kind) {
        var l = ["BPM", "STEPS", "KCAL", "TEMP", "BATT", null, "SUN", "BODY", "STRESS", "MSG", "DATE"];
        if (kind == K_TZ2) { return tz2Label; }
        if (kind == K_WEATHER) { return "WX"; }
        if (kind == K_SUNRISE) { return "RISE"; }
        if (kind == K_SUNSET) { return "SET"; }
        if (kind == K_SUN) { return "SUN"; }
        return (kind >= 0 && kind < l.size()) ? l[kind] : null;
    }

    function kindColor(kind) {
        var cols = [0xE5483E, 0x4CC36A, 0xF08A24, 0x4A90E2, 0x4CC36A, 0, 0xFFD500, 0x2EC4F0, 0xF2A33A, 0xB388FF];
        if (kind == K_DATE) { return textCol; }
        if (kind == K_TZ2) { return lume; }
        if (kind == K_WEATHER) { return c(0x4A90E2); }
        if (kind == K_SUNRISE || kind == K_SUN) { return c(0xFFD500); }
        if (kind == K_SUNSET) { return c(0xF08A24); }
        return (kind >= 0 && kind < cols.size()) ? c(cols[kind]) : textCol;
    }

    // Values change slowly, so each one is computed at most every 15 seconds and reused.
    function slotData(kind) {
        if (nowSec - dataAt > 15) {
            dataCache = {};
            dataAt = nowSec;
        }
        if (dataCache.hasKey(kind)) {
            return dataCache.get(kind);
        }
        var v = readSlot(kind);
        dataCache.put(kind, v);
        return v;
    }

    function readSlot(kind) {
        var label = kindLabel(kind);
        if (label == null) {
            return null;
        }
        var col = kindColor(kind);
        if (kind == K_HR) {
            var hr = getHeartRate();
            return [hr != null ? hr.toString() : "--", hr != null ? (hr - 40) / 140.0 : 0.0, label, col];
        }
        if (kind == K_STEPS) {
            var am = ActivityMonitor.getInfo();
            var st = (am.steps != null) ? am.steps : 0;
            var goal = (am.stepGoal != null && am.stepGoal > 0) ? am.stepGoal : 10000;
            return [formatK(st), st.toFloat() / goal, label, col];
        }
        if (kind == K_KCAL) {
            var am2 = ActivityMonitor.getInfo();
            var kc = (am2.calories != null) ? am2.calories : 0;
            return [formatK(kc), kc.toFloat() / calorieGoal, label, col];
        }
        if (kind == K_TEMP) {
            var t = getTemperature();
            if (t == null) {
                return ["--", 0.0, label, col];
            }
            var p = (t + 20) / 60.0;
            if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) {
                t = t * 9.0 / 5.0 + 32;
            }
            return [t.toNumber().toString() + "°", p, label, col];
        }
        if (kind == K_BATT) {
            var b = System.getSystemStats().battery;
            return [batteryText(), b / 100.0, label, battColor(b)];
        }
        if (kind == K_SOLAR) {
            var sol = getSolar();
            return [sol != null ? sol.toString() + "%" : "--", sol != null ? sol / 100.0 : 0.0, label, col];
        }
        if (kind == K_BODY) {
            var bb = getBodyBattery();
            return [bb != null ? bb.toString() : "--", bb != null ? bb / 100.0 : 0.0, label, col];
        }
        if (kind == K_STRESS) {
            var sv = getStress();
            return [sv != null ? sv.toString() : "--", sv != null ? sv / 100.0 : 0.0, label, col];
        }
        if (kind == K_NOTIF) {
            var n = System.getDeviceSettings().notificationCount;
            return [n.toString(), n / 10.0, label, col];
        }
        if (kind == K_DATE) {
            return [homeInfo.day_of_week.toUpper() + " " + homeInfo.day, 0.0, label, col];
        }
        if (kind == K_TZ2) {
            var hh = tzInfo.hour;
            if (!System.getDeviceSettings().is24Hour) {
                hh = hh % 12;
                if (hh == 0) { hh = 12; }
            }
            return [tz2Label + " " + hh.format("%02d") + ":" + tzInfo.min.format("%02d"), 0.0, label, col];
        }
        if (kind == K_WEATHER) {
            var wx = cityWeather();
            if (wx == null || wx["t"] == null) {
                return ["--", 0.0, label, col];
            }
            var wt = wx["t"].toFloat();
            var wp = (wt + 20) / 60.0;
            if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) {
                wt = wt * 9.0 / 5.0 + 32;
            }
            return [wt.toNumber().toString() + "°", wp, label, col];
        }
        if (kind == K_SUNRISE || kind == K_SUNSET || kind == K_SUN) {
            updateSun();
            var dayFrac = 0.0;
            if (sunRise != null && sunSet != null && sunSet > sunRise) {
                dayFrac = (Time.now().value() - sunRise).toFloat() / (sunSet - sunRise);
                if (dayFrac < 0) { dayFrac = 0.0; }
            }
            if (kind == K_SUNRISE) { return [clockText(sunRise), dayFrac, label, col]; }
            if (kind == K_SUNSET) { return [clockText(sunSet), dayFrac, label, col]; }
            return [clockText(sunRise) + " " + clockText(sunSet), dayFrac, label, col];
        }
        return null;
    }

    // ================= chosen city: weather + sun =================

    // Last weather fetched by the background service, only if it is for this city and < 6 h old
    function cityWeather() {
        var wx = null;
        try {
            wx = Application.Storage.getValue("wx");
        } catch (e) {
            wx = null;
        }
        if (wx == null || !(wx instanceof Lang.Dictionary)) {
            return null;
        }
        if (wx["ci"] == null || wx["ci"] != cityIdx) {
            return null;
        }
        if (wx["ts"] == null || Time.now().value() - wx["ts"] > 21600) {
            return null;
        }
        return wx;
    }

    // how many seconds the watch clock is ahead of real time (from the background check)
    function clockDrift() {
        var wx = null;
        try {
            wx = Application.Storage.getValue("wx");
        } catch (e) {
            wx = null;
        }
        if (wx == null || !(wx instanceof Lang.Dictionary) || wx["dr"] == null || wx["drts"] == null) {
            return 0;
        }
        if (Time.now().value() - wx["drts"] > 604800) {   // older than a week: ignore
            return 0;
        }
        var d = wx["dr"].toNumber();
        return (d > 86400 || d < -86400) ? 0 : d;
    }

    function usesCityWeather() {
        if (tempSource == 2 || timeCorrect) {
            return true;
        }
        var slots = [slotTop, slotLeft, slotRight, win3, win9, win6, slotDialText];
        for (var i = 0; i < slots.size(); i++) {
            if (slots[i] == K_WEATHER) {
                return true;
            }
        }
        return false;
    }

    // WMO weather code -> icon
    function weatherIcon() {
        var wx = cityWeather();
        if (wx == null || wx["c"] == null) {
            return WX_CLOUD;
        }
        var code = wx["c"].toNumber();
        if (code <= 1) { return WX_SUN; }
        if (code <= 3) { return WX_CLOUD; }
        if (code == 45 || code == 48) { return WX_FOG; }
        if ((code >= 71 && code <= 77) || code == 85 || code == 86) { return WX_SNOW; }
        if (code >= 95) { return WX_STORM; }
        return WX_RAIN;
    }

    function clockText(utcSec) {
        if (utcSec == null) {
            return "--:--";
        }
        var t = Gregorian.utcInfo(new Time.Moment(utcSec + homeOff), Time.FORMAT_SHORT);
        var hh = t.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hh = hh % 12;
            if (hh == 0) { hh = 12; }
        }
        return hh.format("%02d") + ":" + t.min.format("%02d");
    }

    function mod360(x) {
        return x - 360.0d * Math.floor(x / 360.0d);
    }

    // Sunrise / sunset for the chosen city (standard sunrise equation), once per local day. UTC seconds.
    function updateSun() {
        var day = homeLocal / 86400;
        if (day == sunDay) {
            return;
        }
        sunDay = day;
        var ll = CityData.selected();
        var lat = ll[0].toDouble();
        var lon = ll[1].toDouble();
        var rad = 3.14159265358979d / 180.0d;

        var utcNoon = day * 86400 + 43200 - homeOff;
        var days = (utcNoon - 946728000).toDouble() / 86400.0d;   // days since J2000
        var n = Math.floor(days + 0.5d).toDouble();
        var jStar = n - lon / 360.0d;
        var M = mod360(357.5291d + 0.98560028d * jStar);
        var C = 1.9148d * Math.sin(M * rad) + 0.02d * Math.sin(2 * M * rad) + 0.0003d * Math.sin(3 * M * rad);
        var lambda = mod360(M + C + 180.0d + 102.9372d);
        var transit = jStar + 0.0053d * Math.sin(M * rad) - 0.0069d * Math.sin(2 * lambda * rad);
        var sinD = Math.sin(lambda * rad) * Math.sin(23.4397d * rad);
        var cosD = Math.sqrt(1.0d - sinD * sinD);
        var cosW = (Math.sin(-0.833d * rad) - Math.sin(lat * rad) * sinD) / (Math.cos(lat * rad) * cosD);
        if (cosW > 1.0d || cosW < -1.0d) {
            sunRise = null;   // polar night / midnight sun
            sunSet = null;
            return;
        }
        var w = Math.acos(cosW) / rad;
        sunRise = (946728000.0d + (transit - w / 360.0d) * 86400.0d).toNumber();
        sunSet = (946728000.0d + (transit + w / 360.0d) * 86400.0d).toNumber();
    }

    // Small triangles on the outer ring at the sunrise / sunset position of the hour hand,
    // optionally with the times written next to them
    function drawSunMarks(dc, cx, cy) {
        if (sunMarks == 0) {
            return;
        }
        updateSun();
        if (sunRise == null) {
            return;
        }
        drawSunMark(dc, cx, cy, sunRise, c(0xFFD500));
        drawSunMark(dc, cx, cy, sunSet, c(0xF08A24));
    }

    function drawSunMark(dc, cx, cy, utcSec, col) {
        var t = Gregorian.utcInfo(new Time.Moment(utcSec + homeOff), Time.FORMAT_SHORT);
        var a = ((t.hour % 12) + t.min / 60.0) * Math.PI / 6;
        var sn = Math.sin(a);
        var cs = Math.cos(a);
        var tip = D * 0.90;
        var base = D * 0.995;
        var hw = D * 0.035 * markerScale;
        dc.setColor(col, T);
        dc.fillPolygon([[cx + sn * tip, cy - cs * tip],
                        [cx + sn * base + cs * hw, cy - cs * base + sn * hw],
                        [cx + sn * base - cs * hw, cy - cs * base - sn * hw]]);
        if (sunMarks == 2) {
            var rt = D * 0.975 - D * 0.09 * markerScale - textH(dc, fNum) * 1.5 - textH(dc, fLabel) * 0.6;
            drawTextC(dc, cx + sn * rt, cy - cs * rt, fLabel, clockText(utcSec));
        }
    }

    // Second time zone as an extra thin arrow hand on the main dial (12-hour)
    function drawTz2Hand(dc, cx, cy) {
        var a = ((tzInfo.hour % 12) + tzInfo.min / 60.0) * Math.PI / 6;
        var sn = Math.sin(a);
        var cs = Math.cos(a);
        var L = D * 0.70;
        dc.setColor(tz2HandCol, T);
        dc.setPenWidth(penW(D * 0.012 * handScale, 2));
        dc.drawLine(cx, cy, cx + sn * L * 0.9, cy - cs * L * 0.9);
        dc.setPenWidth(1);
        var hw = D * 0.035 * handScale;
        dc.fillPolygon(toScreen(cx, cy, sn, cs, [[L, 0], [L * 0.86, hw], [L * 0.86, -hw]]));
        var lr = L * 0.45;
        drawTextC(dc, cx + sn * lr + cs * hw * 2.2, cy - cs * lr + sn * hw * 2.2, fLabel, tz2Label);
    }

    function getHeartRate() {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate;
        }
        var invalid = ActivityMonitor.INVALID_HR_SAMPLE;
        var hasHistory = (ActivityMonitor has :getHeartRateHistory);
        if (hasHistory) {
            var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (sample != null && sample.heartRate != invalid) {
                return sample.heartRate;
            }
        }
        return null;
    }

    function getTemperature() {
        if (tempSource == 3 && compTemp != null) {
        return compTemp;
        }
        if (tempSource == 2) {
            var wx = cityWeather();
            return (wx != null && wx["t"] != null) ? wx["t"].toFloat() : null;
        }
        if (tempSource == 0 && (Toybox has :Weather)) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.temperature != null) {
                return cond.temperature;
            }
        }
        if ((Toybox has :SensorHistory) && (SensorHistory has :getTemperatureHistory)) {
            var smp = SensorHistory.getTemperatureHistory({ :period => 1 }).next();
            if (smp != null && smp.data != null) {
                return smp.data;
            }
        }
        return null;
    }

    function getBodyBattery() {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            var s = SensorHistory.getBodyBatteryHistory({ :period => 1 }).next();
            if (s != null && s.data != null) {
                return s.data.toNumber();
            }
        }
        return null;
    }

    function getStress() {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getStressHistory)) {
            var s = SensorHistory.getStressHistory({ :period => 1 }).next();
            if (s != null && s.data != null) {
                return s.data.toNumber();
            }
        }
        return null;
    }

    function getSolar() {
        var st = System.getSystemStats();
        if ((st has :solarIntensity) && st.solarIntensity != null && st.solarIntensity >= 0) {
            return st.solarIntensity;
        }
        return null;
    }

    function batteryText() {
        var st = System.getSystemStats();
        if (batteryMode == 1 && (st has :batteryInDays) && st.batteryInDays != null) {
            return st.batteryInDays.toNumber().toString() + "d";
        }
        return st.battery.toNumber().toString() + "%";
    }

    function formatK(v) {
        if (v >= 10000) {
            return (v / 1000.0).format("%.1f") + "k";
        }
        return v.toString();
    }

    function battColor(b) {
        return c(b > 30 ? 0x4CC36A : (b > 15 ? 0xF2C230 : 0xE5483E));
    }

    function handleTap(x, y) {
        if (!tapToOpen) {
            return false;
        }
        for (var i = regions.size() - 1; i >= 0; i--) {
            var r = regions[i];
            if (x >= r[1] && x <= r[3] && y >= r[2] && y <= r[4]) {
                return openKind(r[0]);
            }
        }
        return false;
    }

    function openKind(kind) {
        var hasComplications = (Toybox has :Complications);
        if (!hasComplications) {
            return false;
        }
        var type = complicationType(kind);
        if (type == null) {
            return false;
        }
        try {
            Complications.exitTo(new Complications.Id(type));
            return true;
        } catch (e) {
            return false;
        }
    }

    function complicationType(kind) {
        if (kind == K_HR)     { return Complications.COMPLICATION_TYPE_HEART_RATE; }
        if (kind == K_STEPS)  { return Complications.COMPLICATION_TYPE_STEPS; }
        if (kind == K_KCAL)   { return Complications.COMPLICATION_TYPE_CALORIES; }
        if (kind == K_TEMP)   { return Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE; }
        if (kind == K_BATT)   { return Complications.COMPLICATION_TYPE_BATTERY; }
        if (kind == K_SOLAR)  { return Complications.COMPLICATION_TYPE_SOLAR_INPUT; }
        if (kind == K_BODY)   { return Complications.COMPLICATION_TYPE_BODY_BATTERY; }
        if (kind == K_STRESS) { return Complications.COMPLICATION_TYPE_STRESS; }
        if (kind == K_NOTIF)  { return Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT; }
        if (kind == K_DATE)   { return Complications.COMPLICATION_TYPE_CALENDAR_EVENTS; }
        if (kind == K_WEATHER) { return Complications.COMPLICATION_TYPE_CURRENT_WEATHER; }
        if (kind == K_SUNRISE || kind == K_SUN) { return Complications.COMPLICATION_TYPE_SUNRISE; }
        if (kind == K_SUNSET) { return Complications.COMPLICATION_TYPE_SUNSET; }
        return null;
    }

    function zoneOffset(t, hours, dst) {
        var base = hours * 3600;
        if (dst == 0) {
            return base;
        }
        var year = Gregorian.utcInfo(new Time.Moment(t), Time.FORMAT_SHORT).year;
        if (dst == 1) {
            if (t >= lastSundayUtc(year, 3) + 3600 && t < lastSundayUtc(year, 10) + 3600) {
                return base + 3600;
            }
        } else if (dst == 2) {
            var start = nthSundayUtc(year, 3, 2) + (2 - hours) * 3600;
            var end = nthSundayUtc(year, 11, 1) + (1 - hours) * 3600;
            if (t >= start && t < end) {
                return base + 3600;
            }
        }
        return base;
    }

    function lastSundayUtc(year, month) {
        var m = Gregorian.moment({ :year => year, :month => month, :day => 31,
                                   :hour => 0, :minute => 0, :second => 0 });
        var dow = Gregorian.utcInfo(m, Time.FORMAT_SHORT).day_of_week;
        return m.value() - (dow - 1) * 86400;
    }

    function nthSundayUtc(year, month, n) {
        var m = Gregorian.moment({ :year => year, :month => month, :day => 1,
                                   :hour => 0, :minute => 0, :second => 0 });
        var dow = Gregorian.utcInfo(m, Time.FORMAT_SHORT).day_of_week;
        return m.value() + ((8 - dow) % 7 + 7 * (n - 1)) * 86400;
    }
}
