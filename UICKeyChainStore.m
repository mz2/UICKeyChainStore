//
//  UICKeyChainStore.m
//  UICKeyChainStore
//
//  Created by Kishikawa Katsumi on 11/11/20.
//  Copyright (c) 2011 Kishikawa Katsumi. All rights reserved.
//

#import "UICKeyChainStore.h"

static NSString *defaultService;

@interface UICKeyChainStore () {
    NSMutableDictionary *itemsToUpdate;
}

@end

@implementation UICKeyChainStore

@synthesize service;
@synthesize accessGroup;

+ (void)initialize {
    defaultService = [[[NSBundle mainBundle] bundleIdentifier] retain];
}

+ (NSString *)stringForKey:(NSString *)key {
    return [self stringForKey:key service:defaultService accessGroup:nil];
}

+ (NSString *)stringForKey:(NSString *)key service:(NSString *)service {
    return [self stringForKey:key service:service accessGroup:nil];
}

+ (NSString *)stringForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
    NSData *data = [self dataForKey:key service:service accessGroup:accessGroup];
    if (data) {
        return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }
    return nil;
}

+ (void)setString:(NSString *)value forKey:(NSString *)key {
    [self setString:value forKey:key service:defaultService accessGroup:nil];
}

+ (void)setString:(NSString *)value forKey:(NSString *)key service:(NSString *)service {
    [self setString:value forKey:key service:service accessGroup:nil];
}

+ (void)setString:(NSString *)value forKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    [self setData:data forKey:key service:service accessGroup:accessGroup];
}

+ (NSData *)dataForKey:(NSString *)key {
    return [self dataForKey:key service:defaultService accessGroup:nil];
}

+ (NSData *)dataForKey:(NSString *)key service:(NSString *)service {
    return [self dataForKey:key service:service accessGroup:nil];
}

+ (NSData *)dataForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!key) {
        NSAssert(NO, @"key must not be nil.");
		return nil;
	}
	if (!service) {
        service = defaultService;
	}
    
	NSMutableDictionary* query = [NSMutableDictionary dictionary];
	query[(id)kSecClass] = kSecClassGenericPassword;
	query[(id)kSecReturnData] = (id)kCFBooleanTrue;
	query[(id)kSecMatchLimit] = kSecMatchLimitOne;
	query[(id)kSecAttrService] = service;
    query[(id)kSecAttrGeneric] = key;
    query[(id)kSecAttrAccount] = key;
#if !TARGET_IPHONE_SIMULATOR && defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    if (accessGroup) {
        [query setObject:accessGroup forKey:kSecAttrAccessGroup];
    }
#endif
    
	NSData *data = nil;
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&data);
	if (status != errSecSuccess) {
        return nil;
	}
    
    return [data autorelease];
}

+ (void)setData:(NSData *)data forKey:(NSString *)key {
    [self setData:data forKey:key service:defaultService accessGroup:nil];
}

+ (void)setData:(NSData *)data forKey:(NSString *)key service:(NSString *)service {
    [self setData:data forKey:key service:service accessGroup:nil];
}

+ (void)setData:(NSData *)data forKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!key) {
        NSAssert(NO, @"key must not be nil.");
		return;
	}
	if (!service) {
        service = defaultService;
	}
	
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	query[(id)kSecClass] = kSecClassGenericPassword;
	query[(id)kSecAttrService] = service;
    query[(id)kSecAttrGeneric] = key;
    query[(id)kSecAttrAccount] = key;
#if !TARGET_IPHONE_SIMULATOR && defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    if (accessGroup) {
        [query setObject:accessGroup forKey:kSecAttrAccessGroup];
    }
