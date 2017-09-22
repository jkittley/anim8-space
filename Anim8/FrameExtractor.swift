//
//  FrameExtractor.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 10/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit
import AVFoundation

protocol PreviewFrameExtractorDelegate: class {
    func processFrame(image: UIImage)
}

protocol NewPhotoDelegate: class {
    func newPhoto(newImage: UIImage?, message: String)
    func newPhotoError(message: String, dismiss: Bool)
}

class FrameExtractor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    private let position = AVCaptureDevice.Position.back
    private let quality = AVCaptureSession.Preset.medium
    
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()

    var project: Project?
    
    var captureDeviceInput: AVCaptureDeviceInput?
    let photoOutput = AVCapturePhotoOutput()
    var parentController: CaptureViewController?
    
    weak var previewDelegate: PreviewFrameExtractorDelegate?
    weak var newPhotoDeligate: NewPhotoDelegate?
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    // MARK: AVSession configuration
    private func checkPermission() {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized {
            permissionGranted = true
        } else {
            permissionGranted = false
            self.newPhotoDeligate?.newPhotoError(message:"Permission to camera denied.", dismiss: true)
            self.close()
        }
    }
    
        
    private func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        guard let captureDevice = selectCaptureDevice() else {
            // No capture device
            newPhotoDeligate?.newPhotoError(message:"No capture device found.", dismiss: true)
            return
        }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        self.captureDeviceInput = captureDeviceInput
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)

        guard let connection = videoOutput.connection(with: AVFoundation.AVMediaType.video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        
        
        connection.videoOrientation = .landscapeRight
        connection.isVideoMirrored = position == .front
        
//      LIMIT FRAME RATE IF NEEDED
//        do {
//            try captureDevice.lockForConfiguration()
//            captureDevice.activeVideoMinFrameDuration = CMTimeMake(1,10)
//            captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1,2)
//            captureDevice.unlockForConfiguration()
//        } catch {
//        
//        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        } else {
            print("Could not add photo output to the session")
            return
        }
    }
    
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        let deviceTypeBackCamera = AVCaptureDevice.DeviceType.builtInWideAngleCamera
        return AVCaptureDevice.DiscoverySession(deviceTypes: [deviceTypeBackCamera], mediaType: AVMediaType.video, position: position).devices.first
//        return AVCaptureDevice.devices().filter {
//            ($0 as AnyObject).hasMediaType(AVMediaTypeVideo) &&
//                ($0 as AnyObject).position == position
//            }.first as? AVCaptureDevice
    }
    
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        
            guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        // Pick feedback
            var resultImage: UIImage? = nil
        
            if let algotithm = self.project?.algFeatures , let feedback = self.project?.feedback, let kpon = self.project?.keypoints, let kpadv = self.project?.keypointsAdv {
                resultImage = OpenCVWrapper.feedback(uiImage.copy() as! UIImage, arg2:algotithm, arg3:feedback, arg4:kpon, arg5:kpadv)
            }
        
            // Send result to preview
            if resultImage != nil {
                DispatchQueue.main.async {
                    [unowned self] in
                    self.previewDelegate?.processFrame(image: resultImage!)
                }
            } else {
                close()
                print("RETURNED IMAGE WAS NULL FOR FEEDBACK")
                self.newPhotoDeligate?.newPhotoError(message: "Unable to generate selected feedback type", dismiss: true)
            }
       
    }
    
    
    func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = false
        if (self.captureDeviceInput) != nil {
          if (captureDeviceInput?.device.isFlashAvailable)! {
            photoSettings.flashMode = .off
          }
//          if !photoSettings.availablePreviewPhotoPixelFormatTypes.isEmpty {
//               photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String:       photoSettings.availablePreviewPhotoPixelFormatTypes.first!]
//          }
          photoOutput.capturePhoto(with: photoSettings, delegate: self)
        } else {
            // No capture device
            newPhotoDeligate?.newPhotoError(message:"No capture device", dismiss: true)
        }
    }
    
    
    
    
    // MARK: - AVCapturePhotoCaptureDelegate Methods
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if error != nil {
            newPhotoDeligate?.newPhotoError(message:"Error capturing photo", dismiss: true)
            close()
        } else {
            print("SNAP SNAP")
            if let sampleBuffer = photoSampleBuffer,
               let previewBuffer = previewPhotoSampleBuffer,
               let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
               if let image = UIImage(data: dataImage) {
                    // Notify deligate
                    let (processed, message) = processNewPhoto(image: image)
                
                    if processed == nil {
                        newPhotoDeligate?.newPhotoError(message:message, dismiss: false)
                    } else {
                        newPhotoDeligate?.newPhoto(newImage: processed, message:message)
                        close()
                    }
               } else {
                    newPhotoDeligate?.newPhotoError(message:"No Image", dismiss: true)
                    close()
               }
            }
        }
    }
    
    
    
    func processNewPhoto(image: UIImage) -> (UIImage?, String) {
        
        if let project = self.project {
            
            // Rotate the image
            let rot = OpenCVWrapper.rotate(image, arg2:90)
        
            // Is this NOT the first image
            if project.frames.count > 0 {
                if let keyFrame = project.compareFrameWithFirst ? project.frames.first : project.frames.last {
            
                    print("Compare with first?", project.compareFrameWithFirst)
                    print("Compare frame index:", project.frames.index(of: keyFrame) ?? "Not found")
                
                    print("algFeat: ", project.algFeatures)
                    print("algDesc: ", project.algDescriptor)
                    
                    var processed: UIImage?
                    
                    do {
                        try OpenCVWrapper.catchException {
                            processed = OpenCVWrapper.transform(keyFrame.image!, arg2: rot, arg3: project.algFeatures, arg4: project.algDescriptor)
                        }
                    } catch {
                        print(error.localizedDescription)
                        parentController?.hideProcessingMessage()
                        return (nil, "Failed to transform image. " + error.localizedDescription + ".")
                    }
                    
                    parentController?.hideProcessingMessage()
                    print("Returnbing processed")
                    return (processed, "")
                    
                } else {
                    return (nil, "Failed to find comparision frame")
                }
                
            // THis is the first images
            } else {
                if OpenCVWrapper.testfirstimage(rot, arg2: project.algFeatures) {
                    return (rot, "")
                }
                parentController?.hideProcessingMessage()
                return (nil, "The first image is not good enough quality")
            }
        
        } else {
            return (nil, "Project missing")
        }
    
    }

    // MARK: Stop the camera
    func close() {
        // Stop session
        DispatchQueue.global().async {
            self.captureSession.stopRunning()
        }
    }
    
       
}


