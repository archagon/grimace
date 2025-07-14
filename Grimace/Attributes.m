//
//  Attributes.m
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/12/25.
//

#import "Attributes.h"

#import <sys/xattr.h>

typedef void (^ABDeferBlock)(void);
static inline void _ABDeferCallback(ABDeferBlock *block) { (*block)(); }
#define _ABDeferMerge(a, b) a##b
#define _ABDeferNamed(a) _ABDeferMerge(__ABDeferVar_, a)
#define ABDefer __extension__ __attribute__((cleanup(_ABDeferCallback), unused)) ABDeferBlock _ABDeferNamed(__COUNTER__) = ^

@implementation Attributes

const NSString *kAttributeFolderIcon = @"com.apple.icon.folder#S";
const NSString *kAttributeFinderInfo = @"com.apple.FinderInfo";
const NSString *kAttributeUserTags = @"com.apple.metadata:_kMDItemUserTags";

static NSString *kAttributeFolderIconSymbolFormat = @"{\"sym\":\"%@\"}";
static NSString *kAttributeFolderIconEmojiFormat = @"{\"emoji\":\"%@\"}";

+ (NSArray<NSString *> *)attributesForURL:(NSURL *)url error:(NSError **)outError {
    int returnError = 0;
    __auto_type returnValue = [self _attributesForURL:url error:&returnError];
    
    if (returnError != 0 && outError != NULL) {
        *outError = [self errorWithErrno:returnError];
    }
    return returnValue;
}
/// Populates `error` with 0 on success and a POSIX error code on error. Returns `EAGAIN` on atomic failure.
+ (NSArray<NSString *> *)_attributesForURL:(NSURL *)url error:(int *)outError {
    __block int returnError = 0;
    ABDefer {
        if (outError != NULL) {
            *outError = returnError;
        }
    };
    
    ssize_t size = listxattr(url.path.UTF8String, NULL, 0, 0);
    
    if (size < 0) {
        returnError = errno;
        return nil;
    }
    
    if (size == 0) {
        returnError = 0;
        return @[];
    }
    
    char *buffer = calloc(size, sizeof(char));
    ABDefer {
        free(buffer);
    };
    
    ssize_t newSize = listxattr(url.path.UTF8String, buffer, size, 0);
    
    if (newSize < 0) {
        returnError = errno;
        return nil;
    }
    
    if (newSize != size) {
        returnError = EAGAIN;
        return nil;
    }
    
    NSMutableArray<NSString *> *returnArray = [NSMutableArray array];
    NSMutableData *currentData = nil;
    
    for (int i = 0; i < size; i++) {
        char c = buffer[i];
        
        if (c == 0) {
            if (currentData) {
                NSString *string = [[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding];
                [returnArray addObject:string];
            }
            currentData = nil;
        } else {
            currentData = currentData ?: [NSMutableData dataWithCapacity:size];
            [currentData appendBytes:&c length:1];
        }
    }
    
    returnError = 0;
    return returnArray;
}

+ (NSData *)dataForAttribute:(NSString *)attribute forURL:(NSURL *)url error:(NSError **)outError {
    int returnError = 0;
    __auto_type returnValue = [self _dataForAttribute:attribute forURL:url error:&returnError];
    
    if (returnError != 0 && outError != NULL) {
        *outError = [self errorWithErrno:returnError];
    }
    return returnValue;
}
/// Populates `error` with 0 on success and a POSIX error code on error. Returns `EAGAIN` on atomic failure.
+ (NSData *)_dataForAttribute:(NSString *)attribute forURL:(NSURL *)url error:(int *)outError {
    __block int returnError = 0;
    ABDefer {
        if (outError != NULL) {
            *outError = returnError;
        }
    };
    
    ssize_t size = getxattr(url.path.UTF8String, attribute.UTF8String, NULL, 0, 0, 0);
    
    if (size < 0) {
        returnError = errno;
        return nil;
    }
    
    if (size == 0) {
        returnError = 0;
        return [NSData new];
    }
    
    void *buffer = calloc(size, sizeof(void));
    ABDefer {
        free(buffer);
    };
    
    ssize_t newSize = getxattr(url.path.UTF8String, attribute.UTF8String, buffer, size, 0, 0);
    
    if (newSize < 0) {
        returnError = errno;
        return nil;
    }
    
    if (newSize != size) {
        returnError = EAGAIN;
        return nil;
    }
    
    NSData *returnData = [NSData dataWithBytes:buffer length:newSize];
    
    returnError = 0;
    return returnData;
}

+ (BOOL)removeAttribute:(NSString *)attribute fromURL:(NSURL *)url error:(NSError **)outError {
    int success = removexattr(url.path.UTF8String, attribute.UTF8String, kNilOptions);
    
    if (success < 0) {
        if (outError != NULL) {
            *outError = [self errorWithErrno:errno];
        }
        return NO;
    }
    
    return YES;
}

+ (BOOL)setData:(NSData *)data forAttribute:(NSString *)attribute forURL:(NSURL *)url error:(NSError **)outError {
    int success = setxattr(url.path.UTF8String, attribute.UTF8String, data.bytes, data.length, 0, 0);
    
    if (success < 0) {
        if (outError != NULL) {
            *outError = [self errorWithErrno:errno];
        }
        return NO;
    }
    
    return YES;
}

+ (NSData *)folderIconAttributeWithSymbolName:(NSString *)symbolName {
    return [[NSString stringWithFormat:kAttributeFolderIconSymbolFormat, symbolName] dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData *)folderIconAttributeWithText:(NSString *)text {
    return [[NSString stringWithFormat:kAttributeFolderIconEmojiFormat, text] dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData *)finderInfoAttributeToShowIconWithExistingFinderInfoAttribute:(NSData *)attribute error:(NSError **)outError {
    if (attribute.length != 32) {
        if (outError != NULL) {
            *outError = [self errorWithErrno:EINVAL];
        }
        return nil;
    }
    
    uint8_t expectedByte = 4; // found through trial & error; not sure if it should be a bit flip instead
    NSMutableData *returnValue = [attribute mutableCopy];
    [returnValue replaceBytesInRange:NSMakeRange(8, 1) withBytes:&expectedByte];
    
    return returnValue;
}

+ (NSError *)errorWithErrno:(int)code {
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:nil];
}

@end
