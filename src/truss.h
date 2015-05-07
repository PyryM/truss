// C++ truss header

#ifndef TRSS_H_HEADER_GUARD
#define TRSS_H_HEADER_GUARD

#include "trussapi.h"
#include <string>
#include <vector>

#include "SDL_thread.h"

namespace trss {

	class Interpreter;

	// Pure virtual class for addons
	class Addon {
	public:
		virtual std::string getName() = 0;
		virtual std::string getCHeader() = 0;
		virtual void init(Interpreter* owner) = 0;
		virtual void shutdown() = 0;
		virtual void update(double dt) = 0;
		virtual ~Addon(); // needed so it can be deleted cleanly
	};

	class Interpreter {
	public:
		Interpreter(const char* name);
		~Interpreter();

		// Get the interpreter's name
		const std::string& getName() const;

		// the attached addon is considered to be owned by 
		// the interpreter and will be deleted by it when the
		// interpreter shuts down
		void attachAddon(Addon* addon);
		int numAddons();
		Addon* getAddon(int idx);

		// Starting and stopping
		void start(trss_message* arg);
		void stop();

		// Request an execution
		void execute();

		// Send a message
		void sendMessage(trss_message* message);
		int fetchMessages();
		trss_message* getMessage(int index);

		// Inner thread
		void _threadEntry();
	private:
		// Name
		std::string _name;

		// Call into the actual lua/terra interpreter
		void _safeLuaCall(const char* funcname);

		// List of addons
		std::vector<Addon*> _addons;

		// Actual thread
		SDL_Thread* _thread;

		// Lock for messaging
		SDL_Mutex* _messageLock;

		// Messages
		std::vector<trss_message*> _curMessages;
		std::vector<trss_message*> _fetchedMessages;

		// Lock for execution
		// (only used if not autoexecuting)
		SDL_Mutex* _execLock;

		// Terra state
		lua_State* _terraState;

		// Whether to continue running
		bool _running;

		bool _autoExecute;
		bool _executeOnMessage;
		bool _executeNext;
	};

	static int run_interpreter_thread(void* interpreter);

	class Core {
	public:
		static Core* getCore();

		logMessage(int log_level, const char* msg);

		Interpreter* getInterpreter(int idx);
		int findInterpreter(const char* name);
		int spawnInterpreter(const char* name);
		void startInterpreter(int idx, trss_message* arg);
		void stopInterpreter(int idx);
		void executeInterpreter(int idx);
		int numInterpreters();
		void dispatchMessage(int targetIdx, trss_message* msg);

		void acquireMessage(trss_message* msg);
		void releaseMessage(trss_message* msg);
		trss_message* copyMessage(trss_message* src);
		trss_message* allocateMessage(int dataLength);
		void deallocateMessage(trss_message* msg);

		trss_message* loadFile(const char* filename, int path_type);
		void saveFile(const char* filename, int path_type, trss_message* data);

		~Core();
	private:
		Core();

		static Core* __core;
		std::vector<Interpreter*> _interpreters;
	};
}

#endif