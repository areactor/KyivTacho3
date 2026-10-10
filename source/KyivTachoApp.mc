import Toybox.Application;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

(:background)
class KyivTachoApp extends Application.AppBase {
    var view = null;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        view = new KyivTachoView();
        updateBackground();
        if (WatchUi has :WatchFaceDelegate) {
            return [ view, new KyivTachoDelegate(view) ];
        }
        return [ view ];
    }

    // Runs in the background every 30 minutes to fetch weather for the chosen city
    function getServiceDelegate() {
        return [ new WeatherService() ];
    }

    function onBackgroundData(data) {
        if (data != null) {
            Application.Storage.setValue("wx", data);
        }
        WatchUi.requestUpdate();
    }

    function onSettingsChanged() {
        if (view != null) {
            view.loadSettings();
        }
        updateBackground();
        WatchUi.requestUpdate();
    }

    function updateBackground() {
        var hasBg = (Toybox has :Background);
        if (!hasBg) {
            return;
        }
        if (view != null && view.usesCityWeather()) {
            Background.registerForTemporalEvent(new Time.Duration(30 * 60));
        } else {
            Background.deleteTemporalEvent();
        }
    }
}
