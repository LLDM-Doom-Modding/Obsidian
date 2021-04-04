/* $XFree86: xc/lib/X11/lcUniConv/koi8_c.h,v 1.2 2000/11/28 16:10:29 dawes Exp $
 */

/*
 * KOI8-C
 */

static const unsigned short koi8_c_2uni[128] = {
    /* 0x80 */
    0x0493,
    0x0497,
    0x049b,
    0x049d,
    0x04a3,
    0x04af,
    0x04b1,
    0x04b3,
    0x04b7,
    0x04b9,
    0x04bb,
    0x2580,
    0x04d9,
    0x04e3,
    0x04e9,
    0x04ef,
    /* 0x90 */
    0x0492,
    0x0496,
    0x049a,
    0x049c,
    0x04a2,
    0x04ae,
    0x04b0,
    0x04b2,
    0x04b6,
    0x04b8,
    0x04ba,
    0x2321,
    0x04d8,
    0x04e2,
    0x04e8,
    0x04ee,
    /* 0xa0 */
    0x00a0,
    0x0452,
    0x0453,
    0x0451,
    0x0454,
    0x0455,
    0x0456,
    0x0457,
    0x0458,
    0x0459,
    0x045a,
    0x045b,
    0x045c,
    0x0491,
    0x045e,
    0x045f,
    /* 0xb0 */
    0x2116,
    0x0402,
    0x0403,
    0x0401,
    0x0404,
    0x0405,
    0x0406,
    0x0407,
    0x0486,
    0x0409,
    0x040a,
    0x040b,
    0x040c,
    0x0490,
    0x040e,
    0x040f,
    /* 0xc0 */
    0x044e,
    0x0430,
    0x0431,
    0x0446,
    0x0434,
    0x0435,
    0x0444,
    0x0433,
    0x0445,
    0x0438,
    0x0439,
    0x043a,
    0x043b,
    0x043c,
    0x043d,
    0x043e,
    /* 0xd0 */
    0x043f,
    0x044f,
    0x0440,
    0x0441,
    0x0442,
    0x0443,
    0x0436,
    0x0432,
    0x044c,
    0x044b,
    0x0437,
    0x0448,
    0x044d,
    0x0449,
    0x0447,
    0x044a,
    /* 0xe0 */
    0x042e,
    0x0410,
    0x0411,
    0x0426,
    0x0414,
    0x0415,
    0x0424,
    0x0413,
    0x0425,
    0x0418,
    0x0419,
    0x041a,
    0x041b,
    0x041c,
    0x041d,
    0x041e,
    /* 0xf0 */
    0x041f,
    0x042f,
    0x0420,
    0x0421,
    0x0422,
    0x0423,
    0x0416,
    0x0412,
    0x042c,
    0x042b,
    0x0417,
    0x0428,
    0x042d,
    0x0429,
    0x0427,
    0x042a,
};

static int koi8_c_mbtowc(conv_t conv, ucs4_t *pwc, const unsigned char *s,
                         int n) {
    unsigned char c = *s;
    if (c < 0x80)
        *pwc = (ucs4_t)c;
    else
        *pwc = (ucs4_t)koi8_c_2uni[c - 0x80];
    return 1;
}

static const unsigned char koi8_c_page00[1] = {
    0xa0, /* 0xa0-0xa7 */
};
static const unsigned char koi8_c_page04[240] = {
    0x00, 0xb3, 0xb1, 0xb2, 0xb4, 0xb5, 0xb6, 0xb7, /* 0x00-0x07 */
    0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0x00, 0xbe, 0xbf, /* 0x08-0x0f */
    0xe1, 0xe2, 0xf7, 0xe7, 0xe4, 0xe5, 0xf6, 0xfa, /* 0x10-0x17 */
    0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef, 0xf0, /* 0x18-0x1f */
    0xf2, 0xf3, 0xf4, 0xf5, 0xe6, 0xe8, 0xe3, 0xfe, /* 0x20-0x27 */
    0xfb, 0xfd, 0xff, 0xf9, 0xf8, 0xfc, 0xe0, 0xf1, /* 0x28-0x2f */
    0xc1, 0xc2, 0xd7, 0xc7, 0xc4, 0xc5, 0xd6, 0xda, /* 0x30-0x37 */
    0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf, 0xd0, /* 0x38-0x3f */
    0xd2, 0xd3, 0xd4, 0xd5, 0xc6, 0xc8, 0xc3, 0xde, /* 0x40-0x47 */
    0xdb, 0xdd, 0xdf, 0xd9, 0xd8, 0xdc, 0xc0, 0xd1, /* 0x48-0x4f */
    0x00, 0xa3, 0xa1, 0xa2, 0xa4, 0xa5, 0xa6, 0xa7, /* 0x50-0x57 */
    0xa8, 0xa9, 0xaa, 0xab, 0xac, 0x00, 0xae, 0xaf, /* 0x58-0x5f */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x60-0x67 */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x68-0x6f */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x70-0x77 */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x78-0x7f */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x80-0x87 */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0x88-0x8f */
    0xbd, 0xad, 0x90, 0x80, 0x00, 0x00, 0x91, 0x81, /* 0x90-0x97 */
    0x00, 0x00, 0x92, 0x82, 0x93, 0x83, 0x00, 0x00, /* 0x98-0x9f */
    0x00, 0x00, 0x94, 0x84, 0x00, 0x00, 0x00, 0x00, /* 0xa0-0xa7 */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x95, 0x85, /* 0xa8-0xaf */
    0x96, 0x86, 0x97, 0x87, 0x00, 0x00, 0x98, 0x88, /* 0xb0-0xb7 */
    0x99, 0x89, 0x9a, 0x8a, 0x00, 0x00, 0x00, 0x00, /* 0xb8-0xbf */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xc0-0xc7 */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xc8-0xcf */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xd0-0xd7 */
    0x9c, 0x8c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0xd8-0xdf */
    0x00, 0x00, 0x9d, 0x8d, 0x00, 0x00, 0x00, 0x00, /* 0xe0-0xe7 */
    0x9e, 0x8e, 0x00, 0x00, 0x00, 0x00, 0x9f, 0x8f, /* 0xe8-0xef */
};
static const unsigned char koi8_c_page22[1] = {
    0xb0, /* 0x16-0x16 */
};

static int koi8_c_wctomb(conv_t conv, unsigned char *r, ucs4_t wc, int n) {
    unsigned char c = 0;
    if (wc < 0x0080) {
        *r = wc;
        return 1;
    } else if (wc >= 0x00a0 && wc < 0x00a1)
        c = koi8_c_page00[wc - 0x00a0];
    else if (wc >= 0x0400 && wc < 0x04ef)
        c = koi8_c_page04[wc - 0x0400];
    else if (wc >= 0x2216 && wc < 0x2217)
        c = koi8_c_page22[wc - 0x2216];
    if (c != 0) {
        *r = c;
        return 1;
    }
    return RET_ILSEQ;
}
