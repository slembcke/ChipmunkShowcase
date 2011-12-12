/// Function type used as a callback from the marching squares algorithm to sample an image function.
typedef cpFloat (*cpMarchSampleFunc)(cpVect point, void *data);

/// Function type used as a callback from the marching squares algorithm to output a line segment.
typedef void (*cpMarchSegmentFunc)(cpVect v0, cpVect v1, void *data);

/// Trace an anti-aliased contour of an image along a particular threshold.
void cpMarchSoft(
  cpBB bb, int x_samples, int y_samples, cpFloat threshold,
  cpMarchSegmentFunc segment, void *segment_data,
  cpMarchSampleFunc sample, void *sample_data
);

/// Trace an aliased curve of an image along a particular threshold.
void cpMarchHard(
  cpBB bb, int x_samples, int y_samples, cpFloat threshold,
  cpMarchSegmentFunc segment, void *segment_data,
  cpMarchSampleFunc sample, void *sample_data
);
