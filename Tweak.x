#import <dlfcn.h>
#import <UIKit/UIKit.h>
#include <notify.h>
#include <objc/message.h>
#import "FLEXManager.h"

@interface UIStatusBarWindow : UIWindow @end

__attribute__((visibility("hidden")))

@interface UIWindow (PrivateAutoFLEX)
@property (nonatomic, strong) UILongPressGestureRecognizer *flexAllLongPress;
@end

@interface AutoFLEX : NSObject
+(instancetype)sharedInstance;
-(void)show;
@end

@implementation AutoFLEX

+ (instancetype)sharedInstance
{
    static AutoFLEX *_sharedFactory;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedFactory = [[self alloc] init];
    });

    return _sharedFactory;
}

- (id)init
{
    self = [super init];
    return self;
}

-(void)show {
	FLEXManager *manager = [FLEXManager sharedManager];
	// SEL showSelector = NSSelectorFromString(@"showExplorer");
	// SEL showSelector = @selector(showExplorer);
	if (manager != nil)
		[manager performSelector:@selector(showExplorer)];
}

-(void)inject {
	NSLog(@"Openning explorer: %@", [FLEXManager sharedManager]);
	[[FLEXManager sharedManager] showExplorer];
}
@end

static UILongPressGestureRecognizer *RegisterLongPressGesture(UIWindow *window, NSUInteger fingers) {
	UILongPressGestureRecognizer *longPress = nil;
	// Class flexWindowClass = GetFLXWindowClass();
	// if (flexWindowClass == nil || ![window isKindOfClass:flexWindowClass]) {
		longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:[AutoFLEX sharedInstance] action:@selector(show)];
		longPress.numberOfTouchesRequired = fingers;
		[window addGestureRecognizer:longPress];
	// }
	return longPress;
}

%hook UIWindow
%property (nonatomic, strong) UILongPressGestureRecognizer *flexAllLongPress;

-(void)becomeKeyWindow {
	%orig();

	if (self.flexAllLongPress == nil) {
		self.flexAllLongPress = RegisterLongPressGesture(self, 3);
	}
}

-(void)resignKeyWindow {
	if (self.flexAllLongPress != nil) {
		[self removeGestureRecognizer:self.flexAllLongPress];
		self.flexAllLongPress = nil;
	}

	%orig();
}
%end

%hook UIStatusBarWindow
- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(inject:)]];
    return self;
}

-(void) inject: (UILongPressGestureRecognizer*)lges {
    [[FLEXManager sharedManager] showExplorer];
}
%end

%ctor {
	%init();
    // [[NSNotificationCenter defaultCenter] addObserver:[AutoFLEX sharedInstance] selector:@selector(inject) name:UIApplicationDidBecomeActiveNotification object:nil];
}
