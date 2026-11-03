import Foundation
import CryptoKit
@main struct ImportRoundtrip {
 static func main()async throws{
  let fm=FileManager.default,root=fm.temporaryDirectory.appendingPathComponent("reborn-test-"+UUID().uuidString)
  try fm.createDirectory(at:root,withIntermediateDirectories:true);defer{try? fm.removeItem(at:root)}
  let source=root.appendingPathComponent("source"),store=root.appendingPathComponent("managed")
  try fm.createDirectory(at:source,withIntermediateDirectories:true)
  let bytes=Data(repeating:0x5a,count:8*1024*1024+31),path=source.appendingPathComponent("sample.bin")
  try bytes.write(to:path)
  let hash=SHA256.hash(data:bytes).map{String(format:"%02x",$0)}.joined()
  let manifest=AssetManifest(schemaVersion:1,profile:"synthetic",contentVersion:nil,files:[.init(path:"sample.bin",bytes:UInt64(bytes.count),sha256:hash)],totalBytes:UInt64(bytes.count),integrity:"sha256-baseline",runtimeCompatibility:"NOT_COMPLETED")
  let first=try await DataImportManager.perform(source:source,manifest:manifest,store:store){_,_,_ in}
  let copied=try Data(contentsOf:first.appendingPathComponent("sample.bin"));precondition(copied==bytes)
  let second=try await DataImportManager.perform(source:source,manifest:manifest,store:store){_,_,_ in};precondition(second==first)
  let unchanged=try Data(contentsOf:path);precondition(unchanged==bytes)
  let corrupt=Data(repeating:0x11,count:bytes.count);try corrupt.write(to:first.appendingPathComponent("sample.bin"))
  do{_ = try await DataImportManager.perform(source:source,manifest:manifest,store:store){_,_,_ in};fatalError("corrupt existing import accepted")}catch{}
  let wrong=AssetManifest(schemaVersion:1,profile:"synthetic",contentVersion:nil,files:[.init(path:"sample.bin",bytes:UInt64(bytes.count),sha256:String(repeating:"a",count:64))],totalBytes:UInt64(bytes.count),integrity:"sha256-baseline",runtimeCompatibility:"NOT_COMPLETED")
  do{_ = try await DataImportManager.perform(source:source,manifest:wrong,store:store){_,_,_ in};fatalError("source hash mismatch accepted")}catch{}
  let after=try Data(contentsOf:path);precondition(after==bytes)
  print("PASS production managed importer: streaming copy, SHA256, repeated open without duplication, corruption rejection, original untouched")
 }
}
