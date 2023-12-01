//
//  Renderer.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import MetalKit
import SwiftUI

// TODO(HUGE): How can we avoid doing work? The particle sim doesn't need to run every frame if equilibrium has been reached and surfaces haven't moved. Ditto of lines.

class Renderer {
    static let pixelFormat: MTLPixelFormat = .rgba8Unorm
    static let pixelClear: MTLClearColor = .init(red: 1, green: 1, blue: 1, alpha: 1)
    static let depthFormat: MTLPixelFormat = .depth32Float
    static let depthClear = 1.0
    
    var device: MTLDevice
    
    private var commandQueue: MTLCommandQueue
    private var depthStencil: MTLDepthStencilState
    
    private var camera: Camera
    
    private var linePipeline: LinePipeline
    private var surfacePipeline: SurfacePipeline

    init() {
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
    }
    
    func makeView() -> MTKView {
        let view = MTKView()

        view.device = self.device
        view.colorPixelFormat = Self.pixelFormat
        view.clearColor = Self.pixelClear
        view.depthStencilPixelFormat = Self.depthFormat
        view.clearDepth = Self.depthClear
        view.depthStencilAttachmentTextureUsage = .renderTarget
        view.depthStencilStorageMode = .memoryless
        view.drawableSize = view.frame.size
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
//        view.needsDisplay = true
        view.isPaused = false

        return view
    }
    
    func viewResized(size: CGSize) {
        self.camera.aspectRatioUpdated(aspectRatio: Float(size.width / size.height))
    }
    
    func drawGraph(graph: RenderGraph) {
        var drawingLines = false
        var drawingSurfaces = false
        
        graph.walk { (nodeTransform, kind) in
            switch kind {
            case .Camera(_): return
            case .Line(let line):
                if !drawingLines {
                    self.linePipeline.begin()
                    drawingLines = true
                }
                self.linePipeline.draw(nodeTransform, line)
                
            case .Surface(let surface):
                if !drawingSurfaces {
                    self.surfacePipeline.begin()
                    drawingSurfaces = true
                }
                self.surfacePipeline.draw(nodeTransform, surface)
            }
        }
        
        
        if drawingLines {
            self.linePipeline.end()
        }
        
        if drawingSurfaces {
            self.surfacePipeline.end()
        }
    }
    
    func encode(in view: MTKView) {
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

// TODO: decide on double/float for render interfaces


struct RendererView: PlatformAgnosticViewRepresentable {
    @Binding var graph: RenderGraph
    
    init(_ graph: Binding<RenderGraph>) {
        self._graph = graph
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var renderer: Renderer
        var graph: RenderGraph
        
        
        init(graph: RenderGraph) {
            self.renderer = Renderer()
            
            self.graph = graph
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            self.renderer.viewResized(size: size)
        }
        
        func draw(in view: MTKView) {
            self.renderer.drawGraph(graph: self.graph)
            self.renderer.encode(in: view)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(graph: self.graph) }
    
    func makePlatformView(context: Context) -> MTKView {
        let view = context.coordinator.renderer.makeView()

        view.delegate = context.coordinator

        return view
    }

    func updatePlatformView(_ nsView: MTKView, context: Context) {
    }
}

