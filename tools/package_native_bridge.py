"""Local-only unsigned IPA composition. Never downloads or publishes a game runtime."""
import argparse, hashlib, json, plistlib, stat, struct, zipfile
from pathlib import Path, PurePosixPath

LOAD_PATH=b'@executable_path/Frameworks/libRebornBridge.dylib\0'
SUPPORTED={
 '21c5fc0af5ffae8340dc920a0945ec5cee54e955b6f80188af72f036d93ee945',
 'c7b48e0e987de1c516cfe177fce713ea67c4a0324fd31dbc19372abe3e24489f'}

def inject(data):
 if len(data)<32 or struct.unpack_from('<IIII',data)!=(0xfeedfacf,0x100000c,0,2):
  raise ValueError('Expected audited thin ARM64 MH_EXECUTE')
 n,size=struct.unpack_from('<II',data,16);end=32+size
 if n>1000 or end>len(data):raise ValueError('Invalid load command table')
 pos=32;first=len(data);sections=[]
 for _ in range(n):
  if pos+8>end:raise ValueError('Truncated load command')
  cmd,length=struct.unpack_from('<II',data,pos)
  if length<8 or length%8 or pos+length>end:raise ValueError('Invalid load command')
  if cmd==0x19:
   if length<72:raise ValueError('Invalid segment')
   count=struct.unpack_from('<I',data,pos+64)[0]
   if 72+count*80>length:raise ValueError('Invalid sections')
   for i in range(count):
    s=pos+72+i*80; sz=struct.unpack_from('<Q',data,s+40)[0];off=struct.unpack_from('<I',data,s+48)[0];flags=struct.unpack_from('<I',data,s+64)[0]
    # S_ZEROFILL / S_GB_ZEROFILL / S_THREAD_LOCAL_ZEROFILL have no file bytes.
    if sz and flags&255 not in (1,12,18):
     if off<end or off+sz>len(data):raise ValueError('Invalid file-backed section')
     first=min(first,off);sections.append((off,sz))
  if cmd==0x2c and struct.unpack_from('<I',data,pos+16)[0]:raise ValueError('Encrypted executable unsupported')
  if cmd in (0xc,0x80000018,0x8000001f):
   off=struct.unpack_from('<I',data,pos+8)[0]
   if data[pos+off:pos+length].split(b'\0')[0]==LOAD_PATH.rstrip(b'\0'):raise ValueError('Bridge already installed')
  pos+=length
 if pos!=end or not sections:raise ValueError('Invalid header layout')
 length=(24+len(LOAD_PATH)+7)&~7
 if end+length>first or any(data[end:end+length]):raise ValueError('No safe zero-filled header padding; refusing to move engine code')
 entry=struct.pack('<6I',0xc,length,24,0,0x10000,0x10000)+LOAD_PATH
 entry=entry.ljust(length,b'\0')
 out=bytearray(data);out[end:end+length]=entry;struct.pack_into('<II',out,16,n+1,size+length)
 for off,sz in sections:
  if out[off:off+sz]!=data[off:off+sz]:raise ValueError('Engine section modified')
 return bytes(out),len(sections)

def compose(source,bridge,manifest,output):
 if output.resolve()==source.resolve() or output.exists():raise ValueError('Output must be a new file; source is never overwritten')
 dylib=bridge.read_bytes()
 if len(dylib)<32 or struct.unpack_from('<I',dylib)[0]!=0xfeedfacf:raise ValueError('Bridge must be a thin Mach-O dylib')
 if struct.unpack_from('<I',dylib,12)[0]!=6:raise ValueError('Bridge must be MH_DYLIB')
 with zipfile.ZipFile(source) as z:
  names=z.namelist()
  if len(set(names))!=len(names):raise ValueError('Duplicate archive entries')
  for info in z.infolist():
   name=info.filename;p=PurePosixPath(name)
   if p.is_absolute() or '..' in p.parts or '\\' in name:raise ValueError('Unsafe ZIP path')
   if stat.S_ISLNK(info.external_attr>>16):raise ValueError('Symlinks unsupported in this local composer')
  roots=[s for s in names if s.startswith('Payload/') and s.count('/')==2 and s.endswith('.app/Info.plist')]
  if len(roots)!=1:raise ValueError('Expected one app')
  info_path=roots[0];root=info_path.rsplit('/',1)[0];info=plistlib.loads(z.read(info_path));exe=root+'/'+info['CFBundleExecutable']
  original=z.read(exe);digest=hashlib.sha256(original).hexdigest()
  if digest not in SUPPORTED:raise ValueError('Runtime is not one of the two locally audited user IPAs')
  patched,sections=inject(original)
  additions={root+'/Frameworks/libRebornBridge.dylib':dylib,root+'/reborn-expected-manifest.json':manifest.read_bytes()}
  if any(s in names for s in additions):raise ValueError('Existing bridge files; refusing overwrite')
  temp=output.with_suffix('.partial')
  if temp.exists():raise ValueError('Partial output exists')
  try:
   with zipfile.ZipFile(temp,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as dest:
    for item in z.infolist():
     if '/_CodeSignature/' in item.filename or item.filename.endswith('/embedded.mobileprovision'):continue
     dest.writestr(item,patched if item.filename==exe else z.read(item.filename))
    for name,content in additions.items():dest.writestr(name,content)
   with zipfile.ZipFile(temp) as check:
    if check.testzip():raise ValueError('Output ZIP integrity failed')
   temp.rename(output)
  except BaseException:
   temp.unlink(missing_ok=True);raise
 return {'status':'UNSIGNED_DEVICE_TEST_REQUIRED','originalExecutableSHA256':digest,'engineFileSectionsUnchanged':sections,'bridgeSHA256':hashlib.sha256(dylib).hexdigest(),'outputBytes':output.stat().st_size}

if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__)
 for flag in ['source','bridge','manifest','output']:parser.add_argument('--'+flag,type=Path,required=True)
 a=parser.parse_args();print(json.dumps(compose(a.source,a.bridge,a.manifest,a.output),indent=2))
