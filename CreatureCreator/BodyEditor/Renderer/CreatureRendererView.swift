//
//  Renderer.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import MetalKit
import SwiftUI
import SceneKit

// TODO(HUGE): How can we avoid doing work? The particle sim doesn't need to run every frame if equilibrium has been reached and surfaces haven't moved. Ditto of lines.

class CreatureRendererDelegate : NSObject, SCNSceneRendererDelegate {
    var device: MTLDevice
    
    private var uniforms: Uniforms
    
    private var surfacePipeline: SurfacePipeline
    
   
    init(device: MTLDevice) {
        self.device = device
        
        self.surfacePipeline = SurfacePipeline(device)
           
        self.uniforms = Uniforms()
        
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        let pov = renderer.pointOfView!
      
        
        let projection = pov.camera!.projectionTransform(withViewportSize: renderer.currentViewport.size)
        let view = SCNMatrix4Invert(pov.worldTransform)
        
        uniforms.camera = simd_float4x4(projection) * simd_float4x4(view)
        uniforms.cameraPosition = pov.simdWorldPosition
        
        self.surfacePipeline.begin()
        self.surfacePipeline.draw(NodeTransform().matrix(), .Ellipsoid(1, 1, 1))
        self.surfacePipeline.end()
        
        let encoder = renderer.currentRenderCommandEncoder!
        
        encoder.setVertexBytes(&self.uniforms, length: MemoryLayout<Uniforms>.size, index: 10)
            
        self.surfacePipeline.encode(encoder)
    }
}

struct CreatureRendererView: PlatformAgnosticViewRepresentable {
    @Binding var scene: SCNScene
    
    init(_ scene: Binding<SCNScene>) {
        self._scene = scene
    }
    
    class Coordinator {
        var rendererDelegate: CreatureRendererDelegate?
        
        func getRendererDelegate(device: MTLDevice) -> CreatureRendererDelegate {
            assert(self.rendererDelegate == nil)
            
            self.rendererDelegate = CreatureRendererDelegate(device: device)
            
            return self.rendererDelegate!
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makePlatformView(context: Context) -> SCNView {
        let view = SCNView()

        view.delegate = context.coordinator.getRendererDelegate(device: view.device!)
        view.scene = scene
        view.rendersContinuously = true
        view.allowsCameraControl = true

        return view
    }

    func updatePlatformView(_ nsView: SCNView, context: Context) {
    }
}

