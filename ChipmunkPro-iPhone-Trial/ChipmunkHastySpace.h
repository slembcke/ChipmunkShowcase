// Copyright 2013 Howling Moon Software. All rights reserved.
// See http://chipmunk2d.net/legal.php for more information.

/// ChipmunkHastySpace is an Objective-Chipmunk wrapper for cpHastySpace and is only available with Chipmunk Pro.
/// Subclass this class instead of ChipmunkSpace if you want to enable the cpHastySpace optimizations.
/// If ChipmunkHastySpace is linked correctly, calling [[ChipmunkSpace alloc] init] will actually return a ChipmunkHastySpace.
@interface ChipmunkHastySpace : ChipmunkSpace

/// Number of threads to use for the solver.
///	Setting 0 will choose the thread count automatically (recommended).
/// There is currently little benefit in using more than 2 threads.
/// Defaults to 1.
@property(nonatomic, assign) NSUInteger threads;

@end
