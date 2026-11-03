import Foundation
@main struct ScriptTests {
 static func main()throws {
  let registry=NativeFunctionRegistry()
  func machine(_ code:[UInt8],natives:[UInt64]=[],statics:[UInt64]=[])->ScriptMachine{ScriptMachine(program:ScriptProgram(name:"synthetic",code:Data(code),natives:natives,statics:statics),natives:registry)}
  let enter:[UInt8]=[45,0,4,0,0],leave:[UInt8]=[46,0,1]
  let sum=machine(enter+[37,7,37,4,1]+leave);precondition(tryRun(sum));precondition(sum.stack==[11])
  let local=machine(enter+[37,9,57,2,56,2]+leave);precondition(tryRun(local));precondition(local.stack==[9])
  let overflow=machine(enter+[40,255,255,255,127,114,1]+leave);precondition(tryRun(overflow));precondition(overflow.stack==[0x80000000])
  let loop=machine([85,253,255]);let status=try loop.run(maxInstructions:50);if case .budgetExhausted=status{}else{fatalError("runaway not bounded")}
  do{_ = try machine([43]).run();fatalError("underflow accepted")}catch{}
  do{_ = try machine([37]).run();fatalError("truncated immediate accepted")}catch{}
  do{_ = try machine([85,255,127]).run();fatalError("outside branch accepted")}catch{}
  let hash:UInt64=0x12345678
  let native=machine(enter+[37,4,37,5,44,9,0,0]+leave,natives:[hash])
  do{_ = try native.run();fatalError("missing native silently returned")}catch ScriptFault.native(let h,_) {precondition(h==hash)}
  precondition(native.stack==[4,5])
  try registry.register(hash){args in [args[0]+args[1]]};precondition(tryRun(native));precondition(native.stack==[9])
  do{try registry.register(hash){_ in []};fatalError("duplicate handler accepted")}catch{}
  // Exactly one full 16-KiB code page: never truncate the last page to zero.
  var data=Data(count:65536)
  func u32(_ pos:Int,_ n:UInt32){for i in 0..<4{data[pos+i]=UInt8(truncatingIfNeeded:n>>(8*i))}}
  func u64(_ pos:Int,_ n:UInt64){for i in 0..<8{data[pos+i]=UInt8(truncatingIfNeeded:n>>(8*i))}}
  u64(16,0x50000100);u32(28,16384);u32(44,1);u64(64,0x50000180);u64(96,0x50000120);u64(256,0x50001000);u64(384,hash)
  data.replaceSubrange(288..<294,with:Data("probe\0".utf8))
  let program=try ScriptProgram(memory:ResourceMemory(bytes:data,systemBytes:data.count,graphicsBytes:0))
  precondition(program.name=="probe" && program.code.count==16384 && program.natives==[hash])
  u64(16,0x7fffffffffffffff)
  do{_ = try ScriptProgram(memory:ResourceMemory(bytes:data,systemBytes:data.count,graphicsBytes:0));fatalError("host pointer accepted")}catch{}
  print("PASS original YSC loader/VM: exact page boundary, checked pointers, arithmetic, locals, native contracts, unknown-native stop and instruction budget")
 }
 static func tryRun(_ machine:ScriptMachine)->Bool{do{if case .returned=try machine.run(){return true};return false}catch{fatalError(String(describing:error))}}
}
