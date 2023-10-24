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

    var backgroundVertexData: [Float] {
        [
            -1.0, 1.0, 0.0, 1.0,
             1.0, 1.0, 0.0, 1.0,
             -1.0, -1.0, 0.0, 1.0,
             1.0, -1.0, 0.0, 1.0
         ]
    }

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

        device = MTLCreateSystemDefaultDevice()
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.frame
        view.layer.addSublayer(metalLayer)

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
    }

    func render() {
        guard let drawable = metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear

        guard let backgroundImage = UIImage(named: "background"),
              let backgroundCGImage = backgroundImage.cgImage else {
            fatalError("Failed to get image")
        }

        guard let image = UIImage(named: imageName),
              let cgImage = image.cgImage else {
            fatalError("Failed to get image")
        }

        normalizedX = Float(cgImage.width) / Float(metalLayer.drawableSize.width)
        normalizedY = Float(cgImage.height) / Float(metalLayer.drawableSize.height)

        let textureLoader = MTKTextureLoader(device: device)

        guard let backgroundTexture = try? textureLoader.newTexture(
            cgImage: backgroundCGImage,
            options: [.SRGB : false]
        ) else {
            fatalError("Failed to create texture from image")
        }

        guard let texture = try? textureLoader.newTexture(
            cgImage: cgImage,
            options: [.SRGB : false]
        ) else {
            fatalError("Failed to create texture from image")
        }

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

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(backgroundVertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(backgroundTexture, index: 0)
        renderEncoder.setVertexBuffer(identityBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(identityBuffer, offset: 0, index: 2)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(translationBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(scaleBuffer, offset: 0, index: 2)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
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
}
