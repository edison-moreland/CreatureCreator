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
        
        self.graph.root.push(cardinalArrows(magnitude: 10))
    }
    
    var body: some View {
        RendererView($graph)
    }
}

#Preview {
    BodyEditorView()
}
