// Argon2id for the JavaScript side, run natively.
//
// The app's own Argon2 (src/crypto/vendor/noble-argon2.js) is pure
// JavaScript. Hermes has no JIT on iOS, and at the cost every phrase key is
// stamped with — 3 passes over 64 MiB — it took about a minute on an
// iPhone 16. This is the reference C implementation, the copy Freer for Mac
// vendors (see Argon2/UPSTREAM.md); it does the same work in about a second
// and returns the same bytes. src/crypto/kdf.ts uses it when it is there.

#import <React/RCTBridgeModule.h>
#import "argon2.h"

@interface MCArgon2 : NSObject <RCTBridgeModule>
@end

static NSData *MCDataFromHex(NSString *hex) {
  if (hex.length % 2 != 0) {
    return nil;
  }
  NSMutableData *data = [NSMutableData dataWithCapacity:hex.length / 2];
  for (NSUInteger i = 0; i < hex.length; i += 2) {
    unsigned int byte = 0;
    NSScanner *scanner = [NSScanner scannerWithString:[hex substringWithRange:NSMakeRange(i, 2)]];
    if (![scanner scanHexInt:&byte] || !scanner.isAtEnd) {
      return nil;
    }
    uint8_t b = (uint8_t)byte;
    [data appendBytes:&b length:1];
  }
  return data;
}

@implementation MCArgon2

RCT_EXPORT_MODULE(MCArgon2)

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

// Off the main and JavaScript threads: the spinner keeps turning.
- (dispatch_queue_t)methodQueue {
  return dispatch_queue_create("com.mycoins.wallet.argon2", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_METHOD(argon2id:(NSString *)passwordHex
                  salt:(NSString *)saltHex
                  iterations:(double)iterations
                  memoryKiB:(double)memoryKiB
                  parallelism:(double)parallelism
                  length:(double)length
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSData *password = MCDataFromHex(passwordHex);
  NSData *salt = MCDataFromHex(saltHex);
  if (password == nil || salt == nil || length < 4 || length > 1024) {
    reject(@"argon2_input", @"Bad Argon2 input", nil);
    return;
  }
  NSMutableData *out = [NSMutableData dataWithLength:(NSUInteger)length];
  int rc = argon2id_hash_raw((uint32_t)iterations, (uint32_t)memoryKiB, (uint32_t)parallelism,
                             password.bytes, password.length,
                             salt.bytes, salt.length,
                             out.mutableBytes, out.length);
  if (rc != ARGON2_OK) {
    reject(@"argon2_failed", [NSString stringWithUTF8String:argon2_error_message(rc)], nil);
    return;
  }
  const uint8_t *bytes = out.bytes;
  NSMutableString *hex = [NSMutableString stringWithCapacity:out.length * 2];
  for (NSUInteger i = 0; i < out.length; i++) {
    [hex appendFormat:@"%02x", bytes[i]];
  }
  // The derived key is a private key: do not leave a copy behind.
  memset(out.mutableBytes, 0, out.length);
  resolve(hex);
}

@end
