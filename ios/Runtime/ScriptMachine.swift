import Foundation

enum ScriptFault:Error,CustomStringConvertible {
 case truncated(Int),stack(Int),opcode(UInt8,Int),native(UInt64,Int),arithmetic(Int),branch(Int),frame(Int),nativeResult(Int)
 var description:String{switch self{
 case .truncated(let pc):return "Truncated instruction @\(pc)"
 case .stack(let pc):return "Stack bounds @\(pc)"
 case .opcode(let op,let pc):return "Unsupported opcode \(op) @\(pc)"
 case .native(let hash,let pc):return String(format:"Unimplemented native %016llx @%d",hash,pc)
 case .arithmetic(let pc):return "Invalid arithmetic @\(pc)"
 case .branch(let pc):return "Invalid jump @\(pc)"
 case .frame(let pc):return "Unsupported call frame @\(pc)"
 case .nativeResult(let pc):return "Native return-count mismatch @\(pc)"
 }}
}
/// Explicit native contracts: missing gameplay functions never silently return zero.
final class NativeFunctionRegistry {
 typealias Handler=([UInt64])throws->[UInt64]
 private var handlers:[UInt64:Handler]=[:]
 func register(_ hash:UInt64,handler:@escaping Handler)throws {
  guard handlers[hash]==nil else{throw ArchiveFailure.invalid("duplicate native registration")};handlers[hash]=handler
 }
 func resolve(_ hash:UInt64)->Handler?{handlers[hash]}
}
/// Initial deterministic bytecode core, not a full GTA interpreter. Unsupported operations stop.
final class ScriptMachine {
 enum Outcome {case budgetExhausted,returned}
 let program:ScriptProgram
 private let natives:NativeFunctionRegistry
 private(set) var pc=0
 private(set) var stack:[UInt64]=[]
 private(set) var statics:[UInt64]
 private var locals:[UInt64]?
 private var returned=false
 init(program:ScriptProgram,natives:NativeFunctionRegistry){self.program=program;self.natives=natives;statics=program.statics}
 private func byte()throws->UInt8{guard pc<program.code.count else{throw ScriptFault.truncated(pc)};let n=program.code[pc];pc+=1;return n}
 private func immediate(_ count:Int)throws->UInt32{var n:UInt32=0;for i in 0..<count{n |= UInt32(try byte()) << (8*i)};return n}
 private func push(_ n:UInt64)throws{guard stack.count<65536 else{throw ScriptFault.stack(pc)};stack.append(n)}
 private func pop()throws->UInt64{guard let n=stack.popLast() else{throw ScriptFault.stack(pc)};return n}
 private func integer(_ n:UInt64)->Int32{Int32(bitPattern:UInt32(truncatingIfNeeded:n))}
 private func word(_ n:Int32)->UInt64{UInt64(UInt32(bitPattern:n))}
 private func jump(_ offset:Int)throws{let target=pc+offset;guard target>=0,target<program.code.count else{throw ScriptFault.branch(target)};pc=target}
 func run(maxInstructions:Int=10000)throws->Outcome {
  if returned{return .returned}
  guard maxInstructions>0,maxInstructions<=1_000_000 else{throw ScriptFault.arithmetic(pc)}
  for _ in 0..<maxInstructions {
   let start=pc,op=try byte()
   switch op {
   case 0:break
   case 1...5,8...13,31...33:
    let b=integer(try pop()),a=integer(try pop());let value:Int32
    switch op {
    case 1:value=a &+ b;case 2:value=a &- b;case 3:value=a &* b
    case 4,5:
     guard b != 0 else{throw ScriptFault.arithmetic(start)}
     if a==Int32.min && b == -1{value=op==4 ? Int32.min:0}else{value=op==4 ? a/b:a%b}
    case 8:value=a==b ? 1:0;case 9:value=a != b ? 1:0;case 10:value=a>b ? 1:0;case 11:value=a>=b ? 1:0;case 12:value=a<b ? 1:0;case 13:value=a<=b ? 1:0
    case 31:value=a&b;case 32:value=a|b;default:value=a^b
    };try push(word(value))
   case 6:try push(integer(pop())==0 ? 1:0)
   case 7:try push(word(0 &- integer(pop())))
   case 14...18,20...25:
    let b=Float(bitPattern:UInt32(truncatingIfNeeded:try pop())),a=Float(bitPattern:UInt32(truncatingIfNeeded:try pop()))
    if op>=20 {let yes:Bool;switch op{case 20:yes=a==b;case 21:yes=a != b;case 22:yes=a>b;case 23:yes=a>=b;case 24:yes=a<b;default:yes=a<=b};try push(yes ? 1:0)}
    else{let f:Float;switch op{case 14:f=a+b;case 15:f=a-b;case 16:f=a*b;case 17:f=a/b;default:f=a.truncatingRemainder(dividingBy:b)};try push(UInt64(f.bitPattern))}
   case 19:let f=Float(bitPattern:UInt32(truncatingIfNeeded:try pop()));try push(UInt64((-f).bitPattern))
   case 34:let i=integer(try pop());try push(UInt64(Float(i).bitPattern))
   case 35:let f=Double(Float(bitPattern:UInt32(truncatingIfNeeded:try pop())));guard f.isFinite,f>=Double(Int32.min),f<=Double(Int32.max) else{throw ScriptFault.arithmetic(start)};try push(word(Int32(f)))
   case 37:try push(UInt64(byte()))
   case 38:let a=try byte(),b=try byte();try push(UInt64(a));try push(UInt64(b))
   case 39:let a=try byte(),b=try byte(),c=try byte();try push(UInt64(a));try push(UInt64(b));try push(UInt64(c))
   case 40,41:try push(UInt64(immediate(4)))
   case 42:guard let n=stack.last else{throw ScriptFault.stack(start)};try push(n)
   case 43:_ = try pop()
   case 44:
    let packed=try byte(),high=try byte(),low=try byte(),index=Int(high)<<8|Int(low),args=Int(packed>>2),returns=Int(packed&3)
    guard index<program.natives.count else{throw ScriptFault.truncated(start)}
    let hash=program.natives[index]
    guard let handler=natives.resolve(hash) else{pc=start;throw ScriptFault.native(hash,start)}
    guard stack.count>=args else{throw ScriptFault.stack(start)}
    let input=Array(stack.suffix(args)),result=try handler(input)
    guard result.count==returns else{throw ScriptFault.nativeResult(start)}
    stack.removeLast(args);for n in result{try push(n)}
   case 45:
    let args=try byte(),count=Int(try immediate(2)),skip=Int(try byte())
    guard args==0,locals==nil,count>=2,count<=65536,skip<=program.code.count-pc else{throw ScriptFault.frame(start)}
    pc+=skip;locals=Array(repeating:0,count:count)
   case 46:
    let args=try byte(),returns=Int(try byte())
    guard args==0,locals != nil,returns<=3,stack.count>=returns else{throw ScriptFault.frame(start)}
    stack=Array(stack.suffix(returns));returned=true;return .returned
   case 56,57:
    let index=Int(try byte());guard let values=locals,index<values.count else{throw ScriptFault.frame(start)}
    if op==56{try push(values[index])}else{locals![index]=try pop()}
   case 59,60:
    let index=Int(try byte());guard index<statics.count else{throw ScriptFault.stack(start)}
    if op==59{try push(statics[index])}else{statics[index]=try pop()}
   case 67:try push(word(Int32(Int16(bitPattern:UInt16(try immediate(2))))))
   case 85,86:
    let offset=Int(Int16(bitPattern:UInt16(try immediate(2))))
    let shouldJump:Bool
    if op==85{shouldJump=true}else{shouldJump=try pop()==0}
    if shouldJump{try jump(offset)}
   case 100:try push(UInt64(immediate(3)))
   case 112...120:try push(word(Int32(op)-113))
   case 121...129:try push(UInt64(Float(Int(op)-122).bitPattern))
   default:pc=start;throw ScriptFault.opcode(op,start)
   }
  };return .budgetExhausted
 }
}
