//
//  BodyEditor.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 12/1/23.
//

import Foundation
import SwiftUI

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

struct BodyEditorView: View {
    @State var graph: RenderGraph
    
    init() {
        self.graph = RenderGraph()
        self.graph.activeCamera = self.graph.root.push(Node(
            transform(
                position: (0, 0, -40)
            ),
            camera(fov: 90)
        ))
        
        self.graph.root.push(cardinalArrows(magnitude: 10))
    }
    
    func addSphere() {
        self.graph.root.push(Node(transform(), ellipsoid(5, 5, 5)))
    }
    
    func moveCamera() {
        guard let camera = self.graph.activeCamera else {
            preconditionFailure("No active camera set")
        }
        
        camera.transform.position.z += 10
    }
    
    var magnification: some Gesture {
        return MagnifyGesture()
            .onChanged { (value) in
                guard let camera = self.graph.activeCamera else {
                    preconditionFailure("No active camera set")
                }
                
                camera.transform.position.z += value.velocity
            }
    }
    
    var body: some View {
        NavigationStack {
            RendererView($graph)
                .gesture(magnification)
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