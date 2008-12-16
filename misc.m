#import "misc.h"

@implementation NSArray (Footsie)

- (id)randomObject
{
    return [self objectAtIndex:rand() % [self count]];
}

@end

@implementation NSSet (Footsie)

- (id)randomObject
{
    return [[self allObjects] randomObject];
}

@end

