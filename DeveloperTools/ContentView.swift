import SwiftUI

extension String: Identifiable { public var id: Self { self } }

struct ContentView: View {
  @State var input = ""
  @State var output = ""

  @State var selectedTool: Tools?

  var body: some View {
    NavigationView {
      List(Tools.allCases, selection: $selectedTool) { tool in
        Text(tool.text)
      }
      .listStyle(SidebarListStyle())

      VStack(alignment: .leading) {
        HStack {
          Button("Paste") {
            input = NSPasteboard.general.string(forType: .string) ?? ""
          }
          Button("Clear") {
            input = ""
            output = ""
          }
        }
        TextEditor(text: $input)
        (selectedTool ?? .json).toolView(input: $input, output: $output)
        Text("Output:")
        TextEditor(text: .constant(output))
        HStack {
          Button("Copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(output, forType: .string)
          }
          Button("Save") {}
          Button("Use as input") {
            input = output
          }
        }
      }
      .frame(minWidth: 300)
      .padding()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
