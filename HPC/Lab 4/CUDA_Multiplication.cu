#include <iostream>
#include <cstdlib>
#include <ctime>

__global__ void matrixMul(int *A, int *B, int *C, int N) {
    int row = threadIdx.y + blockIdx.y * blockDim.y;
    int col = threadIdx.x + blockIdx.x * blockDim.x;
    if (row < N && col < N) {
        int value = 0;
        for (int k = 0; k < N; k++) {
            value += A[row * N + k] * B[k * N + col];
        }
        C[row * N + col] = value;
    }
}

int main() {
    int N = 3;
    size_t size = N * N * sizeof(int);
    int *A = (int*)malloc(size), *B = (int*)malloc(size), *C = (int*)malloc(size);
    int *d_A, *d_B, *d_C;
    cudaMalloc(&d_A, size); cudaMalloc(&d_B, size); cudaMalloc(&d_C, size);
    
    srand(time(NULL));
    for (int i = 0; i < N * N; i++) {
        B[i] = rand() % 10;
        A[i] = rand() % 10;
    }

    cudaMemcpy(d_A, A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, B, size, cudaMemcpyHostToDevice);
    dim3 threadsPerBlock(16, 16), blocksPerGrid((N + 15) / 16, (N + 15) / 16);
    matrixMul<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, N);
    cudaMemcpy(C, d_C, size, cudaMemcpyDeviceToHost);

    std::cout << "Matrix A: " << std::endl;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            std::cout << A[i * N + j] << " ";
        }
        std::cout << std::endl;
    }

    std::cout << "Matrix B: " << std::endl;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            std::cout << B[i * N + j] << " ";
        }
        std::cout << std::endl;
    }

    std::cout << "Result Matrix C : " << std::endl;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            std::cout << C[i * N + j] << " ";
        }
        std::cout << std::endl;
    }

    std::cout << "Calculation of Matrix C: " << std::endl;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            int value = 0;
            std::cout << "C[" << i << "][" << j << "] = ";
            for (int k = 0; k < N; k++) {
                value += A[i * N + k] * B[k * N + j];
                std::cout << A[i * N + k] << " * " << B[k * N + j];
                if (k < N - 1) std::cout << " + ";
            }
            std::cout << " = " << value << std::endl;
        }
    }

    free(A); free(B); free(C);
    cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);
    return 0;
}
