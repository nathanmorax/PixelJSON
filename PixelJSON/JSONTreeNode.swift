//
//  JSONTreeNode.swift
//  PixelJSON
//
//  Created by Satori Tech 341 on 23/06/26.
//

import SwiftUI

// ── Helpers sobre JSONValue ──

private func graphEntries(of value: JSONValue) -> [(key: String, value: JSONValue)] {
    switch value {
    case .object(let entries):
        return entries
    case .array(let items):
        return items.enumerated().map { (String($0.offset), $0.element) }
    default:
        return []
    }
}

private func isLeafValue(_ value: JSONValue) -> Bool {
    switch value {
    case .object, .array: return false
    default: return true
    }
}

private func summaryText(for value: JSONValue) -> String {
    switch value {
    case .object(let entries):
        return "{ \(entries.count) \(entries.count == 1 ? "key" : "keys") }"
    case .array(let items):
        return "[ \(items.count) \(items.count == 1 ? "item" : "items") ]"
    default:
        return ""
    }
}

private func leafText(for value: JSONValue) -> String {
    switch value {
    case .string(let s): return s
    case .number(let n): return n
    case .bool(let b): return b ? "true" : "false"
    case .null: return "null"
    default: return ""
    }
}

private func leafColor(for value: JSONValue) -> Color {
    switch value {
    case .string: return JSONHighlighter.stringColor
    case .number: return JSONHighlighter.numberColor
    case .bool, .null: return JSONHighlighter.boolNullColor
    default: return .white
    }
}

// ── Modelo del grafo ──

private struct GraphNode: Identifiable {
    let id: String          // ruta estable, p.ej. "root.fault.detail"
    let key: String?
    let value: JSONValue
    let depth: Int
}

private struct GraphEdge: Identifiable {
    let id: String
    let fromRowID: String
    let toNodeID: String
    let label: String
}

private struct GraphAnchorKey: PreferenceKey {
    static var defaultValue: [String: CGPoint] = [:]
    static func reduce(value: inout [String: CGPoint], nextValue: () -> [String: CGPoint]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private func buildGraph(
    value: JSONValue,
    key: String?,
    id: String,
    depth: Int,
    collapsed: Set<String>,
    nodesByDepth: inout [Int: [GraphNode]],
    edges: inout [GraphEdge]
) {
    let node = GraphNode(id: id, key: key, value: value, depth: depth)
    nodesByDepth[depth, default: []].append(node)

    guard !collapsed.contains(id) else { return }

    for (index, entry) in graphEntries(of: value).enumerated() {
        guard !isLeafValue(entry.value) else { continue }
        let childID = "\(id).\(entry.key)"
        let rowID = "\(id)#\(index)"
        edges.append(GraphEdge(id: rowID, fromRowID: rowID, toNodeID: childID, label: entry.key))
        buildGraph(value: entry.value, key: entry.key, id: childID, depth: depth + 1,
                   collapsed: collapsed, nodesByDepth: &nodesByDepth, edges: &edges)
    }
}

// ── Caja individual ──

private struct GraphBoxView: View {
    let node: GraphNode
    @Binding var collapsedIDs: Set<String>

    private var entries: [(key: String, value: JSONValue)] { graphEntries(of: node.value) }
    private var isCollapsed: Bool { collapsedIDs.contains(node.id) }
    private var hasChildren: Bool { entries.contains { !isLeafValue($0.value) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                rowView(entry: entry, index: index)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minWidth: 150, maxWidth: 260, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.13, green: 0.13, blue: 0.15)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.12)))
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: GraphAnchorKey.self,
                    value: [node.id: CGPoint(x: geo.frame(in: .named("graph")).minX,
                                              y: geo.frame(in: .named("graph")).midY)]
                )
            }
        )
        .overlay(alignment: .topLeading) {
            if hasChildren {
                Button(action: toggle) {
                    Image(systemName: isCollapsed ? "plus" : "minus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.65))
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(Color(red: 0.16, green: 0.16, blue: 0.18)))
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.2)))
                }
                .buttonStyle(.plain)
                .offset(x: -7, y: -7)
            }
        }
    }

    private func toggle() {
        withAnimation(.easeInOut(duration: 0.18)) {
            if isCollapsed { collapsedIDs.remove(node.id) } else { collapsedIDs.insert(node.id) }
        }
    }

    @ViewBuilder
    private func rowView(entry: (key: String, value: JSONValue), index: Int) -> some View {
        let rowID = "\(node.id)#\(index)"
        let line: Text = {
            let keyPart = Text(entry.key)
                .foregroundColor(JSONHighlighter.keyColor)
                .fontWeight(.semibold)
            let colonPart = Text(": ").foregroundColor(.white.opacity(0.3))
            let valuePart: Text
            if isLeafValue(entry.value) {
                valuePart = Text(leafText(for: entry.value)).foregroundColor(leafColor(for: entry.value))
            } else {
                valuePart = Text(summaryText(for: entry.value)).foregroundColor(.white.opacity(0.4))
            }
            return keyPart + colonPart + valuePart
        }()

        line
            .font(.system(size: 12, design: .monospaced))
            .lineLimit(1)
            .truncationMode(.tail)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: GraphAnchorKey.self,
                        value: [rowID: CGPoint(x: geo.frame(in: .named("graph")).maxX,
                                                y: geo.frame(in: .named("graph")).midY)]
                    )
                }
            )
    }
}

