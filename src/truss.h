// C++ truss header

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
		Interpreter();
		~Interpreter();

		// the attached addon is considered to be owned by 
		// the interpreter and will be deleted by it when the
		// interpreter shuts down
		void attachAddon(Addon* addon);

		// Starting and stopping
		void start(trss_message* arg, const char* name);
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

	class Core {
	public:
	private:
	};

	static int run_interpreter_thread(void* interpreter);

}