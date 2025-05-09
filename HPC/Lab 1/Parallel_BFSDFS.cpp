#include <omp.h>
#include <iostream>
#include <queue>
#include <vector>
#include <chrono>
using namespace std;
using namespace chrono;

class Node
{
public:
    int value;
    Node *left, *right;
    Node(int v) : value(v), left(NULL), right(NULL) {}
};

Node *generateTree(vector<int> &values)
{
    if (values.empty())
        return NULL;
    vector<Node *> nodes(values.size());
    for (int i = 0; i < values.size(); i++)
        nodes[i] = new Node(values[i]);
    int parent = 0, child = 1;
    while (child < values.size())
    {
        if (nodes[parent])
        {
            nodes[parent]->left = (child < values.size()) ? nodes[child++] : NULL;
            nodes[parent]->right = (child < values.size()) ? nodes[child++] : NULL;
        }
        parent++;
    }
    return nodes[0];
}

void parallel_bfs(Node *root)
{
    if (!root)
        return;
    queue<Node *> q;
    q.push(root);
    while (!q.empty())
    {
        int size = q.size();
        vector<Node *> level;
        for (int i = 0; i < size; i++)
        {
            level.push_back(q.front());
            q.pop();
        }
#pragma omp parallel for
        for (int i = 0; i < level.size(); i++)
        {
#pragma omp critical
            cout << level[i]->value << " -> ";
        }
        for (auto node : level)
        {
            if (node->left)
                q.push(node->left);
            if (node->right)
                q.push(node->right);
        }
    }
}

void parallel_dfs(Node *root)
{
    if (!root)
        return;
#pragma omp critical
    cout << root->value << " -> ";
#pragma omp parallel sections
    {
#pragma omp section
        parallel_dfs(root->left);
#pragma omp section
        parallel_dfs(root->right);
    }
}

int main()
{
    int n;
    cout << "Enter number of nodes (in space separated form): ";
    cin >> n;
    vector<int> values(n);
    cout << "Enter " << n << " node values:\n";
    for (int i = 0; i < n; i++)
        cin >> values[i];
    Node *root = generateTree(values);
    auto start_bfs = high_resolution_clock::now();
    cout << "\nParallel BFS: ";
    parallel_bfs(root);
    auto stop_bfs = high_resolution_clock::now();
    cout << "\nExecution time for Parallel BFS: " << duration_cast<milliseconds>(stop_bfs - start_bfs).count() << " ms\n\n";
    auto start_dfs = high_resolution_clock::now();
    cout << "Parallel DFS: ";
    parallel_dfs(root);
    auto stop_dfs = high_resolution_clock::now();
    cout << "\nExecution time for Parallel DFS: " << duration_cast<milliseconds>(stop_dfs - start_dfs).count() << " ms\n";
    return 0;
}
