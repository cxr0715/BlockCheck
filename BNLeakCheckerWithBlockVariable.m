//
//  BNLeakCheckerWithBlockVariable.m
//  BlockNotification
//
//  Created by caoxuerui on 2019/11/29.
//  Copyright © 2019 yy. All rights reserved.
//

#import "BNLeakCheckerWithBlockVariable.h"

@implementation BNLeakCheckerWithBlockVariable
+ (BOOL)checkBlockWithVariable:(id)callBack retainObserver:(id)observer {
    struct Block_literal_BN *blockLayout = (__bridge struct Block_literal_BN*)(callBack);
    //如果没有引用外部对象也就是没有扩展布局标志的话则直接返回。
    if (!(blockLayout->flags & BLOCK_HAS_EXTENDED_LAYOUT)) {
        return NO;
    }
    
    uint8_t *desc = (uint8_t *)blockLayout->descriptor;
    desc += sizeof(struct BN_Block_descriptor_1);
    
    if (blockLayout->flags & BLOCK_HAS_COPY_DISPOSE) {
        desc += sizeof(struct BN_Block_descriptor_2);
    }
    
    //最终转化为Block_descriptor_3中的结构指针。并且当布局值为0时表明没有引用外部对象。
    struct BN_Block_descriptor_3 *desc3 = (struct BN_Block_descriptor_3 *)desc;
    if (desc3->layout == 0) {
        return NO;
    }
    
    const char *extlayoutstr = desc3->layout;
    //处理压缩布局描述的情况。
    if (extlayoutstr < (const char*)0x1000) {
        //当扩展布局的值小于0x1000时则是压缩的布局描述，这里分别取出xyz部分的内容进行重新编码。
        char compactEncoding[4] = {0};
        unsigned short xyz = (uintptr_t)(extlayoutstr);
        unsigned char x = (xyz >> 8) & 0xF;
        unsigned char y = (xyz >> 4) & 0xF;
        unsigned char z = (xyz >> 0) & 0xF;
        
        int idx = 0;
        if (x != 0)
        {
            x--;
            compactEncoding[idx++] = (3<<4) | x;
        }
        if (y != 0)
        {
            y--;
            compactEncoding[idx++] = (4<<4) | y;
        }
        if (z != 0)
        {
            z--;
            compactEncoding[idx++] = (5<<4) | z;
        }
        compactEncoding[idx++] = 0;
        extlayoutstr = compactEncoding;
    }
    
    unsigned char *blockmemoryAddr = (unsigned char *)(__bridge void*)callBack;
    int refObjOffset = sizeof(struct Block_literal_BN);  //得到外部引用对象的开始偏移位置。
    for (int i = 0; i < strlen(extlayoutstr); i++) {
        //取出字节中所表示的类型和数量。
         unsigned char PN = extlayoutstr[i];
         int P = (PN >> 4) & 0xF;   //P是高4位描述引用的类型。
         int N = (PN & 0xF) + 1;    //N是低4位描述对应类型的数量，这里要加1是因为格式的数量是从0个开始计算，也就是当N为0时其实是代表有1个此类型的数量。
         
        
         //这里只对类型为3，4，5，6四种类型进行处理。
         if (P >= 3 && P <= 6)
         {
             for (int j = 0; j < N; j++)
             {
                 //因为引用外部的__block类型不是一个OC对象，因此这里跳过BLOCK_LAYOUT_BYREF,
                 //当然如果你只想打印引用外部的BLOCK_LAYOUT_STRONG则可以修改具体的条件。
                 if (P != 4)
                 {
                     //根据偏移得到引用外部对象的地址。并转化为OC对象。
                     void *refObjAddr = *(void**)(blockmemoryAddr + refObjOffset);
                     id refObj =  (__bridge id) refObjAddr;
                     //打印对象
                     NSLog(@"the refObj is:%@  type is:%d",refObj, P);
                     if ([refObj isEqual:observer] && P == 3) {
//                         NSLog(@"BlockNotification:callback for retain the observer:%@",observer);
//                         NSException* exception = [NSException exceptionWithName:@"BlockNotification" reason:[NSString stringWithFormat:@"callback retain observer:"] userInfo:nil];
//                         [exception raise];
                         return YES;
                     }
                 } else if (P == 4) {
                     //根据偏移得到引用外部对象的地址。并转化为OC对象。
                     void *aaaa = *((void **)(blockmemoryAddr + 32));
                     void *bbbb = *((void **)(aaaa + 40));
                     id refObj =  (__bridge id) bbbb;
                     //打印对象
                     NSLog(@"the refObj is:%@  type is:%d",refObj, P);
                     if ([refObj isEqual:observer]) {
//                         NSLog(@"BlockNotification:callback for retain the observer:%@",observer);
//                         NSException* exception = [NSException exceptionWithName:@"BlockNotification" reason:[NSString stringWithFormat:@"callback retain observer:"] userInfo:nil];
//                         [exception raise];
                         return YES;
                     }
                 } else {
                     NSLog(@"the type is:%d", P);
                 }
                 //因为布局中保存的是对象的指针，所以偏移要加上一个指针的大小继续获取下一个偏移。
                 refObjOffset += sizeof(void*);
             }
         }
    }
    return NO;
}
@end
