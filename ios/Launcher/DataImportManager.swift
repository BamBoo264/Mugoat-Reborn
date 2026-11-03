import Foundation
import CryptoKit
import Combine

/// Owns the imported copy. External provider access is used only while copying;
/// playback will never depend on a temporary provider URL or bookmark.
@MainActor final class DataImportManager:ObservableObject {
 @Published private(set) var state:ImportState = .notImported
 @Published private(set) var message="Chọn thư mục dữ liệu qua Files."
 @Published private(set) var progress:Double=0
 @Published private(set) var importedRoot:URL?
 private var task:Task<Void,Never>?
 private let store:URL
 init(){store=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("GameImports",isDirectory:true)}
 func cancel(){task?.cancel()}
 func start(source:URL,manifest:AssetManifest){
  guard task==nil else{return}
  state = .validating;message="Kiểm tra dữ liệu và dung lượng…"
  let destination=store
  task=Task {
   do {
    let worker=Task.detached(priority:.utility){try await Self.perform(source:source,manifest:manifest,store:destination){done,total,path in
     await MainActor.run {self.state = .importing;self.progress=total==0 ? 0:Double(done)/Double(total);self.message=path}
    }}
    let root=try await withTaskCancellationHandler(operation:{try await worker.value},onCancel:{worker.cancel()})
    importedRoot=root;state = .ready;progress=1
    message="Dữ liệu khớp manifest SHA256. Runtime/gameplay: NOT COMPLETED."
   }catch {
    if error is CancellationError {state = .notImported;message=ImportFailure.interrupted.localizedDescription}
    else if let failure=error as? ImportFailure {
     switch failure{case .missing:state = .missing;case .storage:state = .storage;case .permission:state = .permission;default:state = .invalid};message=failure.localizedDescription
    }else{state = .invalid;message=error.localizedDescription}
   };task=nil
  }
 }
 nonisolated static func digest(_ file:URL)throws->String {
  let h=try FileHandle(forReadingFrom:file);defer{try? h.close()};var sha=SHA256()
  while let b=try h.read(upToCount:4<<20),!b.isEmpty{try Task.checkCancellation();sha.update(data:b)}
  return sha.finalize().map{String(format:"%02x",$0)}.joined()
 }
 nonisolated private static func checkedSource(_ root:URL,_ entry:AssetManifest.Entry)throws->URL {
  let f=root.appendingPathComponent(entry.path)
  let resolved=f.resolvingSymlinksInPath().standardizedFileURL.path
  guard resolved.hasPrefix(root.resolvingSymlinksInPath().standardizedFileURL.path+"/") else{throw ImportFailure.invalid("Path escapes source: "+entry.path)}
  guard FileManager.default.fileExists(atPath:f.path) else{throw ImportFailure.missing(entry.path)}
  let v=try f.resourceValues(forKeys:[.isRegularFileKey,.isSymbolicLinkKey,.fileSizeKey])
  guard v.isRegularFile==true,v.isSymbolicLink!=true,UInt64(v.fileSize ?? 0)==entry.bytes else{throw ImportFailure.invalid("Wrong size/type: "+entry.path)}
  return f
 }
 nonisolated static func perform(source:URL,manifest:AssetManifest,store:URL,report:@escaping @Sendable(UInt64,UInt64,String)async->Void)async throws->URL {
  try manifest.validate();let fm=FileManager.default
  let scoped=source.startAccessingSecurityScopedResource();defer{if scoped{source.stopAccessingSecurityScopedResource()}}
  // Sandbox-local folders can be readable without a security scope grant.
  guard fm.isReadableFile(atPath:source.path) else{throw ImportFailure.permission(source.lastPathComponent)}
  let encoded=try JSONEncoder().encode(manifest)
  let id=SHA256.hash(data:encoded).map{String(format:"%02x",$0)}.joined()
  try fm.createDirectory(at:store,withIntermediateDirectories:true)
  var excluded=store;var flags=URLResourceValues();flags.isExcludedFromBackup=true;try excluded.setResourceValues(flags)
  let stage=store.appendingPathComponent(id+".partial",isDirectory:true),final=store.appendingPathComponent(id,isDirectory:true)
  // A completed import is verified again explicitly; no new copy or provider dependency.
  if fm.fileExists(atPath:final.path){
   var done:UInt64=0
   for entry in manifest.files{let f=try checkedSource(final,entry);guard try digest(f)==entry.sha256 else{throw ImportFailure.invalid("Imported file changed: "+entry.path)};done+=entry.bytes;await report(done,manifest.totalBytes,entry.path)}
   return final
  }
  try fm.createDirectory(at:stage,withIntermediateDirectories:true)
  var remaining=manifest.totalBytes,verified=Set<String>()
  for entry in manifest.files {
   try Task.checkCancellation();_ = try checkedSource(source,entry)
   let target=stage.appendingPathComponent(entry.path)
   if fm.fileExists(atPath:target.path),let v=try? target.resourceValues(forKeys:[.fileSizeKey]),UInt64(v.fileSize ?? 0)==entry.bytes,try digest(target)==entry.sha256{verified.insert(entry.path);remaining-=entry.bytes}
  }
  let disk=try store.resourceValues(forKeys:[.volumeAvailableCapacityForImportantUsageKey])
  guard let free=disk.volumeAvailableCapacityForImportantUsage,free>=0,UInt64(free)>=remaining+min(manifest.totalBytes/20,512<<20) else{throw ImportFailure.storage(remaining)}
  var done=manifest.totalBytes-remaining
  for entry in manifest.files {
   try Task.checkCancellation();if verified.contains(entry.path){continue}
   let input=try checkedSource(source,entry),target=stage.appendingPathComponent(entry.path),partial=target.appendingPathExtension("importing")
   try fm.createDirectory(at:target.deletingLastPathComponent(),withIntermediateDirectories:true)
   // Provider coordination runs off the main thread; materializes files before streaming them.
   var coordinationError:NSError?,copyError:Error?
   NSFileCoordinator().coordinate(readingItemAt:input,options:.withoutChanges,error:&coordinationError){url in
    do {
     try? fm.removeItem(at:partial);guard fm.createFile(atPath:partial.path,contents:nil) else{throw ImportFailure.invalid("Cannot create "+entry.path)}
     let reader=try FileHandle(forReadingFrom:url),writer=try FileHandle(forWritingTo:partial);defer{try? reader.close();try? writer.close()}
     var hash=SHA256(),bytes:UInt64=0
     while let block=try reader.read(upToCount:4<<20),!block.isEmpty{try Task.checkCancellation();bytes+=UInt64(block.count);guard bytes<=entry.bytes else{throw ImportFailure.invalid("Source changed: "+entry.path)};hash.update(data:block);try writer.write(contentsOf:block)}
     guard bytes==entry.bytes,hash.finalize().map({String(format:"%02x",$0)}).joined()==entry.sha256 else{throw ImportFailure.invalid("SHA256 mismatch: "+entry.path)}
     try writer.synchronize();try writer.close()
     if fm.fileExists(atPath:target.path){try fm.removeItem(at:target)}
     try fm.moveItem(at:partial,to:target)
    }catch{copyError=error;try? fm.removeItem(at:partial)}
   }
   if let error=copyError{throw error};if let error=coordinationError{throw error}
   done+=entry.bytes;await report(done,manifest.totalBytes,entry.path)
  }
  try encoded.write(to:stage.appendingPathComponent("import-manifest.json"),options:.atomic)
  try fm.moveItem(at:stage,to:final);return final
 }
}