// ── Grid fijo de fondo (siempre llena todo el contenedor) ──

private struct GraphGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 32
            var x: CGFloat = 0
            while x < size.width {
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }, with: .color(.white.opacity(0.03)), lineWidth: 1)
                x += spacing
            }
            var y: CGFloat = 0
            while y < size.height {
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }, with: .color(.white.opacity(0.03)), lineWidth: 1)
                y += spacing
            }
        }
    }
}

// ── Lienzo de las líneas de conexión (se mueve junto con las cajas) ──

private struct GraphConnectionsCanvas: View {
    let edges: [GraphEdge]
    let anchors: [String: CGPoint]

    var body: some View {
        Canvas { context, size in
            for edge in edges {
                guard let from = anchors[edge.fromRowID], let to = anchors[edge.toNodeID] else { continue }

                var path = Path()
                path.move(to: from)
                let midX = (from.x + to.x) / 2
                path.addCurve(to: to, control1: CGPoint(x: midX, y: from.y), control2: CGPoint(x: midX, y: to.y))
                context.stroke(path, with: .color(.white.opacity(0.25)), lineWidth: 1.2)

                let labelPoint = CGPoint(x: midX, y: (from.y + to.y) / 2 - 10)
                context.draw(
                    Text(edge.label).font(.system(size: 10)).foregroundColor(.white.opacity(0.45)),
                    at: labelPoint
                )
            }
        }
    }
}

// ── Vista raíz del grafo ──

struct JSONGraphView: View {
    let root: JSONValue
    @State private var collapsedIDs: Set<String> = []
    @State private var anchors: [String: CGPoint] = [:]
    @State private var contentOffset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @GestureState private var magnifyBy: CGFloat = 1.0

    private let minScale: CGFloat = 0.4
    private let maxScale: CGFloat = 2.5

    private var totalOffset: CGSize {
        CGSize(width: contentOffset.width + dragTranslation.width,
               height: contentOffset.height + dragTranslation.height)
    }

    private var currentScale: CGFloat {
        scale * magnifyBy
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                contentOffset.width += value.translation.width
                contentOffset.height += value.translation.height
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { value, state, _ in
                state = value
            }
            .onEnded { value in
                scale = min(max(scale * value, minScale), maxScale)
            }
    }

    var body: some View {
        if isLeafValue(root) {
            // fallback simple si el JSON raíz no es objeto/array
            Text(leafText(for: root))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(leafColor(for: root))
                .padding(14)
        } else {
            let (nodesByDepth, edges) = computeGraph()
            let depths = nodesByDepth.keys.sorted()

            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    // Grid fijo: siempre cubre el contenedor completo, sin importar
                    // cuánto contenido haya ni cuánto se haya paneado.
                    GraphGridBackground()

                    // Capa pannable: cajas + líneas de conexión.
                    HStack(alignment: .top, spacing: 70) {
                        ForEach(depths, id: \.self) { depth in
                            VStack(alignment: .leading, spacing: 36) {
                                ForEach(nodesByDepth[depth] ?? []) { node in
                                    GraphBoxView(node: node, collapsedIDs: $collapsedIDs)
                                }
                            }
                        }
                    }
                    .padding(40)
                    .background(GraphConnectionsCanvas(edges: edges, anchors: anchors))
                    .coordinateSpace(name: "graph")
                    .onPreferenceChange(GraphAnchorKey.self) { anchors = $0 }
                    .scaleEffect(currentScale, anchor: .topLeading)
                    .offset(x: totalOffset.width, y: totalOffset.height)
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .contentShape(Rectangle())
                .clipped()
                // Arrastrar con mouse o con 3 dedos (si está activado
                // "Arrastre de tres dedos" en Accesibilidad > Trackpad) mueve el canvas.
                .gesture(panGesture)
                // Pellizcar con 2 dedos hace zoom in/out.
                .simultaneousGesture(zoomGesture)
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scale = 1.0
                        contentOffset = .zero
                    }
                }
            }
            .background(Color(red: 0.07, green: 0.07, blue: 0.08))
        }
    }

    private func computeGraph() -> ([Int: [GraphNode]], [GraphEdge]) {
        var nodesByDepth: [Int: [GraphNode]] = [:]
        var edges: [GraphEdge] = []
        buildGraph(value: root, key: nil, id: "root", depth: 0,
                   collapsed: collapsedIDs, nodesByDepth: &nodesByDepth, edges: &edges)
        return (nodesByDepth, edges)
    }
}
