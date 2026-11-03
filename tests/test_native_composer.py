import importlib.util,struct,unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location('composer',Path(__file__).parents[1]/'tools/package_native_bridge.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def fixture():
 b=bytearray(4096);struct.pack_into('<8I',b,0,0xfeedfacf,0x100000c,0,2,1,152,0,0)
 struct.pack_into('<II',b,32,0x19,152);struct.pack_into('<I',b,96,1)
 s=104;struct.pack_into('<Q',b,s+40,64);struct.pack_into('<I',b,s+48,1024)
 b[1024:1088]=b'x'*64
 return b
class ComposerTests(unittest.TestCase):
 def test_code_preserved(self):
  b=fixture();out,count=m.inject(b)
  self.assertEqual(count,1);self.assertEqual(out[1024:],b[1024:]);self.assertEqual(len(out),len(b))
 def test_nonzero_padding_rejected(self):
  b=fixture();b[184]=1
  with self.assertRaises(ValueError):m.inject(b)
 def test_insufficient_padding_rejected(self):
  b=fixture();struct.pack_into('<I',b,104+48,192)
  with self.assertRaises(ValueError):m.inject(b)
 def test_truncated_command_rejected(self):
  b=fixture();struct.pack_into('<I',b,36,160)
  with self.assertRaises(ValueError):m.inject(b)
 def test_duplicate_rejected(self):
  b,_=m.inject(fixture())
  with self.assertRaises(ValueError):m.inject(b)
 def test_wrong_architecture_rejected(self):
  b=fixture();struct.pack_into('<I',b,4,7)
  with self.assertRaises(ValueError):m.inject(b)
if __name__=='__main__':unittest.main()
