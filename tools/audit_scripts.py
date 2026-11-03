from pathlib import Path
import argparse,struct,json,collections,zlib
from compression import zstd
from rpf7 import RPF7
p=argparse.ArgumentParser();p.add_argument('data',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
def segment(f):return (512<<(f&15))*sum(((f>>s)&m)*w for s,m,w in [(27,1,1),(26,1,2),(25,1,4),(24,1,8),(17,127,16),(11,63,32),(7,15,64),(5,3,128),(4,1,256)])
rows=[];errors=[];hashes=collections.Counter()
def script(archive,e,label):
 packed=archive.read(e.offset,e.stored);raw=zstd.decompress(packed[16:]) if packed[16:20]==bytes.fromhex('28b52ffd') else zlib.decompress(packed[16:],-15);expected=segment(e.flags)+segment(e.graphics)
 if len(raw)!=expected:raise ValueError('resource size')
 def u(at):return struct.unpack_from('<I',raw,at)[0]
 def q(at):return struct.unpack_from('<Q',raw,at)[0]
 def data(ptr,n):
  offset=ptr-0x50000000
  if offset<0 or offset>segment(e.flags) or n>segment(e.flags)-offset:raise ValueError('YSC pointer')
  return raw[offset:offset+n]
 code_size=u(28);code_table=data(q(16),((code_size+16383)//16384)*8);code=bytearray()
 for i in range((code_size+16383)//16384):code.extend(data(struct.unpack_from('<Q',code_table,i*8)[0],min(16384,code_size-i*16384)))
 name=data(q(96),min(256,segment(e.flags)-(q(96)-0x50000000))).split(b'\0',1)[0].decode()
 native_count=u(44);native_bytes=data(q(64),native_count*8) if native_count else b''
 for i in range(native_count):
  value=struct.unpack_from('<Q',native_bytes,i*8)[0];n=(code_size+i)&63;h=value if n==0 else ((value<<n)|(value>>(64-n)))&0xffffffffffffffff;hashes[f'{h:016x}']+=1
 rows.append({'script':name,'archive':label,'codeBytes':len(code),'nativeCount':native_count,'statics':u(36),'parameters':u(32),'entryOpcode':code[0] if code else None})
def walk(archive,label,depth):
 if depth>8:return
 for e in archive.entries:
  if e.path.endswith('.rpf'):
   try:walk(archive.nested(e),label+'/'+e.path,depth+1)
   except Exception:pass
  elif e.path.endswith('.ysc'):
   try:script(archive,e,label)
   except Exception as ex:errors.append({'script':e.path,'error':str(ex)})
for file in sorted(a.data.rglob('*.rpf')):
 try:walk(RPF7(file),file.relative_to(a.data).as_posix(),0)
 except Exception as ex:errors.append({'archive':str(file.relative_to(a.data)),'error':str(ex)})
a.out.mkdir(parents=True,exist_ok=True);(a.out/'script-index.local.json').write_text(json.dumps(rows));(a.out/'script-native-coverage.local.json').write_text(json.dumps(dict(hashes),indent=2))
summary={'scriptsLoaded':len(rows),'uniqueNativeHashes':len(hashes),'errors':errors,'codeBytes':sum(x['codeBytes'] for x in rows)};(a.out/'script-summary.local.json').write_text(json.dumps(summary,indent=2));print(json.dumps(summary)[:3000])
