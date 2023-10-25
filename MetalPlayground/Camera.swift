//
//  Camera.swift
//  MetalPlayground
//
//  Created by user on 2023/10/25.
//

import AVFoundation
import Combine
import Foundation

final class Camera: NSObject {
    private let captureSession = AVCaptureSession()
    private let cameraQueue = DispatchQueue(label: "cameraQueue", qos: .userInteractive)

    private(set) var pixelBuffer: CVPixelBuffer?
    private var currentVideoOutput: AVCaptureOutput?

    func setup(with preset: AVCaptureSession.Preset) {
        Task {
            guard await requestAuthorization() else { return }

            captureSession.beginConfiguration()
            captureSession.sessionPreset = preset

            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ) else { return }

            guard let videoInput = try? AVCaptureDeviceInput(device: camera),
                  captureSession.canAddInput(videoInput) else { return }
            captureSession.addInput(videoInput)

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            guard captureSession.canAddOutput(videoOutput) else { return }
            captureSession.addOutput(videoOutput)
            currentVideoOutput = videoOutput

            captureSession.commitConfiguration()
            captureSession.startRunning()
            videoOutput.connection(with: .video)?.videoOrientation = .portrait
        }
    }

    private func requestAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted: return false
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { isGranted in
                    continuation.resume(returning: isGranted)
                }
            }
        default: return false
        }
    }
}

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard output == currentVideoOutput,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.pixelBuffer = pixelBuffer
    }
}
