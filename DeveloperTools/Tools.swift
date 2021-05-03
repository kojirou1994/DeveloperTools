import Foundation
import HTMLString
import KwiftExtension
import KwiftUtility
import SwiftUI

struct ToolWorker {
  let name: String
  let worker: (String) -> String
}

enum Tools: String, CaseIterable, Identifiable {

  case json

  case base64
  case url
  case string
  case htmlEscape
  case stringTransform
  case unicode

  var text: LocalizedStringKey {
    switch self {
    case .base64: return "Base64"
    case .htmlEscape: return "Html Escape"
    case .json: return "JSON"
    case .string: return "String"
    case .stringTransform: return "String Transform"
    case .unicode: return "Unicode"
    case .url: return "URL"
    }
  }

  var id: Self { self }

  @inlinable
  func toolView(input: Binding<String>, output: Binding<String>) -> AnyView {
    switch self {
    case .json: return AnyView(JSONTool(input: input, output: output))
    case .base64: return AnyView(Base64Tool(input: input, output: output))
    case .string: return AnyView(StringTool(input: input, output: output))
    case .htmlEscape:
      return AnyView(HtmlEscapeTool(input: input, output: output))
    case .stringTransform:
      return AnyView(StringTransformTool(input: input, output: output))
    case .unicode: return AnyView(UnicodeTool(input: input, output: output))
    case .url: return AnyView(UrlTool(input: input, output: output))
    }
  }

}

extension Data {
  public init?(base64URLEncoded string: String) {
    let base64Encoded = string.replacingOccurrences(of: "_", with: "/")
      .replacingOccurrences(of: "-", with: "+")
    // iOS can't handle base64 encoding without padding. Add manually
    let padLength = (4 - (base64Encoded.count % 4)) % 4
    let base64EncodedWithPadding =
      base64Encoded + String(repeating: "=", count: padLength)
    self.init(base64Encoded: base64EncodedWithPadding)
  }

  public func base64URLEncodedString() -> String {
    // use URL safe encoding and remove padding
    return base64EncodedString().replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "+", with: "-").replacingOccurrences(
        of: "=", with: "")
  }
}

extension String {
  public var base64URLEncoded: String {
    return data(using: .utf8)!.base64URLEncodedString()
  }

  public var base64URLDecoded: String? {
    if let decodedData = Data(base64URLEncoded: self) {
      return String(decoding: decodedData, as: UTF8.self)
    } else {
      return nil
    }
  }

  public var base64Encoded: String {
    return data(using: .utf8)!.base64EncodedString()
  }

  public var base64Decoded: String? {
    if let decodedData = Data(base64Encoded: self) {
      return String(decoding: decodedData, as: UTF8.self)
    } else {
      return nil
    }
  }
}

protocol WorkerViewProtocol: View {
  init(input: Binding<String>, output: Binding<String>)
}

struct Base64Tool: WorkerViewProtocol {
  @Binding var input: String
  @Binding var output: String
  @State var safe = false

  @State var decodeError: Bool = false

  init(input: Binding<String>, output: Binding<String>) {
    _input = input
    _output = output
  }

  var body: some View {
    HStack {
      Toggle("Url safe", isOn: $safe)
      Button("Encode") {
        let encoded =
          safe ? input.base64URLEncoded : input.base64Encoded
        output = encoded
      }
      Button("Decode") {
        if let decoded = safe
          ? input.base64URLDecoded : input.base64Decoded
        {
          output = decoded
        } else {
          decodeError = true
        }
      }.alert(isPresented: $decodeError) {
        .init(title: Text("DecodeError"), dismissButton: .default(Text("OK")))
      }
    }
  }
}

struct JSONTool: WorkerViewProtocol {
  @Binding var input: String
  @Binding var output: String
  @State var sorted = false
  @State var prettyPrinted = false
  @State var escaping = false

  @State var decodeError: Bool = false

  init(input: Binding<String>, output: Binding<String>) {
    _input = input
    _output = output
  }

  var writeOptions: JSONSerialization.WritingOptions {
    var options: JSONSerialization.WritingOptions = []
    if sorted { options.insert(.sortedKeys) }
    if prettyPrinted { options.insert(.prettyPrinted) }
    if !escaping { options.insert(.withoutEscapingSlashes) }
    return options
  }

  var body: some View {
    HStack {
      Toggle("Sorted key", isOn: $sorted)
      Toggle("Pretty", isOn: $prettyPrinted)
      Toggle("Escape", isOn: $escaping)
      Button("Format") {
        do {
          try autoreleasepool {
            let json = try JSONSerialization.jsonObject(
              with: Data(input.utf8), options: [])
            let output = try JSONSerialization.data(
              withJSONObject: json, options: writeOptions)
            self.output = .init(decoding: output, as: UTF8.self)
          }
        } catch {
          print(error)
          decodeError = true
        }
      }.alert(isPresented: $decodeError) {
        .init(title: Text("DecodeError"), dismissButton: .default(Text("OK")))
      }
    }
  }
}

