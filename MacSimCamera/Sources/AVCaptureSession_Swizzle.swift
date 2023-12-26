//
//  AVCaptureSession_Swizzle.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import AVFoundation

class AVCaptureSession_Swizzle: NSObject {
    
    @objc var inputs: [AVCaptureInput] {
        MacSimCamera.instance.inputs
    }
    
    @objc var outputs: [AVCaptureOutput] {
        MacSimCamera.instance.outputs
    }
    
    @objc var isRunning: Bool {
        MacSimCamera.instance.isRunning
    }
    
    @objc open func addInput(_ input: AVCaptureInput) {
        MacSimCamera.instance.setInput(input)
    }
    
    @objc open func canAddInput(_ input: AVCaptureInput) -> Bool {
        true
    }
    
    @objc open func addOutput(_ output: AVCaptureOutput) {
        MacSimCamera.instance.setOutput(output)
    }
    
    @objc open func startRunning() {
        MacSimCamera.instance.startRunning()
    }
    
    @objc open func stopRunning() {
        MacSimCamera.instance.stopRunning()
    }
    
    @objc func isBeingConfigured() -> Bool {
        true
    }
    
    @objc func beginConfiguration() {}
    
    @objc func commitConfiguration() {}
    
    @objc func isInterrupted() -> Bool {
        true
    }
    
    @objc func _setMultitaskingCameraAccessEnabled(_ enabled: Bool) {}
}
