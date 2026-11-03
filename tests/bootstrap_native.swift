import Foundation
@main struct BootstrapTests {static func main()throws{
 let root=try RuntimeBootstrap.parseXML(Data("<?xml version=\"1.0\"?><GameConfig><Pools/></GameConfig>".utf8));precondition(root=="GameConfig")
 do{_ = try RuntimeBootstrap.parseXML(Data("<broken>".utf8));fatalError("invalid XML accepted")}catch{}
 print("PASS bootstrap metadata parser: valid XML root and malformed input rejection")
}}
