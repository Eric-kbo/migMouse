#import "MMMultitouchBridge.h"

#import <dlfcn.h>

typedef CFArrayRef (*MMCreateDeviceListFunction)(void);
typedef void (*MMRegisterCallbackFunction)(MMMTDeviceRef, MMMTFrameCallback, void *);
typedef void (*MMUnregisterCallbackFunction)(MMMTDeviceRef, MMMTFrameCallback, void *);
typedef int32_t (*MMStartDeviceFunction)(MMMTDeviceRef, int32_t);
typedef void (*MMStopDeviceFunction)(MMMTDeviceRef);
typedef bool (*MMIsBuiltInFunction)(MMMTDeviceRef);
typedef int32_t (*MMGetFamilyIDFunction)(MMMTDeviceRef, int32_t *);

@interface MMMultitouchBridge () {
    void *_framework;
    MMUnregisterCallbackFunction _unregisterCallback;
    MMStopDeviceFunction _stopDevice;
    NSMutableArray<NSValue *> *_devices;
}

@property(nonatomic, copy) MMTouchFrameBlock frameHandler;
@property(nonatomic, readwrite, getter=isRunning) BOOL running;
@property(nonatomic, readwrite) NSInteger activeDeviceCount;
@property(nonatomic, copy, readwrite) NSString *statusMessage;

- (void)receiveTouches:(const MMMTouch *)touches
                 count:(NSInteger)count
             timestamp:(double)timestamp;

@end


static void MMFrameworkCallback(MMMTDeviceRef device,
                                MMMTouch *touches,
                                size_t count,
                                double timestamp,
                                size_t frame,
                                void *context) {
    (void)device;
    (void)frame;
    MMMultitouchBridge *bridge = (__bridge MMMultitouchBridge *)context;
    [bridge receiveTouches:touches count:(NSInteger)count timestamp:timestamp];
}


@implementation MMMultitouchBridge

- (instancetype)init {
    self = [super init];
    if (self) {
        _devices = [NSMutableArray array];
        _statusMessage = NSLocalizedString(@"not_started", nil);
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

- (BOOL)startWithFrameHandler:(MMTouchFrameBlock)handler {
    if (self.running) {
        self.frameHandler = handler;
        return YES;
    }

    static const char *path = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport";
    _framework = dlopen(path, RTLD_NOW | RTLD_LOCAL);
    if (!_framework) {
        self.statusMessage = NSLocalizedString(@"framework_load_failed", nil);
        return NO;
    }

    MMCreateDeviceListFunction createDeviceList =
        (MMCreateDeviceListFunction)dlsym(_framework, "MTDeviceCreateList");
    MMRegisterCallbackFunction registerCallback =
        (MMRegisterCallbackFunction)dlsym(_framework, "MTRegisterContactFrameCallbackWithRefcon");
    _unregisterCallback =
        (MMUnregisterCallbackFunction)dlsym(_framework, "MTUnregisterContactFrameCallbackWithRefcon");
    MMStartDeviceFunction startDevice =
        (MMStartDeviceFunction)dlsym(_framework, "MTDeviceStart");
    _stopDevice = (MMStopDeviceFunction)dlsym(_framework, "MTDeviceStop");
    MMIsBuiltInFunction isBuiltIn =
        (MMIsBuiltInFunction)dlsym(_framework, "MTDeviceIsBuiltIn");
    MMGetFamilyIDFunction getFamilyID =
        (MMGetFamilyIDFunction)dlsym(_framework, "MTDeviceGetFamilyID");

    if (!createDeviceList || !registerCallback || !startDevice || !_stopDevice) {
        self.statusMessage = NSLocalizedString(@"framework_symbols_unavailable", nil);
        dlclose(_framework);
        _framework = NULL;
        return NO;
    }

    CFArrayRef deviceList = createDeviceList();
    if (!deviceList) {
        self.statusMessage = NSLocalizedString(@"no_multitouch_devices", nil);
        dlclose(_framework);
        _framework = NULL;
        return NO;
    }

    self.frameHandler = handler;
    CFIndex count = CFArrayGetCount(deviceList);
    for (CFIndex index = 0; index < count; index++) {
        MMMTDeviceRef device = (MMMTDeviceRef)CFArrayGetValueAtIndex(deviceList, index);
        if (isBuiltIn && isBuiltIn(device)) {
            continue;
        }

        // Known Magic Mouse family IDs. If the family API is absent or returns an
        // unknown value, accept the external device so new hardware can still be
        // diagnosed instead of silently disappearing.
        int32_t familyID = 0;
        BOOL familyKnown = getFamilyID && getFamilyID(device, &familyID) == 0;
        if (familyKnown && familyID != 112 && familyID != 113) {
            continue;
        }

        registerCallback(device, MMFrameworkCallback, (__bridge void *)self);
        int32_t result = startDevice(device, 0);
        if (result == 0) {
            [_devices addObject:[NSValue valueWithPointer:device]];
        } else if (_unregisterCallback) {
            _unregisterCallback(device, MMFrameworkCallback, (__bridge void *)self);
        }
    }
    CFRelease(deviceList);

    self.activeDeviceCount = _devices.count;
    self.running = _devices.count > 0;
    self.statusMessage = self.running
        ? (_devices.count == 1
            ? NSLocalizedString(@"one_device_active", nil)
            : [NSString localizedStringWithFormat:NSLocalizedString(@"devices_active_format", nil), (long)_devices.count])
        : NSLocalizedString(@"no_compatible_mouse", nil);

    if (!self.running) {
        self.frameHandler = nil;
        dlclose(_framework);
        _framework = NULL;
    }
    return self.running;
}

- (void)stop {
    if (!_framework) {
        return;
    }

    for (NSValue *value in _devices) {
        MMMTDeviceRef device = (MMMTDeviceRef)value.pointerValue;
        if (_unregisterCallback) {
            _unregisterCallback(device, MMFrameworkCallback, (__bridge void *)self);
        }
        if (_stopDevice) {
            _stopDevice(device);
        }
    }
    [_devices removeAllObjects];
    self.frameHandler = nil;
    self.running = NO;
    self.activeDeviceCount = 0;
    self.statusMessage = NSLocalizedString(@"stopped", nil);

    dlclose(_framework);
    _framework = NULL;
    _unregisterCallback = NULL;
    _stopDevice = NULL;
}

- (void)receiveTouches:(const MMMTouch *)touches
                 count:(NSInteger)count
             timestamp:(double)timestamp {
    MMTouchFrameBlock handler = self.frameHandler;
    if (!handler) {
        return;
    }

    NSData *snapshot = count > 0 && touches
        ? [NSData dataWithBytes:touches length:(NSUInteger)count * sizeof(MMMTouch)]
        : nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        handler(snapshot ? snapshot.bytes : NULL, count, timestamp);
    });
}

@end
