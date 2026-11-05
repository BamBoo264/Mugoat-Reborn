import importlib.util,struct,unittest,tempfile,zipfile,plistlib,json,hashlib
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
class CompositionTests(unittest.TestCase):
 def test_local_composition_preserves_runtime_and_replaces_only_identity(self):
  with tempfile.TemporaryDirectory() as folder:
   folder=Path(folder);source=folder/'original.ipa';bridge=folder/'bridge.dylib';language=folder/'launcher_vi.json';out=folder/'reborn.ipa'
   executable=bytes(fixture());h=hashlib.sha256(executable).hexdigest();m.SUPPORTED.add(h)
   library=b'original runtime library unchanged'
   with zipfile.ZipFile(source,'w') as z:
    z.writestr('Payload/GTAV.app/Info.plist',plistlib.dumps({'CFBundleExecutable':'GTA5','CFBundleIdentifier':'com.macport.gtav','MinimumOSVersion':'16.3'}))
    z.writestr('Payload/GTAV.app/GTA5',executable)
    z.writestr('Payload/GTAV.app/Frameworks/libgtacompat.dylib',library)
    z.writestr('Payload/GTAV.app/_CodeSignature/CodeResources',b'old signature')
   before=source.read_bytes();header=bytearray(32);struct.pack_into('<I',header,0,0xfeedfacf);struct.pack_into('<I',header,12,6);bridge.write_bytes(header)
   language.write_text(json.dumps({'language':'vi','launcher':{'PLAY':'CHƠI'}}),encoding='utf-8')
   try:
    report=m.compose(source,bridge,language,out)
    self.assertEqual(source.read_bytes(),before);self.assertEqual(report['engineFileSectionsUnchanged'],1)
    with zipfile.ZipFile(out) as z:
     self.assertIsNone(z.testzip());self.assertEqual(z.read('Payload/GTAV.app/Frameworks/libgtacompat.dylib'),library)
     self.assertEqual(json.loads(z.read('Payload/GTAV.app/launcher_vi.json')),json.loads(language.read_bytes()))
     self.assertNotIn('Payload/GTAV.app/reborn-expected-manifest.json',z.namelist())
     self.assertNotIn('Payload/GTAV.app/_CodeSignature/CodeResources',z.namelist())
     info=plistlib.loads(z.read('Payload/GTAV.app/Info.plist'))
     self.assertEqual(info['CFBundleIdentifier'],'app.bamboo264.reborn.native');self.assertEqual(info['MinimumOSVersion'],'16.3')
    with self.assertRaises(ValueError):m.compose(source,bridge,language,out)
   finally:m.SUPPORTED.remove(h)
if __name__=='__main__':unittest.main()
