import SwiftUI
import UniformTypeIdentifiers
@main struct MugoatRebornApp:App {var body:some Scene{WindowGroup{LauncherView()}}}
struct LauncherView:View {
 @StateObject private var imports=DataImportManager()
 @State private var picking=false
 @State private var confirmingDelete=false
 @State private var manifest:AssetManifest?
 @State private var error=""
 @State private var catalog=""
 @State private var scanning=false
 var body:some View {
  NavigationView {VStack(alignment:.leading,spacing:20){
   Text("MUGOAT REBORN").font(.largeTitle.bold())
   Text("Dữ liệu do bạn tự chuẩn bị • không kèm game assets")
   Text(imports.state.rawValue).font(.headline.monospaced())
   Text(imports.message).textSelection(.enabled)
   ProgressView(value:imports.progress)
   Button("IMPORT GTA V GAME DATA"){picking=true}.buttonStyle(.borderedProminent).disabled(manifest==nil || imports.state == .importing || imports.state == .validating)
   Button("Kiểm tra lại dữ liệu đã import"){imports.revalidate()}.disabled(imports.importedRoot==nil || imports.state == .importing || imports.state == .validating)
   Button("Dừng import, giữ phần đã xác minh"){imports.cancel()}.disabled(imports.state != .importing)
   Text(error).foregroundColor(.red)
   Button("Xoá bản dữ liệu app quản lý",role:.destructive){confirmingDelete=true}.disabled(imports.importedRoot==nil || imports.state == .importing || imports.state == .validating)
   Button(scanning ? "Đang đọc archive…":"Lập chỉ mục RPF bằng runtime mới"){
    guard let root=imports.importedRoot else{return};scanning=true
    Task{do{let report=try await Task.detached(priority:.utility){try RuntimeCatalog.scan(root)}.value;catalog=report.summary}catch{catalog=error.localizedDescription};scanning=false}
   }.disabled(imports.importedRoot==nil || scanning || imports.state != .ready)
   Button("Kiểm tra metadata khởi tạo bằng asset store mới"){
    guard let root=imports.importedRoot else{return};scanning=true
    Task{do{catalog=try await RuntimeBootstrap.inspect(root).summary}catch{catalog=error.localizedDescription};scanning=false}
   }.disabled(imports.importedRoot==nil || scanning || imports.state != .ready)
   Text(catalog).font(.caption).textSelection(.enabled)
   Divider()
   Text("Game runtime: NOT COMPLETED").font(.headline)
   Text("Dữ liệu hợp lệ không đồng nghĩa engine tương thích. PLAY chỉ được bật sau khi tích hợp runtime và kiểm thử thế giới 3D.")
   Button("PLAY — runtime chưa khả dụng"){}.disabled(true)
   Spacer()
  }.padding().navigationTitle("Import & diagnostics")}
  .confirmationDialog("Xoá bản sao game do app quản lý? Thư mục nguồn bạn đã chọn không bị xoá.",isPresented:$confirmingDelete,titleVisibility:.visible){Button("Xoá bản sao",role:.destructive){imports.deleteManagedImportAfterConfirmation()};Button("Huỷ",role:.cancel){}}
  .task {do{guard let url=Bundle.main.url(forResource:"expected-manifest",withExtension:"json") else{throw ImportFailure.invalid("Thiếu manifest của bộ data đã audit")};let m=try JSONDecoder().decode(AssetManifest.self,from:Data(contentsOf:url));try m.validate();manifest=m}catch{self.error=error.localizedDescription}}
  .fileImporter(isPresented:$picking,allowedContentTypes:[.folder],allowsMultipleSelection:false){result in
   do{guard let source=try result.get().first,let m=manifest else{return};imports.start(source:source,manifest:m)}catch{self.error=error.localizedDescription}
  }
 }
}
