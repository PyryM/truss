// C++ truss header

#ifndef TRSS_H_HEADER_GUARD
#define TRSS_H_HEADER_GUARD

#include "trussapi.h"
#include "external/tinythread.h"

#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <terra/terra.h>

namespace trss {

	class Interpreter;

	// Pure virtual class for addons
	class Addon {
	public:
		// These have to return a string by reference so that
		// e.g. getName().c_str() doesn't go out of scope when
		// the function returns
		virtual const std::string& getName() = 0;

		// Note: the header should use Addon* rather than
		// SubclassAddon* as "this" so that terra doesn't
		// have to deal with casts
		virtual const std::string& getCHeader() = 0;
		virtual const std::string& getVersionString() = 0;
		virtual void init(Interpreter* owner) = 0;
		virtual void shutdown() = 0;
		virtual void update(double dt) = 0;
		virtual ~Addon(){
			// needed so it can be deleted cleanly
		}
	};

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
		void dispatchMessage(int targetIdx, trss_message* msg);

		void acquireMessage(trss_message* msg);
		void releaseMessage(trss_message* msg);
		trss_message* copyMessage(trss_message* src);
		trss_message* allocateMessage(size_t dataLength);
		void deallocateMessage(trss_message* msg);

		int checkFile(const char* filename);
		trss_message* loadFile(const char* filename);
		trss_message* loadFileRaw(const char* filename);
		void saveFile(const char* filename, trss_message* data);
		void saveFileRaw(const char* filename, trss_message* data);

		trss_message* getStoreValue(const std::string& key);
		int setStoreValue(const std::string& key, trss_message* val);
		int setStoreValue(const std::string& key, const std::string& val);

		~Core();
	private:
		static Core* core__;

		Core();
		tthread::mutex coreLock_;
		bool physFSInitted_;
		std::vector<Interpreter*> interpreters_;
		std::map<std::string, trss_message*> store_;
		std::ofstream logfile_;
	};

	// syntax sugar to avoid the verbose
	// trss::Core::getCore()
	inline Core* core() {
		return Core::getCore();
	}
}

#endif
