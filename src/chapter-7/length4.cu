#include <stdlib.h> // malloc() and free()
#include <stdio.h> // printf()
double get_length(double *x, int N);

int main(void)
{
    int N = 1000;
    int M = sizeof(double) * N;
    double *x = (double *) malloc(M);
    for (int n = 0; n < N; ++n)
    {
        x[n] = 1.0;
    }
    double length = get_length(x, N);
    printf("length = %g.\n", length);
    free(x);
    return 0;
}

void __global__ get_length(double *g_x, double *g_length, int N)
{
    int tid = threadIdx.x;
    __shared__ double s_x[1024];
    s_x[tid] = 0.0;
    if (tid < N)
    {
        double tmp = g_x[tid];
        s_x[tid] = tmp * tmp;
    }
    __syncthreads();
    for (int offset = blockDim.x / 2; offset > 0; offset /= 2)
    {
        if (tid < offset)
        {
            s_x[tid] += s_x[tid + offset];
        }
        __syncthreads();
    }
    if (tid == 0)
    {
        g_length[0] = sqrt(s_x[0]);
    }
}

double get_length(double *x, int N)
{
    double *g_length;
    cudaMalloc((void**)&g_length, sizeof(double));
    double *g_x;
    cudaMalloc((void**)&g_x, sizeof(double) * N);
    cudaMemcpy(g_x, x, sizeof(double) * N, cudaMemcpyHostToDevice);
    get_length<<<1, 1024>>>(g_x, g_length, N);
    double *cpu_length = (double *) malloc(sizeof(double));
    cudaMemcpy(cpu_length, g_length, sizeof(double), cudaMemcpyDeviceToHost);
    cudaFree(g_length);
    cudaFree(g_x);
    double length = cpu_length[0];
    free(cpu_length);
    return length;
}

