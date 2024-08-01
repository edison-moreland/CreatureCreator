//
//  BodyEditor.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 12/1/23.
//

import Foundation
import SwiftUI
import SceneKit


func cardinalArrows(magnitude: Float) -> Node {
    return Node(transform()) {
        Node(transform(rotation: (0, 0, -90)),
             arrow(length: magnitude,
                   color: (1, 0, 0),
                   thickness: 0.2))
        Node(transform(),
             arrow(length: magnitude,
                   color: (0, 1, 0),
                   thickness: 0.2))
        Node(transform(rotation: (90, 0, 0)),
             arrow(length: magnitude,
                   color: (0, 0, 1),
                   thickness: 0.2))
    }
}

func sceneKitArrows(magnitude: CGFloat) -> SCNNode {
    let root = SCNNode()
   
    let coreMagnitude = magnitude/20;
    
    root.addChildNode({
        let geometry = SCNBox(width: coreMagnitude,
                              height: coreMagnitude,
                              length: coreMagnitude,
                              chamferRadius: 0.0)
        
        let material = SCNMaterial()
        material.diffuse.contents = CGColor(red: 0.0,
                                            green: 0.0,
                                            blue: 0.0,
                                            alpha: 1.0)
        
        geometry.firstMaterial = material
        
        let node = SCNNode(geometry: geometry)
        
        return node
    }())
   
    root.addChildNode({
        let geometry = SCNPyramid(width: coreMagnitude,
                                  height: magnitude,
                                  length: coreMagnitude)
        
        let material = SCNMaterial()
        material.diffuse.contents = CGColor(red: 0.0,
                                            green: 1.0,
                                            blue: 0.0,
                                            alpha: 1.0)
        
        geometry.firstMaterial = material
        
        let node = SCNNode(geometry: geometry)
        node.position.y = coreMagnitude/2
        
        return node
    }())
    
    root.addChildNode({
        let geometry = SCNPyramid(width: coreMagnitude,
                                  height: magnitude,
                                  length: coreMagnitude)
        
        let material = SCNMaterial()
        material.diffuse.contents = CGColor(red: 1.0,
                                            green: 0.0,
                                            blue: 0.0,
                                            alpha: 1.0)
        
        geometry.firstMaterial = material
        
        let node = SCNNode(geometry: geometry)
        node.position.x = coreMagnitude/2
        node.rotation = SCNVector4(0, 0, 1, -CGFloat.pi/2)
        
        return node
    }())
    
    root.addChildNode({
        let geometry = SCNPyramid(width: coreMagnitude,
                                  height: magnitude,
                                  length: coreMagnitude)
        
        let material = SCNMaterial()
        material.diffuse.contents = CGColor(red: 0.0,
                                            green: 0.0,
                                            blue: 1.0,
                                            alpha: 1.0)
        
        geometry.firstMaterial = material
        
        let node = SCNNode(geometry: geometry)
        node.position.z = coreMagnitude/2
        node.rotation = SCNVector4(1, 0, 0, CGFloat.pi/2)
        
        return node
    }())

    return root
}

struct BodyEditorView: View {
    @State var scene: SCNScene
    
    init() {
        scene = SCNScene(named: "BodyEditor.scn")!
       
        scene.rootNode.addChildNode(sceneKitArrows(magnitude: 10.0))
    }
    
    func addSphere() {
    }
    
    func moveCamera() {
    }
    
    var body: some View {
        NavigationStack {
            CreatureRendererView($scene)
                .toolbar(id: "body_editor") {
                    ToolbarItem(id: "add_sphere", placement: .primaryAction) {
                        Button(action: addSphere) {
                            Text("Add Shape")
                        }
                    }
                    ToolbarItem(id: "move_camera") {
                        Button(action: moveCamera) {
                            Text("Move Camera")
                        }
                    }
                }.toolbarRole(.editor)
        }
    }
}

#Preview {
    BodyEditorView()
}
