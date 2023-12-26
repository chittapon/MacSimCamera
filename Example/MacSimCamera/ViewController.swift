//
//  ViewController.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 12/25/2023.
//  Copyright (c) 2023 Chittapon Thongchim. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {

    @IBOutlet var recordButton: UIButton!
    private let captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput!
    private var videoOutput: AVCaptureMovieFileOutput!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var metadataOutput: AVCaptureMetadataOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRecordButton()
        requestAccess()
    }
    
    private func setupRecordButton() {
        if #available(iOS 13.0, *) {
            recordButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
            recordButton.setImage(UIImage(systemName: "stop.circle"), for: .selected)
        } else {}
    }
    
    private func requestAccess() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { grant in
            if grant {
                DispatchQueue.main.async {
                    self.setupCamera()
                }
            }
        }
    }
    
    private func setupCamera() {
        let device = AVCaptureDevice.default(for: .video)
        guard let device = device else { return }
        
        /// Device IO
        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(deviceInput)
            
            photoOutput = AVCapturePhotoOutput()
            photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput)
            
            videoOutput = AVCaptureMovieFileOutput()
            captureSession.addOutput(videoOutput)
            
            videoDataOutput = AVCaptureVideoDataOutput()
            captureSession.addOutput(videoDataOutput)
            
            metadataOutput = AVCaptureMetadataOutput()
            metadataOutput.metadataObjectTypes = [.qr]
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureSession.addOutput(metadataOutput)
        } catch {
            print(error.localizedDescription)
        }
        
        /// VideoPreviewLayer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        previewLayer.frame = view.frame
        view.layer.insertSublayer(previewLayer, at: 0)
        
        /// Start running camera
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    @IBAction func capturePhoto(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        settings.isAutoStillImageStabilizationEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @IBAction func recordVideo(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let isRecord = sender.isSelected
        if isRecord {
            let path = NSTemporaryDirectory()
            let filePath: String = "\(path)/temp.mov"
            let fileURL = URL(fileURLWithPath: filePath)
            videoOutput.startRecording(to: fileURL, recordingDelegate: self)
        } else {
            videoOutput.stopRecording()
        }
    }
    
    @IBAction func photoGallery(_ sender: UIButton) {
        let sourceType: UIImagePickerController.SourceType = .savedPhotosAlbum
        if UIImagePickerController.isSourceTypeAvailable(sourceType){
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.mediaTypes = ["public.image", "public.movie"]
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
            let uiImage = UIImage(data: imageData) {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        }
    }
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        PHPhotoLibrary.shared()
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { saved, error in
            if let error = error {
                print(error.localizedDescription)
            } else if saved {
                print("Saved video successful!")
            }
        }
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let object = metadataObjects.first {
            let readable = object as? AVMetadataMachineReadableCodeObject
            let stringValue = readable?.stringValue ?? ""
            print("QRCode value: \(stringValue)")
            captureSession.stopRunning()
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
    }
}
