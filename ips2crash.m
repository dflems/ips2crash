#import <Foundation/Foundation.h>
#import <libgen.h>

// TODO: looks like OSATransformOptionTracerURL can be used for
//   symbolication, somehow.

extern NSString * const OSATransformOptionFullReport;
extern NSString * const OSATransformResultError;
extern NSString * const OSATransformResultReport;

// Private API from OSAnalytics.framework
@interface OSALegacyXform : NSObject
+ (NSDictionary *)transformURL:(NSURL *)url options:(NSDictionary *)options;
@end

int main(int argc, char *argv[])
{
    NSString *ipsPath = nil;
    NSString *outputPath = nil;
    if (argc == 2) {
        ipsPath = @(argv[1]);
    } else if (argc == 3) {
        ipsPath = @(argv[1]);
        outputPath = @(argv[2]);
        if ([@"-" isEqualToString:outputPath]) {
            outputPath = nil;
        }
    } else {
        fprintf(stderr, "usage: %s <ips-path> [<output-path>]\n", basename(argv[0]));
        exit(1);
    }

    NSURL* ipsUrl = [NSURL fileURLWithPath:ipsPath];

    // use OSALegacyXform to transform the IPS file
    NSDictionary *options = @{OSATransformOptionFullReport: @YES};
    NSDictionary *transformed = [OSALegacyXform transformURL:ipsUrl options:options];
    if (![transformed isKindOfClass:[NSDictionary class]]) {
        fprintf(stderr, "error: unknown transformation failure\n");
        exit(1);
    }

    // handle errors
    NSError *error = transformed[OSATransformResultError];
    if (error) {
        if ([error isKindOfClass:[NSError class]]) {
            fprintf(stderr, "error: %s\n", error.localizedDescription.UTF8String);
        } else {
            fprintf(stderr, "error: unknown transformation failure\n");
        }
        exit(1);
    }

    // get transformed result
    NSString *result = transformed[OSATransformResultReport];
    if (![result isKindOfClass:[NSString class]]) {
        fprintf(stderr, "error: result missing\n");
        exit(1);
    }

    if (outputPath == nil) {
        printf("%s", result.UTF8String);
    } else {
        NSError *writeError = nil;
        BOOL didWrite = [result writeToFile:outputPath
                                 atomically:YES
                                   encoding:NSUTF8StringEncoding
                                      error:&writeError];
        if (!didWrite) {
            fprintf(
                stderr,
                "error: could not write to %s: %s\n",
                outputPath.UTF8String,
                writeError.localizedDescription.UTF8String
            );
            exit(1);
        }
    }
}
