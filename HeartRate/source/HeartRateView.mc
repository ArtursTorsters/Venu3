import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

class HeartRateView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        System.println("TEST: View is showing!");
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Set text color to white
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Get screen dimensions
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Display test information
        dc.drawText(
            width / 2,
            height / 4,
            Graphics.FONT_LARGE,
            "TEST MODE",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            width / 2,
            height / 2,
            Graphics.FONT_MEDIUM,
            "App is Running!",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Show current time as proof it's updating
        var clockTime = System.getClockTime();
        var timeString = clockTime.hour.format("%02d") + ":" + clockTime.min.format("%02d");

        dc.drawText(
            width / 2,
            height * 3 / 4,
            Graphics.FONT_MEDIUM,
            timeString,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        System.println("TEST: View updated at " + timeString);
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
        System.println("TEST: View is hiding!");
    }
}
