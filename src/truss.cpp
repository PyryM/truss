// C++ truss implementation

// TODO: switch to a better logging framework
#include <iostream>

using namespace trss;

Interpreter::Interpreter() {
		_thread = NULL;
		_messageLock = SDL_CreateMutex();
		_execLock = SDL_CreateMutex();
		_terraState = NULL;
		_running = false;
		_autoExecute = true;
		_executeOnMessage = false;
		_executeNext = false;
}

Interpreter::~Interpreter() {
	// Nothing special to do
}

void Interpreter::attachAddon(Addon* addon) {
	if(!_running && _thread == NULL) {
		_addons.push_back(addon);
	} else {
		std::cout << "Cannot attach addon to running interpreter.\n";
		delete addon;
	}
}

void Interpreter::start(trss_message* arg, const char* name) {
	if(_thread != NULL) {
		std::cout << "Can't start interpreter twice: already running\n"; 
		return;
	}

	_running = true;
	_thread = SDL_CreateThread(run_interpreter_thread, 
								name, 
								(void*)this);
}

void Interpreter::stop() {
	_running = false;
}

void Interpreter::_threadEntry() {
	_terraState = luaL_newstate();
	luaL_openlibs(_terraState);
	terra_Options* opts = new terra_Options;
	opts->verbose = 2; // very verbose
	opts->debug = 1; // debug enabled
	terra_initwithoptions(_terraState, opts);
	delete opts; // not sure if necessary or desireable

	// load and execute the bootstrap script
	trss_message* bootstrap = trss_load_file("bootstrap.t", TRSS_CORE_PATH);
	terra_loadbuffer(_terraState, 
                     bootstrap->data, 
                     bootstrap->message_length, 
                     "bootstrap.t");
	int res = lua_pcall(_terraState, 0, 0, 0);
	if(res != 0) {
		std::cout << "Error bootstrapping interpreter: " 
				  << lua_tostring(_terraState, -1) << std::endl;
	}

	// Init all the addons
	for(size_t i = 0; i < _addons.size(); ++i) {
		_addons[i]->init(this);
	}

	// Call init
	_safeLuaCall("_core_init");

	double dt = 1.0 / 60.0; // just fudge this at the moment

	// Enter thread main loop
	while(_running) {
		// update addons
		for(unsigned int i = 0; i < _addons.size(); ++i) {
			_addons[i]->update(dt);
		}

		// update lua
		_safeLuaCall("_core_update");
	}

	// Shutdown
	std::cout << "Shuttind down.\n";
	// TODO: actually shutdown stuff here
}

void Interpreter::sendMessage(trss_message* message) {
	SDL_LockMutex(_messageLock);
	trss_acquire_message(message);
	_curMessages.push_back(message);
	SDL_UnlockMutex(_messageLock);
}

int Interpreter::fetchMessages() {
	SDL_LockMutex(_messageLock);
	// swap messages
	std::vector<trss_message*>* temp = _curMessages;
	_curMessages = _fetchedMessages;
	_fetchedMessages = temp;

	// clear the 'current' messages (i.e., the old fetched messages)
	for(unsigned int i = 0; i < _curMessages.size(); ++i) {
		trss_release_message(_curMessages[i]);
	}
	_curMessages.clear();
	int numMessages = _fetchedMessages.size();

	SDL_UnlockMutex(_messageLock);
	return numMessages;
}

trss_message* Interpreter::getMessage(int index) {
	// Note: don't need to lock because only 'our' thread
	// should call fetchMessages (which is the only other function
	// that touches _fetchedMessages)
	return _fetchedMessages[index];
}

void Interpreter::_safeLuaCall(const char* funcname) {
	lua_getglobal(_terraState, funcname);
	int res = lua_pcall(_terraState, 0, 0, 0);
	if(res != 0) {
		std::cout << lua_tostring(_terraState, -1) << std::endl;
	}
}

int run_interpreter_thread(void* interpreter) {
	Interpreter* target = (Interpreter*)interpreter;
	target->_threadEntry();
}