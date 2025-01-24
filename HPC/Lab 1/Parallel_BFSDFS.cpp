#include <iostream>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <queue>
#include <thread>
#include <future>
#include <atomic>
using namespace std;
class Graph {
private:
    unordered_map<int, vector<int>> adjList;
public:
    void addEdge(int u, int v) {
        adjList[u].push_back(v);
        adjList[v].push_back(u);
    }
    vector<int> getNeighbors(int u) {
        if (adjList.find(u) != adjList.end()) {
            return adjList[u];
        }
        return {};
    }
    void printGraph() {
        cout << "\nGraph Structure:" << endl;
        for (auto& entry : adjList) {
            cout << entry.first << " -> ";
            for (int neighbor : entry.second) {
                cout << neighbor << " ";
            }
            cout << endl;
        }
    }
};
vector<int> parallelBFS(Graph& graph, int start) {
    unordered_set<int> visited;
    queue<int> q;
    vector<int> bfsTraversal;
    atomic<bool> done(false);
    q.push(start);
    visited.insert(start);
    while (!q.empty()) {
        int levelSize = q.size();
        vector<future<void>> futures;
        for (int i = 0; i < levelSize; i++) {
            int currentNode = q.front();
            q.pop();
            bfsTraversal.push_back(currentNode);
            futures.push_back(async(launch::async, [&]() {
                for (int neighbor : graph.getNeighbors(currentNode)) {
                    if (visited.find(neighbor) == visited.end()) {
                        visited.insert(neighbor);
                        q.push(neighbor);
                    }
                }
            }));
        }
        for (auto& fut : futures) {
            fut.get();
        }
    }
    return bfsTraversal;
}
void dfsRecursive(Graph& graph, int node, unordered_set<int>& visited, vector<int>& dfsTraversal) {
    visited.insert(node);
    dfsTraversal.push_back(node);
    vector<int> neighbors = graph.getNeighbors(node);
    vector<future<void>> futures;
    for (int neighbor : neighbors) {
        if (visited.find(neighbor) == visited.end()) {
            futures.push_back(async(launch::async, [&]() {
                dfsRecursive(graph, neighbor, visited, dfsTraversal);
            }));
        }
    }
    for (auto& fut : futures) {
        fut.get();
    }
}
vector<int> parallelDFS(Graph& graph, int start) {
    unordered_set<int> visited;
    vector<int> dfsTraversal;
    dfsRecursive(graph, start, visited, dfsTraversal);   
    return dfsTraversal;
}
void printTraversalAsTree(const vector<int>& traversal, const string& traversalType) {
    cout << "\n" << traversalType << " Traversal Output: " << endl;
    for (int node : traversal) {
        cout << node << " ";
    }
    cout << endl;
}
int main() {
    Graph graph;
    int numEdges;
    cout << "Enter the number of edges you want to add to the graph:" << endl;
    cin >> numEdges;
    cout << "Enter edges as pairs of nodes (e.g., 0 1 for an edge between 0 and 1): " << endl;
    for (int i = 0; i < numEdges; i++) {
        int u, v;
        cin >> u >> v;
        graph.addEdge(u, v);
    }
    graph.printGraph();
    bool continueRunning = true;
    while (continueRunning) {
        cout << "\nChoose an option: " << endl;
        cout << "1. Parallel BFS" << endl;
        cout << "2. Parallel DFS" << endl;
        cout << "3. Exit" << endl;
        cout << "Enter your choice: ";
        int choice;
        cin >> choice;
        switch (choice) {
            case 1: {
                cout << "Enter starting node for BFS: ";
                int startBFS;
                cin >> startBFS;
                cout << "\nRunning Parallel BFS..." << endl;
                vector<int> bfsTraversal = parallelBFS(graph, startBFS);
                printTraversalAsTree(bfsTraversal, "BFS");
                break;
            }
            case 2: {
                cout << "Enter starting node for DFS: ";
                int startDFS;
                cin >> startDFS;
                cout << "\nRunning Parallel DFS..." << endl;
                vector<int> dfsTraversal = parallelDFS(graph, startDFS);
                printTraversalAsTree(dfsTraversal, "DFS");
                break;
            }
            case 3:
                continueRunning = false;
                cout << "Exited the program successfully" << endl;
                break;
            default:
                cout << "Invalid choice! Please choose a valid option." << endl;
                break;
        }
        if (continueRunning) {
            cout << "\nDo you want to continue? (yes/no): ";
            string userChoice;
            cin >> userChoice;
            if (userChoice == "no" || userChoice == "No") {
                continueRunning = false;
                cout << "Exited the program successfully" << endl;
            }
        }
    }
    return 0;
}
