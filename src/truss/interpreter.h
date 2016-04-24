#ifndef TRUSS_INTERPRETER_H_
#define TRUSS_INTERPRETER_H_

#include "addon.h"

#include <external/tinythread.h>
#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <terra/terra.h>
#include <trussapi.h>

namespace trss {

class Interpreter {
public:
    Interpreter(int id, const char* name);
    ~Interpreter();

    // Get the interpreter's ID
    int getID() const;

    // Get the interpreter's name
    const std::string& getName() const;

    // the attached addon is considered to be owned by
    // the interpreter and will be deleted by it when the
    // interpreter shuts down
    void attachAddon(Addon* addon);
    int numAddons();
    Addon* getAddon(int idx);

    // Set debug mode on/off (default: off)
    // Must be called before starting
    void setDebug(int debugLevel);

    // Starting and stopping
    void start(const char* arg);
    void startUnthreaded(const char* arg);
    void stop();

    // Request an execution
    void execute();

    // Send a message
    void sendMessage(trss_message* message);
    int fetchMessages();
    trss_message* getMessage(int index);

    // Inner thread
    void threadEntry();
private:
    // ID
    int id_;

    // Name
    std::string name_;

    // Argument when starting
    std::string arg_;

    // Debug settings (ints because that's what terra wants)
    int verboseLevel_;
    int debugEnabled_;

    // Call into the actual lua/terra interpreter
    bool safeLuaCall(const char* funcname, const char* argstr = NULL);

    // List of addons
    std::vector<Addon*> addons_;

    // Actual thread
    tthread::thread* thread_;

    // Lock for messaging
    tthread::mutex messageLock_;

    // Messages
    std::vector<trss_message*>* curMessages_;
    std::vector<trss_message*>* fetchedMessages_;

    // Terra state
    lua_State* terraState_;

    // Whether to continue running
    bool running_;
};

} // namespace trss

#endif // TRUSS_INTERPRETER_H_
