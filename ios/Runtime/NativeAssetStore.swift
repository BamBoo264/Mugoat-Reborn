import Foundation
/// Bounded demand-first CPU cache. Real archive reads/decompression execute off the actor/UI.
actor NativeAssetStore {
 enum Priority {case demand,prefetch}
 struct Metrics {let cachedBytes:Int;let cacheItems:Int;let reads:Int;let hits:Int;let maxConcurrent:Int}
 private struct Job {let key:String;let archive:RPF7Archive;let entry:RPF7Entry;let priority:Priority}
 private struct Cached {let data:Data;var stamp:UInt64}
 private let budget:Int
 private let workers:Int
 private var cache:[String:Cached]=[:],queue:[Job]=[]
 private var waiters:[String:[CheckedContinuation<Data,Error>]]=[:]
 private var active=0,used=0,reads=0,hits=0,maxActive=0
 private var clock:UInt64=0
 init(budgetBytes:Int=32<<20,workers:Int=2){budget=max(0,min(budgetBytes,256<<20));self.workers=max(1,min(workers,4))}
 func read(archive:RPF7Archive,entry:RPF7Entry,priority:Priority = .demand)async throws->Data {
  let key=archive.identity+"/"+entry.path.lowercased();clock &+= 1
  if var item=cache[key]{hits+=1;item.stamp=clock;cache[key]=item;return item.data}
  if priority == .prefetch && queue.filter({$0.priority == .prefetch}).count>=16{throw ArchiveFailure.unsupported("prefetch queue full")}
  if waiters[key]==nil && queue.count>=128{throw ArchiveFailure.unsupported("asset queue full")}
  return try await withCheckedThrowingContinuation{continuation in
   if waiters[key] != nil {
    waiters[key]!.append(continuation)
    if priority == .demand,let i=queue.firstIndex(where:{$0.key==key}),queue[i].priority == .prefetch {
     let old=queue.remove(at:i);queue.insert(Job(key:old.key,archive:old.archive,entry:old.entry,priority:.demand),at:0)
    }
   }else{waiters[key]=[continuation];queue.append(Job(key:key,archive:archive,entry:entry,priority:priority))}
   pump()
  }
 }
 private func pump(){
  while active<workers && !queue.isEmpty {
   let index=queue.firstIndex(where:{$0.priority == .demand}) ?? 0,job=queue.remove(at:index)
   active+=1;reads+=1;maxActive=max(maxActive,active)
   Task.detached(priority:job.priority == .demand ? .userInitiated:.utility){
    let result=Result{try job.entry.resource ? job.archive.resource(job.entry).bytes:job.archive.binary(job.entry)}
    await self.finish(job.key,result)
   }
  }
 }
 private func finish(_ key:String,_ result:Result<Data,Error>){
  active-=1
  if case .success(let data)=result,data.count<=budget {
   while used+data.count>budget,let oldest=cache.min(by:{$0.value.stamp<$1.value.stamp}) {used-=oldest.value.data.count;cache.removeValue(forKey:oldest.key)}
   clock &+= 1;cache[key]=Cached(data:data,stamp:clock);used+=data.count
  }
  let pending=waiters.removeValue(forKey:key) ?? [];for continuation in pending{continuation.resume(with:result)}
  pump()
 }
 func memoryWarning(){cache.removeAll(keepingCapacity:false);used=0}
 func metrics()->Metrics{Metrics(cachedBytes:used,cacheItems:cache.count,reads:reads,hits:hits,maxConcurrent:maxActive)}
}
