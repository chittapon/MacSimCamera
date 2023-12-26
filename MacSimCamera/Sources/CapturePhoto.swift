//
//  CapturePhoto.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import UIKit
import AVFoundation

class CapturePhoto: AVCapturePhoto {
    
    var data: Data?
    
    static func instance(image: UIImage) -> CapturePhoto? {
        let instance = class_createInstance(CapturePhoto.self, 0) as? CapturePhoto
        instance?.data = image.pngData()
        return instance
    }
    
    open override func fileDataRepresentation() -> Data? {
        data
    }
}
