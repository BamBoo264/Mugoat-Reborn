import struct,zlib
from pathlib import Path
def fixture(path,mode='valid'):
 payload=b'original reborn fixture\n'*37
 compressor=zlib.compressobj(wbits=-15);packed=compressor.compress(payload)+compressor.flush()
 names=b'\0meta.xml\0';size=(512+len(packed)+511)&~511
 rows=[struct.pack('<4I',0,0x7fffff00,1,1),struct.pack('<4I',1|(len(packed)<<16),1<<8,len(payload),0)]
 if mode=='cycle':rows[0]=struct.pack('<4I',0,0x7fffff00,0,1)
 if mode=='orphan':rows[0]=struct.pack('<4I',0,0x7fffff00,1,0)
 if mode=='payload':rows[1]=struct.pack('<4I',1|(len(packed)<<16),0xffffff00,len(payload),0)
 if mode=='name':rows[1]=struct.pack('<4I',65535|(len(packed)<<16),1<<8,len(payload),0)
 header=struct.pack('<4I',0x52504637,2,len(names),0 if mode!='encrypted' else 0xffffff9)
 data=bytearray(header+b''.join(rows)+names);data.extend(bytes(512-len(data)));data.extend(packed);data.extend(bytes(size-len(data)))
 Path(path).write_bytes(data);return payload
if __name__=='__main__':
 import sys
 root=Path(sys.argv[1]);root.mkdir(parents=True,exist_ok=True)
 for mode in ['valid','cycle','orphan','payload','name','encrypted']:fixture(root/(mode+'.rpf'),mode)
