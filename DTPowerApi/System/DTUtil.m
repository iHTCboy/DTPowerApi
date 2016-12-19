//
//  DTUtil.m
//
//  Created by Leks Zhang on 11-4-4.
//  Copyright 2011年 Leks Zhang. All rights reserved.
//

#import "DTUtil.h"

#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <sys/utsname.h>
#import <Foundation/Foundation.h>

#define LONGITUDE_METERS_PER_DEGREE (111.0*1000.0)



//暴雪MPQ HASH算法
#define HASH_MAX_LENGTH 2*1024	//最大字符串长度(字节)
typedef unsigned int DWORD;		//类型定义
static DWORD cryptTable[0x500];		//哈希表
static bool HASH_TABLE_INITED = false;
static void prepareCryptTable();
DWORD HashString(const char *lpszFileName,DWORD dwCryptIndex);


@implementation DTUtil

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth,
                                 float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth(rect) / ovalWidth;
    fh = CGRectGetHeight(rect) / ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);  // Start at lower right corner
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);  // Top right corner
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); // Top left corner
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); // Lower left corner
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // Back to lower right
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

+ (NSString *)timeIntervalSince1970:(NSTimeInterval)secs Format:(NSString*)formatestr
{
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:secs];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:formatestr];
    NSString *ret = [formatter stringFromDate:date];
    [formatter release];
    
    return ret;
}

+ (NSTimeInterval)secTimeInterValSice1970:(NSString *)string Format:(NSString *)formatestr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:formatestr];
    NSDate *date = [formatter dateFromString:string];
    
    NSTimeInterval sec = [date timeIntervalSince1970];
    [formatter release];
    
    return sec;
}

+(NSString*)timeSinceDate:(NSString*)datestr Format:(NSString*)formatestr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:formatestr];
	NSDate *pub_dt = [formatter dateFromString:datestr];
	[formatter release];
    
    return [DTUtil timeSinceDate:pub_dt];
}

+(NSString*)dateStringSinceDate:(NSDate*)date Format:(NSString*)formatestr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:formatestr];
	NSString *result = [formatter stringFromDate:date];
	[formatter release];
    
    return result;
}

+(NSString*)filterHtml:(NSString*)str
{
    if (!str) {
        return nil;
    }
    NSMutableString *ms = [NSMutableString stringWithCapacity:10];
    [ms setString:str];
    [ms replaceOccurrencesOfString:@"<p>" withString:@" " options:NSOrderedSame range:NSMakeRange(0, ms.length)];
    [ms replaceOccurrencesOfString:@"</p>" withString:@"" options:NSOrderedSame range:NSMakeRange(0, ms.length)];
    [ms replaceOccurrencesOfString:@"<br />" withString:@"\r\n" options:NSOrderedSame range:NSMakeRange(0, ms.length)];
    [ms replaceOccurrencesOfString:@"<br>" withString:@"\r\n" options:NSOrderedSame range:NSMakeRange(0, ms.length)];
    [ms replaceOccurrencesOfString:@"<br/>" withString:@"\r\n" options:NSOrderedSame range:NSMakeRange(0, ms.length)];
    //    [ms replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSOrderedSame range:NSMakeRange(0, ms.length)];
    [ms replaceOccurrencesOfString:@"&nbsp;" withString:@" " options:NSOrderedSame range:NSMakeRange(0, ms.length)];
    [ms replaceOccurrencesOfString:@"\t" withString:@" " options:NSOrderedSame range:NSMakeRange(0, ms.length)];
    [ms replaceOccurrencesOfString:@"&#" withString:@" " options:NSOrderedSame range:NSMakeRange(0, ms.length)];
    
    while ([ms hasPrefix:@"\r\n"])
    {
        [ms replaceOccurrencesOfString:@"\r\n" withString:@"" options:NSOrderedSame range:NSMakeRange(0, ms.length>5?5:ms.length)];
    }
    
    while ([ms replaceOccurrencesOfString:@"\r\n\r\n" withString:@"\r\n" options:NSOrderedSame range:NSMakeRange(0, ms.length)] > 0)
    {
        
    }
    
    while ([ms replaceOccurrencesOfString:@"\n\n" withString:@"\n" options:NSOrderedSame range:NSMakeRange(0, ms.length)] > 0)
    {
        
    }
    
    return ms;
}

