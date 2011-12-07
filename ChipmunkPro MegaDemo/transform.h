#import "chipmunk.h"

typedef struct Transform {
  GLfloat a, b, c, d, e, f;
} Transform;

typedef struct Matrix {
  GLfloat m[16];
} Matrix;

static const Transform t_identity = {
  1.0, 0.0, 0.0,
  0.0, 1.0, 0.0,
};

void t_print(Transform t); 


static inline Transform
t_inverse(Transform t){
  float coef = 1.0/(t.a*t.e - t.b*t.d);
  return (Transform){
     t.e*coef, -t.b*coef,  (t.b*t.f - t.c*t.e)*coef,
    -t.d*coef,  t.a*coef, -(t.a*t.f - t.c*t.d)*coef,
  };
}

static inline Transform
t_mult(Transform a, Transform b)
{
  return (Transform){
    a.a*b.a + a.b*b.d, a.a*b.b + a.b*b.e, a.a*b.c + a.b*b.f + a.c,
    a.d*b.a + a.e*b.d, a.d*b.b + a.e*b.e, a.d*b.c + a.e*b.f + a.f,
  };
}

static inline Transform
t_wrap(Transform outer, Transform inner)
{
  return t_mult(t_inverse(outer), t_mult(inner, outer));
}

static inline Transform
t_wrap_inv(Transform outer, Transform inner)
{
  return t_mult(outer, t_mult(inner, t_inverse(outer)));
}

static inline cpVect
t_point(Transform t, cpVect p)
{
  return cpv(t.a*p.x + t.b*p.y + t.c, t.d*p.x + t.e*p.y + t.f);
}

static inline cpVect
t_vect(Transform t, cpVect v)
{
  return cpv(t.a*v.x + t.b*v.y, t.d*v.x + t.e*v.y);
}

static inline cpBB
cpBBFromExtents(cpVect c, cpFloat hw, cpFloat hh)
{
	return cpBBNew(c.x - hw, c.y - hh, c.x + hw, c.y + hh);
}

static inline cpBB
t_bb(Transform t, cpBB bb)
{
	cpVect center = cpv((bb.r + bb.l)*0.5, (bb.t + bb.b)*0.5);
	cpFloat hw = (bb.r - bb.l)*0.5;
	cpFloat hh = (bb.t - bb.b)*0.5;
	
	cpFloat a = t.a*hw, b = t.b*hh, d = t.d*hw, e = t.e*hh;
	cpFloat hw_max = cpfmax(cpfabs(a + b), cpfabs(a - b));
	cpFloat hh_max = cpfmax(cpfabs(d + e), cpfabs(d - e));
	return cpBBFromExtents(t_point(t, center), hw_max, hh_max);
}

static inline Transform
t_translate(cpVect v)
{
  return (Transform){
    1.0, 0.0, v.x,
    0.0, 1.0, v.y,
  };
}

static inline Transform
t_scale(cpFloat x, cpFloat y)
{
	return (Transform){
    x, 0.0, 0.0,
  0.0,   y, 0.0,
	};
}

static inline Transform
t_rotate(cpFloat radians)
{
	cpVect rot = cpvforangle(radians);
	return (Transform){
  rot.x, -rot.y, 0.0,
  rot.y,  rot.x, 0.0,
	};
}

static inline Transform
t_ortho(cpBB bb){
  return (Transform){
    2.0/(bb.r - bb.l), 0.0, -(bb.r + bb.l)/(bb.r - bb.l),
    0.0, 2.0/(bb.t - bb.b), -(bb.t + bb.b)/(bb.t - bb.b),
  };
}

static inline Transform
t_boneScale(cpVect v0, cpVect v1)
{
  cpVect d = cpvsub(v1, v0); 
  return (Transform){
    d.x, -d.y, v0.x,
    d.y,  d.x, v0.y,
  };
}

static inline Transform
t_axialScale(cpVect n, cpVect pivot, float scale)
{
  cpFloat A = n.x*n.y*(scale - 1.0);
  cpFloat B = cpvdot(n, pivot)*(1.0 - scale);
  
  return (Transform){
    scale*n.x*n.x + n.y*n.y, A, n.x*B,
    A, n.x*n.x + scale*n.y*n.y, n.y*B,
  };
}

static inline Matrix
t_matrix(Transform t)
{
  return (Matrix){{
    t.a, t.d, 0.0, 0.0,
    t.b, t.e, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    t.c, t.f, 0.0, 1.0,
  }};
}
