//
//  UIImage+.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import UIKit
import AVFoundation

extension UIImage {
    
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(self.size.width),
            Int(self.size.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer
        )
        
        guard (status == kCVReturnSuccess) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: pixelData,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
    
    func toCMSampleBuffer() -> CMSampleBuffer? {
        
        guard let pixelBuffer = toCVPixelBuffer() else { return nil }
        
        /// https://gist.github.com/rampadc/79c01eb3fa4eba0b941befa7c55f4e13
        var sampleBuffer: CMSampleBuffer?
        
        var timimgInfo  = CMSampleTimingInfo()
        var formatDescription: CMFormatDescription? = nil
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        
        let osStatus = CMSampleBufferCreateReadyWithImageBuffer(
          allocator: kCFAllocatorDefault,
          imageBuffer: pixelBuffer,
          formatDescription: formatDescription!,
          sampleTiming: &timimgInfo,
          sampleBufferOut: &sampleBuffer
        )
        
        // Print out errors
        if osStatus == kCMSampleBufferError_AllocationFailed {
            log("⚠️ osStatus == kCMSampleBufferError_AllocationFailed")
        }
        if osStatus == kCMSampleBufferError_RequiredParameterMissing {
            log("⚠️ osStatus == kCMSampleBufferError_RequiredParameterMissing")
        }
        if osStatus == kCMSampleBufferError_AlreadyHasDataBuffer {
            log("⚠️ osStatus == kCMSampleBufferError_AlreadyHasDataBuffer")
        }
        if osStatus == kCMSampleBufferError_BufferNotReady {
            log("⚠️ osStatus == kCMSampleBufferError_BufferNotReady")
        }
        if osStatus == kCMSampleBufferError_SampleIndexOutOfRange {
            log("⚠️ osStatus == kCMSampleBufferError_SampleIndexOutOfRange")
        }
        if osStatus == kCMSampleBufferError_BufferHasNoSampleSizes {
            log("⚠️ osStatus == kCMSampleBufferError_BufferHasNoSampleSizes")
        }
        if osStatus == kCMSampleBufferError_BufferHasNoSampleTimingInfo {
            log("⚠️ osStatus == kCMSampleBufferError_BufferHasNoSampleTimingInfo")
        }
        if osStatus == kCMSampleBufferError_ArrayTooSmall {
            log("⚠️ osStatus == kCMSampleBufferError_ArrayTooSmall")
        }
        if osStatus == kCMSampleBufferError_InvalidEntryCount {
            log("⚠️ osStatus == kCMSampleBufferError_InvalidEntryCount")
        }
        if osStatus == kCMSampleBufferError_CannotSubdivide {
            log("⚠️ osStatus == kCMSampleBufferError_CannotSubdivide")
        }
        if osStatus == kCMSampleBufferError_SampleTimingInfoInvalid {
            log("⚠️ osStatus == kCMSampleBufferError_SampleTimingInfoInvalid")
        }
        if osStatus == kCMSampleBufferError_InvalidMediaTypeForOperation {
            log("⚠️ osStatus == kCMSampleBufferError_InvalidMediaTypeForOperation")
        }
        if osStatus == kCMSampleBufferError_InvalidSampleData {
            log("⚠️ osStatus == kCMSampleBufferError_InvalidSampleData")
        }
        if osStatus == kCMSampleBufferError_InvalidMediaFormat {
            log("⚠️ osStatus == kCMSampleBufferError_InvalidMediaFormat")
        }
        if osStatus == kCMSampleBufferError_Invalidated {
            log("⚠️ osStatus == kCMSampleBufferError_Invalidated")
        }
        if osStatus == kCMSampleBufferError_DataFailed {
            log("⚠️ osStatus == kCMSampleBufferError_DataFailed")
        }
        if osStatus == kCMSampleBufferError_DataCanceled {
            log("⚠️ osStatus == kCMSampleBufferError_DataCanceled")
        }
        
        guard let buffer = sampleBuffer else {
            log("⚠️ Cannot create sample buffer")
          return nil
        }
        
        return buffer
    }
    
}

