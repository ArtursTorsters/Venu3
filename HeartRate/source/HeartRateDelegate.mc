import Toybox.Lang;
import Toybox.WatchUi;

class HeartRateDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new HeartRateMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}