#endif
    
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, NULL);
	if (status == errSecSuccess) {
        if (data) {
            NSMutableDictionary *attributesToUpdate = [NSMutableDictionary dictionary];
            attributesToUpdate[(id)kSecValueData] = data;
            
            status = SecItemUpdate((CFDictionaryRef)query, (CFDictionaryRef)attributesToUpdate);
            if (status != errSecSuccess) {
                NSLog(@"%s|SecItemUpdate: error(%d)", __func__, status);
            }
        } else {
            [self removeItemForKey:key service:service accessGroup:accessGroup];
        }
	} else if (status == errSecItemNotFound) {
		NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
		attributes[(id)kSecClass] = kSecClassGenericPassword;
        attributes[(id)kSecAttrService] = service;
        attributes[(id)kSecAttrGeneric] = key;
        attributes[(id)kSecAttrAccount] = key;
		attributes[(id)kSecValueData] = data;
#if !TARGET_IPHONE_SIMULATOR && defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        if (accessGroup) {
            [attributes setObject:accessGroup forKey:kSecAttrAccessGroup];
        }
#endif
		
		status = SecItemAdd((CFDictionaryRef)attributes, NULL);
		if (status != errSecSuccess) {
			NSLog(@"%s|SecItemAdd: error(%d)", __func__, status);
		}		
	} else {
		NSLog(@"%s|SecItemCopyMatching: error(%d)", __func__, status);
	}
}

+ (void)removeItemForKey:(NSString *)key {
    [UICKeyChainStore removeItemForKey:key service:defaultService accessGroup:nil];
}

+ (void)removeItemForKey:(NSString *)key service:(NSString *)service {
    [UICKeyChainStore removeItemForKey:key service:service accessGroup:nil];
}

+ (void)removeItemForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!key) {
        NSAssert(NO, @"key must not be nil.");
		return;
	}
	if (!service) {
        service = defaultService;
	}
	
	NSMutableDictionary *itemToDelete = [NSMutableDictionary dictionary];
	itemToDelete[(id)kSecClass] = kSecClassGenericPassword;
	itemToDelete[(id)kSecAttrService] = service;
    itemToDelete[(id)kSecAttrGeneric] = key;
    itemToDelete[(id)kSecAttrAccount] = key;
#if !TARGET_IPHONE_SIMULATOR && defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    if (accessGroup) {
        [itemToDelete setObject:accessGroup forKey:kSecAttrAccessGroup];
    }
#endif
	
	OSStatus status = SecItemDelete((CFDictionaryRef)itemToDelete);
	if (status != errSecSuccess && status != errSecItemNotFound) {
		NSLog(@"%s|SecItemDelete: error(%d)", __func__, status);
	}
}

+ (NSArray *)itemsForService:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!service) {
        service = defaultService;
	}
	
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	query[(id)kSecClass] = kSecClassGenericPassword;
	query[(id)kSecReturnAttributes] = (id)kCFBooleanTrue;
	query[(id)kSecReturnData] = (id)kCFBooleanTrue;
	query[(id)kSecMatchLimit] = kSecMatchLimitAll;
	query[(id)kSecAttrService] = service;
#if !TARGET_IPHONE_SIMULATOR && defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    if (accessGroup) {
        [query setObject:accessGroup forKey:kSecAttrAccessGroup];
    }
#endif
	
	CFArrayRef result = nil;
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&result);
	if (status == errSecSuccess || status == errSecItemNotFound) {
		return [(NSArray *)result autorelease];
	} else {
		NSLog(@"%s|SecItemCopyMatching: error(%d)", __func__, status);
		return nil;
	}
}

+ (void)removeAllItems {
    [self removeAllItemsForService:defaultService accessGroup:nil];
}

+ (void)removeAllItemsForService:(NSString *)service {
    [self removeAllItemsForService:service accessGroup:nil];
}

+ (void)removeAllItemsForService:(NSString *)service accessGroup:(NSString *)accessGroup {
    NSArray *items = [UICKeyChainStore itemsForService:service accessGroup:accessGroup];    
    for (NSDictionary *item in items) {
        NSMutableDictionary *itemToDelete = [NSMutableDictionary dictionaryWithDictionary:item];
        itemToDelete[(id)kSecClass] = kSecClassGenericPassword;
        
        OSStatus status = SecItemDelete((CFDictionaryRef)itemToDelete);
        if (status != errSecSuccess) {
            NSLog(@"%s|SecItemDelete: error(%d)", __func__, status);
            NSLog(@"%@", itemToDelete);
        }
    }
}

