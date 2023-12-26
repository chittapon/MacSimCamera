//
//  MacSimCamera.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import AVFoundation

public class MacSimCamera: NSObject {
    
    @objc public static let instance: MacSimCamera = MacSimCamera()
    
    let connection = SocketConnection()
    var inputs: [AVCaptureInput] = []
    var outputs: [AVCaptureOutput] = []
    var images: [UIImage] = []
    var image: UIImage?
    weak var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    weak var videoDataOutput: AVCaptureVideoDataOutput?
    weak var metadataOutput: AVCaptureMetadataOutput?
    weak var movieFileOutput: AVCaptureMovieFileOutput?
    weak var photoOutput: AVCapturePhotoOutput?
    weak var movieFileOutputDelegate: AVCaptureFileOutputRecordingDelegate?
    weak var photoCaptureDelegate: AVCapturePhotoCaptureDelegate?
    var isRecording = false
    var isRunning = false
    
    @objc public func performSwizzle() {
        #if !targetEnvironment(simulator)
            log("can only be used in the simulator")
            return
        #endif
        SwizzleHelper.exchange(
            #selector(AVCaptureDevice.default(for:)),
            with: #selector(AVCaptureDevice_Swizzle.default(for:)),
            oldClass: AVCaptureDevice.self,
            newClass: AVCaptureDevice_Swizzle.self
        )
        SwizzleHelper.replace(
            oldClass: AVCaptureDevice.DiscoverySession.self,
            newClass: AVCaptureDevice_Swizzle.DiscoverySession_Swizzle.self
        )
        SwizzleHelper.replace(
            oldClass: AVCaptureDevice.self,
            newClass: AVCaptureDevice_Swizzle.self
        )
        SwizzleHelper.replace(
            oldClass: AVCaptureSession.self,
            newClass: AVCaptureSession_Swizzle.self
        )
        
        do {
            
            _ = try Interpose(AVCaptureMetadataOutput.self) {
                typealias Signature = (@convention(block) (AVCaptureMetadataOutput, [AVMetadataObject.ObjectType]) -> Void)
                try $0.hook("setMetadataObjectTypes:") {
                    store in { object, objectTypes in
                    } as Signature
                }
            }
            
            _ = try Interpose(AVCaptureSession.self) {
                typealias Signature = (@convention(block) (AVCaptureSession) -> Void)
                try $0.hook("dealloc") {
                    store in { object in
                        self.releaseResource()
                    } as Signature
                }
            }
            
            _ = try Interpose(AVCaptureVideoPreviewLayer.self) {
                typealias Signature = (@convention(block) (AVCaptureVideoPreviewLayer) -> Void)
                try $0.hook("setSession:") {
                    store in { object in
                        self.videoPreviewLayer = object
                    } as Signature
                }
            }
            
            _ = try Interpose(AVCapturePhotoOutput.self) {
                typealias Signature = (@convention(block) (AVCapturePhotoOutput, AVCapturePhotoSettings, AVCapturePhotoCaptureDelegate) -> Void)
                try $0.hook(#selector(AVCapturePhotoOutput.capturePhoto(with:delegate:))) { 
                    store in { object, settings, delegate in
                        self.photoCaptureDelegate = delegate
                        self.capturePhoto()
                    } as Signature
                }
            }
            
            _ = try Interpose(AVCaptureMovieFileOutput.self) {
                typealias Signature = (@convention(block) (AVCaptureMovieFileOutput, URL, AVCaptureFileOutputRecordingDelegate) -> Void)
                try $0.hook(#selector(AVCaptureMovieFileOutput.startRecording(to:recordingDelegate:))) {
                    store in { object, url, delegate in
                        self.movieFileOutputDelegate = delegate
                        self.isRecording = true
                    } as Signature
                }
            }
            
            _ = try Interpose(AVCaptureMovieFileOutput.self) {
                typealias Signature = (@convention(block) (AVCaptureMovieFileOutput) -> Void)
                try $0.hook(#selector(AVCaptureMovieFileOutput.stopRecording)) {
                    store in { object in
                        if self.isRecording {
                            self.isRecording = false
                            self.processMovieFileOutput()
                        }
                    } as Signature
                }
            }
            
        } catch let error {
            log("⚠️ Method swizzling failed: \(error.localizedDescription)")
        }
    }
    
