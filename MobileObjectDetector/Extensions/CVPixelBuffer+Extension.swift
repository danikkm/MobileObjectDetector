//
//  CVPixelBuffer+Extension.swift
//  MobileObjectDetector
//
//  Created by Daniel on 2021-05-12.
//

import Foundation
import Vision

// Source: https://stackoverflow.com/questions/53132611/copy-a-cvpixelbuffer-on-any-ios-device
public extension CVPixelBuffer {
    func copy() throws -> CVPixelBuffer {
        precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "copy() cannot be called on a non-CVPixelBuffer")
        
        var _copy: CVPixelBuffer?
        
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let formatType = CVPixelBufferGetPixelFormatType(self)
        let attachments = CVBufferGetAttachments(self, .shouldPropagate)
        
        CVPixelBufferCreate(nil, width, height, formatType, attachments, &_copy)
        
        guard let copy = _copy else {
            throw CVPixelBufferError.allocationFailed
        }
        
        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(copy, [])
        
        defer {
            CVPixelBufferUnlockBaseAddress(copy, [])
            CVPixelBufferUnlockBaseAddress(self, .readOnly)
        }
        
        let pixelBufferPlaneCount: Int = CVPixelBufferGetPlaneCount(self)
        
        
        if pixelBufferPlaneCount == 0 {
            let dest = CVPixelBufferGetBaseAddress(copy)
            let source = CVPixelBufferGetBaseAddress(self)
            let height = CVPixelBufferGetHeight(self)
            let bytesPerRowSrc = CVPixelBufferGetBytesPerRow(self)
            let bytesPerRowDest = CVPixelBufferGetBytesPerRow(copy)
            if bytesPerRowSrc == bytesPerRowDest {
                memcpy(dest, source, height * bytesPerRowSrc)
            } else {
                var startOfRowSrc = source
                var startOfRowDest = dest
                for _ in 0..<height {
                    memcpy(startOfRowDest, startOfRowSrc, min(bytesPerRowSrc, bytesPerRowDest))
                    startOfRowSrc = startOfRowSrc?.advanced(by: bytesPerRowSrc)
                    startOfRowDest = startOfRowDest?.advanced(by: bytesPerRowDest)
                }
            }
            
        } else {
            for plane in 0 ..< pixelBufferPlaneCount {
                let dest = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
                let source = CVPixelBufferGetBaseAddressOfPlane(self, plane)
                let height = CVPixelBufferGetHeightOfPlane(self, plane)
                let bytesPerRowSrc = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
                let bytesPerRowDest = CVPixelBufferGetBytesPerRowOfPlane(copy, plane)
                
                if bytesPerRowSrc == bytesPerRowDest {
                    memcpy(dest, source, height * bytesPerRowSrc)
                }else {
                    var startOfRowSrc = source
                    var startOfRowDest = dest
                    for _ in 0 ..< height {
                        memcpy(startOfRowDest, startOfRowSrc, min(bytesPerRowSrc, bytesPerRowDest))
                        startOfRowSrc = startOfRowSrc?.advanced(by: bytesPerRowSrc)
                        startOfRowDest = startOfRowDest?.advanced(by: bytesPerRowDest)
                    }
                }
            }
        }
        return copy
    }
}
