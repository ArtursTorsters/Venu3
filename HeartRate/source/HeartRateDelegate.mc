import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.System;
import Toybox.Communications;
import Toybox.Position;


// When app starts:
// 1. Enable heart rate sensor
// 2. Start a timer that runs every 3 seconds
// 3. Set monitoring flag to true

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

    function initialize() {
        BehaviorDelegate.initialize();
        System.println("Initializing heart rate app...");
        initializeHeartRateMonitoring();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new HeartRateMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    // Initialize heart rate sensor and monitoring
    function initializeHeartRateMonitoring() as Void {
        System.println("Starting heart rate monitoring...");

        try {
            // Enable heart rate sensor
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            System.println("Heart rate sensor enabled");

            // Start monitoring timer for periodic checks
            _monitoringTimer = new Timer.Timer();
            _monitoringTimer.start(method(:checkHeartRate), 3000, true); // Every 3 seconds

            _isMonitoring = true;
            System.println("Heart rate monitoring started!");

        } catch (ex) {
            System.println("Error initializing heart rate monitoring: " + ex.getErrorMessage());
        }
    }

    // Check heart rate using Sensor.getInfo() (reliable method)
    function checkHeartRate() as Void {
        try {
            // Get current sensor info
            var info = Sensor.getInfo();

            if (info has :heartRate && info.heartRate != null) {
                _currentHeartRate = info.heartRate;
                System.println("Heart Rate: " + _currentHeartRate + " BPM");

                // Check for alerts
                checkForAlerts();

            } else {
                System.println("No heart rate data available");
                // In simulator, let's use fake data for testing
                simulateHeartRateForTesting();
            }

        } catch (ex) {
            System.println("Error reading heart rate: " + ex.getErrorMessage());
        }
    }

    // Alert logic
    function checkForAlerts() as Void {
        if (_currentHeartRate == null) {
            return;
        }

        var currentTime = System.getTimer();

        // Check if heart rate is above alert threshold
        if (_currentHeartRate >= ALERT_THRESHOLD) {

            if (_highHRStartTime == null) {
                // First time detecting high HR
                _highHRStartTime = currentTime;
                System.println("HIGH HEART RATE DETECTED! Starting timer...");
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
            System.println("WARNING: Heart rate elevated (" + _currentHeartRate + " BPM)");

        } else {
            // Heart rate is normal - reset everything
            if (_highHRStartTime != null) {
                System.println("Heart rate returned to normal");
                _highHRStartTime = null;
                _alertSent = false;
            }
        }
    }

    // For testing in simulator - simulate escalating heart rate
    private var _simulatedHR as Number = 65;
    function simulateHeartRateForTesting() as Void {
        // Gradually increase heart rate for testing
        _simulatedHR = _simulatedHR + 5;

        if (_simulatedHR > 200) {
            _simulatedHR = 65; // Reset cycle
        }

        _currentHeartRate = _simulatedHR;
        System.println("SIMULATED Heart Rate: " + _currentHeartRate + " BPM");

        // Check for alerts with simulated data
        checkForAlerts();
    }

    // Send emergency alert to phone
    function sendEmergencyAlert() as Void {
        System.println("🚨 SENDING EMERGENCY ALERT! 🚨");

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
                "type" => "heart_rate_emergency",
                "heartRate" => _currentHeartRate,
                "location" => location,
                "timestamp" => System.getClockTime().hour + ":" + System.getClockTime().min,
                "message" => "EMERGENCY: Dangerously high heart rate detected during exercise!"
            };

            // Send to phone via Bluetooth
            Communications.transmit(
                alertData,
                null,
                new AlertCommListener()
            );

            _alertSent = true;
            System.println("🚨 EMERGENCY ALERT SENT TO PHONE! 🚨");

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
        _simulatedHR = 65; // Reset simulation
        System.println("Alert status reset");
    }

    // Clean up when app closes
    function onStop() as Void {
        if (_monitoringTimer != null) {
            _monitoringTimer.stop();
        }
        System.println("Heart rate monitoring stopped");
    }
}

// Communication listener for handling alert responses
class AlertCommListener extends Communications.ConnectionListener {

    function initialize() {
        Communications.ConnectionListener.initialize();
    }

    function onComplete() as Void {
        System.println("✅ Alert sent successfully to phone!");
    }

    function onError() as Void {
        System.println("❌ Failed to send alert - no phone connection");
    }
}
