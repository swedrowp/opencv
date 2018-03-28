//
//  ViewController.swift
//  OpenCv
//
//  Created by swedrowp on 12/03/2018.
//  Copyright © 2018 roche. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var input: AVCaptureDeviceInput!
    var output: AVCaptureVideoDataOutput!
    var cameraView: UIImageView!
    var cameraSession: AVCaptureSession!
    var camera: AVCaptureDevice!
    var refImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenWidth = UIScreen.main.bounds.size.width;
        let screenHeight = UIScreen.main.bounds.size.height;
        cameraView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: screenHeight))
        cameraView.contentMode = .scaleAspectFill
        cameraSession = AVCaptureSession()
        self.view.addSubview(cameraView)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //　Initialize view
    override func viewWillAppear(_ animated: Bool) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) {
            (granted: Bool) -> Void in
            guard granted else {
                /// Report an error. We didn't get access to hardware.
                return
            }
            
            /// All good, access granted.
            self.camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
            
            self.cameraSession.beginConfiguration()
            do {
                self.input = try AVCaptureDeviceInput(device: self.camera) as AVCaptureDeviceInput
            } catch let error as NSError {
                print(error)
            }
            
            if( self.cameraSession.canAddInput(self.input)) {
                self.cameraSession.addInput(self.input)
            }
            
            // Send the image to processing
            self.output = AVCaptureVideoDataOutput()
            self.output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
            
            // delegate
            let queue: DispatchQueue = DispatchQueue(label: "videoqueue")
            self.output.setSampleBufferDelegate(self, queue: queue)
            
            // Discard the frames not in time.
            self.output.alwaysDiscardsLateVideoFrames = true
        
            
            // Add output to session
            if self.cameraSession.canAddOutput(self.output) {
                self.cameraSession.addOutput(self.output)
            }
            
            for connection in self.output.connections {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = AVCaptureVideoOrientation.portrait
                }
            }
            
            self.cameraSession.commitConfiguration()
            self.cameraSession.startRunning()
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let frame = self.captureImage(sampleBuffer: sampleBuffer)
        let image = OpenCvWrapper.recognizeHandGesture(frame)
        
        DispatchQueue.main.async() {
            self.cameraView.image = image
        }
        
    }
    
    func scaleImgToSize(img: UIImage, size: CGSize) -> UIImage {
        let frame = CGRect(origin: CGPoint.zero, size: size)
        UIGraphicsBeginImageContext(size)
        img.draw(in: frame)
        let newImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImg!
    }
    
    // Create a UIImage from sampleBuffer
    func captureImage(sampleBuffer:CMSampleBuffer) -> UIImage {
        
        // Fetch an image
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        //　Lock a base address
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0) )
        
        // Image information
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue as UInt32
        
        //RGB color space
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let newContext: CGContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
        // Quartz Image
        let imageRef: CGImage = newContext.makeImage()!
        
        // UIImage
        let cameraImage: UIImage = UIImage(cgImage: imageRef)
        
        return cameraImage
        
    }

}

