//
//  JSONValue.swift
//  PixelJSON
//
//  Created by Satori Tech 341 on 23/06/26.
//


indirect enum JSONValue {
    case object([(key: String, value: JSONValue)])
    case array([JSONValue])
    case string(String)
    case number(String)
    case bool(Bool)
    case null
}

final class JSONParser {
    private let chars: [Character]
    private var pos: Int = 0

    private init(_ string: String) {
        self.chars = Array(string)
    }

    static func parse(_ string: String) -> JSONValue? {
        let parser = JSONParser(string)
        return parser.parseValue()
    }

    private func peek() -> Character? {
        pos < chars.count ? chars[pos] : nil
    }

    private func advance() -> Character? {
        guard pos < chars.count else { return nil }
        let c = chars[pos]
        pos += 1
        return c
    }

    private func skipWhitespace() {
        while let c = peek(), c == " " || c == "\n" || c == "\t" || c == "\r" {
            pos += 1
        }
    }

    private func parseValue() -> JSONValue? {
        skipWhitespace()
        guard let c = peek() else { return nil }
        switch c {
        case "{": return parseObject()
        case "[": return parseArray()
        case "\"": return parseString().map { .string($0) }
        case "t", "f": return parseBool()
        case "n": return parseNull()
        default: return parseNumber()
        }
    }

    private func parseObject() -> JSONValue? {
        guard advance() == "{" else { return nil }
        var entries: [(String, JSONValue)] = []
        skipWhitespace()
        if peek() == "}" { pos += 1; return .object(entries) }

        while true {
            skipWhitespace()
            guard let key = parseString() else { return nil }
            skipWhitespace()
            guard advance() == ":" else { return nil }
            guard let value = parseValue() else { return nil }
            entries.append((key, value))
            skipWhitespace()
            guard let c = peek() else { return nil }
            if c == "," { pos += 1; continue }
            else if c == "}" { pos += 1; break }
            else { return nil }
        }
        return .object(entries)
    }

    private func parseArray() -> JSONValue? {
        guard advance() == "[" else { return nil }
        var items: [JSONValue] = []
        skipWhitespace()
        if peek() == "]" { pos += 1; return .array(items) }

        while true {
            guard let value = parseValue() else { return nil }
            items.append(value)
            skipWhitespace()
            guard let c = peek() else { return nil }
            if c == "," { pos += 1; continue }
            else if c == "]" { pos += 1; break }
            else { return nil }
        }
        return .array(items)
    }

    private func parseString() -> String? {
        skipWhitespace()
        guard advance() == "\"" else { return nil }
        var str = ""
        while let c = advance() {
            if c == "\"" { return str }
            if c == "\\" {
                guard let next = advance() else { return nil }
                switch next {
                case "\"": str.append("\"")
                case "\\": str.append("\\")
                case "/": str.append("/")
                case "n": str.append("\n")
                case "t": str.append("\t")
                case "r": str.append("\r")
                case "u":
                    var hex = ""
                    for _ in 0..<4 { if let h = advance() { hex.append(h) } }
                    if let code = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(code) {
                        str.append(Character(scalar))
                    }
                default: str.append(next)
                }
            } else {
                str.append(c)
            }
        }
        return nil
    }

    private func parseNumber() -> JSONValue? {
        var num = ""
        while let c = peek(), c.isNumber || c == "-" || c == "+" || c == "." || c == "e" || c == "E" {
            num.append(c)
            pos += 1
        }
        return num.isEmpty ? nil : .number(num)
    }

    private func parseBool() -> JSONValue? {
        if matchLiteral("true") { return .bool(true) }
        if matchLiteral("false") { return .bool(false) }
        return nil
    }

    private func parseNull() -> JSONValue? {
        matchLiteral("null") ? .null : nil
    }

    private func matchLiteral(_ literal: String) -> Bool {
        let litChars = Array(literal)
        guard pos + litChars.count <= chars.count else { return false }
        for i in 0..<litChars.count where chars[pos + i] != litChars[i] { return false }
        pos += litChars.count
        return true
    }
}
