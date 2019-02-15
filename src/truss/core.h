#ifndef TRUSS_CORE_H_
#define TRUSS_CORE_H_

#include "interpreter.h"

#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <thread>
#include <terra/terra.h>
#include <trussapi.h>

namespace truss {

class Core {
public:
    static Core& instance();

    // functions for dealing with physfs (you can also make direct physfs
    // calls if you need to, after you've called initFS)
    void initFS(char* argv0, bool mountBaseDir=true);
    void addFSPath(const char* pathname, const char* mountname, bool append=true);
    void setWriteDir(const char* writepath);
	void setRawWriteDir(const char* path, bool mount=true);
    void extractLibraries();

    std::ostream& logStream(int log_level);
    void logMessage(int log_level, const char* msg);
    void logPrint(int log_level, const char* format, ...);
    void setError(int errcode);
    int getError();

    Interpreter* getInterpreter(int idx);
    Interpreter* spawnInterpreter();

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
	const char* getFileRealPath(const char* filename);
    truss_message* loadFile(const char* filename);
    truss_message* loadFileRaw(const char* filename);
    void saveFile(const char* filename, truss_message* data);
    void saveFileRaw(const char* filename, truss_message* data);
    void saveData(const char* filename, const char* data, unsigned int datalength);
    void saveDataRaw(const char* filename, const char* data, unsigned int datalength);
    int listDirectory(int interpreter, const char* dirpath);
    const char* getStringResult(int interpreter, int idx);
    void clearStringResults(int interpreter);

    truss_message* getStoreValue(const std::string& key);
    int setStoreValue(const std::string& key, truss_message* val);
    int setStoreValue(const std::string& key, const std::string& val);

    ~Core();
private:
    Core();

    // Mark core as non-copyable.
    Core(const Core&) = delete;
    Core& operator=(const Core&) = delete;

    std::mutex coreLock_;
    bool physFSInitted_;
    std::vector<Interpreter*> interpreters_;
    std::vector<std::vector<std::string>> stringResults_;
    std::map<std::string, truss_message*> store_;
    std::ofstream logfile_;

    int errCode_;
};

// syntax sugar to avoid the verbose
// truss::Core::getCore()
inline Core& core() {
    return Core::instance();
}

} // namespace truss

#endif // TRUSS_CORE_H_