struct StringTool: WorkerViewProtocol {
  @Binding var input: String
  @Binding var output: String

  init(input: Binding<String>, output: Binding<String>) {
    _input = input
    _output = output
  }

  var body: some View {
    HStack {
      Button("Lowercased") { output = input.lowercased() }
      Button("Uppercased") { output = input.uppercased() }
      Button("Reverse") { output = String(input.reversed()) }
      Button("Character Count") { output = input.count.description }
      //            Button("Word Count") {
      //                self.output = self.input.count.description
      //            }
    }
  }
}

struct HtmlEscapeTool: WorkerViewProtocol {
  @Binding var input: String
  @Binding var output: String
  @State var allowUnicode: Bool = false

  init(input: Binding<String>, output: Binding<String>) {
    _input = input
    _output = output
  }

  var body: some View {
    HStack {
      Toggle("Allow Unicode", isOn: $allowUnicode)
      Button("Escape") {
        if allowUnicode {
          output = input.addingUnicodeEntities
        } else {
          output = input.addingASCIIEntities
        }
      }

      Button("Unescape") { output = input.removingHTMLEntities }
    }
  }
}

struct StringTransformTool: WorkerViewProtocol {
  @Binding var input: String
  @Binding var output: String
  @State var failed = false
  @State var reverse = false

  @State var script = ""

  init(input: Binding<String>, output: Binding<String>) {
    _input = input
    _output = output
  }

  var body: some View {
    VStack(alignment: .leading) {
      Toggle("Reverse", isOn: $reverse)
      HStack {
        Button("汉字->拼音") {
          guard
            let v = input.applyingTransform(
              .mandarinToLatin, reverse: reverse)
          else {
            failed = true
            return
          }
          output = v
        }
        Button("平假->片假") {
          guard
            let v = input.applyingTransform(
              .hiraganaToKatakana, reverse: reverse)
          else {
            failed = true
            return
          }
          output = v
        }
        Button("平假->字母") {
          guard
            let v = input.applyingTransform(
              .latinToHiragana, reverse: !reverse)
          else {
            failed = true
            return
          }
          output = v
        }
        Button("半角->全角") {
          guard
            let v = input.applyingTransform(
              .fullwidthToHalfwidth, reverse: reverse)
          else {
            failed = true
            return
          }
          output = v
        }
      }
      HStack {
        TextField("ICU tranforms", text: $script)
        Button("Transform") {
          guard
            let v = input.applyingTransform(
              .init(script), reverse: reverse)
          else {
            failed = true
            return
          }
          output = v
        }
      }
    }.alert(isPresented: $failed) {
      .init(title: Text("ConvertError"), dismissButton: .default(Text("OK")))
    }
  }
}

struct UnicodeTool: WorkerViewProtocol {
  @Binding var input: String
  @Binding var output: String

  @State var unit: Unit = .binary

  enum Unit: CaseIterable, Identifiable {
    case binary
    case decimal
    case hex

    var id: Self { self }

    var radix: Int {
      switch self {
      case .binary: return 2
      case .decimal: return 10
      case .hex: return 16
      }
    }
  }

  init(input: Binding<String>, output: Binding<String>) {
    _input = input
    _output = output
  }

  func convert(isUtf8: Bool) {
    output = input.map { "\($0) \($0.convert(isUtf8: isUtf8, unit: unit))" }.joined(separator: "\n")
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("Only take first character")
      Picker("Format", selection: $unit) {
        ForEach(Unit.allCases) { unit in Text(String(describing: unit)) }
      }.pickerStyle(RadioGroupPickerStyle()).horizontalRadioGroupLayout()
      HStack {
        Button("UTF-8") {
          convert(isUtf8: true)
        }
        Button("UTF-16") {
          convert(isUtf8: false)
        }
      }
    }
  }
}

extension Character {

  func convert(isUtf8: Bool, unit: UnicodeTool.Unit) -> String {
    if isUtf8 {
      return utf8.map { String($0, radix: unit.radix, uppercase: false) }.joined(separator: " ")
    } else {
      return utf16.map { String($0, radix: unit.radix, uppercase: false) }.joined(separator: " ")
    }
  }
}

struct UrlTool: WorkerViewProtocol {
  @Binding var input: String
  @Binding var output: String

  init(input: Binding<String>, output: Binding<String>) {
    _input = input
    _output = output
  }

  var body: some View {
    VStack(alignment: .leading) {

      HStack {
        Button("Parse") {
          guard
            let str = input.addingPercentEncoding(
              withAllowedCharacters: .urlQueryAllowed),
            let url = URLComponents(string: str)
          else { return }
          output = """
            \(url.url!.absoluteString)
            scheme: \(url.scheme ?? "")
            host: \(url.host ?? "")
            user: \(url.user ?? "")
            password: \(url.password ?? "")
            port: \(url.port?.description ?? "")
            path: \(url.path)
            queryItems: \(url.queryItems ?? [])
            """
        }

      }

    }
  }
}
