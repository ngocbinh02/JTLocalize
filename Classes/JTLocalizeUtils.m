 // JTLocalizeUtils.m
//
// Copyright (c) 2015 JoyTunes (http://joytunes.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "JTLocalizeUtils.h"

NSString *const kJTDefaultLocalizationBundleName = @"JTLocalizable.bundle";
NSString *const kJTDefaultStringsTableName = @"Localizable";


@interface JTLocalize()

@property (nonatomic, copy) NSString *stringsTableName;
@property (nonatomic, strong) NSBundle *localizationBundle;

@end


@implementation JTLocalize

+ (JTLocalize *)instance {
    static JTLocalize *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.stringsTableName = kJTDefaultStringsTableName;
        self.localizationBundle = [self.class defaultLocalizationBundle];
    }

    return self;
}

// Will try to find the kJTDefaultLocalizationBundleName as a resource in the app bundle.
// If not found - will use the app bundle itself.
+ (NSBundle *)defaultLocalizationBundle {
    NSBundle *appBundle = [NSBundle bundleForClass:self.class];
    NSBundle *result = [NSBundle bundleWithPath:[appBundle pathForResource:kJTDefaultLocalizationBundleName ofType:nil]];

    if (result != nil) {
        return result;
    } else {
        return appBundle;
    }

}

+ (void)setLocalizationBundleToPath:(NSString *)bundlePath stringsTableName:(NSString *)tableName {
    [self instance].stringsTableName = tableName ?: kJTDefaultStringsTableName;

    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    if (bundle != nil) {
        [self instance].localizationBundle = bundle;
    } else {
        [self instance].localizationBundle = [self defaultLocalizationBundle];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
+ (NSString *)localizedStringForKey:(NSString *)key comment:(NSString *)comment {
    NSString *localized = NSLocalizedStringFromTableInBundle(key,
                                                             [self instance].stringsTableName,
                                                             [self instance].localizationBundle,
                                                             comment);

    return localized ?: key;
}
#pragma clang diagnostic pop

@end

@implementation NSString (JTLocalizeExtensions)

- (NSString *)stringByLocalizingJTLDirectives {
    NSString *string = self;
    //Intended string : JTL\(['"](.+?)['"],\s*['"](.+?)['"]\)
    NSString *regexString = @"JTL\\(['\"](.+?)['\"],\\s*['\"](.+?)['\"]\\)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    NSTextCheckingResult *match = [regex firstMatchInString:string
                                                    options:0
                                                      range:NSMakeRange(0, string.length)];
    while (match != nil) {
        NSRange localizedKeyRange = [match rangeAtIndex:1];
        NSString *localizedKey = [string substringWithRange:localizedKeyRange];
        NSString *localizedString = localizedKey.localizedString;
        string = [string stringByReplacingCharactersInRange:match.range withString:localizedString];
        match = [regex firstMatchInString:string
                                  options:0
                                    range:NSMakeRange(0, string.length)];
    }
    
    return string;
}

- (NSString *)localizedString {
    return [JTLocalize localizedStringForKey:self comment:@""];
}

@end

@implementation NSAttributedString(JTLocalizeExtensions)

- (NSAttributedString *)localizedAttributedStringByFragments {
    NSMutableAttributedString *localizedText = self.mutableCopy;
    NSRange range;
    NSInteger startIndex = localizedText.length - 1;
    while (startIndex > 0) {
        [localizedText attributesAtIndex:(NSUInteger)startIndex effectiveRange:&range];
        NSString *fragment = [localizedText attributedSubstringFromRange:range].string;
        NSString *localizedFragment = [fragment localizedString];
        [localizedText replaceCharactersInRange:range withString:localizedFragment];
        startIndex = range.location - 1;
    }

    return localizedText;
}

- (BOOL)needsAttributedLocalization {
    if (self.length == 0) {
        return NO;
    }

    NSRange range;
    [self attributesAtIndex:0 effectiveRange:&range];
    return range.length < self.length;
}

@end

@implementation UIView(JTLocalizeExtensions)

- (void)localizeTextPropertyNamed:(NSString *)propertyName {
    NSString *attributedPropertyName = [NSString stringWithFormat:@"attributed%@", propertyName.capitalizedString];
    NSAttributedString *attributedText = [self valueForKey:attributedPropertyName];
    if (attributedText.needsAttributedLocalization) {
        [self setValue:attributedText.localizedAttributedStringByFragments
                forKey:attributedPropertyName];
    } else {
        NSString *text = [self valueForKey:propertyName];
        [self setValue:text.localizedString forKey:propertyName];
    }
}

@end
