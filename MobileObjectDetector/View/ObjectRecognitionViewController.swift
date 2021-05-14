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
                    
                    guard let url = self.detectionViewModel.selectedModel.url else {
                        print("Invalid URL for the mlmodel")
                        return
                    }
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        // TODO: refactor to view model
                        self.setupVision(withURL: url, nameOfTheModel: self.detectionViewModel.selectedModel.name)
                    }
                    
                    self.setupVision(withURL: url,
                                     nameOfTheModel: self.detectionViewModel.selectedModel.name)
                case .inactive:
                    // TODO: is it necessary?
                    self.detectionViewModel.setRequests([])
                    self.detectionOverlay.removeFromSuperlayer()
                    print("inactive")
                }
            }).disposed(by: disposeBag)
        
        detectionViewModel.model.selectedModelDriver
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
    
    func setupVision(withURL url: URL, nameOfTheModel: String) {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: url, configuration: config))
            
            print("Using: \(nameOfTheModel), running on \(config.computeUnits.rawValue)")
            
            let objectRecognition = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                //                let startTime = CACurrentMediaTime()
                DispatchQueue.main.async {
                    if let results = request.results {
                        self?.drawVisionRequestResults(results)
                    }
                    
                    if let _error = error {
                        print(_error.localizedDescription)
                    }
                }
                //                let endTime = CACurrentMediaTime()
                //                print("Done inference in: \(endTime - startTime))")
            }
            
            detectionViewModel.setRequests([objectRecognition])
        }
        catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
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
            
            let shapeLayer = createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = createTextSubLayerInBounds(objectBounds,
                                                       identifier: topLabelObservation.identifier,
                                                       confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        
        updateLayerGeometry()
        
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput,
                                didOutput sampleBuffer: CMSampleBuffer,
                                from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var options: [VNImageOption : Any] = [:]
        if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
                                                       attachmentModeOut: nil) {
            options[.cameraIntrinsics] = cameraIntrinsicMatrix
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        autoreleasepool {
            var clonePixelBuffer: CVPixelBuffer? = try? pixelBuffer.copy()
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: clonePixelBuffer!,
                                                            orientation: exifOrientation,
                                                            options: options)
            do {
                try imageRequestHandler.perform(detectionViewModel.requests)
            } catch {
                drawVisionRequestResults([])
                print(error)
            }
            clonePixelBuffer = nil
        }
    }
}
