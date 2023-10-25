//
//  ViewController.swift
//  MetalPlayground
//
//  Created by user on 2023/10/18.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink!
    var textureLoader: MTKTextureLoader!
    var textureCache: CVMetalTextureCache!
    let outputSize = CGSize(width: 720, height: 1280)
    var outputWidth: Float { Float(outputSize.width) }
    var outputHeight: Float { Float(outputSize.height) }

    let camera = Camera()

    lazy var scaleSlider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 1.0
        slider.minimumValue = 0.0
        slider.value = scale
        slider.addTarget(self, action: #selector(didChangeScaleValue), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    lazy var xTranslationSlider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 2.0
        slider.minimumValue = -2.0
        slider.value = xTranslation
        slider.addTarget(self, action: #selector(didChangeXtranslationValue), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    lazy var yTranslationSlider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 2.0
        slider.minimumValue = -2.0
        slider.value = yTranslation
        slider.addTarget(self, action: #selector(didChangeYtranslationValue), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    lazy var zTranslationSlider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 2.0
        slider.minimumValue = -2.0
        slider.value = zTranslation
        slider.addTarget(self, action: #selector(didChangeZtranslationValue), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    lazy var imageSelector: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(
            frame: .zero,
            actions: [
                .init(title: "Lenna") { [weak self] _ in self?.imageName = "lenna" },
                .init(title: "Smurfcat") { [weak self] _ in self?.imageName = "smurfcat" }
            ]
        )
        segmentedControl.backgroundColor = .systemGray3
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()

    lazy var flipper: UISwitch = {
        let flipper = UISwitch()
        flipper.isOn = false
        flipper.addTarget(self, action: #selector(didToggleFlipper), for: .valueChanged)
        flipper.translatesAutoresizingMaskIntoConstraints = false
        return flipper
    }()

    var backgroundVertexData: [Float] {
        [
            -1.0, 1.0, 0.0, 1.0,
             1.0, 1.0, 0.0, 1.0,
             -1.0, -1.0, 0.0, 1.0,
             1.0, -1.0, 0.0, 1.0
         ]
    }

    var isBackgroundFlipped = false

    var identity: [Float] {
        [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        ]
    }

    var imageName = "lenna"

    var normalizedX: Float = .zero
    var normalizedY: Float = .zero
    var vertexData: [Float] {
        [
            -normalizedX, normalizedY, 0.0, 1.0,
           normalizedX, normalizedY, 0.0, 1.0,
            -normalizedX, -normalizedY, 0.0, 1.0,
            normalizedX, -normalizedY, 0.0,1.0,
        ]
    }

    var scale: Float = 0.5
    var scaleData: [Float] {
        [
            scale, 0, 0, 0,
            0, scale, 0, 0,
            0, 0, scale, 0,
            0, 0, 0, 1.0
        ]
    }

    var xTranslation: Float = .zero
    var yTranslation: Float = .zero
    var zTranslation: Float = .zero
    var translationData: [Float] {
        [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            xTranslation, yTranslation, zTranslation, 1
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        camera.setup(with: .hd1280x720)

        device = MTLCreateSystemDefaultDevice()
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = false

        let convertedWidth = (view.frame.height / outputSize.height) * outputSize.width
        let xOffset = (view.frame.width - convertedWidth) / 2.0
        metalLayer.frame = CGRect(x: xOffset, y: 0, width: convertedWidth, height: view.frame.height)
        metalLayer.drawableSize = outputSize
        view.layer.addSublayer(metalLayer)

        textureLoader = MTKTextureLoader(device: device)
        CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            device,
            nil,
            &textureCache
        )

        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

        commandQueue = device.makeCommandQueue()

        timer = CADisplayLink(target: self, selector: #selector(gameloop))
        timer.add(to: RunLoop.main, forMode: .default)

        view.addSubview(scaleSlider)
        NSLayoutConstraint.activate([
            scaleSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scaleSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scaleSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12.0),
            scaleSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12.0)
        ])

        view.addSubview(xTranslationSlider)
        NSLayoutConstraint.activate([
            xTranslationSlider.topAnchor.constraint(equalTo: scaleSlider.topAnchor, constant: 30.0),
            xTranslationSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12.0),
            xTranslationSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12.0)
        ])

        view.addSubview(yTranslationSlider)
        NSLayoutConstraint.activate([
            yTranslationSlider.topAnchor.constraint(equalTo: xTranslationSlider.topAnchor, constant: 30.0),
            yTranslationSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12.0),
            yTranslationSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12.0)
        ])

        view.addSubview(zTranslationSlider)
        NSLayoutConstraint.activate([
            zTranslationSlider.topAnchor.constraint(equalTo: yTranslationSlider.topAnchor, constant: 30.0),
            zTranslationSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12.0),
            zTranslationSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12.0)
        ])

        view.addSubview(imageSelector)
        NSLayoutConstraint.activate([
            imageSelector.topAnchor.constraint(equalTo: zTranslationSlider.topAnchor, constant: 30.0),
            imageSelector.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        view.addSubview(flipper)
        NSLayoutConstraint.activate([
            flipper.topAnchor.constraint(equalTo: imageSelector.topAnchor, constant: 60.0),
            flipper.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    func render() {
        guard let cameraOutput = camera.pixelBuffer,
              let drawable = metalLayer?.nextDrawable() else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)

        var backgroundCVMetalTexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            cameraOutput,
            nil,
            .bgra8Unorm,
            Int(outputSize.width),
            Int(outputSize.height),
            0,
            &backgroundCVMetalTexture
        )

        guard let backgroundCVMetalTexture,
              let backgroundTexture = CVMetalTextureGetTexture(backgroundCVMetalTexture) else { return }

        guard let texture = try? textureLoader.newTexture(
            name: imageName,
            scaleFactor: 1.0,
            bundle: Bundle.main,
            options: [.SRGB : false]
        ) else {
            fatalError("Failed to create texture from image")
        }

        normalizedX = Float(texture.width) / outputWidth
        normalizedY = Float(texture.height) / outputHeight

        let backgroundVertexBuffer = device.makeBuffer(
            bytes: backgroundVertexData,
            length: backgroundVertexData.count * MemoryLayout.size(ofValue: backgroundVertexData[0]),
            options: []
        )

        let identityBuffer = device.makeBuffer(
            bytes: identity,
            length: identity.count * MemoryLayout.size(ofValue: identity[0]),
            options: []
        )

        let vertexBuffer = device.makeBuffer(
            bytes: vertexData,
            length: vertexData.count * MemoryLayout.size(ofValue: vertexData[0]),
            options: []
        )

        let translationBuffer = device.makeBuffer(
            bytes: translationData,
            length: translationData.count * MemoryLayout.size(ofValue: translationData[0]),
            options: []
        )

        let scaleBuffer = device.makeBuffer(
            bytes: scaleData,
            length: scaleData.count * MemoryLayout.size(ofValue: scaleData[0]),
            options: []
        )

        let imageWidth = Float(backgroundTexture.width)
        let imageHeight = Float(backgroundTexture.height)
        let xInset = (imageWidth - ((imageHeight / outputHeight) * outputWidth)) / (2.0 * imageWidth)
        let backgroundInset: [Float] = [xInset, .zero]
        let backgroundInsetBuffer = device.makeBuffer(
            bytes: backgroundInset,
            length: backgroundInset.count * MemoryLayout.size(ofValue: backgroundInset[0]),
            options: []
        )

        let zeroInset: [Float] = [.zero, .zero]
        let zeroInsetBuffer = device.makeBuffer(
            bytes: zeroInset,
            length: zeroInset.count * MemoryLayout.size(ofValue: zeroInset[0]),
            options: []
        )

        let backgroundFlipBuffer = device.makeBuffer(
            bytes: &isBackgroundFlipped,
            length: MemoryLayout.size(ofValue: isBackgroundFlipped),
            options: []
        )

        var notFlipped = false
        let noFlipBuffer = device.makeBuffer(
            bytes: &notFlipped,
            length: MemoryLayout.size(ofValue: notFlipped),
            options: []
        )

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(backgroundVertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(backgroundTexture, index: 0)
        renderEncoder.setVertexBuffer(identityBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(identityBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(backgroundInsetBuffer, offset: 0, index: 3)
        renderEncoder.setVertexBuffer(backgroundFlipBuffer, offset: 0, index: 4)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(translationBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(scaleBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(zeroInsetBuffer, offset: 0, index: 3)
        renderEncoder.setVertexBuffer(noFlipBuffer, offset: 0, index: 4)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.addCompletedHandler { _ in
            let texture = drawable.texture
            var pixelBuffer: CVPixelBuffer?
            guard CVPixelBufferCreate(
                kCFAllocatorDefault,
                texture.width,
                texture.height,
                kCVPixelFormatType_32BGRA,
                nil,
                &pixelBuffer
            )  == kCVReturnSuccess,
                  let buffer = pixelBuffer else {
                fatalError("Error: Could not create pixel buffer")
            }

            CVPixelBufferLockBaseAddress(buffer, [])
            let pixelData = CVPixelBufferGetBaseAddress(buffer)
            let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
            texture.getBytes(pixelData!, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), from: region, mipmapLevel: 0)
            CVPixelBufferUnlockBaseAddress(buffer, [])
        }
        commandBuffer.commit()
    }

    @objc func gameloop() {
        autoreleasepool {
            render()
        }
    }

    @objc func didChangeScaleValue(_ sender: UISlider) {
        scale = sender.value
    }

    @objc func didChangeXtranslationValue(_ sender: UISlider) {
        xTranslation = sender.value
    }

    @objc func didChangeYtranslationValue(_ sender: UISlider) {
        yTranslation = sender.value
    }

    @objc func didChangeZtranslationValue(_ sender: UISlider) {
        zTranslation = sender.value
    }

    @objc func didToggleFlipper(_ sender: UISwitch) {
        isBackgroundFlipped = sender.isOn
    }
}
