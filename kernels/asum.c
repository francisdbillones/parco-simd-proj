#include <math.h>

double asum(const int n, const double* A) {
	double sum = 0;
	for (int i = 0; i < n; ++i)
		sum += fabs(A[i]);
	return sum;
}
