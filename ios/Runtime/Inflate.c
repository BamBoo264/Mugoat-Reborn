#include "RuntimeBridge.h"
#include <zlib.h>
int rb_inflate(const void *input,uint32_t n,void *output,uint32_t count){
 if(!input||!output||!n||!count)return 0;
 z_stream s={0};s.next_in=(Bytef*)input;s.avail_in=n;s.next_out=output;s.avail_out=count;
 if(inflateInit2(&s,-MAX_WBITS)!=Z_OK)return 0;
 int result=inflate(&s,Z_FINISH);
 int valid=result==Z_STREAM_END && s.total_in==n && s.total_out==count;
 inflateEnd(&s);return valid;
}

#include "../Vendor/zstd/lib/zstd.h"
int rb_zstd(const void *input,uint32_t n,void *output,uint32_t expected){
 if(!input||!output||!n||!expected)return 0;
 size_t frame=ZSTD_findFrameCompressedSize(input,n);
 if(ZSTD_isError(frame)||frame!=n)return 0;
 unsigned long long declared=ZSTD_getFrameContentSize(input,n);
 if(declared!=ZSTD_CONTENTSIZE_UNKNOWN && declared!=expected)return 0;
 size_t decoded=ZSTD_decompress(output,expected,input,n);
 return !ZSTD_isError(decoded)&&decoded==expected;
}
