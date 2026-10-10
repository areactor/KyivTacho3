import Toybox.WatchUi;

// Tap on a subdial / window -> open the matching Garmin widget (heart rate, steps, weather...)
class KyivTachoDelegate extends WatchUi.WatchFaceDelegate {
    var view;

    function initialize(v) {
        WatchFaceDelegate.initialize();
        view = v;
    }

    function onPress(clickEvent) {
        var xy = clickEvent.getCoordinates();
        return view.handleTap(xy[0], xy[1]);
    }
}
