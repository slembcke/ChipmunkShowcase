/* Copyright (c) 2012 Scott Lembcke and Howling Moon Software
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

// Not terribly happy with how this demo turned out yet.
// It's a giant mess and not as stable as I'd like.

#import "ShowcaseDemo.h"

@interface RemoteJoint : ChipmunkGearJoint @end
@implementation RemoteJoint
{
	ChipmunkGearJoint *_master;
	ChipmunkSimpleMotor *_friction;
}

+(RemoteJoint *)remoteJointWithBodyA:(ChipmunkBody *)a bodyB:(ChipmunkBody *)b master:(ChipmunkGearJoint *)master
{
	return [[self alloc] initWithBodyA:a bodyB:b master:master];
}

-(id)initWithBodyA:(ChipmunkBody *)a bodyB:(ChipmunkBody *)b master:(ChipmunkGearJoint *)master
{
	if((self = [super initWithBodyA:a bodyB:b phase:master.phase ratio:master.ratio])){
		_master = master;
		
		self.errorBias = cpfpow(1.0f - 0.9f, 60.0f);
		self.maxBias = 1.0;
		self.maxForce = master.maxForce*4.0;
		
		_friction = [ChipmunkSimpleMotor simpleMotorWithBodyA:a bodyB:b rate:0.0];
		_friction.maxForce = master.maxForce;
	}
	
	return self;
}

-(void)preSolve:(ChipmunkSpace *)space
{
	self.phase = _master.bodyB.angle - _master.bodyA.angle;
}

-(void)addToSpace:(ChipmunkSpace *)space
{
	[super addToSpace:space];
	[space add:_friction];
}

-(void)removeFromSpace:(ChipmunkSpace *)space
{
	[super removeFromSpace:space];
	[space remove:_friction];
}

@end


@interface RemoteArm : ShowcaseDemo @end
@implementation RemoteArm

-(NSString *)name
{
	return @"Robotic Claw";
}

-(NSTimeInterval)preferredTimeStep
{
	return 1.0/180.0;
}

-(void)setup
{
	self.space.iterations = 25;
	self.space.gravity = cpv(0, -500);
	
	cpShapeFilter filter = cpShapeFilterNew(CP_NO_GROUP, NOT_GRABABLE_MASK, NOT_GRABABLE_MASK);
	[self.space addBounds:self.demoBounds thickness:10.0 elasticity:1.0 friction:1.0 filter:filter collisionType:nil];
	[self.space add:[ChipmunkSegmentShape segmentWithBody:self.staticBody from:cpv(0.0, -1000.0) to:cpv(0.0, 1000.0) radius:10.0]];
	
	cpVect offset = cpv(160.0, 160.0);
	
	cpFloat armMass = 4.0;
	cpFloat armLength = 110.0;
	cpVect armVertA = cpv(0.0, -armLength/2.0);
	cpVect armVertB = cpv(0,  armLength/2.0);
	
	// Exaggerate the moment to make the simulation more stable.
	cpFloat armMoment = 10.0*cpMomentForSegment(armMass, armVertA, armVertB, 0.0);
	
	cpFloat masterFriction = 1e6;
	
	// Make the master arm
	NSString *masterGroup = @"master";
	
	ChipmunkBody *arm1Master = [self.space add:[ChipmunkBody bodyWithMass:armMass andMoment:armMoment]];
	arm1Master.position = cpvadd(cpv(0, 0), offset);
	
	ChipmunkShape *arm1MasterShape = [self.space add:[ChipmunkSegmentShape segmentWithBody:arm1Master from:armVertA to:armVertB radius:10.0]];
	arm1MasterShape.filter = cpShapeFilterNew(masterGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:self.staticBody bodyB:arm1Master pivot:[arm1Master localToWorld:armVertB]]];
	ChipmunkGearJoint *arm1MasterFriction = [self.space add:[ChipmunkGearJoint gearJointWithBodyA:self.staticBody bodyB:arm1Master phase:0.0 ratio:1.0]];
	arm1MasterFriction.maxBias = 0.0;
	arm1MasterFriction.maxForce = 3.0*masterFriction;
	
	ChipmunkBody *arm2Master = [self.space add:[ChipmunkBody bodyWithMass:armMass andMoment:armMoment]];
	arm2Master.position = cpvadd(cpv(0, -armLength), offset);
	
	ChipmunkShape *arm2MasterShape = [self.space add:[ChipmunkSegmentShape segmentWithBody:arm2Master from:armVertA to:armVertB radius:10.0]];
	arm2MasterShape.filter = cpShapeFilterNew(masterGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:arm1Master bodyB:arm2Master pivot:[arm2Master localToWorld:armVertB]]];
	ChipmunkGearJoint *arm2MasterFriction = [self.space add:[ChipmunkGearJoint gearJointWithBodyA:arm1Master bodyB:arm2Master phase:0.0 ratio:1.0]];
	arm2MasterFriction.maxBias = 0.0;
	arm2MasterFriction.maxForce = 2.0*masterFriction;
	
	ChipmunkBody *arm3Master = [self.space add:[ChipmunkBody bodyWithMass:armMass andMoment:armMoment]];
	arm3Master.position = cpvadd(cpv(0, -2.0*armLength), offset);
	
	ChipmunkShape *arm3MasterShape = [self.space add:[ChipmunkSegmentShape segmentWithBody:arm3Master from:armVertA to:armVertB radius:10.0]];
	arm3MasterShape.filter = cpShapeFilterNew(masterGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:arm2Master bodyB:arm3Master pivot:[arm3Master localToWorld:armVertB]]];
	ChipmunkGearJoint *arm3MasterFriction = [self.space add:[ChipmunkGearJoint gearJointWithBodyA:arm2Master bodyB:arm3Master phase:0.0 ratio:1.0]];
	arm3MasterFriction.maxBias = 0.0;
	arm3MasterFriction.maxForce = masterFriction;
	
	cpFloat pincherMass = armMass;
	cpFloat pincherOffset = armLength/2.0;
	cpFloat pincherMoment = 2.0*cpMomentForSegment(pincherMass/2.0, cpv(0.0, -pincherOffset/2.0), cpv(pincherOffset, pincherOffset/2.0), 0.0);
	
	ChipmunkBody *leftPincherMaster = [self.space add:[ChipmunkBody bodyWithMass:pincherMass andMoment:pincherMoment]];
	leftPincherMaster.position = cpvadd(cpv(-pincherOffset/2.0, -2.5*armLength - pincherOffset), offset);
	
	ChipmunkShape *leftPincherMasterShape1 = [self.space add:[ChipmunkSegmentShape segmentWithBody:leftPincherMaster from:cpv( pincherOffset/2.0,  pincherOffset) to:cpv(-pincherOffset/2.0, 0.0) radius:10.0]];
	leftPincherMasterShape1.filter = cpShapeFilterNew(masterGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	leftPincherMasterShape1.friction = 0.7;
	
	ChipmunkShape *leftPincherMasterShape2 = [self.space add:[ChipmunkSegmentShape segmentWithBody:leftPincherMaster from:cpv( pincherOffset/2.0, -pincherOffset) to:cpv(-pincherOffset/2.0, 0.0) radius:10.0]];
	leftPincherMasterShape2.filter = cpShapeFilterNew(masterGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	leftPincherMasterShape2.friction = 0.7;
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:arm3Master bodyB:leftPincherMaster pivot:[arm3Master localToWorld:armVertA]]];
	ChipmunkGearJoint *leftPincherMasterFriction = [self.space add:[ChipmunkGearJoint gearJointWithBodyA:arm3Master bodyB:leftPincherMaster phase:0.0 ratio:1.0]];
	leftPincherMasterFriction.maxBias = 0.0;
	leftPincherMasterFriction.maxForce = 0.5*masterFriction;
	
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:arm3Master bodyB:leftPincherMaster min:-M_PI/2.0 max:M_PI/2.0]];
	
	ChipmunkBody *rightPincherMaster = [self.space add:[ChipmunkBody bodyWithMass:pincherMass andMoment:pincherMoment]];
	rightPincherMaster.position = cpvadd(cpv( pincherOffset/2.0, -2.5*armLength - pincherOffset), offset);
	
	ChipmunkShape *rightPincherMasterShape1 = [self.space add:[ChipmunkSegmentShape segmentWithBody:rightPincherMaster from:cpv(-pincherOffset/2.0,  pincherOffset) to:cpv( pincherOffset/2.0, 0.0) radius:10.0]];
	rightPincherMasterShape1.filter = cpShapeFilterNew(masterGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	ChipmunkShape *rightPincherMasterShape2 = [self.space add:[ChipmunkSegmentShape segmentWithBody:rightPincherMaster from:cpv(-pincherOffset/2.0, -pincherOffset) to:cpv( pincherOffset/2.0, 0.0) radius:10.0]];
	rightPincherMasterShape2.filter = cpShapeFilterNew(masterGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:arm3Master bodyB:rightPincherMaster pivot:[arm3Master localToWorld:armVertA]]];
	ChipmunkGearJoint *rightPincherMasterFriction = [self.space add:[ChipmunkGearJoint gearJointWithBodyA:arm3Master bodyB:rightPincherMaster phase:0.0 ratio:1.0]];
	rightPincherMasterFriction.maxBias = 0.0;
	rightPincherMasterFriction.maxForce = 0.5*masterFriction;
	
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:arm3Master bodyB:rightPincherMaster min:-M_PI/2.0 max:M_PI/2.0]];
	
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:leftPincherMaster bodyB:rightPincherMaster min:0.0 max: M_PI/2.0]];
	
	// Make the remote arm
	offset = cpv(-160, 160);
	NSString *remoteGroup = @"remote";
	
	ChipmunkBody *arm1Remote = [self.space add:[ChipmunkBody bodyWithMass:armMass andMoment:armMoment]];
	arm1Remote.position = cpvadd(cpv(0, 0), offset);
	
	ChipmunkShape *arm1RemoteShape = [self.space add:[ChipmunkSegmentShape segmentWithBody:arm1Remote from:armVertA to:armVertB radius:10.0]];
	arm1RemoteShape.filter = cpShapeFilterNew(remoteGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:self.staticBody bodyB:arm1Remote pivot:[arm1Remote localToWorld:armVertB]]];
	[self.space add:[RemoteJoint remoteJointWithBodyA:self.staticBody bodyB:arm1Remote master:arm1MasterFriction]];
	
	ChipmunkBody *arm2Remote = [self.space add:[ChipmunkBody bodyWithMass:armMass andMoment:armMoment]];
	arm2Remote.position = cpvadd(cpv(0, -armLength), offset);
	
	ChipmunkShape *arm2RemoteShape = [self.space add:[ChipmunkSegmentShape segmentWithBody:arm2Remote from:armVertA to:armVertB radius:10.0]];
	arm2RemoteShape.filter = cpShapeFilterNew(remoteGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:arm1Remote bodyB:arm2Remote pivot:[arm2Remote localToWorld:armVertB]]];
	[self.space add:[RemoteJoint remoteJointWithBodyA:arm1Remote bodyB:arm2Remote master:arm2MasterFriction]];
	
	ChipmunkBody *arm3Remote = [self.space add:[ChipmunkBody bodyWithMass:armMass andMoment:armMoment]];
	arm3Remote.position = cpvadd(cpv(0, -2.0*armLength), offset);
	
	ChipmunkShape *arm3RemoteShape = [self.space add:[ChipmunkSegmentShape segmentWithBody:arm3Remote from:armVertA to:armVertB radius:10.0]];
	arm3RemoteShape.filter = cpShapeFilterNew(remoteGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:arm2Remote bodyB:arm3Remote pivot:[arm3Remote localToWorld:armVertB]]];
	[self.space add:[RemoteJoint remoteJointWithBodyA:arm2Remote bodyB:arm3Remote master:arm3MasterFriction]];
	
	ChipmunkBody *leftPincherRemote = [self.space add:[ChipmunkBody bodyWithMass:pincherMass andMoment:pincherMoment]];
	leftPincherRemote.position = cpvadd(cpv(-pincherOffset/2.0, -2.5*armLength - pincherOffset), offset);
	
	ChipmunkShape *leftPincherRemoteShape1 = [self.space add:[ChipmunkSegmentShape segmentWithBody:leftPincherRemote from:cpv( pincherOffset/2.0,  pincherOffset) to:cpv(-pincherOffset/2.0, 0.0) radius:10.0]];
	leftPincherRemoteShape1.filter = cpShapeFilterNew(remoteGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	leftPincherRemoteShape1.friction = 0.7;
	
	ChipmunkShape *leftPincherRemoteShape2 = [self.space add:[ChipmunkSegmentShape segmentWithBody:leftPincherRemote from:cpv( pincherOffset/2.0, -pincherOffset) to:cpv(-pincherOffset/2.0, 0.0) radius:10.0]];
	leftPincherRemoteShape2.filter = cpShapeFilterNew(remoteGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	leftPincherRemoteShape2.friction = 0.7;
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:arm3Remote bodyB:leftPincherRemote pivot:[arm3Remote localToWorld:armVertA]]];
	[self.space add:[RemoteJoint remoteJointWithBodyA:arm3Remote bodyB:leftPincherRemote master:leftPincherMasterFriction]];
	
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:arm3Remote bodyB:leftPincherRemote min:-M_PI/2.0 max:M_PI/2.0]];
	
	ChipmunkBody *rightPincherRemote = [self.space add:[ChipmunkBody bodyWithMass:pincherMass andMoment:pincherMoment]];
	rightPincherRemote.position = cpvadd(cpv( pincherOffset/2.0, -2.5*armLength - pincherOffset), offset);
	
	ChipmunkShape *rightPincherRemoteShape1 = [self.space add:[ChipmunkSegmentShape segmentWithBody:rightPincherRemote from:cpv(-pincherOffset/2.0,  pincherOffset) to:cpv( pincherOffset/2.0, 0.0) radius:10.0]];
	rightPincherRemoteShape1.filter = cpShapeFilterNew(remoteGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	ChipmunkShape *rightPincherRemoteShape2 = [self.space add:[ChipmunkSegmentShape segmentWithBody:rightPincherRemote from:cpv(-pincherOffset/2.0, -pincherOffset) to:cpv( pincherOffset/2.0, 0.0) radius:10.0]];
	rightPincherRemoteShape2.filter = cpShapeFilterNew(remoteGroup, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES);
	
	[self.space add:[ChipmunkPivotJoint pivotJointWithBodyA:arm3Remote bodyB:rightPincherRemote pivot:[arm3Remote localToWorld:armVertA]]];
	[self.space add:[RemoteJoint remoteJointWithBodyA:arm3Remote bodyB:rightPincherRemote master:rightPincherMasterFriction]];
	
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:arm3Remote bodyB:rightPincherRemote min:-M_PI/2.0 max:M_PI/2.0]];
	
	[self.space add:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:leftPincherRemote bodyB:rightPincherRemote min:0.0 max: M_PI/2.0]];
	
	// Add a ball to grab.
	{
		cpFloat mass = 8.0;
		cpFloat radius = 50.0;
		
		ChipmunkBody *body = [self.space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForCircle(mass, 0.0, radius, cpvzero)]];
		body.position = cpv(-80, -100);
		
		ChipmunkShape *shape = [self.space add:[ChipmunkCircleShape circleWithBody:body radius:radius offset:cpvzero]];
		shape.friction = 0.7;
	}
}

-(void)tick:(cpFloat)dt
{
//	self.space.gravity = cpvmult([Accelerometer getAcceleration], 600);
	
	[super tick:dt];
}

@end
