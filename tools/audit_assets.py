"""Read-only inventory; hashes stream in chunks. Never changes source game files."""
from pathlib import Path
import argparse,json,hashlib,collections,struct
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('--out',type=Path,required=True);p.add_argument('--full-hash',action='store_true');a=p.parse_args()
source=a.source.resolve();out=a.out.resolve()
if out==source or source in out.parents:raise SystemExit('Output must be outside game data')
rows=[];counts=collections.Counter();issues=[]
for f in sorted(source.rglob('*')):
 if f.is_symlink():issues.append({'path':f.relative_to(source).as_posix(),'issue':'symlink'});continue
 if not f.is_file():continue
 rel=f.relative_to(source).as_posix()
 if rel.split('/')[0].lower()=='log':continue
 size=f.stat().st_size;row={'path':rel,'bytes':size};counts[f.suffix.lower()]+=1
 with f.open('rb') as h:
  head=h.read(32);row['headerHex']=head[:16].hex()
  if f.suffix.lower()=='.rpf':
   if len(head)<16 or head[:4]!=b'7FPR':issues.append({'path':rel,'issue':'unexpected RPF7 header'})
   else:
    magic,entries,names,key=struct.unpack('<IIII',head[:16]);row['rpf']={'entries':entries,'nameBytes':names,'encryption':key}
    if 16+entries*16+names>size:issues.append({'path':rel,'issue':'RPF table exceeds file'})
  if a.full_hash:
   h.seek(0);digest=hashlib.sha256()
   while chunk:=h.read(4<<20):digest.update(chunk)
   row['sha256']=digest.hexdigest()
 rows.append(row)
manifest={'schemaVersion':1,'profile':'gtav-ios-native-archive-unverified','contentVersion':(source/'version.txt').read_text().strip() if (source/'version.txt').exists() else None,'files':rows,'totalBytes':sum(r['bytes'] for r in rows),'integrity':'sha256-baseline' if a.full_hash else 'headers-and-sizes-only','runtimeCompatibility':'NOT_COMPLETED'}
out.mkdir(parents=True,exist_ok=True);(out/'asset-manifest.local.json').write_text(json.dumps(manifest,indent=2));(out/'audit-summary.json').write_text(json.dumps({'files':len(rows),'totalBytes':manifest['totalBytes'],'formats':dict(counts),'issues':issues,'fullHash':a.full_hash},indent=2));print(json.dumps({'files':len(rows),'bytes':manifest['totalBytes'],'issues':len(issues),'fullHash':a.full_hash}))
