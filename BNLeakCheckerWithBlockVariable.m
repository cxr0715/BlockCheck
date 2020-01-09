//
//  BNLeakCheckerWithBlockVariable.m
//  BlockNotification
//
//  Created by caoxuerui on 2019/11/29.
//  Copyright © 2019 yy. All rights reserved.
//

#import "BNLeakCheckerWithBlockVariable.h"

@implementation BNLeakCheckerWithBlockVariable
+ (NSMutableSet *)_GetBlockStrongLayout_new:(void *)block//通过block_extended_layout获取强引用信息
{
    struct Block_literal_BN* blockLiteral = block;
    
    /**
     BLOCK_HAS_CTOR - Block has a C++ constructor/destructor, which gives us a good chance it retains
     objects that are not pointer aligned, so omit them.
     !BLOCK_HAS_COPY_DISPOSE - Block doesn't have a dispose function, so it does not retain objects and
     we are not able to blackbox it.
     */
    if ((blockLiteral->flags & BLOCK_HAS_CTOR)
        || !(blockLiteral->flags & BLOCK_HAS_COPY_DISPOSE) || !(blockLiteral->flags & BLOCK_HAS_EXTENDED_LAYOUT)) {
        return nil;
    }
    
    // Run through the release detectors and add each one that got released to the object's
    // strong ivar layout.
    NSMutableSet *layout_strong = [NSMutableSet new];
    const char *layout = (const char *)(&blockLiteral->descriptor->layout);
    const unsigned short firstlayout = *(const unsigned short *)layout;
    void *firstCapture = &(blockLiteral->capture);
    if (firstlayout < 0x1000) { //0xXYZ模式
        unsigned char strong = (firstlayout>>8)&0xf;
        unsigned char bbyref = (firstlayout>>4)&0xf;
        for (int i = 0; i < strong; ++i) {
            void *s = *((void **)(firstCapture + i*sizeof(void *)));
            [layout_strong addObject:(__bridge id)s];
        }
        for (int i = 0; i < bbyref; ++i) {
            void *s = *((void **)(firstCapture + (strong + i)*sizeof(void *)));
            void *ss = NULL;
            struct Block_byref_block *s = (struct Block_byref_block *)block_byref;
            if ( (s->flags & BLOCK_BYREF_LAYOUT_STRONG) == BLOCK_BYREF_LAYOUT_STRONG ) {
                ss = s->capture;
            }
            if ( ss != NULL ) {
                [layout_strong addObject:(__bridge id)ss];
            }
        }
    } else { //0xPN模式
        unsigned int offset = 0;
        unsigned char *llayout = (unsigned char *)layout;
        while (llayout!=0) {
            unsigned char pn = *llayout;
            unsigned char type = (pn>>4)&0xf;
            switch (type) {
                case BLOCK_LAYOUT_STRONG:
                {
                    void *s = firstCapture+offset;
                    [layout_strong addObject:(__bridge id)s];
                }
                    break;
                case BLOCK_LAYOUT_BYREF:
                {
                    void *s = firstCapture +offset;
                    void *ss = NULL;
                    struct Block_byref_block *s = (struct Block_byref_block *)block_byref;
                    if ( (s->flags & BLOCK_BYREF_LAYOUT_STRONG) == BLOCK_BYREF_LAYOUT_STRONG ) {
                        ss = s->capture;
                    }
                    if ( ss != NULL ) {
                        [layout_strong addObject:(__bridge id)ss];
                    }
                }
                    break;
                    
                default:
                    break;
            }
            offset += (pn&0xf)+1;
            llayout++;
        }
    }
    return layout_strong;
}

@end
