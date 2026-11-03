import Foundation
@main struct ManifestTests {
 static func main()throws {
  let hash=String(repeating:"a",count:64)
  func m(_ entries:[AssetManifest.Entry],_ bytes:UInt64)->AssetManifest{AssetManifest(schemaVersion:1,profile:"test",contentVersion:nil,files:entries,totalBytes:bytes,integrity:"sha256-baseline",runtimeCompatibility:"NOT_COMPLETED")}
  try m([.init(path:"common.rpf",bytes:1,sha256:hash)],1).validate()
  for path in ["../escape","/absolute","a//b","a/./b","C:/test","a\\b"]{
   do{try m([.init(path:path,bytes:1,sha256:hash)],1).validate();fatalError("unsafe path accepted")}catch{}
  }
  do{try m([.init(path:"a",bytes:1,sha256:hash),.init(path:"A",bytes:1,sha256:hash)],2).validate();fatalError("duplicate accepted")}catch{}
  do{try m([.init(path:"a",bytes:1,sha256:nil)],1).validate();fatalError("unhashed accepted")}catch{}
  do{try m([.init(path:"a",bytes:1,sha256:hash)],2).validate();fatalError("wrong sum accepted")}catch{}
  print("PASS manifest paths, duplicate names, required hashes and byte totals")
 }
}
