//
//  Renderer.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import MetalKit


struct RendererView: PlatformAgnosticViewRepresentable {
    static let pixelFormat: MTLPixelFormat = .rgba8Unorm
    static let pixelClear: MTLClearColor = .init(red: 1, green: 1, blue: 1, alpha: 1)
    static let depthFormat: MTLPixelFormat = .depth32Float
    static let depthClear = 1.0
    
    class Renderer: NSObject, MTKViewDelegate {
        var device: MTLDevice
        
        private var commandQueue: MTLCommandQueue
        private var depthStencil: MTLDepthStencilState
        
        private var camera: Camera
        
        private var linePipeline: LinePipeline
        
        override init() {
            self.device = MTLCreateSystemDefaultDevice()!
            self.commandQueue = device.makeCommandQueue()!
            self.linePipeline = LinePipeline(device)
           
            let depthDescriptor = MTLDepthStencilDescriptor()
            depthDescriptor.isDepthWriteEnabled = true
            depthDescriptor.depthCompareFunction = .lessEqual
            self.depthStencil = device.makeDepthStencilState(descriptor: depthDescriptor)!
            
            self.camera = Camera(
                eye: simd_float3(40, 40, 40),
                target: simd_float3(0, 0, 0),
                fov: 60,
                aspectRatio: 1
            )
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            self.camera.aspectRatioUpdated(aspectRatio: Float(size.width / size.height))
        }
        
        func commit(view: MTKView) {
            let buffer = self.commandQueue.makeCommandBuffer()!
            let descriptor = view.currentRenderPassDescriptor!
            let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)!
            
            encoder.setDepthStencilState(self.depthStencil)
            
            var uniforms = self.camera.uniforms()
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
                
            self.linePipeline.commit(encoder)
            
            encoder.endEncoding()
            
            buffer.present(view.currentDrawable!)
            buffer.commit()
        }
        
        func draw(in view: MTKView) {
            self.linePipeline.draw(
                transform(
                    rotation: (0, 0, -90)
                ),
                arrow(
                    length: 10,
                    color: (1, 0, 0),
                    thickness: 0.5
                )
            )
            
            self.linePipeline.draw(
                transform(),
                arrow(
                    length: 10,
                    color: (0, 1, 0),
                    thickness: 0.5
                )
            )
            self.linePipeline.draw(
                transform(
                    rotation: (90, 0, 0)
                ),
                arrow(
                    length: 10,
                    color: (0, 0, 1),
                    thickness: 0.5
                )
            )
            
            self.commit(view: view)
        }
    }
    
    func makeCoordinator() -> Renderer { Renderer() }
    
    func makePlatformView(context: Context) -> MTKView {
        let view = MTKView()

        view.delegate = context.coordinator
        view.device = context.coordinator.device
        view.colorPixelFormat = RendererView.pixelFormat
        view.clearColor = RendererView.pixelClear
        view.depthStencilPixelFormat = RendererView.depthFormat
        view.clearDepth = RendererView.depthClear
        view.depthStencilAttachmentTextureUsage = .renderTarget
        view.depthStencilStorageMode = .memoryless
        view.drawableSize = view.frame.size
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
//        view.needsDisplay = true
        view.isPaused = false

        return view
    }

    func updatePlatformView(_ nsView: MTKView, context: Context) { }
}

