import Foundation
@main struct ResourceTests {
 static func main()throws {
  let hex="28b52ffd60003f750000185252470200fc0f7ab1ff3dc002";var packed=Data();var i=hex.startIndex
  while i<hex.endIndex{let j=hex.index(i,offsetBy:2);packed.append(UInt8(hex[i..<j],radix:16)!);i=j}
  func u(_ n:UInt32)->Data{var v=n.littleEndian;return withUnsafeBytes(of:&v){Data($0)}}
  let flags:UInt32=1<<17
  let input=u(0x37435352)+u(1)+u(flags)+u(flags)+packed
  let memory=try ResourceMemory.decode(input,system:flags,graphics:flags)
  precondition(memory.systemBytes==8192 && memory.graphicsBytes==8192)
  let v=try memory.slice(address:0x50000000,count:8192),p=try memory.slice(address:0x60000000,count:8192)
  precondition(v==Data(repeating:82,count:8192) && p==Data(repeating:71,count:8192))
  do{_ = try memory.slice(address:0x50001fff,count:2);fatalError("cross segment read accepted")}catch{}
  do{_ = try ResourceMemory.decode(input+Data([0]),system:flags,graphics:flags);fatalError("trailing bytes accepted")}catch{}
  do{_ = try ResourceMemory.decode(input,system:flags*2,graphics:flags);fatalError("wrong size accepted")}catch{}
  print("PASS native RSC7 Zstandard decode, pointer tags/segment bounds, declared size and trailing-data rejection")
 }
}
