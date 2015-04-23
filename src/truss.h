// C++ truss header

#include "trussapi.h"

namespace trss {

	class Interpreter {
	public:
		Interpreter();
		~Interpreter();

		// Starting and stopping
		void init(trss_message* arg);
		void start(bool autoexecute, bool executeOnMessage);
		void stop();

		// Request an execution
		void execute();

		// Messaging functions
		void sendMessage(trss_message* message);
		int fetchMessages();
		trss_message* getMessage(int index);
	private:
		// Lock for messaging
		mutex_t _messageLock;

		// Terra state
		lua_State* _terraState;

		bool _autoExecute;
		bool _executeOnMessage;
		bool _executeNext;
	};

	class Core {
	public:
	private:
	};

}