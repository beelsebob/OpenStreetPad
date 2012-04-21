/*
 PSYEnumerable.m
 Created by Remy "Psy" Demarest on 21/4/2012.
 
 Copyright (c) 2012. Remy "Psy" Demarest
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "PSYEnumerable.h"

#define OBJECT_BUFFER_SIZE 8 /* I don't necessary want to allocate too much memory there... */

typedef struct _PSYMultiEnumState {
__unsafe_unretained id objectsBuf[OBJECT_BUFFER_SIZE]; 
NSFastEnumerationState state;
unsigned long          mutationPtrValue;
NSUInteger             count;
NSUInteger             position;
} PSYMultiEnumState;

void PSYMultiDictionaryEnumerator(NSArray *enumaratedDicts, BOOL finishAll, void(^block)(id key, __unsafe_unretained const id *objects, BOOL *stop))
{
    const NSUInteger count = [enumaratedDicts count];
    
    if(count == 0) return;
    
    __unsafe_unretained id *objects = (__unsafe_unretained id *)calloc(count, sizeof(*objects));
    
    __unsafe_unretained NSDictionary **enumerables = (__unsafe_unretained id *)calloc(count, sizeof(id));
    [enumaratedDicts getObjects:enumerables range:NSMakeRange(0, count)];
    
    NSMutableSet *alreadyDone = finishAll ? [NSMutableSet setWithCapacity:[enumerables[0] count]] : nil;
    
    PSYMultiEnumState currentState = { 0 };
    
    BOOL stop = NO, isFirstLoop __unused = YES;
    
    for(NSUInteger baseIdx = 0; baseIdx < count; baseIdx++)
    {
        currentState = (PSYMultiEnumState){ 0 };
        while((currentState.count = [enumerables[baseIdx] countByEnumeratingWithState:&currentState.state objects:currentState.objectsBuf count:OBJECT_BUFFER_SIZE]))
        {
            for(NSUInteger i = 0; i < currentState.count; i++)
            {
                id key = currentState.state.itemsPtr[i];
                
                if([alreadyDone containsObject:key]) continue;
                [alreadyDone addObject:key];
                
                BOOL shouldEnumerate = YES;
                
                for(NSUInteger j = baseIdx; j < count; j++)
                {
                    objects[j] = [enumerables[j] objectForKey:key];
                    
                    if(!finishAll && objects[j] == nil)
                    {
                        shouldEnumerate = NO;
                        break;
                    }
                }
                
                if(shouldEnumerate) block(key, objects, &stop);
                
                if(stop) break;
            }
            
            if(stop) break;
        }
        
        if(stop || !finishAll) break;
        
        // This value at this index will remain nil until the end of the whole enumeration
        objects[baseIdx] = nil;
    }
    
    free(objects);
    free(enumerables);
}

void PSYMultiEnumerator(NSArray *enumerated, BOOL finishAll, void(^block)(__unsafe_unretained const id *objects, BOOL *stop))
{
    const NSUInteger count = [enumerated count];
    
    if(count == 0) return;
    
    PSYMultiEnumState      *states  = calloc(count, sizeof(*states));
    __unsafe_unretained id *objects = (__unsafe_unretained id *)calloc(count, sizeof(*objects));
    
    __unsafe_unretained id<NSObject, NSFastEnumeration> *enumerables = (__unsafe_unretained id *)calloc(count, sizeof(id));
    [enumerated getObjects:enumerables range:NSMakeRange(0, count)];
    
    BOOL stop = NO, isFirstLoop = YES;
    
    while(YES)
    {
        BOOL hasNonZeroCount = NO;
        
        // Update each enumeration states
        for(NSUInteger i = 0; i < count; i++)
        {
            if(states[i].position >= states[i].count)
            {
                // Sentinel to avoid calling the count method over and over
                if(states[i].count == 0 && states[i].position == NSNotFound) continue;
                
                states[i].count = [enumerables[i] countByEnumeratingWithState:&states[i].state objects:states[i].objectsBuf count:OBJECT_BUFFER_SIZE];
                
                if(states[i].count == 0)
                {
                    states[i].position = NSNotFound;
                    
                    if(!finishAll)
                    {
                        hasNonZeroCount = NO;
                        break;
                    }
                }
                else
                {
                    states[i].position = 0;
                    
                    if(!isFirstLoop && states[i].mutationPtrValue != *states[i].state.mutationsPtr)
                        @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"Collection <%@: %p> was mutated while being enumerated.", [enumerables[i] class], enumerables[i]] userInfo:nil];
                    
                    hasNonZeroCount = YES;
                }
            }
            else hasNonZeroCount = YES;
            
            objects[i] = (states[i].position < states[i].count ? states[i].state.itemsPtr[states[i].position++] : nil);
        }
        
        // All enumeratable objects returned 0, we're done enumerating
        if(!hasNonZeroCount) break;
        
        block(objects, &stop);
        
        if(stop) break;
    }
    
    free(states);
    free(objects);
    free(enumerables);
}

NSArray *PSYZipCollections(NSArray *collections, BOOL finishAll, id(^block)(__unsafe_unretained const id *objects, BOOL *stop))
{
    if([collections count] == 0) return [NSArray array];
    
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[[collections objectAtIndex:0] count]];
    
    PSYMultiEnumerator(collections, finishAll, ^(__unsafe_unretained id const *objects, BOOL *stop) {
        [ret addObject:block(objects, stop)];
    });
    
    return ret;
}

NSDictionary *PSYZipDictionaries(NSArray *dicts, BOOL finishAll, id(^block)(id key, __unsafe_unretained const id *objects, BOOL *stop))
{
    if([dicts count] == 0) return [NSDictionary dictionary];
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:[[dicts objectAtIndex:0] count]];
    
    PSYMultiDictionaryEnumerator(dicts, finishAll, ^(id key, __unsafe_unretained id const *objects, BOOL *stop) {
        [ret setObject:block(key, objects, stop) forKey:key];
    });
    
    return ret;
}