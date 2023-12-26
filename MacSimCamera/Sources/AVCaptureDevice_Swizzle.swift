//
//  AVCaptureDevice_Swizzle.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import AVFoundation

class AVCaptureDevice_Swizzle: AVCaptureDevice {
    
    override class func devices() -> [AVCaptureDevice] {
        _devices
    }
    
    override class func devices(for mediaType: AVMediaType) -> [AVCaptureDevice] {
        _devices
    }
    
    override class func `default`(for mediaType: AVMediaType) -> AVCaptureDevice? {
        _devices.first
    }
    
    override var position: AVCaptureDevice.Position {
        _position
    }
    
    open var _position: AVCaptureDevice.Position = .back
    
    static func instance(position: AVCaptureDevice.Position) -> AVCaptureDevice_Swizzle? {
        let instance = class_createInstance(AVCaptureDevice_Swizzle.self, 0) as? AVCaptureDevice_Swizzle
        instance?._position = position
        return instance
    }
    
    override func hasMediaType(_ mediaType: AVMediaType) -> Bool {
        return mediaType == .video
    }

    override func supportsSessionPreset(_ preset: AVCaptureSession.Preset) -> Bool {
        return true
    }
    
    static let _devices: [AVCaptureDevice_Swizzle] = {
        func createDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice_Swizzle? {
            AVCaptureDevice_Swizzle.instance(position: position)
        }
        return [
            createDevice(position: .back),
            createDevice(position: .front)
        ].compactMap{ $0 }
    }()
    
    class DiscoverySession_Swizzle: NSObject {
        
        @objc open var devices: [AVCaptureDevice] {
            AVCaptureDevice_Swizzle._devices
        }
        
        @objc open var supportedMultiCamDeviceSets: [Set<AVCaptureDevice>] {
            [Set(AVCaptureDevice_Swizzle._devices)]
        }
    }
}