#pragma mark -

+ (UICKeyChainStore *)keyChainStore {
    return [[[self alloc] initWithService:defaultService] autorelease];
}

+ (UICKeyChainStore *)keyChainStoreWithService:(NSString *)service {
    return [[[self alloc] initWithService:service] autorelease];
}

+ (UICKeyChainStore *)keyChainStoreWithService:(NSString *)service accessGroup:(NSString *)accessGroup {
    return [[[self alloc] initWithService:service accessGroup:accessGroup] autorelease];
}

- (id)init {
    return [self initWithService:defaultService accessGroup:nil];
}

- (id)initWithService:(NSString *)s {
    return [self initWithService:s accessGroup:nil];
}

- (id)initWithService:(NSString *)s accessGroup:(NSString *)group {
    self = [super init];
    if (self) {
        if (!s) {
            s = defaultService;
        }
        service = [s copy];
        accessGroup = [group copy];
        if (accessGroup) {
#if !TARGET_IPHONE_SIMULATOR && defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
            [itemsToUpdate setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
#endif
        }
		
        NSMutableDictionary *query = [NSMutableDictionary dictionaryWithDictionary:itemsToUpdate];
        query[(id)kSecMatchLimit] = (id)kSecMatchLimitAll;
        query[(id)kSecReturnAttributes] = (id)kCFBooleanTrue;
        
        NSMutableDictionary *result = nil;
        OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&result);
        if (status == errSecSuccess) {
            itemsToUpdate = [[NSMutableDictionary alloc] initWithDictionary:result];
		} else {
            itemsToUpdate = [[NSMutableDictionary alloc] init];
        }
        [result release];
    }
    return self;
}

- (void)dealloc {
    [service release];
    [accessGroup release];
    [itemsToUpdate release];
    [super dealloc];
}

#pragma mark -

- (NSString *)description {
    NSArray *items = [UICKeyChainStore itemsForService:service accessGroup:accessGroup];
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:[items count]];    
    for (NSDictionary *attributes in items) {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
        attrs[@"Service"] = attributes[(id)kSecAttrService];
        attrs[@"Account"] = attributes[(id)kSecAttrAccount];
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        [attrs setObject:[attributes objectForKey:kSecAttrAccessGroup] forKey:@"AccessGroup"];
#endif
        NSData *data = attributes[(id)kSecValueData];
        NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        if (string) {
            attrs[@"Value"] = string;
        } else {
            attrs[@"Value"] = data;
        }
        [list addObject:attrs];
    }
    return [list description];
}

#pragma mark -

- (void)setString:(NSString *)string forKey:(NSString *)key {
    [self setData:[string dataUsingEncoding:NSUTF8StringEncoding] forKey:key];
}

- (NSString *)stringForKey:(id)key {
    NSData *data = [self dataForKey:key];
    if (data) {
        return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }
    return nil;
}

- (void)setData:(NSData *)data forKey:(NSString *)key {
    if (!key) {
        return;
    }
    if (!data) {
        [self removeItemForKey:key];
    } else {
        itemsToUpdate[key] = data;
    }
}

- (NSData *)dataForKey:(NSString *)key {
    NSData *data = itemsToUpdate[key];
    if (!data) {
        data = [[self class] dataForKey:key service:service accessGroup:accessGroup];
    }
    return data;
}

- (void)removeItemForKey:(NSString *)key {
    if (itemsToUpdate[key]) {
        [itemsToUpdate removeObjectForKey:key];
    } else {
        [[self class] removeItemForKey:key service:service accessGroup:accessGroup];
    }
}

#pragma mark -

- (void)removeAllItems {
    [itemsToUpdate removeAllObjects];
    [[self class] removeAllItemsForService:service accessGroup:accessGroup];
}

#pragma mark -

- (void)synchronize {    
    for (NSString *key in itemsToUpdate) {
        [[self class] setData:itemsToUpdate[key] forKey:key service:service accessGroup:accessGroup];
    }
}

@end
