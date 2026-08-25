#pragma once

#include <CoreFoundation/CoreFoundation.h>
#include <stdint.h>

typedef void *MMMTDeviceRef;

typedef struct {
    float x;
    float y;
} MMMTPoint;

typedef struct {
    MMMTPoint position;
    MMMTPoint velocity;
} MMMTVector;

// Reverse-engineered layout used by macOS' private MultitouchSupport framework.
// Keep this definition isolated so compatibility probes can replace it safely.
typedef struct {
    int32_t frame;
    double timestamp;
    int32_t pathIndex;
    int32_t stage;
    int32_t fingerID;
    int32_t handID;
    MMMTVector normalizedVector;
    float zTotal;
    float zPressure;
    float angle;
    float majorAxis;
    float minorAxis;
    MMMTVector absoluteVector;
    int32_t field14;
    int32_t field15;
    float zDensity;
} MMMTouch;

typedef void (*MMMTFrameCallback)(
    MMMTDeviceRef device,
    MMMTouch *touches,
    size_t count,
    double timestamp,
    size_t frame,
    void *context
);
