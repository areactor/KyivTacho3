import Toybox.Application;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.System;
import Toybox.Time;

// Cities you can pick in settings (no GPS needed). Last list entry = custom latitude/longitude.
(:background)
module CityData {
    const COORDS = [
        [50.450, 30.523],   // Kyiv
        [49.839, 24.029],   // Lviv
        [46.482, 30.723],   // Odesa
        [49.993, 36.231],   // Kharkiv
        [48.464, 35.046],   // Dnipro
        [47.838, 35.139],   // Zaporizhzhia
        [49.233, 28.468],   // Vinnytsia
        [51.494, 31.294],   // Chernihiv
        [48.621, 22.288],   // Uzhhorod
        [48.922, 24.711],   // Ivano-Frankivsk
        [52.230, 21.011],   // Warsaw
        [52.520, 13.405],   // Berlin
        [51.507, -0.128],   // London
        [40.713, -74.006]   // New York
    ];

    function index() {
        var v = Application.Properties.getValue("City");
        return (v == null) ? 0 : v.toNumber();
    }

    function selected() {
        var i = index();
        if (i >= 0 && i < COORDS.size()) {
            return COORDS[i];
        }
        var lat = Application.Properties.getValue("CityLat");
        var lon = Application.Properties.getValue("CityLon");
        return [lat != null ? lat.toFloat() : 50.45, lon != null ? lon.toFloat() : 30.52];
    }
}

// Background service: asks Open-Meteo (free, no key) for the current weather at the chosen city.
// The request goes through the phone's Garmin Connect app.
(:background)
class WeatherService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    var wx = {};

    function onTemporalEvent() as Void {
        var ll = CityData.selected();
        var params = {
            "latitude" => ll[0].format("%.3f"),
            "longitude" => ll[1].format("%.3f"),
            "current" => "temperature_2m,weather_code",
            "timezone" => "UTC"
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest("https://api.open-meteo.com/v1/forecast", params, options, method(:onReceive));
    }

    // 1) weather for the chosen city
    function onReceive(responseCode as Lang.Number,
                       data as Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null) as Void {
        wx = { "ci" => CityData.index(), "ts" => Time.now().value() };
        if (responseCode == 200 && data instanceof Lang.Dictionary) {
            var cur = data.get("current");
            if (cur instanceof Lang.Dictionary) {
                var t = cur.get("temperature_2m");
                var c = cur.get("weather_code");
                wx.put("t", (t != null) ? (t as Lang.Numeric).toFloat() : null);
                wx.put("c", (c != null) ? (c as Lang.Numeric).toNumber() : null);
            }
        }
        // 2) real UTC time, to measure how far the watch clock has drifted
        Communications.makeWebRequest(
            "https://worldtimeapi.org/api/timezone/Etc/UTC",
            {},
            { :method => Communications.HTTP_REQUEST_METHOD_GET,
              :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON },
            method(:onTimeReceived));
    }

    function onTimeReceived(responseCode as Lang.Number,
                            data as Lang.Dictionary or Lang.String or PersistedContent.Iterator or Null) as Void {
        if (responseCode == 200 && data instanceof Lang.Dictionary && data.get("unixtime") != null) {
            var server = (data.get("unixtime") as Lang.Numeric).toNumber();
            wx.put("dr", Time.now().value() - server);   // watch minus real time
            wx.put("drts", Time.now().value());
        }
        Background.exit(wx);
    }
}
