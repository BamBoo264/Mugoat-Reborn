from pathlib import Path
from collections import Counter
import argparse,json
from rpf7 import RPF7
p=argparse.ArgumentParser();p.add_argument('data',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
rows=[];errors=[];formats=Counter();archives=0
for file in sorted(a.data.rglob('*.rpf')):
 def scan(archive,label,depth):
  global archives
  if depth>8:raise ValueError('nested archive depth limit')
  archives+=1
  for e in archive.entries:
   formats[Path(e.path).suffix.lower()]+=1
   rows.append({'archive':label,'path':e.path,'kind':e.kind,'stored':e.stored,'size':e.size,'encrypted':e.kind=='binary' and bool(e.flags)})
   if e.path.lower().endswith('.rpf'):
    try:scan(archive.nested(e),label+'/'+e.path,depth+1)
    except Exception as ex:errors.append({'archive':label+'/'+e.path,'error':str(ex)})
 try:scan(RPF7(file),file.relative_to(a.data).as_posix(),0)
 except Exception as ex:errors.append({'archive':file.relative_to(a.data).as_posix(),'error':str(ex)})
a.out.mkdir(parents=True,exist_ok=True);(a.out/'archive-index.local.json').write_text(json.dumps(rows));summary={'archives':archives,'entries':len(rows),'formats':dict(formats),'errors':errors};(a.out/'archive-summary.local.json').write_text(json.dumps(summary,indent=2));print(json.dumps(summary)[:5000])
