import UIKit
import UniformTypeIdentifiers

@objc(RebornNativeEntry) @MainActor public final class RebornNativeEntry:NSObject {
 @objc(installOn:) public static func install(on host:UIViewController) {
  guard host.view.viewWithTag(0x524542)==nil else{return}
  var config=UIButton.Configuration.filled();config.title="Nhập dữ liệu GTA V";config.baseBackgroundColor = .systemIndigo
  let button=UIButton(configuration:config,primaryAction:UIAction{[weak host] _ in
   guard let host,host.presentedViewController==nil else{return}
   host.present(UINavigationController(rootViewController:ImportController()),animated:true)
  })
  button.tag=0x524542;button.translatesAutoresizingMaskIntoConstraints=false
  host.view.addSubview(button)
  NSLayoutConstraint.activate([button.centerXAnchor.constraint(equalTo:host.view.safeAreaLayoutGuide.centerXAnchor),button.bottomAnchor.constraint(equalTo:host.view.safeAreaLayoutGuide.bottomAnchor,constant:-8)])
 }
}
@MainActor private final class ImportController:UIViewController,UIDocumentPickerDelegate {
 private let status=UILabel(),progress=UIProgressView(progressViewStyle:.default)
 private var work:Task<Void,Never>?
 private var destination:URL {FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0].appendingPathComponent("GTAV",isDirectory:true)}
 override func viewDidLoad(){
  super.viewDidLoad();title="Dữ liệu do bạn cung cấp";view.backgroundColor = .systemBackground
  navigationItem.rightBarButtonItem=UIBarButtonItem(barButtonSystemItem:.done,target:self,action:#selector(close))
  status.numberOfLines=0;status.text="Chọn thư mục GTA V qua Files. App kiểm tra SHA256 rồi lưu bản sao cục bộ. Cần khoảng 22 GB trống. Dữ liệu nguồn không bị sửa. Nếu Documents/GTAV đã tồn tại, app không ghi đè."
  var c=UIButton.Configuration.filled();c.title="IMPORT GTA V GAME DATA"
  let choose=UIButton(configuration:c,primaryAction:UIAction{[weak self] _ in self?.choose()})
  let stack=UIStackView(arrangedSubviews:[status,progress,choose]);stack.axis = .vertical;stack.spacing=20;stack.translatesAutoresizingMaskIntoConstraints=false
  view.addSubview(stack);NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leadingAnchor,constant:24),stack.trailingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.trailingAnchor,constant:-24),stack.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,constant:24)])
 }
 @objc private func close(){guard work==nil else{return};dismiss(animated:true)}
 private func choose(){
  guard work==nil else{return}
  if FileManager.default.fileExists(atPath:destination.path){status.text="Documents/GTAV đã tồn tại. Giữ nguyên dữ liệu hiện tại; module không ghi đè hoặc tự xoá.";return}
  let picker=UIDocumentPickerViewController(forOpeningContentTypes:[.folder],asCopy:false);picker.delegate=self;present(picker,animated:true)
 }
 func documentPicker(_ controller:UIDocumentPickerViewController,didPickDocumentsAt urls:[URL]) {
  guard let source=urls.first,work==nil else{return}
  isModalInPresentation=true;navigationItem.rightBarButtonItem?.isEnabled=false
  work=Task {
   do {
    guard let path=Bundle.main.url(forResource:"reborn-expected-manifest",withExtension:"json") else{throw ImportFailure.invalid("Thiếu manifest")}
    let manifest=try JSONDecoder().decode(AssetManifest.self,from:Data(contentsOf:path))
    let store=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("RebornNativeImport")
    let root=try await Task.detached(priority:.utility){
     try await DataImportManager.perform(source:source,manifest:manifest,store:store){[weak self] done,total,file in
      await MainActor.run{self?.progress.progress=total==0 ? 0:Float(Double(done)/Double(total));self?.status.text="IMPORTING: \(file)"}
     }
    }.value
    guard !FileManager.default.fileExists(atPath:destination.path) else{throw ImportFailure.invalid("GTAV xuất hiện trong khi nhập; giữ bản đã kiểm tra trong Application Support")}
    // Same app volume: rename, not another 22 GB copy. No overwrite.
    try FileManager.default.moveItem(at:root,to:destination)
    status.text="READY: dữ liệu đã xác minh. Tắt hẳn rồi mở lại app để runtime nhận Documents/GTAV. Gameplay cần kiểm thử trên iPhone."
    NSLog("[Reborn] Verified import installed at Documents/GTAV; restart required")
   }catch{status.text=error.localizedDescription;NSLog("[Reborn] Import failed: %@",error.localizedDescription)}
   work=nil;isModalInPresentation=false;navigationItem.rightBarButtonItem?.isEnabled=true
  }
 }
}
