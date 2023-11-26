//
//  Renderer.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import MetalKit

// TODO(HUGE): How can we avoid doing work? The particle sim doesn't need to run every frame if equilibrium has been reached and surfaces haven't moved. Ditto of lines.

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
        private var surfacePipeline: SurfacePipeline
        
        override init() {
            self.device = MTLCreateSystemDefaultDevice()!
            self.commandQueue = device.makeCommandQueue()!
            self.linePipeline = LinePipeline(device)
            self.surfacePipeline = SurfacePipeline(device)
           
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
            
            
            self.surfacePipeline.begin()
            self.surfacePipeline.draw(
                transform(),
                ellipsoid: (5.0, 5.0, 5.0)
            )
            self.surfacePipeline.draw(
                transform(
                    position: (0.0, 0.0, 5.0)
                ),
                ellipsoid: (2.5, 2.5, 5.0)
            )
            self.surfacePipeline.draw(
                transform(
                    position: (5.0, 0.0, 0.0)
                ),
                ellipsoid: (5.0, 2.5, 2.5)
            )
            self.surfacePipeline.end()
            
            self.linePipeline.begin()
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
            self.linePipeline.end()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            self.camera.aspectRatioUpdated(aspectRatio: Float(size.width / size.height))
        }
        
        func draw(in view: MTKView) {
            let buffer = self.commandQueue.makeCommandBuffer()!
            let descriptor = view.currentRenderPassDescriptor!
            let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)!
            
            encoder.setDepthStencilState(self.depthStencil)
            
            var uniforms = self.camera.uniforms()
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
                
            self.surfacePipeline.encode(encoder)
            self.linePipeline.encode(encoder)
            
            encoder.endEncoding()
            
            buffer.present(view.currentDrawable!)
            buffer.commit()
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

