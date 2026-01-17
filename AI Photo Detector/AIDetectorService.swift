//
//  AIDetector.swift
//  AI Photo Detector
//

import CoreML
import Vision
import UIKit

enum DetectionResult {
    case real(confidence: Float)
    case aiGenerated(confidence: Float)
    case error(String)
}

class AIDetectorService {
    private var model: VNCoreMLModel?

    init() {
        loadModel()
    }

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all

            let mlModel = try AIDetector(configuration: config).model
            model = try VNCoreMLModel(for: mlModel)
        } catch {
            print("Failed to load model: \(error)")
        }
    }

    func detect(image: UIImage, completion: @escaping (DetectionResult) -> Void) {
        guard let model = model else {
            completion(.error("Model not loaded"))
            return
        }

        guard let cgImage = image.cgImage else {
            completion(.error("Invalid image"))
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.error(error.localizedDescription))
                }
                return
            }

            guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let multiArray = results.first?.featureValue.multiArrayValue else {
                DispatchQueue.main.async {
                    completion(.error("No results"))
                }
                return
            }

            // Get logits: [REAL, FAKE]
            let realLogit = Float(truncating: multiArray[0])
            let fakeLogit = Float(truncating: multiArray[1])

            // Apply softmax to get probabilities
            let maxLogit = max(realLogit, fakeLogit)
            let expReal = exp(realLogit - maxLogit)
            let expFake = exp(fakeLogit - maxLogit)
            let sumExp = expReal + expFake

            let realProb = expReal / sumExp
            let fakeProb = expFake / sumExp

            DispatchQueue.main.async {
                if fakeProb > realProb {
                    completion(.aiGenerated(confidence: fakeProb))
                } else {
                    completion(.real(confidence: realProb))
                }
            }
        }

        // Preprocessing: resize and center crop to 224x224
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.error(error.localizedDescription))
                }
            }
        }
    }
}
