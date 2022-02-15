
#import <Foundation/Foundation.h>
#import "PendoOptions.h"

@interface PendoInitParams : NSObject

/** @brief The visitor's id */
@property (nonatomic, copy, nullable) NSString *visitorId;

/** @brief The account's id */
@property (nonatomic, copy, nullable) NSString *accountId;

/** @brief The data that are used by Pendo Mobile visitor level data. */
@property (nonatomic, copy, nullable) NSDictionary *visitorData;

/** @brief the data that are used by Pendo Mobile for account level data. */
@property (nonatomic, copy, nullable) NSDictionary *accountData;

/** @brief additional options for pendo initialization. */
@property (nonatomic, copy, nullable) PendoOptions *options;

- (instancetype _Nonnull)init NS_DESIGNATED_INITIALIZER;

@end
