#ifndef TRUSS_CORE_H_
#define TRUSS_CORE_H_

#include "interpreter.h"

#include <external/tinythread.h>
#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <terra/terra.h>
#include <trussapi.h>

namespace truss {
    
class Core {
public:
    static Core* getCore();

    // functions for dealing with physfs (you can also make direct physfs
    // calls if you need to, after you've called initFS)
    void initFS(char* argv0, bool mountBaseDir = true);
    void addFSPath(const char* pathname, const char* mountname, int append);
    void setWriteDir(const char* writepath);

    std::ostream& logStream(int log_level);
    void logMessage(int log_level, const char* msg);

    Interpreter* getInterpreter(int idx);
    Interpreter* getNamedInterpreter(const char* name);
    Interpreter* spawnInterpreter(const char* name);

    // block until all interpreters have finished
    void waitForInterpreters();

    void stopAllInterpreters();

    int numInterpreters();
    void dispatchMessage(int targetIdx, truss_message* msg);

    void acquireMessage(truss_message* msg);
    void releaseMessage(truss_message* msg);
    truss_message* copyMessage(truss_message* src);
    truss_message* allocateMessage(size_t dataLength);
    void deallocateMessage(truss_message* msg);

    int checkFile(const char* filename);
    truss_message* loadFile(const char* filename);
    truss_message* loadFileRaw(const char* filename);
    void saveFile(const char* filename, truss_message* data);
    void saveFileRaw(const char* filename, truss_message* data);

    truss_message* getStoreValue(const std::string& key);
    int setStoreValue(const std::string& key, truss_message* val);
    int setStoreValue(const std::string& key, const std::string& val);

    ~Core();
private:
    static Core* core__;

    Core();
    tthread::mutex coreLock_;
    bool physFSInitted_;
    std::vector<Interpreter*> interpreters_;
    std::map<std::string, truss_message*> store_;
    std::ofstream logfile_;
};

// syntax sugar to avoid the verbose
// truss::Core::getCore()
inline Core* core() {
    return Core::getCore();
}

} // namespace truss

#endif // TRUSS_CORE_H_
