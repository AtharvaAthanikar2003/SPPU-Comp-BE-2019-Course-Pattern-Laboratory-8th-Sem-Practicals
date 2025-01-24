// Mini Project – Huffman Encoding on GPU
#include <iostream>
#include <vector>
#include <queue>
#include <unordered_map>
#include <cuda_runtime.h>
using namespace std;
struct HuffmanNode {
    char character;
    int frequency;
    HuffmanNode* left;
    HuffmanNode* right;
    HuffmanNode(char c, int freq) : character(c), frequency(freq), left(nullptr), right(nullptr) {}
    HuffmanNode(int freq, HuffmanNode* leftNode, HuffmanNode* rightNode)
        : character(0), frequency(freq), left(leftNode), right(rightNode) {}
    bool operator>(const HuffmanNode& other) const {
        return frequency > other.frequency;
    }
};
__global__ void count_frequencies_kernel(const char* text, int* freqs, int text_length) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    if (idx < text_length) {
        atomicAdd(&freqs[(unsigned char)text[idx]], 1);
    }
}
void count_frequencies(const char* text, int* freqs, int text_length) {
    char* d_text;
    int* d_freqs;
    cudaMalloc(&d_text, text_length * sizeof(char));
    cudaMalloc(&d_freqs, 256 * sizeof(int));
    cudaMemset(d_freqs, 0, 256 * sizeof(int));
    cudaMemcpy(d_text, text, text_length * sizeof(char), cudaMemcpyHostToDevice);
    int block_size = 256;
    int grid_size = (text_length + block_size - 1) / block_size;
    count_frequencies_kernel<<<grid_size, block_size>>>(d_text, d_freqs, text_length);
    cudaDeviceSynchronize();
    cudaMemcpy(freqs, d_freqs, 256 * sizeof(int), cudaMemcpyDeviceToHost);
    cudaFree(d_text);
    cudaFree(d_freqs);
}
void generate_huffman_codes(HuffmanNode* root, string code, unordered_map<char, string>& huffman_codes) {
    if (!root) return;
    if (root->left == nullptr && root->right == nullptr) {
        huffman_codes[root->character] = code;
    }
    generate_huffman_codes(root->left, code + "0", huffman_codes);
    generate_huffman_codes(root->right, code + "1", huffman_codes);
}
HuffmanNode* build_huffman_tree(const int* freqs) {
    priority_queue<HuffmanNode, vector<HuffmanNode>, greater<HuffmanNode>> min_heap;
    for (int i = 0; i < 256; ++i) {
        if (freqs[i] > 0) {
            min_heap.push(HuffmanNode(i, freqs[i]));
        }
    }
    while (min_heap.size() > 1) {
        HuffmanNode* left = new HuffmanNode(min_heap.top());
        min_heap.pop();
        HuffmanNode* right = new HuffmanNode(min_heap.top());
        min_heap.pop();
        int combined_freq = left->frequency + right->frequency;
        HuffmanNode* combined = new HuffmanNode(combined_freq, left, right);
        min_heap.push(*combined);
    }
    return new HuffmanNode(min_heap.top());
}
void huffman_encoding(const char* text, int text_length) {
    int freqs[256] = {0};
    count_frequencies(text, freqs, text_length);
    HuffmanNode* root = build_huffman_tree(freqs);
    unordered_map<char, string> huffman_codes;
    generate_huffman_codes(root, "", huffman_codes);
    cout << "Huffman Codes:" << endl;
    for (const auto& pair : huffman_codes) {
        cout << pair.first << ": " << pair.second << endl;
    }
}
int main() {
    const char* text = "this is a simple example of huffman encoding on gpu";
    int text_length = strlen(text);
    huffman_encoding(text, text_length);
    return 0;
}
