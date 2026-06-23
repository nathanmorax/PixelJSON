//
//  JSONViewMode.swift
//  PixelJSON
//
//  Created by Satori Tech 341 on 23/06/26.
//
import SwiftUI

enum JSONViewMode: String, CaseIterable {
    case raw = "Raw"
    case tree = "Tree"
}

struct JSONViewModeSwitcher: View {
    @Binding var mode: JSONViewMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(JSONViewMode.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { mode = option }
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 12, weight: mode == option ? .bold : .medium))
                        .foregroundStyle(mode == option ? .white : Color.accentLavender.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(mode == option ? Color.accentLavender.opacity(0.25) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.black.opacity(0.25)))
    }
}
