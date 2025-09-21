#ifndef RUNNER_FOREGROUND_APP_DETECTOR_H_
#define RUNNER_FOREGROUND_APP_DETECTOR_H_

#include <memory>
#include <string>

// Forward declarations
class X11ForegroundDetector;
class WaylandForegroundDetector;

class ForegroundAppDetector {
public:
    ForegroundAppDetector();
    ~ForegroundAppDetector();
    
    // Check if foreground app detection is supported on this system
    bool IsSupported() const;
    
    // Get the name of the currently active/foreground application
    std::string GetForegroundAppName();
    
    // Get information about which detector is being used
    std::string GetDetectorInfo() const;

private:
    enum class DetectorType {
        None,
        X11,
        Wayland
    };
    
    DetectorType detector_type_ = DetectorType::None;
    std::unique_ptr<X11ForegroundDetector> x11_detector_;
    std::unique_ptr<WaylandForegroundDetector> wayland_detector_;
};

#endif  // RUNNER_FOREGROUND_APP_DETECTOR_H_