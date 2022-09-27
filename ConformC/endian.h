unsigned short changeEndian16(unsigned short v){
    return( ((v & 0xFF00) >> 8) | ((v & 0xFF) << 8));
}

unsigned short bigEndian16(unsigned short v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return v;
#else
    return changeEndian16(v);
#endif
}

unsigned short littleEndian16(unsigned short v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return changeEndian16(v);
#else
    return v;
#endif
}


u_int32_t  changeEndian32(u_int32_t v){
    return( ((v & 0xFF000000) >> 24) |
	    ((v & 0x00FF0000) >> 8) |
	    ((v & 0x0000FF00) << 8) |
	    ((v & 0x000000FF) << 24));
}

u_int32_t bigEndian32(u_int32_t v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return v;
#else
    return changeEndian32(v);
#endif
}

u_int32_t littleEndian32(u_int32_t v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return changeEndian32(v);
#else
    return v;
#endif
}

unsigned long long changeEndian64(unsigned long long v){
    return( ((v & 0xFF00000000000000) >> 56) | // -> (0x00000000000000FF)
	    ((v & 0x00FF000000000000) >> 40) | // -> (0x000000000000FF00)
	    ((v & 0x0000FF0000000000) >> 24) | // -> (0x0000000000FF0000)
	    ((v & 0x000000FF00000000) >> 8)  | // -> (0x00000000FF000000)
	    ((v & 0x00000000FF000000) << 8)  | // -> (0x000000FF00000000)
	    ((v & 0x0000000000FF0000) << 24) | // -> (0x00000FF000000000)
	    ((v & 0x000000000000FF00) << 40)  | // -> (0x000FF00000000000)
	    ((v & 0x00000000000000FF) << 56)); // -> (0xFF00000000000000)
}

unsigned long long bigEndian64(unsigned long long v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return v;
#else
    return changeEndian64(v);
#endif
}

unsigned long long littleEndian64(unsigned long long v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return changeEndian64(v);
#else
    return v;
#endif
}

#ifdef NOTNOW
double changeEndianDouble(double v){
    u_int64_t t = *((u_int64_t*)(&v));
    t = changeEndian64(t);
    return *((float*)(&t));
}

double littleEndianDouble(double v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return changeEndian64(v);
#else
    return v;
#endif
    return v;
}
double bigEndianDouble(double v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return changeEndian64(v);
#else
    return v;
#endif
    return v;
}

float changeEndianFloat(float v){
    u_int32_t t = *((u_int32_t*)(&v));
    t = changeEndian32(t);
    return *((float*)(&t));
}

float littleEndianFloat(float v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return changeEndian64(v);
#else
    return v;
#endif
}

float bigEndianFloat(float v){
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN_
    return v;
#else
    return changeEndian64(v);
#endif
}

#endif