//过滤HTML标签
+ (NSString *)flattenHTML:(NSString *)html {
    
	if (!html)
	{
		return nil;
	}
    
    NSScanner *theScanner;
    NSString *text = nil;
    
    theScanner = [NSScanner scannerWithString:html];
    NSString *ret = [NSString stringWithString:html];
    
    while ([theScanner isAtEnd] == NO) {
        
        // find start of tag
        [theScanner scanUpToString:@"<" intoString:NULL] ;
        
        // find end of tag
        [theScanner scanUpToString:@">" intoString:&text] ;
        
        // replace the found tag with a space
        //(you can filter multi-spaces out later if you wish)
        ret = [ret stringByReplacingOccurrencesOfString:
               [ NSString stringWithFormat:@"%@>", text]
                                             withString:@" "];
        
    } // while //
    
    return ret;
    
}

+(NSString*)hashString:(NSString*)str
{
    if (!str) {
        return nil;
    }
	char buffer[HASH_MAX_LENGTH];
	memset(buffer, 0, sizeof(char)*HASH_MAX_LENGTH);
	const char *buffer2 = [str UTF8String];
	DWORD hashCode = HashString(buffer2, 1);
	//NSLog(@`"%d", hashCode);
	return [NSString stringWithFormat:@"%u", hashCode];
}

+(BOOL)isPhoneNumber:(NSString *)_text
{
    NSMutableString *regex = [NSMutableString stringWithCapacity:50];
	
	[regex appendString:@"(^(0[0-9]{2,3}\\-)?([2-9][0-9]{6,7})+(\\-[0-9]{1,4})?$)"];
	[regex appendString:@"|(^(0[0-9]{2,3})?([2-9][0-9]{6,7})+(\\-[0-9]{1,4})?$)"];
	[regex appendString:@"|(^((\\(\\d{3}\\))|(\\d{3}\\-))?13[0-9]\\d{8})"];
	[regex appendString:@"|(15[89]\\d{8})"];
	[regex appendString:@"|(189\\d{8})"];
	
	NSPredicate *phonePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	BOOL result = [phonePredicate evaluateWithObject:_text];
    
	//NSLog(@"number:%@ result:%@", _text, rstr);
    return result;
}

+ (BOOL)isMobileNumber:(NSString *)mobileNum {
    /**
     * 手机号码
     * 移动：134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     * 联通：130,131,132,152,155,156,185,186
     * 电信：133,1349,153,180,189
     */
    NSString * MOBILE = @"^1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$";
    /**
     10         * 中国移动：China Mobile
     11         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     12         */
    NSString * CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$";
    /**
     15         * 中国联通：China Unicom
     16         * 130,131,132,152,155,156,185,186
     17         */
    NSString * CU = @"^1(3[0-2]|5[256]|8[56])\\d{8}$";
    /**
     20         * 中国电信：China Telecom
     21         * 133,1349,153,180,189
     22         */
    NSString * CT = @"^1((33|53|8[09])[0-9]|349)\\d{7}$";
    /**
     25         * 大陆地区固话及小灵通
     26         * 区号：010,020,021,022,023,024,025,027,028,029
     27         * 号码：七位或八位
     28         */
    NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
    
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    NSPredicate *regextestphs = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", PHS];
    
    if (([regextestmobile evaluateWithObject:mobileNum] == YES)
        || ([regextestcm evaluateWithObject:mobileNum] == YES)
        || ([regextestct evaluateWithObject:mobileNum] == YES)
        || ([regextestcu evaluateWithObject:mobileNum] == YES)
        || ([regextestphs evaluateWithObject:mobileNum] == YES))
    {
        return YES;
    }
    //对14开头的号码，认为是合法的
    if ([[mobileNum substringToIndex:2]isEqualToString:@"14"]) {
        return YES;
    }
    else
    {
        return NO;
    }
}

+(BOOL)isHttpURL:(NSString*)_url
{
    if ([_url hasPrefix:@"http"])
    {
        return YES;
    }
    return NO;
    NSMutableDictionary *combindedGetParams = [NSMutableDictionary dictionaryWithCapacity:10];
    
    
    NSString *regex = @"(http[s]{0,1})://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?";
    NSPredicate *urlPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    BOOL result = [urlPredicate evaluateWithObject:_url];
    return result;
}

