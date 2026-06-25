//
//  ContentView.swift
//  PixelJSON
//
//  Created by Satori Tech 341 on 23/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var pastedJSON: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let json = pastedJSON {
                    JSONResultView(json: json) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            pastedJSON = nil
                        }
                    }
                } else {
                    emptyStateView
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.08))

            footerView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.11, green: 0.11, blue: 0.13))
        .onReceive(NotificationCenter.default.publisher(for: .jsonPasted)) { notification in
            if let raw = notification.userInfo?["raw"] as? String {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pastedJSON = raw
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentLavender.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: "document.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.accentLavender)
            }
            .padding(.top, 28)

            Text("JSON Import & Export")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, 12)

            Text("Update or download CMS content with JSON files.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.horizontal, 24)

            HStack(spacing: 6) {
                Image(systemName: "command")
                    .font(.system(size: 11, weight: .semibold))
                Text("+")
                    .font(.system(size: 11, weight: .regular))
                Text("V")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.06))
            )
            .padding(.top, 18)

            HStack(spacing: 8) {
                pillButton(title: "Import", filled: false) { }
                pillButton(title: "Export", filled: true) { }
            }
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private func pillButton(title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(filled ? .white : .white.opacity(0.85))
                .frame(maxWidth: 60)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(filled ? Color.accentLavender : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }

    private var footerView: some View {
        HStack {
            Button {

            } label: {
                Image(systemName: "gearshape")
            }

            Spacer()
                        
            Button {
                NSApplication.shared.terminate(nil)

            } label: {
                Image(systemName: "door.left.hand.open")
            }

        }
        .font(.system(size: 12, weight: .medium))
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

struct JSONResultView: View {
    let json: String
    var onClear: () -> Void

    @State private var didCopy = false
    @State private var viewMode: JSONViewMode = .raw

    private var parsedValue: JSONValue? {
        JSONParser.parse(json)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                Text("JSON detected")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            JSONViewModeSwitcher(mode: $viewMode)
                .padding(.horizontal, 18)

            Group {
                if viewMode == .raw {
                    ScrollView {
                        Text(JSONHighlighter.highlight(json))
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                } else {
                    if let parsedValue {
                        JSONTreeView(value: parsedValue)
                            .id(json) // reconstruye el grafo (y resetea pan/zoom/colapsos) con cada JSON nuevo
                    } else {
                        Text("No se pudo construir el árbol")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(14)
                    }
                }
            }
            .frame(height: 360)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.25)))
            .padding(.horizontal, 18)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(json, forType: .string)
                didCopy = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { didCopy = false }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                    Text(didCopy ? "Copied" : "Copy result")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.accentLavender)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
    }
}

extension Color {
    static let accentLavender = Color(red: 0.55, green: 0.52, blue: 0.96)
}

#Preview {
    ContentView()
}

struct JSONTreeView: View {
    let value: JSONValue

    var body: some View {
        JSONGraphView(root: value)
    }
}
