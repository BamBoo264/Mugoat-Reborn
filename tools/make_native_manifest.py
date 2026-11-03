"""Exclude machine-generated diagnostics from the fixed game-data fingerprint."""
import json,sys
from pathlib import Path
EXCLUDE={'_dxgi.log','audio_report.json','litebuild_report.json','scripts_report.json'}
def transform(data):
    data=dict(data)
    data['files']=[f for f in data['files'] if f['path'] not in EXCLUDE]
    data['totalBytes']=sum(f['bytes'] for f in data['files'])
    return data
if __name__=='__main__':
    source,target=map(Path,sys.argv[1:])
    target.write_text(json.dumps(transform(json.loads(source.read_text(encoding='utf-8'))),ensure_ascii=False,indent=2),encoding='utf-8')
