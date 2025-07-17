//
//  Attributes.h
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/12/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Attributes : NSObject

extern const NSString *kAttributeFolderIcon;
extern const NSString *kAttributeFinderInfo;
extern const NSString *kAttributeUserTags;

+ (nullable NSArray<NSString *> *)attributesForURL:(NSURL *)url error:(NSError **)outError;
+ (nullable NSData *)dataForAttribute:(NSString *)attribute forURL:(NSURL *)url error:(NSError **)outError;
+ (BOOL)removeAttribute:(NSString *)attribute fromURL:(NSURL *)url error:(NSError **)outError;
+ (BOOL)setData:(NSData *)data forAttribute:(NSString *)attribute forURL:(NSURL *)url error:(NSError **)outError;

+ (NSData *)folderIconAttributeWithSymbolName:(NSString *)symbolName;
+ (NSData *)folderIconAttributeWithText:(NSString *)text;
+ (nullable NSData *)finderInfoAttributeFromExistingAttribute:(NSData *)attribute withCustomIconEnabled:(BOOL)customIcon error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
