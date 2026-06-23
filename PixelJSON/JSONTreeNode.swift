//
//  JSONTreeNode.swift
//  PixelJSON
//
//  Created by Satori Tech 341 on 23/06/26.
//
import SwiftUI

// ── Nodo recursivo ──
struct JSONTreeNode: View {
    let key: String?
    let value: JSONValue
    let depth: Int

    @State private var isExpanded: Bool = true

    var body: some View {
        switch value {
        case .object(let entries):
            VStack(alignment: .leading, spacing: 3) {
                headerRow(summary: "{ \(entries.count) }")
                if isExpanded {
                    ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                        JSONTreeNode(key: entry.key, value: entry.value, depth: depth + 1)
                    }
                }
            }
        case .array(let items):
            VStack(alignment: .leading, spacing: 3) {
                headerRow(summary: "[ \(items.count) ]")
                if isExpanded {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        JSONTreeNode(key: "\(index)", value: item, depth: depth + 1)
                    }
                }
            }
        default:
            leafRow
        }
    }

    private func headerRow(summary: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 12)

                if let key = key {
                    Text(key)
                        .foregroundStyle(JSONHighlighter.keyColor)
                        .fontWeight(.semibold)
                    Text(":").foregroundStyle(.white.opacity(0.3))
                }

                Text(summary).foregroundStyle(.white.opacity(0.35))
            }
            .font(.system(size: 12, design: .monospaced))
        }
        .buttonStyle(.plain)
        .padding(.leading, CGFloat(depth) * 14)
    }

    private var leafRow: some View {
        HStack(spacing: 4) {
            Spacer().frame(width: 12) // alinea con el espacio del chevron

            if let key = key {
                Text(key)
                    .foregroundStyle(JSONHighlighter.keyColor)
                    .fontWeight(.semibold)
                Text(":").foregroundStyle(.white.opacity(0.3))
            }

            switch value {
            case .string(let s):
                Text("\"\(s)\"").foregroundStyle(JSONHighlighter.stringColor)
            case .number(let n):
                Text(n).foregroundStyle(JSONHighlighter.numberColor)
            case .bool(let b):
                Text(b ? "true" : "false").foregroundStyle(JSONHighlighter.boolNullColor)
            case .null:
                Text("null").foregroundStyle(JSONHighlighter.boolNullColor)
            default:
                EmptyView()
            }
        }
        .font(.system(size: 12, design: .monospaced))
        .padding(.leading, CGFloat(depth) * 14)
    }
}
