#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

static double now_ms(void) {
	LARGE_INTEGER f, c;
	QueryPerformanceFrequency(&f);
	QueryPerformanceCounter(&c);
	return 1000.0 * (double)c.QuadPart / (double)f.QuadPart;
}


double asum(const int n, const double* A);
double asum_x64(const int n, const double* A);
double asum_xmm(const int n, const double* A);
double asum_ymm(const int n, const double* A);
double asum_ymm_unrolled(const int n, const double* A);

typedef double (*kernel_fn)(const int, const double*);
typedef struct { const char* name; kernel_fn fn; } Kernel;

static const Kernel kernels[] = {
	{ "C",            asum              },
	//{ "x86-64",       asum_x64          },
	{ "XMM",          asum_xmm          },
	{ "YMM",          asum_ymm          },
	{ "YMM_unrolled", asum_ymm_unrolled },
};
#define N_KERNEL (int)(sizeof kernels / sizeof kernels[0])

#define N_RUNS   30

#define PAD    8        // extra elements past the end, filled with a poison value
#define POISON 1e300    // any over-read by a kernel blows up the sum

static double* make_vector(size_t n) {
	double* A = (double*)malloc((n + PAD) * sizeof(double));
	if (!A) return NULL;
	for (size_t i = 0; i < n; i++)
		A[i] = (double)((int)(i % 1000) - 500);
	for (size_t i = n; i < n + PAD; i++)
		A[i] = POISON;
	return A;
}

// check that the kernels produce the same result as the C version for sizes that
// don't align with the register width
static int test_boundary_situations(void) {
	const int sizes[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 15, 17, 1003, 1021, 4099 };
	int all_ok = 1;
	printf("\n=== Test boundary situations (kernel vs C) ===\n");
	printf("%6s |", "n");
	for (int k = 1; k < N_KERNEL; k++) printf(" %-12s", kernels[k].name);
	printf("\n");
	for (int s = 0; s < (int)(sizeof sizes / sizeof sizes[0]); s++) {
		int n = sizes[s];
		double* A = make_vector(n);
		if (!A) return 0;
		double ref = asum(n, A);
		printf("%6d |", n);
		for (int k = 1; k < N_KERNEL; k++) {
			int ok = kernels[k].fn(n, A) == ref;
			all_ok &= ok;
			printf(" %-12s", ok ? "OK" : "FAIL");
		}
		printf("\n");
		free(A);
	}
	return all_ok;
}

static int test_normal(void) {
	const int exps[] = { 20, 26, 30 };
	double avg[3][N_KERNEL] = { 0 };
	int used_exp[3];
	int all_ok = 1;

	for (int e = 0; e < 3; e++) {
		// reduce the size if the machine can't allocate it
		int exp = exps[e];
		double* A = NULL;
		size_t n = 0;
		for (; exp >= 20; exp--) {
			n = (size_t)1 << exp;
			A = make_vector(n);
			if (A) break;
		}
		if (!A) { printf("could not allocate vector\n"); return 0; }
		used_exp[e] = exp;

		printf("\n=== n = 2^%d = %zu (%.1f MiB) ===\n", exp, n, n * 8.0 / (1 << 20));
		double ref = asum((int)n, A);
		printf("C answer key: %.10f\n", ref);

		for (int k = 0; k < N_KERNEL; k++) {
			double total = 0, result = 0;
			for (int r = 0; r < N_RUNS; r++) {
				double t0 = now_ms();
				result = kernels[k].fn((int)n, A);
				total += now_ms() - t0;
			}
			avg[e][k] = total / N_RUNS;
			int ok = result == ref;
			all_ok &= ok;
			printf("%-12s asum =%.10f  avg time = %10.4f ms  [%s]\n",
			       kernels[k].name, result, avg[e][k], ok ? "CORRECT" : "WRONG");
		}
		free(A);
	}

	printf("\n=== Summary: avg ms (speedup vs C) ===\n");
	printf("%-8s", "n");
	for (int k = 0; k < N_KERNEL; k++) printf(" | %-18s", kernels[k].name);
	printf("\n");
	for (int e = 0; e < 3; e++) {
		printf("2^%-6d", used_exp[e]);
		for (int k = 0; k < N_KERNEL; k++)
			printf(" | %9.4f (%5.2fx)", avg[e][k], avg[e][0] / avg[e][k]);
		printf("\n");
	}
	return all_ok;
}

int main(void) {
	int perf_ok = test_normal();
	int boundary_ok = test_boundary_situations();
	printf("\nPerformance run: %s\n", perf_ok ? "ALL CORRECT" : "WRONG RESULTS");
	printf("Boundary check: %s\n", boundary_ok ? "ALL CORRECT" : "WRONG RESULTS");
	return perf_ok && boundary_ok ? 0 : 1;
}
