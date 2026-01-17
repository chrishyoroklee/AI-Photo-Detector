//
//  ContentView.swift
//  AI Photo Detector
//
//  Created by 이효록 on 1/17/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var detectionResult: DetectionResult?
    @State private var isAnalyzing = false

    private let detector = AIDetectorService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Image display area
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                            Text("Select a photo to analyze")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                // Result display
                if isAnalyzing {
                    ProgressView("Analyzing...")
                        .padding()
                } else if let result = detectionResult {
                    ResultCard(result: result)
                        .padding(.horizontal)
                }

                Spacer()

                // Select photo button
                Button {
                    showingImagePicker = true
                } label: {
                    Label("Select Photo", systemImage: "photo.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("AI Photo Detector")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    analyzeImage(image)
                }
            }
        }
    }

    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        detectionResult = nil

        detector.detect(image: image) { result in
            isAnalyzing = false
            detectionResult = result
        }
    }
}

struct ResultCard: View {
    let result: DetectionResult

    var body: some View {
        VStack(spacing: 12) {
            switch result {
            case .real(let confidence):
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                    Text("Likely Real")
                        .font(.title2.bold())
                }
                Text("Confidence: \(Int(confidence * 100))%")
                    .foregroundStyle(.secondary)
                ConfidenceBar(confidence: confidence, color: .green)

            case .aiGenerated(let confidence):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text("Likely AI Generated")
                        .font(.title2.bold())
                }
                Text("Confidence: \(Int(confidence * 100))%")
                    .foregroundStyle(.secondary)
                ConfidenceBar(confidence: confidence, color: .orange)

            case .error(let message):
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                    Text("Error")
                        .font(.title2.bold())
                }
                Text(message)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ConfidenceBar: View {
    let confidence: Float
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray4))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(confidence), height: 8)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    ContentView()
}
