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

		// Starting and stopping
		void start(const char* arg);
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
		// ID
		int _ID;

		// Name
		std::string _name;

		// Call into the actual lua/terra interpreter
		void _safeLuaCall(const char* funcname, const char* argstr = NULL);

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
		Interpreter* getNamedInterpreter(const char* name);
		Interpreter* spawnInterpreter(const char* name);

		// block until all interpreters have finished
		void waitForInterpreters();

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
		static Core* __core;

		Core();
		SDL_Mutex* _coreLock;
		std::vector<Interpreter*> _interpreters;
	};

	Core* core(); // syntax sugar for Core::getCore()
}

#endif