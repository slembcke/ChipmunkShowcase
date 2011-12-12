

typedef struct cpHastySpace {
	cpSpace space;
} cpHastySpace;


cpSpace *cpHastySpaceNew(void);
void cpHastySpaceStep(cpSpace *space, cpFloat dt);
