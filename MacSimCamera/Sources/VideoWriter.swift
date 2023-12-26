//
//  VideoWriter.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import AVFoundation

class VideoWriter {
    
    private lazy var videoPath: URL? = {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return path?.appendingPathComponent("MacSim-\(Date())).mov")
    }()
    private let fps: Int32 = 30
    private lazy var screenSize: CGSize = UIScreen.main.bounds.size
    private lazy var outputSettings = [AVVideoCodecKey: AVVideoCodecType.h264,
                                       AVVideoWidthKey: screenSize.width,
                                      AVVideoHeightKey: screenSize.height] as [String : Any]
    private lazy var bufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                                         kCVPixelBufferWidthKey as String: screenSize.width,
                                         kCVPixelBufferHeightKey as String: screenSize.height] as [String : Any]
    private var assetWriter: AVAssetWriter!
    
    func fromImages(images: [UIImage], _ completion: @escaping (_ url: URL, _ error: Error?) -> Void) {
        guard let videoPath = videoPath else { return }
        do {
            assetWriter = try AVAssetWriter(outputURL: videoPath, fileType: AVFileType.mov)
        } catch let error {
            completion(videoPath, error)
            return
        }
        guard assetWriter != nil else { return }
        let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        assetWriter.add(writerInput)
        writerInput.expectsMediaDataInRealTime = true
        
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: bufferAttributes
        )
        
        guard assetWriter.startWriting() else {
            completion(videoPath, assetWriter.error)
            return
        }
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        var frameCount = 0
        while frameCount < images.count {
            let image = images[frameCount]
            guard adaptor.assetWriterInput.isReadyForMoreMediaData else { continue }
            let frameTime: CMTime = CMTimeMake(value: Int64(frameCount), timescale: fps)
            guard let buffer = image.toCVPixelBuffer() else { continue }
            adaptor.append(buffer, withPresentationTime: frameTime)
            frameCount += 1
        }
        writerInput.markAsFinished()
        assetWriter.finishWriting(completionHandler: {
            self.assetWriter = nil
            completion(videoPath, nil)
        })
    }
}
