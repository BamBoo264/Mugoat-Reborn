import Foundation
@main struct NativeRPFTests {
 static func main()throws{
  let root=URL(fileURLWithPath:CommandLine.arguments[1]),file=root.appendingPathComponent("valid.rpf")
  let before=try Data(contentsOf:file),a=try RPF7Archive(file:file)
  precondition(a.entries.count==1 && a.entries[0].path=="meta.xml")
  let bytes=try a.binary(a.entries[0]);precondition(String(decoding:bytes,as:UTF8.self)==String(repeating:"original reborn fixture\n",count:37))
  let after=try Data(contentsOf:file);precondition(before==after)
  for name in ["cycle","orphan","payload","name","encrypted"]{do{_ = try RPF7Archive(file:root.appendingPathComponent(name+".rpf"));fatalError("bad archive accepted")}catch{}}
  do{_ = try a.binary(a.entries[0],limit:1);fatalError("output cap ignored")}catch{}
  print("PASS native production RPF parser: deflate, paths, cycles, orphans, payload bounds, encryption and output caps")
 }
}
