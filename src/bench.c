#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define N 512
#define V (1 << 22)
#define S (1 << 20)

static float A[N * N], B[N * N], C[N * N];
static float X[V], Y[V], Z[S];

static double now(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

__attribute__((noinline)) void fill(float *p, size_t n, unsigned seed)
{
    for (size_t i = 0; i < n; i++) {
        seed = seed * 1664525u + 1013904223u;
        p[i] = (float)(seed >> 8) / 16777216.0f;
    }
}

__attribute__((noinline)) void matmul(const float *a, const float *b, float *c, int n)
{
    memset(c, 0, sizeof(float) * n * n);
    for (int i = 0; i < n; i++)
        for (int k = 0; k < n; k++) {
            float s = a[i * n + k];
            for (int j = 0; j < n; j++)
                c[i * n + j] += s * b[k * n + j];
        }
}

__attribute__((noinline)) void saxpy(float a, const float *x, float *y, size_t n)
{
    for (size_t i = 0; i < n; i++)
        y[i] = a * x[i] + y[i];
}

__attribute__((noinline)) float dot(const float *x, const float *y, size_t n)
{
    float s = 0.0f;
    for (size_t i = 0; i < n; i++)
        s += x[i] * y[i];
    return s;
}

static int cmp(const void *a, const void *b)
{
    float x = *(const float *)a, y = *(const float *)b;
    return (x > y) - (x < y);
}

__attribute__((noinline)) void sort_sample(const float *src, float *dst, size_t n)
{
    memcpy(dst, src, sizeof(float) * n);
    qsort(dst, n, sizeof(float), cmp);
}

int main(int argc, char **argv)
{
    int reps = argc > 1 ? atoi(argv[1]) : 5;
    double t[5] = {0}, t0;
    double check = 0.0;

    t0 = now();
    fill(A, N * N, 1);
    fill(B, N * N, 2);
    fill(X, V, 3);
    fill(Y, V, 4);
    t[0] += now() - t0;

    for (int r = 0; r < reps; r++) {
        t0 = now();
        matmul(A, B, C, N);
        t[1] += now() - t0;

        t0 = now();
        for (int k = 0; k < 20; k++)
            saxpy(0.5f, X, Y, V);
        t[2] += now() - t0;

        t0 = now();
        for (int k = 0; k < 20; k++)
            check += dot(X, Y + k, V - k) * 1e-9;
        t[3] += now() - t0;

        t0 = now();
        sort_sample(Y, Z, S);
        t[4] += now() - t0;

        check += C[r] + Z[S / 2];
    }

    const char *names[] = {"fill", "matmul", "saxpy", "dot", "sort"};
    double total = 0;
    for (int i = 0; i < 5; i++) {
        printf("%-8s %8.3f s\n", names[i], t[i]);
        total += t[i];
    }
    printf("%-8s %8.3f s\n", "total", total);
    printf("checksum %.6f\n", check);
    return 0;
}
