import Foundation
struct AssetManifest:Codable {
 struct Entry:Codable {let path:String;let bytes:UInt64;let sha256:String?}
 let schemaVersion:Int
 let profile:String
 let contentVersion:String?
 let files:[Entry]
 let totalBytes:UInt64
 let integrity:String
 let runtimeCompatibility:String
 func validate()throws {
  guard schemaVersion==1,files.count>0,files.count<=100000 else{throw ImportFailure.invalid("Manifest schema/count")}
  var seen=Set<String>(),sum:UInt64=0
  for f in files {
   let parts=f.path.split(separator:"/",omittingEmptySubsequences:false)
   guard !f.path.hasPrefix("/"),!f.path.contains("\\"),!f.path.contains(":"),!parts.contains(where:{$0.isEmpty || $0==".." || $0=="."}),seen.insert(f.path.lowercased()).inserted else{throw ImportFailure.invalid("Unsafe/duplicate path: \(f.path)")}
   guard let hash=f.sha256,hash.count==64,hash.utf8.allSatisfy({(48...57).contains($0)||(97...102).contains($0)}) else{throw ImportFailure.invalid("Missing SHA256: \(f.path)")}
   let (next,overflow)=sum.addingReportingOverflow(f.bytes);guard !overflow else{throw ImportFailure.invalid("Manifest overflow")};sum=next
  }
  guard sum==totalBytes else{throw ImportFailure.invalid("Manifest size sum")}
 }
}
enum ImportFailure:LocalizedError {
 case invalid(String),missing(String),storage(UInt64),permission(String),interrupted
 var errorDescription:String? {switch self{case .invalid(let s):return "INVALID_DATA: "+s;case .missing(let s):return "MISSING_FILES: "+s;case .storage(let n):return "INSUFFICIENT_STORAGE: cần thêm \(n) byte";case .permission(let s):return "ACCESS_PERMISSION_REQUIRED: "+s;case .interrupted:return "Import đã dừng; chọn lại cùng thư mục để tiếp tục."}}
}
enum ImportState:String {case notImported="NOT_IMPORTED",importing="IMPORTING",validating="VALIDATING",ready="READY",invalid="INVALID_DATA",missing="MISSING_FILES",storage="INSUFFICIENT_STORAGE",permission="ACCESS_PERMISSION_REQUIRED"}
