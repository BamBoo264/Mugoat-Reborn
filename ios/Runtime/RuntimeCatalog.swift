import Foundation
struct RuntimeCatalogReport {
 var archives=0,files=0,models=0,textures=0,maps=0,scripts=0,audio=0
 var errors:[String]=[]
 var summary:String{"Archive: \(archives) · Tệp: \(files)\nModel: \(models) · Texture: \(textures) · Map: \(maps)\nScript: \(scripts) · Audio: \(audio)\nLỗi đọc: \(errors.count). Gameplay: NOT COMPLETED."}
}
enum RuntimeCatalog {
 static func scan(_ root:URL)throws->RuntimeCatalogReport {
  var result=RuntimeCatalogReport()
  func walk(_ archive:RPF7Archive,_ label:String,_ depth:Int)throws {
   try Task.checkCancellation();guard depth<=8 else{throw ArchiveFailure.invalid("nested depth limit")}
   result.archives+=1
   for entry in archive.entries {
    try Task.checkCancellation();result.files+=1
    let ext=(entry.path as NSString).pathExtension.lowercased()
    if ["ydr","yft","ydd"].contains(ext){result.models+=1}
    if ext=="ytd"{result.textures+=1};if ["ymap","ytyp"].contains(ext){result.maps+=1}
    if ext=="ysc"{result.scripts+=1};if ext=="awc"{result.audio+=1}
    if ext=="rpf" {do{try walk(archive.nested(entry),label+"/"+entry.path,depth+1)}catch is CancellationError{throw CancellationError()}catch{result.errors.append(label+"/"+entry.path+": "+error.localizedDescription)}}
   }
  }
  guard let enumerator=FileManager.default.enumerator(at:root,includingPropertiesForKeys:[.isRegularFileKey,.isSymbolicLinkKey],options:.skipsHiddenFiles) else{throw ArchiveFailure.invalid("directory unreadable")}
  for case let file as URL in enumerator where file.pathExtension.lowercased()=="rpf" {
   let info=try file.resourceValues(forKeys:[.isRegularFileKey,.isSymbolicLinkKey]);guard info.isRegularFile==true,info.isSymbolicLink != true else{continue}
   guard file.resolvingSymlinksInPath().path.hasPrefix(root.resolvingSymlinksInPath().path+"/") else{continue}
   do{try walk(RPF7Archive(file:file),file.lastPathComponent,0)}catch is CancellationError{throw CancellationError()}catch{result.errors.append(file.lastPathComponent+": "+error.localizedDescription)}
  };return result
 }
}
