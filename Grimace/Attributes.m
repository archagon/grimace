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

/// Just a simple retry in rare case that xattrs change out from under us as we try to read them, since we call the functions twice.
/// An alternative is to initialize our buffers with a max size, but I'm not sure what that would be (and don't care to find out).
static const int kRetryCount = 5;

const NSString *kAttributeFolderIcon = @"com.apple.icon.folder#S";
const NSString *kAttributeFinderInfo = @"com.apple.FinderInfo";
const NSString *kAttributeUserTags = @"com.apple.metadata:_kMDItemUserTags";

static NSString *kAttributeFolderIconSymbolFormat = @"{\"sym\":\"%@\"}";
static NSString *kAttributeFolderIconEmojiFormat = @"{\"emoji\":\"%@\"}";

+ (NSArray<NSString *> *)attributesForURL:(NSURL *)url error:(NSError **)outError {
    int returnError = 0;
    NSArray<NSString *> *returnValue = nil;
    
    for (int i = 0; i < kRetryCount; i++) {
        returnValue = [self _attributesForURL:url error:&returnError];
        
        if (returnValue == nil && returnError == EAGAIN) {
            continue;
        } else {
            break;
        }
    }
    
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
    NSData *returnValue = nil;
    
    for (int i = 0; i < kRetryCount; i++) {
        returnValue = [self _dataForAttribute:attribute forURL:url error:&returnError];
        
        if (returnValue == nil && returnError == EAGAIN) {
            continue;
        } else {
            break;
        }
    }
    
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

+ (NSData *)finderInfoAttributeFromExistingAttribute:(NSData *)attribute withCustomIconEnabled:(BOOL)customIcon error:(NSError **)outError {
    /// Not sure if this invariant always holds. I suppose I'll fix it if it comes up.
    if (attribute.length != 32) {
        if (outError != NULL) {
            *outError = [self errorWithErrno:EINVAL];
        }
        return nil;
    }
    
    /// AKA `kHasCustomIcon`. Discovered through trial & error.
    const uint8_t expectedBit = 4;
    const NSRange expectedRange = NSMakeRange(8, 1);
    
    uint8_t existingByte = 0;
    [attribute getBytes:&existingByte range:expectedRange];
    
    uint8_t newByte = existingByte;
    if (customIcon) {
        newByte |= expectedBit;
    } else {
        newByte &= (~expectedBit);
    }
    
    NSMutableData *returnValue = [attribute mutableCopy];
    [returnValue replaceBytesInRange:expectedRange withBytes:&newByte];
    
    return returnValue;
}

+ (NSError *)errorWithErrno:(int)code {
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:nil];
}

@end
