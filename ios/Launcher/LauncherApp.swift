import SwiftUI
import UniformTypeIdentifiers
@main struct MugoatRebornApp:App {var body:some Scene{WindowGroup{LauncherView()}}}
struct LauncherView:View {
 @StateObject private var imports=DataImportManager()
 @State private var picking=false
 @State private var manifest:AssetManifest?
 @State private var error=""
 var body:some View {
  NavigationView {VStack(alignment:.leading,spacing:20){
   Text("MUGOAT REBORN").font(.largeTitle.bold())
   Text("Dữ liệu do bạn tự chuẩn bị • không kèm game assets")
   Text(imports.state.rawValue).font(.headline.monospaced())
   Text(imports.message).textSelection(.enabled)
   ProgressView(value:imports.progress)
   Button("IMPORT GTA V GAME DATA"){picking=true}.buttonStyle(.borderedProminent).disabled(manifest==nil || imports.state == .importing || imports.state == .validating)
   Button("Dừng import, giữ phần đã xác minh"){imports.cancel()}.disabled(imports.state != .importing)
   Text(error).foregroundColor(.red)
   Divider()
   Text("Game runtime: NOT COMPLETED").font(.headline)
   Text("Dữ liệu hợp lệ không đồng nghĩa engine tương thích. PLAY chỉ được bật sau khi tích hợp runtime và kiểm thử thế giới 3D.")
   Button("PLAY — runtime chưa khả dụng"){}.disabled(true)
   Spacer()
  }.padding().navigationTitle("Import & diagnostics")}
  .task {do{guard let url=Bundle.main.url(forResource:"expected-manifest",withExtension:"json") else{throw ImportFailure.invalid("Thiếu manifest của bộ data đã audit")};let m=try JSONDecoder().decode(AssetManifest.self,from:Data(contentsOf:url));try m.validate();manifest=m}catch{self.error=error.localizedDescription}}
  .fileImporter(isPresented:$picking,allowedContentTypes:[.folder],allowsMultipleSelection:false){result in
   do{guard let source=try result.get().first,let m=manifest else{return};imports.start(source:source,manifest:m)}catch{self.error=error.localizedDescription}
  }
 }
}
