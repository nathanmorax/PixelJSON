//
//  JSONHighlighter.swift
//  PixelJSON
//
//  Created by Satori Tech 341 on 23/06/26.
//
import SwiftUI


enum JSONHighlighter {
    
    // Colores tipo editor de código
    static let keyColor = Color(red: 0.55, green: 0.78, blue: 1.0)      // azul claro
    static let stringColor = Color(red: 0.65, green: 0.88, blue: 0.55)  // verde
    static let numberColor = Color(red: 0.97, green: 0.71, blue: 0.45)  // naranja
    static let boolNullColor = Color(red: 0.85, green: 0.55, blue: 0.95) // morado
    static let punctuationColor = Color.white.opacity(0.45)
    static let defaultColor = Color.white.opacity(0.85)
    
    static func highlight(_ raw: String) -> AttributedString {
        var result = AttributedString()
        let chars = Array(raw)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            // Strings (keys o values)
            if char == "\"" {
                var str = "\""
                var j = i + 1
                while j < chars.count {
                    str.append(chars[j])
                    if chars[j] == "\"" && chars[j - 1] != "\\" {
                        j += 1
                        break
                    }
                    j += 1
                }
                
                // Mira hacia adelante (saltando espacios) para ver si sigue ':'
                var k = j
                while k < chars.count && (chars[k] == " " || chars[k] == "\n" || chars[k] == "\t") {
                    k += 1
                }
                let isKey = k < chars.count && chars[k] == ":"
                
                var attr = AttributedString(str)
                attr.foregroundColor = isKey ? keyColor : stringColor
                if isKey {
                    attr.font = .system(size: 12, weight: .semibold, design: .monospaced)
                }
                result.append(attr)
                
                i = j
                continue
            }
            
            // Números (incluye negativos y decimales)
            if char.isNumber || (char == "-" && i + 1 < chars.count && chars[i + 1].isNumber) {
                var num = String(char)
                var j = i + 1
                while j < chars.count && (chars[j].isNumber || chars[j] == "." || chars[j] == "e" || chars[j] == "E" || chars[j] == "+" || chars[j] == "-") {
                    num.append(chars[j])
                    j += 1
                }
                var attr = AttributedString(num)
                attr.foregroundColor = numberColor
                result.append(attr)
                i = j
                continue
            }
            
            // true / false / null
            if char.isLetter {
                var word = String(char)
                var j = i + 1
                while j < chars.count && chars[j].isLetter {
                    word.append(chars[j])
                    j += 1
                }
                var attr = AttributedString(word)
                if ["true", "false", "null"].contains(word) {
                    attr.foregroundColor = boolNullColor
                } else {
                    attr.foregroundColor = defaultColor
                }
                result.append(attr)
                i = j
                continue
            }
            
            // Puntuación: { } [ ] , :
            if "{}[],:".contains(char) {
                var attr = AttributedString(String(char))
                attr.foregroundColor = punctuationColor
                result.append(attr)
                i += 1
                continue
            }
            
            // Espacios, saltos de línea, etc.
            result.append(AttributedString(String(char)))
            i += 1
        }
        
        return result
    }
}
