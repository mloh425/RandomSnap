//
//  PostNewPhotoViewController.swift
//  RandomSnap
//
//  Created by Sau Chung Loh on 1/19/17.
//  Copyright © 2017 Matthew Loh. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    var captureSession : AVCaptureSession?
    var stillImageOutput : AVCapturePhotoOutput?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var didPressTakeAnotherPhotoButton: UIButton!
    @IBOutlet weak var didPressTakePhotoButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        didPressTakeAnotherPhotoButton.isHidden = true
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer?.frame = cameraView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPreset1920x1080
        
        var backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            var input = try AVCaptureDeviceInput(device: backCamera) //as AVCaptureDeviceInput
            if (captureSession?.canAddInput(input))! {
                captureSession?.addInput(input)
                
                stillImageOutput = AVCapturePhotoOutput()
                
                if (captureSession?.canAddOutput(stillImageOutput))! {
                    captureSession?.addOutput(stillImageOutput)
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
                    previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                    cameraView.layer.addSublayer(previewLayer!)
                    captureSession?.startRunning()
                }
                
            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func didPressTakePhoto() {
        //What is all this stuff? Look it up
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        stillImageOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    // callBack from didPressTakePhoto
    func capture(_ captureOutput: AVCapturePhotoOutput,  didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,  previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings:  AVCaptureResolvedPhotoSettings, bracketSettings:   AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("error occured : \(error.localizedDescription)")
        }
        
        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            //print(UIImage(data: dataImage)?.size as Any)
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            
            self.tempImageView.image = image
            self.tempImageView.isHidden = false
            self.didPressTakePhotoButton.isHidden = true
            self.didPressTakeAnotherPhotoButton.isHidden = false
        } else {
            print("some error here")
        }
    }

//    var didTakePhoto = Bool()
    
//    func didPressTakeAnother() {
//        if didTakePhoto == true {
//            tempImageView.isHidden = true
//            didTakePhoto = false
//        } else {
//            captureSession?.startRunning()
//            didTakePhoto = true
//            
//            didPressTakePhoto()
//            
//        }
//    }

    @IBAction func didPressTakeAnotherPhotoButton(_ sender: UIButton) {
        self.didPressTakePhotoButton.isHidden = false
        self.didPressTakeAnotherPhotoButton.isHidden = true
        self.tempImageView.isHidden = true
        captureSession?.startRunning()
    }

    @IBAction func didPressTakePhotoButton(_ sender: UIButton) {
        didPressTakePhoto()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let screenSize = cameraView.bounds.size
        let frameSize : CGSize = view.frame.size
        
        if let touchPoint = touches.first {
            var location : CGPoint = touchPoint.location(in: cameraView)
            
            print("Tap Location : X: \(location.x), Y: \(location.y)")
            
            let x = location.x / frameSize.width
            let y = 1.0 - (location.x / frameSize.width)
            
            let focusPoint = CGPoint(x: x, y: y)
            
            print("POINT : X: \(x), Y: \(y)")
            let captureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
            
            if let device = captureDevice {
                do {
                    //Must lock first for config
                    try device.lockForConfiguration()
                    
                    if device.isFocusPointOfInterestSupported {
                        //Add focusPoint
                        device.focusPointOfInterest = focusPoint
                        device.focusMode = .autoFocus
                        
                    } else {
                        print("The focusPointOfInterest is not supported on this device!")
                    }
                        
                    if device.isExposurePointOfInterestSupported{
                        //Add exposurePoint
                        device.exposurePointOfInterest = focusPoint
                        device.exposureMode = AVCaptureExposureMode.autoExpose
                        
                    } else {
                        print("The exposurePointOfInterest is not supported on this device!")
                    }

                    device.unlockForConfiguration()
                }
                catch {
                    // just ignore
                    print("Focus point error")
                }
            }
        }
        }
}

