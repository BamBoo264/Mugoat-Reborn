from pathlib import Path
import unittest,tempfile,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from rpf7 import RPF7,RPFError
from rpf_fixture import fixture
class RPFTests(unittest.TestCase):
 def test_roundtrip(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'valid.rpf';expected=fixture(p);before=p.read_bytes();r=RPF7(p)
   self.assertEqual(r.entries[0].path,'meta.xml');self.assertEqual(r.binary(r.entries[0]),expected);self.assertEqual(p.read_bytes(),before)
 def test_reject_malformed(self):
  with tempfile.TemporaryDirectory() as d:
   for mode in ['cycle','orphan','payload','name','encrypted']:
    with self.subTest(mode=mode):
     p=Path(d)/(mode+'.rpf');fixture(p,mode)
     with self.assertRaises(RPFError):RPF7(p)
 def test_output_cap(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'valid.rpf';fixture(p);r=RPF7(p)
   with self.assertRaises(RPFError):r.binary(r.entries[0],limit=1)
if __name__=='__main__':unittest.main(verbosity=2)
