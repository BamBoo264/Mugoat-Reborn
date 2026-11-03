import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif
/// Boots authored data subsystems only. This must not be reported as gameplay ready.
enum RuntimeBootstrap {
 struct Report {let roots:[String];let bytes:Int;let cacheBytes:Int
  var summary:String{"Metadata khởi tạo: \(roots.joined(separator:", ")) · \(bytes) byte đọc/parse · cache \(cacheBytes) byte. Script VM, scene và gameplay: NOT COMPLETED."}}
 static func inspect(_ root:URL)async throws->Report {
  let archive=try await Task.detached(priority:.utility){try RPF7Archive(file:root.appendingPathComponent("common.rpf"))}.value
  let store=NativeAssetStore(budgetBytes:8<<20,workers:2)
  let required=["data/gameconfig.xml","data/handling.meta","data/levels/gta5/gta5.meta"]
  var roots:[String]=[],bytes=0
  for path in required {
   guard let entry=archive.entries.first(where:{$0.path.lowercased()==path}) else{throw ArchiveFailure.invalid("missing bootstrap metadata: "+path)}
   let data=try await store.read(archive:archive,entry:entry)
   let name=try await Task.detached(priority:.utility){try parseXML(data)}.value
   roots.append(name);bytes+=data.count
  }
  let stats=await store.metrics();return Report(roots:roots,bytes:bytes,cacheBytes:stats.cachedBytes)
 }
 static func parseXML(_ bytes:Data)throws->String {
  guard bytes.count<=8<<20 else{throw ArchiveFailure.invalid("metadata size cap")}
  let parser=XMLParser(data:bytes),delegate=RootReader();parser.shouldResolveExternalEntities=false;parser.delegate=delegate
  guard parser.parse(),!delegate.root.isEmpty else{throw ArchiveFailure.invalid("XML metadata: "+(parser.parserError?.localizedDescription ?? "missing root"))}
  return delegate.root
 }
 private final class RootReader:NSObject,XMLParserDelegate {
  var root=""
  func parser(_ parser:XMLParser,didStartElement name:String,namespaceURI:String?,qualifiedName:String?,attributes:[String:String]){if root.isEmpty{root=name}}
 }
}
