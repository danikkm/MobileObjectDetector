//
//  ObjectRecognitionViewController.swift
//  MobileObjectDetector
//
//  Created by Daniel Dluznevskij on 12/16/20.
//

import Foundation
import AVFoundation
import Vision
import RxSwift

class ObjectRecognitionViewController: ViewController {
    
    private var detectionOverlay: CALayer! = nil
    private var disposeBag = DisposeBag()
    
    // Vision parts
    private var requests = [VNRequest]()
    private var testStop = false
    
    override func setupAVCapture() {
        super.setupAVCapture()
        detectionViewModel.startCaptureSession()
        setupBindings()
    }
    
    func setupBindings() {
        detectionViewModel.detectionStateDriver
            .distinctUntilChanged()
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .active:
                    self.setupLayers()
                    self.updateLayerGeometry()
                    guard let url = self.mlModelsViewModel.selectedMLModel.value.url else {
                        print("Invalid URL for the mlmodel")
                        return
                    }
                    self.setupVision(withURL: url, nameOfTheModel: self.mlModelsViewModel.selectedMLModel.value.name)
                case .inactive:
                    self.requests = []
                    self.detectionOverlay.removeFromSuperlayer()
                    print("inactive")
                }
            }).disposed(by: disposeBag)
        
        mlModelsViewModel.selectedMLModelDriver
            .drive(onNext: { [weak self] mlModel in
                self?.selectedModelLabel.text = mlModel.name
            }).disposed(by: disposeBag)
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: detectionViewModel.bufferSize.width,
                                         height: detectionViewModel.bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / detectionViewModel.bufferSize.height
        let yScale: CGFloat = bounds.size.height / detectionViewModel.bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        
        let confidenceFormatted = String(format: ": %.2f", confidence * 100)
        textLayer.fontSize = 21
        textLayer.string = "\(identifier)\(confidenceFormatted)"
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor.SystemItem.white
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.borderColor = CGColor.SystemItem.cyan
        shapeLayer.borderWidth = 4.0
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
    @discardableResult
    func setupVision(withURL url: URL, nameOfTheModel: String) -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: url))
            print("Using: \(nameOfTheModel)")
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { [weak self] request, error in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self?.drawVisionRequestResults(results)
                    }
                    
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    
                })
            })
            self.requests = [objectRecognition]
        }
        catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        guard detectionOverlay != nil else { return }
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(detectionViewModel.bufferSize.width), Int(detectionViewModel.bufferSize.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var options: [VNImageOption : Any] = [:]
        if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            options[.cameraIntrinsics] = cameraIntrinsicMatrix
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        autoreleasepool {
            var clonePixelBuffer: CVPixelBuffer? = try? pixelBuffer.copy()
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: clonePixelBuffer!, orientation: exifOrientation, options: options)
            
            do {
                try imageRequestHandler.perform(self.requests)
            } catch {
                drawVisionRequestResults([])
                print(error)
            }
            clonePixelBuffer = nil
        }
    }
}
