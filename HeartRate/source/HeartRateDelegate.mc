import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.System;
import Toybox.Communications;
import Toybox.Position;

class HeartRateDelegate extends WatchUi.BehaviorDelegate {

    // Heart rate monitoring variables
    private var _currentHeartRate as Number?;
    private var _monitoringTimer as Timer.Timer?;
    private var _highHRStartTime as Number?;
    private var _alertSent as Boolean = false;

    // Thresholds (you can adjust these)
    private const WARNING_THRESHOLD = 170;
    private const ALERT_THRESHOLD = 180;
    private const ALERT_DURATION = 30; // seconds

    // Monitoring settings
    private var _isMonitoring as Boolean = false;


//main initialize
    function initialize() {
        BehaviorDelegate.initialize();
            initializeHeartRateMonitoring();
    }
    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new HeartRateMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    // Initialize heart rate sensor and monitoring
    function initializeHeartRateMonitoring() as Void {
        System.println("Initializing heart rate monitoring...");

        try {
            // Enable heart rate sensor
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);

            // Register for sensor data
            Sensor.registerSensorDataListener(method(:onSensorData), {
                :period => 1,        // Check every 1 second
                :sampleRate => 1     // 1 sample per check
            });

            // Start monitoring timer for periodic checks
            _monitoringTimer = new Timer.Timer();
            _monitoringTimer.start(method(:checkHeartRate), 3000, true); // Every 3 seconds

            _isMonitoring = true;
            System.println("Heart rate monitoring started!");

        } catch (ex) {
            System.println("Error initializing heart rate monitoring: " + ex.getErrorMessage());
        }
    }

    // Called when sensor data is available
    function onSensorData(sensorData as Sensor.Info) as Void {
        if (sensorData.heartRate != null) {
            _currentHeartRate = sensorData.heartRate;
            System.println("Heart Rate: " + _currentHeartRate);
        }
    }

    // Periodic heart rate check and alert logic
    function checkHeartRate() as Void {
        if (_currentHeartRate == null) {
            System.println("No heart rate data available");
            return;
        }

        var currentTime = System.getTimer();

        System.println("Checking HR: " + _currentHeartRate + " BPM");

        // Check if heart rate is above alert threshold
        if (_currentHeartRate >= ALERT_THRESHOLD) {

            if (_highHRStartTime == null) {
                // First time detecting high HR
                _highHRStartTime = currentTime;
                System.println("High heart rate detected! Starting timer...");
            } else {
                // Calculate how long HR has been high
                var highDuration = (currentTime - _highHRStartTime) / 1000; // Convert to seconds

                System.println("High HR duration: " + highDuration + " seconds");

                // Send alert if high for too long and haven't sent one yet
                if (highDuration >= ALERT_DURATION && !_alertSent) {
                    sendEmergencyAlert();
                }
            }

        } else if (_currentHeartRate >= WARNING_THRESHOLD) {
            // Warning level - just log for now
            System.println("Warning: Heart rate elevated (" + _currentHeartRate + " BPM)");

        } else {
            // Heart rate is normal - reset everything
            if (_highHRStartTime != null) {
                System.println("Heart rate returned to normal");
                _highHRStartTime = null;
                _alertSent = false;
            }
        }
    }

    // Send emergency alert to phone
    function sendEmergencyAlert() as Void {
        System.println("SENDING EMERGENCY ALERT!");

        try {
            // Get current location
            var position = Position.getInfo();
            var location = "Unknown";

            if (position.position != null) {
                var lat = position.position.toDegrees()[0];
                var lon = position.position.toDegrees()[1];
                location = lat.format("%.6f") + "," + lon.format("%.6f");
            }

            // Create alert message
            var alertData = {
                "type" => "heart_rate_alert",
                "heartRate" => _currentHeartRate,
                "location" => location,
                "timestamp" => System.getClockTime().hour + ":" + System.getClockTime().min,
                "message" => "Emergency: High heart rate detected during exercise!"
            };

            // Send to phone via Bluetooth
            Communications.transmit(
                alertData,
                null,
                new AlertCommListener()
            );

            _alertSent = true;
            System.println("Emergency alert sent to phone!");

        } catch (ex) {
            System.println("Error sending alert: " + ex.getErrorMessage());
        }
    }

    // Get current heart rate (for the view to display)
    function getCurrentHeartRate() as Number? {
        return _currentHeartRate;
    }

    // Get monitoring status
    function isMonitoring() as Boolean {
        return _isMonitoring;
    }

    // Get alert status
    function isAlertSent() as Boolean {
        return _alertSent;
    }

    // Manual reset function (can be called from menu)
    function resetAlert() as Void {
        _alertSent = false;
        _highHRStartTime = null;
        System.println("Alert status reset");
    }

    // Clean up when app closes
    function onStop() as Void {
        if (_monitoringTimer != null) {
            _monitoringTimer.stop();
        }
        Sensor.unregisterSensorDataListener();
        System.println("Heart rate monitoring stopped");
    }
}

// Communication listener for handling alert responses
class AlertCommListener extends Communications.ConnectionListener {

    function initialize() {
        Communications.ConnectionListener.initialize();
    }

    function onComplete() as Void {
        System.println("Alert sent successfully!");
    }

    function onError() as Void {
        System.println("Failed to send alert - no phone connection");
    }
}
