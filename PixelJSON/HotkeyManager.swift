//
//  HotkeyManager.swift
//  PixelJSON
//
//  Created by Satori Tech 341 on 23/06/26.
//

import AppKit

final class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    func register() {
        // Captura ⌘V cuando OTRA app tiene el foco
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.handle(event: event)
        }
        
        // Captura ⌘V cuando TU PROPIA app (el popover) tiene el foco
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.handle(event: event)
            return event // importante: dejar pasar el evento normalmente
        }
        
        print("📡 Global monitor registrado: \(globalMonitor != nil)")
        print("📡 Local monitor registrado: \(localMonitor != nil)")
    }
    
    private func handle(event: NSEvent) {
        let isCmd = event.modifierFlags.contains(.command)
        let isV = event.keyCode == 9 // kVK_ANSI_V
        
        guard isCmd && isV else { return }
        
        print("✅ ⌘V detectado")
        
        DispatchQueue.main.async {
            HotkeyManager.handlePaste()
        }
    }
    
    deinit {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }
    
    static func handlePaste() {
        guard let text = NSPasteboard.general.string(forType: .string),
              let data = text.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            print("❌ No es JSON válido")
            return
        }
        
        let pretty = format(raw: text)
        
        NotificationCenter.default.post(
            name: .jsonPasted,
            object: nil,
            userInfo: ["raw": pretty]
        )
    }
    
    private static func format(raw: String) -> String {
        // Solo valida que sea JSON, pero no lo reconstruye desde un diccionario
        guard let data = raw.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            return raw
        }
        
        // Reformatea preservando el orden original usando re-indentación manual
        return reindent(raw)
    }

    private static func reindent(_ raw: String) -> String {
        var result = ""
        var indentLevel = 0
        var insideString = false
        var previousChar: Character? = nil
        let indentUnit = "  "
        
        for char in raw {
            if char == "\"" && previousChar != "\\" {
                insideString.toggle()
            }
            
            if !insideString {
                switch char {
                case "{", "[":
                    indentLevel += 1
                    result.append(char)
                    result.append("\n")
                    result.append(String(repeating: indentUnit, count: indentLevel))
                    previousChar = char
                    continue
                case "}", "]":
                    indentLevel -= 1
                    result.append("\n")
                    result.append(String(repeating: indentUnit, count: indentLevel))
                    result.append(char)
                    previousChar = char
                    continue
                case ",":
                    result.append(char)
                    result.append("\n")
                    result.append(String(repeating: indentUnit, count: indentLevel))
                    previousChar = char
                    continue
                case ":":
                    result.append(": ")
                    previousChar = char
                    continue
                case " ", "\n", "\t":
                    previousChar = char
                    continue // ignora espacios/saltos originales, los regeneramos nosotros
                default:
                    break
                }
            }
            
            result.append(char)
            previousChar = char
        }
        
        return result
    }
}

extension Notification.Name {
    static let jsonPasted = Notification.Name("jsonPasted")
}
