import Foundation
/// Read-only loader for the PC YSC container. No host address in the header is executed.
struct ScriptProgram {
 let name:String
 let code:Data
 let strings:Data
 let natives:[UInt64]
 let statics:[UInt64]
 let parameterCount:Int
 static func u64(_ data:Data,_ pos:Int)->UInt64 {(0..<8).reduce(UInt64(0)){$0 | UInt64(data[pos+$1]) << (8*$1)}}
 static func rotate(_ value:UInt64,_ count:Int)->UInt64 {let n=count&63;return n==0 ? value:(value<<n)|(value>>(64-n))}
 init(memory:ResourceMemory)throws {
  let header=try memory.slice(address:0x50000000,count:128)
  let codeSize=Int(RPF7Archive.u32(header,28)),args=Int(RPF7Archive.u32(header,32)),staticCount=Int(RPF7Archive.u32(header,36)),nativeCount=Int(RPF7Archive.u32(header,44)),stringSize=Int(RPF7Archive.u32(header,112))
  guard codeSize>0,codeSize<=32<<20,stringSize<=16<<20,staticCount<=1_048_576,args<=staticCount,nativeCount<=65536 else{throw ArchiveFailure.invalid("YSC sizes/counts")}
  func bytes(_ address:UInt64,_ count:Int)throws->Data{try memory.slice(address:address,count:count)}
  func pages(_ pointer:UInt64,_ count:Int)throws->Data {
   if count==0{return Data()}
   let number=(count+16383)/16384,table=try bytes(pointer,number*8)
   var result=Data();result.reserveCapacity(count)
   for i in 0..<number {let size=min(16384,count-i*16384);result.append(try bytes(Self.u64(table,i*8),size))}
   return result
  }
  code=try pages(Self.u64(header,16),codeSize)
  strings=try pages(Self.u64(header,104),stringSize)
  let rawNatives=nativeCount==0 ? Data():try bytes(Self.u64(header,64),nativeCount*8)
  natives=(0..<nativeCount).map{Self.rotate(Self.u64(rawNatives,$0*8),codeSize+$0)}
  let rawStatics=staticCount==0 ? Data():try bytes(Self.u64(header,48),staticCount*8)
  statics=(0..<staticCount).map{Self.u64(rawStatics,$0*8)};parameterCount=args
  let nameAddress=Self.u64(header,96)
  guard nameAddress>=0x50000000,nameAddress-0x50000000<UInt64(memory.systemBytes) else{throw ArchiveFailure.invalid("YSC name pointer")}
  let cap=min(256,memory.systemBytes-Int(nameAddress-0x50000000)),rawName=try bytes(nameAddress,cap)
  guard let end=rawName.firstIndex(of:0),let text=String(data:rawName.prefix(end),encoding:.utf8),!text.isEmpty else{throw ArchiveFailure.invalid("YSC name")};name=text
 }
 init(name:String,code:Data,natives:[UInt64]=[],statics:[UInt64]=[]){self.name=name;self.code=code;self.natives=natives;self.statics=statics;parameterCount=0;strings=Data()}
}
