#include "foreground_app_detector.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <memory>
#include <string>
#include <iostream>

// X11 implementation for foreground app detection
class X11ForegroundDetector {
public:
    X11ForegroundDetector() : display_(nullptr) {
        display_ = XOpenDisplay(nullptr);
    }
    
    ~X11ForegroundDetector() {
        if (display_) {
            XCloseDisplay(display_);
        }
    }
    
    bool IsAvailable() const {
        return display_ != nullptr;
    }
    
    std::string GetForegroundAppName() {
        if (!display_) {
            return "";
        }
        
        try {
            // Get the currently focused window
            Window focused_window;
            int revert_to;
            XGetInputFocus(display_, &focused_window, &revert_to);
            
            if (focused_window == None || focused_window == PointerRoot) {
                return "";
            }
            
            // Get the top-level window (traverse up the hierarchy)
            Window root, parent;
            Window* children;
            unsigned int nchildren;
            Window current = focused_window;
            
            while (true) {
                if (XQueryTree(display_, current, &root, &parent, &children, &nchildren) == 0) {
                    break;
                }
                
                if (children) {
                    XFree(children);
                }
                
                if (parent == root) {
                    break;
                }
                
                current = parent;
            }
            
            // Try to get WM_CLASS property (application class name)
            XClassHint class_hint;
            if (XGetClassHint(display_, current, &class_hint) != 0) {
                std::string app_name;
                if (class_hint.res_class) {
                    app_name = class_hint.res_class;
                    XFree(class_hint.res_class);
                }
                if (class_hint.res_name) {
                    XFree(class_hint.res_name);
                }
                
                if (!app_name.empty()) {
                    return app_name;
                }
            }
            
            // Fallback: try to get window name
            char* window_name = nullptr;
            if (XFetchName(display_, current, &window_name) != 0 && window_name) {
                std::string name(window_name);
                XFree(window_name);
                return name;
            }
            
            // Try _NET_WM_NAME (UTF-8 window title)
            Atom net_wm_name = XInternAtom(display_, "_NET_WM_NAME", False);
            Atom utf8_string = XInternAtom(display_, "UTF8_STRING", False);
            
            Atom actual_type;
            int actual_format;
            unsigned long nitems, bytes_after;
            unsigned char* prop = nullptr;
            
            if (XGetWindowProperty(display_, current, net_wm_name, 0, 1024, False,
                                 utf8_string, &actual_type, &actual_format,
                                 &nitems, &bytes_after, &prop) == Success && prop) {
                std::string name(reinterpret_cast<char*>(prop));
                XFree(prop);
                return name;
            }
            
        } catch (const std::exception& e) {
            std::cerr << "Error getting foreground app: " << e.what() << std::endl;
        }
        
        return "";
    }
    
private:
    Display* display_;
};

// Wayland implementation placeholder
class WaylandForegroundDetector {
public:
    bool IsAvailable() const {
        // Wayland detection is more complex and requires compositor-specific protocols
        return false;  // Not implemented yet
    }
    
    std::string GetForegroundAppName() {
        return "";  // Not implemented yet
    }
};

// Main interface implementation
ForegroundAppDetector::ForegroundAppDetector() {
    // Try X11 first
    x11_detector_ = std::make_unique<X11ForegroundDetector>();
    if (x11_detector_->IsAvailable()) {
        detector_type_ = DetectorType::X11;
        return;
    }
    
    // Try Wayland
    wayland_detector_ = std::make_unique<WaylandForegroundDetector>();
    if (wayland_detector_->IsAvailable()) {
        detector_type_ = DetectorType::Wayland;
        return;
    }
    
    detector_type_ = DetectorType::None;
}

ForegroundAppDetector::~ForegroundAppDetector() = default;

bool ForegroundAppDetector::IsSupported() const {
    return detector_type_ != DetectorType::None;
}

std::string ForegroundAppDetector::GetForegroundAppName() {
    switch (detector_type_) {
        case DetectorType::X11:
            return x11_detector_->GetForegroundAppName();
        case DetectorType::Wayland:
            return wayland_detector_->GetForegroundAppName();
        default:
            return "";
    }
}

std::string ForegroundAppDetector::GetDetectorInfo() const {
    switch (detector_type_) {
        case DetectorType::X11:
            return "X11";
        case DetectorType::Wayland:
            return "Wayland";
        default:
            return "None";
    }
}