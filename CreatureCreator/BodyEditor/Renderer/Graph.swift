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
    weak private(set) var parent: Node?
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
        node.parent = self
        self.children.append(node)
        
        return node
    }
    
    func transformMatrix() -> MatrixTransform {
//        Walk up the graph towards the root
        if let parent = self.parent {
            return self.transform.matrix() * parent.transformMatrix()
        }
        
        return self.transform.matrix()
    }
}

class RenderGraph {
    var root: Node
    var aspectRatio: Float
    weak var activeCamera: Node?
    
    init() {
        self.root = Node(NodeTransform())
        self.aspectRatio = 1
    }
    
    func cameraParameters() -> (matrix_float4x4, simd_float3) {
        guard let cameraNode = self.activeCamera else {
            preconditionFailure("No active camera set")
        }
        
        guard let cameraKind = cameraNode.kind else {
            preconditionFailure("No active camera set")
        }
        
        guard case .Camera(let camera) = cameraKind else {
            preconditionFailure("No active camera set")
        }
        
        let projection = camera.projectionMatrix(aspectRatio: self.aspectRatio)
        let view = cameraNode.transformMatrix().matrix_inverse
        
        let cameraOrigin = cameraNode.transform.position;
        
        return (projection * view, simd_float3(cameraOrigin))
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