    func streamData() {
        connection.onReceiveData = { data in
            self.didReceiveData(data: data)
        }
    }
    
    func didReceiveData(data: Data) {
        guard let image = UIImage(data: data) else { return }
        videoPreviewLayer?.contents = image.cgImage
        self.image = image
        recordImages(image: image)
        processVideoDataOutput(image: image)
        processMetadataOutput(image: image)
    }
    
    func processVideoDataOutput(image: UIImage) {
        guard let output = videoDataOutput else { return }
        let ports = inputs.flatMap{ $0.ports }
        let connection = AVCaptureConnection(inputPorts: ports, output: output)
        guard let buffer = image.toCMSampleBuffer() else { return }
        output.sampleBufferDelegate?.captureOutput?(output, didOutput: buffer, from: connection)
    }
    
    func recordImages(image: UIImage) {
        guard movieFileOutput != nil, isRecording else { return }
        images.append(image)
    }
    
    func capturePhoto() {
        guard let output = photoOutput else { return }
        guard let image = image else { return }
        guard let photo = CapturePhoto.instance(image: image) else { return }
        photoCaptureDelegate?.photoOutput?(output, didFinishProcessingPhoto: photo, error: nil)
    }
    
    func processMovieFileOutput() {
        guard let output = movieFileOutput  else { return }
        let ports = inputs.flatMap{ $0.ports }
        let connection = AVCaptureConnection(inputPorts: ports, output: output)
        let writer = VideoWriter()
        writer.fromImages(images: images) { url, error in
            self.images.removeAll()
            self.movieFileOutputDelegate?.fileOutput(output, didFinishRecordingTo: url, from: [connection], error: error)
        }
    }
    
    func processMetadataOutput(image: UIImage) {
        guard let output = metadataOutput else { return }
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { return }
        guard let ciImage = CIImage(image: image) else { return }
        guard let features = detector.features(in: ciImage) as? [CIQRCodeFeature] else { return }
        let featuresString = features.compactMap { feature in
            feature.messageString
        }
        guard !featuresString.isEmpty else { return }
        let stringValue = featuresString.joined()
        let ports = inputs.flatMap{ $0.ports }
        let connection = AVCaptureConnection(inputPorts: ports, output: output)
        let object = QRCodeObject.instance(qrCode: stringValue)
        let metadataObjects = [object].compactMap{ $0 }
        output.metadataObjectsDelegate?.metadataOutput?(output, didOutput: metadataObjects, from: connection)
    }
    
    func setInput(_ input: AVCaptureInput) {
        inputs.append(input)
    }
    
    func setOutput(_ output: AVCaptureOutput) {
        if let output = output as? AVCaptureVideoDataOutput {
            videoDataOutput = output
            outputs.append(output)
        } else if let output = output as? AVCaptureMetadataOutput {
            metadataOutput = output
            outputs.append(output)
        } else if let output = output as? AVCaptureMovieFileOutput {
            movieFileOutput = output
            outputs.append(output)
        } else if let output = output as? AVCapturePhotoOutput {
            photoOutput = output
            outputs.append(output)
        }
    }
    
    func startRunning() {
        streamData()
        connection.start()
        isRunning = true
    }
    
    func stopRunning() {
        connection.cancel()
        isRunning = false
        isRecording = false
    }

    func releaseResource() {
        connection.cancel()
        inputs.removeAll()
        outputs.removeAll()
        images.removeAll()
        videoPreviewLayer = nil
        videoDataOutput = nil
        metadataOutput = nil
        movieFileOutput = nil
        photoOutput = nil
        movieFileOutputDelegate = nil
        photoCaptureDelegate = nil
    }
}
