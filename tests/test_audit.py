from pathlib import Path
import unittest,tempfile,struct,subprocess,json,sys
SCRIPT=Path(__file__).resolve().parents[1]/'tools/audit_assets.py'
class AuditTests(unittest.TestCase):
 def test_header_hash_readonly(self):
  with tempfile.TemporaryDirectory() as d:
   r=Path(d);source=r/'game';source.mkdir();original=struct.pack('<4I',0x52504637,1,4,0)+bytes(20)
   (source/'common.rpf').write_bytes(original)
   subprocess.run([sys.executable,str(SCRIPT),str(source),'--out',str(r/'out'),'--full-hash'],check=True,capture_output=True)
   m=json.loads((r/'out/asset-manifest.local.json').read_text());self.assertEqual(len(m['files'][0]['sha256']),64);self.assertEqual((source/'common.rpf').read_bytes(),original)
   self.assertFalse(json.loads((r/'out/audit-summary.json').read_text())['issues'])
 def test_truncated_rpf(self):
  with tempfile.TemporaryDirectory() as d:
   r=Path(d);s=r/'game';s.mkdir();(s/'bad.rpf').write_bytes(b'bad')
   subprocess.run([sys.executable,str(SCRIPT),str(s),'--out',str(r/'out')],check=True,capture_output=True)
   self.assertEqual(len(json.loads((r/'out/audit-summary.json').read_text())['issues']),1)
 def test_output_inside_source_rejected(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);result=subprocess.run([sys.executable,str(SCRIPT),str(p),'--out',str(p/'output')],capture_output=True);self.assertNotEqual(result.returncode,0)
if __name__=='__main__':unittest.main(verbosity=2)
