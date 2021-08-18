#ifndef TRUSS_INTERPRETER_H_
#define TRUSS_INTERPRETER_H_

#include <thread>
#include <mutex>
#include <condition_variable>
#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <terra/terra.h>
#include <trussapi.h>

namespace truss {

class Interpreter {
public:
    Interpreter(int id);
    ~Interpreter();

    // Get the interpreter's ID
    int getID() const;

    // Set debug mode on/off (default: off)
    // Must be called before starting
    void setDebug(int debugLevel);

    // Starting and stopping
    void start(const char* arg, bool multithreaded);
    void stop();
	bool step();
	void step_();
	truss_interpreter_state getState();

    // Send a message
    void sendMessage(truss_message* message);
    int fetchMessages();
    truss_message* getMessage(int index);

	void threadLoop_();
private:
    // ID
    int id_;

	// Current state
	truss_interpreter_state state_;
	std::mutex stateLock_;
	bool setState_(truss_interpreter_state newState);

    // Debug settings (ints because that's what terra wants)
    int verboseLevel_;
    int debugEnabled_;

    // Call into the actual lua/terra interpreter
    bool call(const char* funcname, const char* argstr = NULL);

    // Actual thread
    std::thread* thread_;

	// Lock for thread signaling
	std::mutex stepLock_;
	bool stepRequested_;
	std::condition_variable stepCV_;

    // Lock for messaging
    std::mutex messageLock_;

    // Messages
    std::vector<truss_message*>* curMessages_;
    std::vector<truss_message*>* fetchedMessages_;

    // Terra state
    lua_State* terraState_;
};

} // namespace truss

#endif // TRUSS_INTERPRETER_H_
