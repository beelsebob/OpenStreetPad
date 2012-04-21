/*
 PSYEnumerable.h
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

void PSYMultiDictionaryEnumerator(NSArray *enumaratedDicts, BOOL finishAll, void(^block)(id key, __unsafe_unretained const id *objects, BOOL *stop));
void PSYMultiEnumerator(NSArray *enumerated, BOOL finishAll, void(^block)(__unsafe_unretained const id *objects, BOOL *stop));

NSArray *PSYZipCollections(NSArray *collections, BOOL finishAll, id(^block)(__unsafe_unretained const id *objects, BOOL *stop));
NSDictionary *PSYZipDictionaries(NSArray *dicts, BOOL finishAll, id(^block)(id key, __unsafe_unretained const id *objects, BOOL *stop));
