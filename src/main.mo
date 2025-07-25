// ATAN - AI Agent Management System
// Minimal main canister for ICP project requirements

import Debug "mo:base/Debug";
import Time "mo:base/Time";

actor Main {
    
    // Simple greeting function
    public func greet(name : Text) : async Text {
        "Hello, " # name # "! Welcome to ATAN - AI Agent Management System."
    };
    
    // Health check function
    public func health() : async Text {
        "ATAN System is running. Timestamp: " # debug_show(Time.now())
    };
    
    // Get system info
    public func getSystemInfo() : async {name: Text; version: Text; timestamp: Int} {
        {
            name = "ATAN - AI Agent Management System";
            version = "1.0.0";
            timestamp = Time.now();
        }
    };
}