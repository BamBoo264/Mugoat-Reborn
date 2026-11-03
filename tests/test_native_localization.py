import json,re,unittest
from pathlib import Path
ROOT=Path(__file__).parents[1]
FORMAT=re.compile(r'%(?:[0-9]+\$)?[-+ #0]*[0-9]*(?:\.[0-9]+)?(?:ll|l|h|hh|z)?[@diouxXfFeEgGcsp%]')
class LocalizationTests(unittest.TestCase):
 def test_format_parser(self):
  self.assertEqual(FORMAT.findall("%.1f %@ %llu %d %1$@"),["%.1f","%@","%llu","%d","%1$@"])
 def test_nonempty_and_matching_placeholders(self):
  d=json.loads((ROOT/'ios/NativeBridge/launcher_vi.json').read_text(encoding='utf-8'))
  self.assertEqual(d['language'],'vi');self.assertEqual(len(d['launcher']),800)
  for key,value in d['launcher'].items():
   with self.subTest(key=key):
    self.assertTrue(value.strip() or not key.strip());self.assertEqual(FORMAT.findall(key),FORMAT.findall(value))
 def test_import_button_and_hooks_removed(self):
  s=(ROOT/'ios/NativeBridge/Entry.m').read_text(encoding='utf-8')
  self.assertNotIn('method_setImplementation',s);self.assertNotIn('UIButton',s)
  self.assertNotIn('UIDocumentPicker',s);self.assertIn('MACPORT_LAUNCHER_LANGUAGE',s)
  workflow=(ROOT/'.github/workflows/native-bridge.yml').read_text(encoding='utf-8')
  self.assertNotIn('DataImportManager.swift',workflow);self.assertNotIn('NativeEntry.swift',workflow)
if __name__=='__main__':unittest.main()
