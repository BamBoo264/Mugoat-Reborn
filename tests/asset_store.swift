import Foundation
@main struct AssetStoreTest {
 static func main()async throws {
  let file=URL(fileURLWithPath:CommandLine.arguments[1]).appendingPathComponent("valid.rpf"),archive=try RPF7Archive(file:file),entry=archive.entries[0]
  let store=NativeAssetStore(budgetBytes:4096,workers:2)
  try await withThrowingTaskGroup(of:Data.self){group in
   for _ in 0..<64{group.addTask{try await store.read(archive:archive,entry:entry)}}
   for try await bytes in group{precondition(!bytes.isEmpty)}
  }
  let first=await store.metrics();precondition(first.reads==1 && first.cacheItems==1 && first.cachedBytes<=4096 && first.maxConcurrent<=2)
  await store.memoryWarning();let cleared=await store.metrics();precondition(cleared.cachedBytes==0)
  _ = try await store.read(archive:archive,entry:entry);let again=await store.metrics();precondition(again.reads==2)
  print("PASS native asset store: concurrent coalescing, worker/cache caps, memory-warning release and reload")
 }
}