- (BOOL) validateUrl: (NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

+(BOOL)isEmptyString:(NSString *)_str
{
    if ([_str isEqualToString:@""]) {
        return YES;
    }
    if (_str == nil) {
        return YES;
    }
    if (_str == NULL) {
        return YES;
    }
    if ((NSNull*)_str == [NSNull null]) {
        return YES;
    }
    return NO;
}

+(BOOL)isEmptyStringFilterBlank:(NSString *)_str
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@",_str];
    [string replaceOccurrencesOfString:@"\n" withString:@"" options:NSStringEnumerationByLines range:NSMakeRange(0, string.length)];
    [string replaceOccurrencesOfString:@" " withString:@"" options:NSStringEnumerationByWords range:NSMakeRange(0, string.length)];
    if (string.length == 0) {
        return YES;
    }
    return NO;
}

+(NSUInteger)theLenthOfStringFilterBlank:(NSString *)_str
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@",_str];
    [string replaceOccurrencesOfString:@"\n" withString:@"" options:NSStringEnumerationByLines range:NSMakeRange(0, string.length)];
    [string replaceOccurrencesOfString:@" " withString:@"" options:NSStringEnumerationByWords range:NSMakeRange(0, string.length)];
    return string.length;
}


+(BOOL)checkEmailInput:(NSString *)_text
{
    NSString *Regex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", Regex];
    
    return [emailTest evaluateWithObject:_text];
}

#pragma mark MAC
// Return the local MAC addy
// Courtesy of FreeBSD hackers email list
// Accidentally munged during previous update. Fixed thanks to mlamb.
+ (NSString *) macaddress
{
    static NSMutableString *MAC_ADDRESS = nil;
    
    if (MAC_ADDRESS) {
        return MAC_ADDRESS;
    }
    
    int                    mib[6];
    size_t                len;
    char                *buf;
    unsigned char        *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl    *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1/n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        free(buf);
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    // NSString *outstring = [NSString stringWithFormat:@"%x:%x:%x:%x:%x:%x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    NSString *outstring = [NSString stringWithFormat:@"%x%x%x%x%x%x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    if (outstring)
    {
        MAC_ADDRESS = [[NSMutableString stringWithCapacity:10] retain];
        [MAC_ADDRESS setString:[outstring uppercaseString]];
    }
    
    return MAC_ADDRESS;
    
}

+ (NSUInteger)hexToDec:(NSString*)hex
{
    NSUInteger dec = 0;
    NSUInteger unit = 1;
    
    for (int i=hex.length-1; i>=0; i--)
    {
        unichar c = [hex characterAtIndex:i];
        NSUInteger num = 0;
        if (c >= 'a' && c <= 'f')
        {
            num = c - 'a' + 10;
        }
        else if (c >= 'A' && c <= 'F')
        {
            num = c - 'A' + 10;
        }
        else {
            num = c - '0';
        }
        
        dec += unit * num;
        unit *= 16;
    }
    return dec;
}
@end



//生成哈希表
static void prepareCryptTable()
{
	DWORD dwHih, dwLow,seed = 0x00100001,index1 = 0,index2 = 0, i;
	for(index1 = 0; index1 < 0x100; index1++)
	{
		for(index2 = index1, i = 0; i < 5; i++, index2 += 0x100)
		{
			seed = (seed * 125 + 3) % 0x2AAAAB;
			dwHih= (seed & 0xFFFF) << 0x10;
			seed = (seed * 125 + 3) % 0x2AAAAB;
			dwLow= (seed & 0xFFFF);
			cryptTable[index2] = (dwHih| dwLow);
		}
	}
}

//生成HASH值
DWORD HashString(const char *lpszFileName,DWORD dwCryptIndex)
{
	if (!HASH_TABLE_INITED)
	{
		prepareCryptTable();
		HASH_TABLE_INITED = true;
	}
	unsigned char *key = (unsigned char *)lpszFileName;
	DWORD seed1 = 0x7FED7FED, seed2 = 0xEEEEEEEE;
	int ch;
	while(*key != 0)
	{
		ch = *key++;
		seed1 = cryptTable[(dwCryptIndex<< 8) + ch] ^ (seed1 + seed2);
		seed2 = ch + seed1 + seed2 + (seed2 << 5) + 3;
	}
	return seed1; 
}


