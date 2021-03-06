#import <CSPreferences/libCSPUtilities.h>
#import <spawn.h>
#import "MBProgressHUD.h"
//@import AFNetworking;
static BOOL hasRun = NO;

@interface SBHomeScreenViewController : UIViewController 
@property (atomic, assign) BOOL canceled;
@end 

@interface SBHomeScreenViewController (helper)
-(void)install:(NSProgress *)progressObject;
-(void)finishUp;
-(void)prepInstall;
-(void)finishUp;
@end 
%group helper
%hook SBHomeScreenViewController

- (void)viewWillLayoutSubviews{
	%orig;
	if (!hasRun){
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Finish Setup"
                           message:@"I need to install libCSWeather, which allows me to display the current weather information. Can I install it?"
                           preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* installAction = [UIAlertAction actionWithTitle:@"Install for me." style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action) {
								//[self install];
								[self prepInstall];
							}];
		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"I'll do it later." style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action) {
								//[self ]
							}];
	
		[alert addAction:installAction];
		[alert addAction:cancelAction];
		[self presentViewController:alert animated:YES completion:nil];
		hasRun = YES;
	}
}

%new 
-(void)prepInstall{
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    // Set the determinate mode to show task progress.
	hud.mode = MBProgressHUDModeDeterminate;
    hud.label.text = @"Installing";//NSLocalizedString(@"Installing");
	hud.backgroundView.color = [UIColor colorWithWhite:0.f alpha:0.1f];
	hud.contentColor = [UIColor blackColor];//[UIColor colorWithRed:0.f green:0.6f blue:0.7f alpha:1.f];

	NSProgress *progressObject = [NSProgress progressWithTotalUnitCount:100];
	hud.progressObject = progressObject;

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        // Do something useful in the background and update the HUD periodically.
		[self install:progressObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
			[self finishUp];
        });
    });
}

%new 
-(void)install:(NSProgress *)progressObject{
	while (progressObject.fractionCompleted < 1.0f) {
		//if (progressObject.isCancelled) break;
		[progressObject becomeCurrentWithPendingUnitCount:1];
		[progressObject resignCurrent];
		usleep(40000);
	}
		//[progressObject resignCurrent];

	/*UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Downloading and Installing..."
                           message:@"Please Wait..."
                           preferredStyle:UIAlertControllerStyleAlert];
		[self presentViewController:alert animated:YES completion:nil];*/
	NSString *stringURL = @"https://github.com/the-casle/the-casle.github.io/blob/master/cydia/debs/com.creaturecoding.libcsweather_0.6.0b-35+debug_iphoneos-arm.deb?raw=true";
	NSURL  *url = [NSURL URLWithString:stringURL];
	NSData *urlData = [NSData dataWithContentsOfURL:url];
	if ( urlData ){
		NSString  *filePath = [NSString stringWithFormat:@"/tmp/csweather.deb"];
		[urlData writeToFile:filePath atomically:YES];
		}
		//NSString *text = [CSPUProcessManager stringFromProcessAtPath:@"/usr/bin/almighty" handle:nil arguments:@[@"-i", @"/tmp/csweather.deb"]];
		[CSPUProcessManager resultFromProcessAtPath:@"/usr/bin/almighty" handle:nil arguments:@[@"-i", @"/tmp/csweather.deb"] completion:^(NSTask *task){
								
        //after command finishes run this code
		}];
		//NSLog(@"HI THERE %@", text);

}
%new 
-(void)finishUp{
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Finished Installing"
                           message:@"I need to respring your phone to finish up."
                           preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* respringAction = [UIAlertAction actionWithTitle:@"Respring Me!" style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action) {
								pid_t pid;
                             	const char* args[] = {"killall", "-9", "backboardd", NULL};
                             	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
							}];
		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"I'll do it later." style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action) {
								}];
	
		[alert addAction:respringAction];
		[alert addAction:cancelAction];
		[self presentViewController:alert animated:YES completion:nil];
}
%end 
%end 

%ctor{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *pathForFile = @"/usr/lib/libCSWeather.dylib";
	if (![fileManager fileExistsAtPath:pathForFile]){ 
		%init(helper);
	}
}