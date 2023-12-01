//
//  Graph.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/26/23.
//

import Foundation

enum Kind {
    case Camera(Camera)
    case Line(Line)
    case Surface(Surface)
}

class Node {
    private(set) var children: [Node]
    
    var transform: NodeTransform
    var kind: Kind?
    
    init(_ transform: NodeTransform) {
        self.transform = transform
        self.children = []
    }
    
    init(_ transform: NodeTransform, _ kind: Kind) {
        self.transform = transform
        self.children = []
        self.kind = kind
    }
    
    init(_ transform: NodeTransform, _ camera: Camera) {
        self.transform = transform
        self.children = []
        self.kind = .Camera(camera)
    }
    
    init(_ transform: NodeTransform, _ line: Line) {
        self.transform = transform
        self.children = []
        self.kind = .Line(line)
    }
    
    init(_ transform: NodeTransform, _ surface: Surface) {
        self.transform = transform
        self.children = []
        self.kind = .Surface(surface)
    }
    
    init(_ transform: NodeTransform, @NodeBuilder _ children: () -> [Node]) {
        self.transform = transform
        self.children = children()
    }
    
    @discardableResult
    func push(_ node: Node) -> Node {
        self.children.append(node)
        
        return node
    }
}

class RenderGraph {
    var root: Node
    
    init() {
        root = Node(NodeTransform())
    }
    
    func walk(
        body: (MatrixTransform, Kind) -> ()
    ) {
        self.visitNode(NodeTransform().matrix(), self.root, body)
    }
    
    private func visitNode(
        _ previousTransform: MatrixTransform,
        _ node: Node,
        _ body: (MatrixTransform, Kind) -> ()
    ) {
        let nodeTransform = node.transform.matrix() * previousTransform
        
        if let kind = node.kind {
            body(nodeTransform, kind)
        }
        
        for child in node.children {
            self.visitNode(nodeTransform, child, body)
        }
    }
}

@resultBuilder
struct NodeBuilder {
    static func buildBlock() -> [Node] {
        []
    }
    
    static func buildBlock(_ components: Node...) -> [Node] {
        components
    }
}
