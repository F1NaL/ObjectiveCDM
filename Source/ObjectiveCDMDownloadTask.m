//
//  ObjectiveCDMDownloadTask.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import "ObjectiveCDMDownloadTask.h"

@implementation ObjectiveCDMDownloadTask

- (instancetype) initWithURLString:(NSString *)urlString
                   withDestination:(NSString *)destination
     andTotalBytesExepectedToWrite:(int64_t)totalBytesExpectedToWriteInput
                       andChecksum:(NSString *)checksum
              andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput {
    self = [super init];
    if(self) {
        [self commonInstructor:urlString
               withDestination:destination
 andTotalBytesExepectedToWrite:totalBytesExpectedToWriteInput
                   andChecksum:checksum
          andFileHashAlgorithm:fileHashAlgorithmInput];
        self.url = [[NSURL alloc] initWithString:urlString];
        self.totalBytesExpectedToWrite = totalBytesExpectedToWriteInput;
    }//end if
    return self;
}

- (instancetype) initWithURL:(NSURL *)url
             withDestination:(NSString *)destination
andTotalBytesExepectedToWrite:(int64_t)totalBytesExpectedToWriteInput
                 andChecksum:(NSString *)checksum
        andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput {
    self = [super init];
    if(self) {
        [self commonInstructor:[url absoluteString]
               withDestination:destination
 andTotalBytesExepectedToWrite:totalBytesExpectedToWriteInput
                   andChecksum:checksum
          andFileHashAlgorithm:fileHashAlgorithmInput];
        self.url = url;
    }
    
    return self;
}

- (void) commonInstructor:(NSString *)urlString
          withDestination:(NSString *)destination
andTotalBytesExepectedToWrite:(int64_t)totalBytesExpectedToWriteInput
              andChecksum:(NSString *)checksum
     andFileHashAlgorithm:(FileHashAlgorithm)algorithm {
    self.completed = NO;
    self.totalBytesWritten = 0;
    self.totalBytesExpectedToWrite = totalBytesExpectedToWriteInput;
    self.urlString = urlString;
    self.checkSum = checksum;
    fileHashAlgorithm = algorithm;
   
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    self.destination = [NSString stringWithFormat:@"%@/%@", documentDirectory, destination];
    self.fileName = [self.destination lastPathComponent];
    [self prepareFolderForDestination];
}

- (float) downloadingProgress {
    if(self.totalBytesExpectedToWrite > 0) {
        return (double)self.totalBytesWritten / (double)self.totalBytesExpectedToWrite;
    } else {
        return 0;
    }
}

- (void) prepareFolderForDestination {
    NSString *containerFolderPath = [self.destination stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![[NSFileManager defaultManager] fileExistsAtPath:containerFolderPath]){
        NSError* createDirectoryError;
        if([fileManager createDirectoryAtPath:containerFolderPath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError]) {
        }//end if
        if(createDirectoryError) {
            NSLog(@"Create Directory Error: %@", [createDirectoryError localizedDescription]);
        }//end if

    }//end if
    
    [self cleanUp];
}

- (BOOL) verifyDownload {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // file does not exist as expected location
    if([fileManager fileExistsAtPath:self.destination] == NO) {
        return NO;
    }//end if
    
    BOOL isVerified = NO;
    if(self.checkSum) {
        NSString *calculatedChecksum = [self retrieveChecksumOfDownloadedFile];
        isVerified = [calculatedChecksum isEqualToString:self.checkSum];
    } else { // check for file size
        NSError *attributesError;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:self.destination error:&attributesError];
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        int64_t fileSize = [fileSizeNumber longLongValue];
        isVerified = (fileSize == self.totalBytesExpectedToWrite);
    }
    if(isVerified) {
        self.completed = YES;
    }//end if
    return isVerified;
}

- (NSString *) retrieveChecksumOfDownloadedFile {
    if(fileHashAlgorithm == FileHashAlgorithmMD5) {
        return [FileHash md5HashOfFileAtPath:self.destination];
    } else if(fileHashAlgorithm == FileHashAlgorithmSHA1) {
        return [FileHash sha1HashOfFileAtPath:self.destination];
    } else if(fileHashAlgorithm == FileHashAlgorithmSHA1) {
        return [FileHash sha512HashOfFileAtPath:self.destination];
    }//end else
    
    return nil;
}

- (void) cleanUp {
    self.completed = NO;
    self.totalBytesWritten = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *removeFileError;
    if([fileManager fileExistsAtPath:self.destination]) {
        [fileManager removeItemAtPath:self.destination error:&removeFileError];
    }//end if
    if(removeFileError) {
        NSLog(@"Removing Existing File Error: %@", [removeFileError localizedDescription]);
    }//end if
}

@end