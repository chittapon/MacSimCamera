//
//  QRCodeObject.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import AVFoundation

class QRCodeObject: AVMetadataMachineReadableCodeObject {
    
    override var stringValue: String? {
        qrCode
    }
    
    var qrCode: String?
    
    static func instance(qrCode: String? = nil) -> QRCodeObject? {
        let instance = class_createInstance(QRCodeObject.self, 0) as? QRCodeObject
        instance?.qrCode = qrCode
        return instance
    }
}
