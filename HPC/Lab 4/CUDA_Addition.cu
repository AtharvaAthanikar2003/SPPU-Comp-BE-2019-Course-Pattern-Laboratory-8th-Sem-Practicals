#include <iostream>
#include <cuda_runtime.h>
#include <cstdlib>

__global__ void vectorAdd(int *A, int *B, int *C, int N) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x; 
    if (idx < N) {
        C[idx] = A[idx] + B[idx];  
    }
}

int main() {
    int N = 11;  
    size_t size = N * sizeof(int);  
    int *A, *B, *C, *d_A, *d_B, *d_C;

    A = (int*)malloc(size);
    B = (int*)malloc(size);
    C = (int*)malloc(size);

    cudaMalloc(&d_A, size);
    cudaMalloc(&d_B, size);
    cudaMalloc(&d_C, size);

    srand(time(NULL));
    for (int i = 1; i < N; i++) {
        A[i] = rand() % 100;  
        B[i] = rand() % 100;  
    }

    cudaMemcpy(d_A, A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, B, size, cudaMemcpyHostToDevice);
    int threadsPerBlock = 256;  
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;  
    vectorAdd<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, N);
    cudaMemcpy(C, d_C, size, cudaMemcpyDeviceToHost);

    std::cout << "Vector A: ";
    for (int i = 1; i < N; i++) {
        std::cout << A[i] << " ";  
    }
    std::cout << std::endl;

    std::cout << "Vector B: ";
    for (int i = 1; i < N; i++) {
        std::cout << B[i] << " ";  
    }
    std::cout << std::endl;

    std::cout << "Result Vector C: ";
    for (int i = 1; i < N; i++) {
        std::cout << C[i] << " ";  
    }
    std::cout << std::endl;

    std::cout << "Calculations of Matrix C: " << std::endl;
    for (int i = 1; i < N; i++) {
        std::cout << "C[" << i << "] = " << A[i] << " + " << B[i] << " = " << C[i] << std::endl;
    }

    free(A);
    free(B);
    free(C);
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    return 0;
}
