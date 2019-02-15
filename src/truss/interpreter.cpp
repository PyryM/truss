#include "interpreter.h"
#include "core.h"

// TODO: switch to a better logging framework
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstring>
#include <external/bx_utils.h> // has to be included early or else luaconfig.h will clobber winver
#include <trussapi.h>
#include <physfs.h>

using namespace truss;

void run_interpreter_thread(void* interpreter) {
    Interpreter* target = (Interpreter*)interpreter;
    target->threadLoop_();
}

Interpreter::Interpreter(int id)
    : thread_(NULL)
    , terraState_(NULL)
    , id_(id)
	, state_(THREAD_NOT_STARTED)
	, stepRequested_(false)
{
    // TODO: Is any of this necessary?
    curMessages_ = new std::vector < truss_message* > ;
    fetchedMessages_ = new std::vector < truss_message* >;
}

Interpreter::~Interpreter() {
    // TODO: delete message queues here
}

int Interpreter::getID() const {
    return id_;
}

void Interpreter::attachAddon(Addon* addon) {
	addons_.push_back(addon);
}

int Interpreter::numAddons() {
    return (int)(addons_.size());
}

Addon* Interpreter::getAddon(int idx) {
    if(idx >= 0 && idx < addons_.size()) {
        return addons_[idx];
    } else {
        return NULL;
    }
}

void Interpreter::setDebug(int debugLevel) {
    if (debugLevel > 0) {
        verboseLevel_ = debugLevel;
        debugEnabled_ = 1;
    } else {
        verboseLevel_ = 0;
        debugEnabled_ = 0;
    }
}

void Interpreter::start(const char* arg, bool multithreaded) {
	if (state_ != THREAD_NOT_STARTED) {
		core().logMessage(TRUSS_LOG_ERROR, "Can't start interpreter: in wrong state.");
		return;
	}

    terraState_ = luaL_newstate();
    if (!terraState_) {
        core().logMessage(TRUSS_LOG_ERROR, "Error creating a new Lua state.");
        state_ = THREAD_ERROR;
        return;
    }

    luaL_openlibs(terraState_);
    terra_Options* opts = new terra_Options;
    opts->verbose = verboseLevel_;
    opts->debug = debugEnabled_;
    terra_initwithoptions(terraState_, opts);
    delete opts; // not sure if necessary or desireable

    // Set some globals
    lua_pushnumber(terraState_, id_);
    lua_setglobal(terraState_, "TRUSS_INTERPRETER_ID");

    // load and execute the bootstrap script
    truss_message* bootstrap = core().loadFile("scripts/core/core.t");
    if (!bootstrap) {
        core().logMessage(TRUSS_LOG_ERROR, "Error loading core script.");
        core().setError(1000);
        state_ = THREAD_ERROR;
        return;
    }
    int res = terra_loadbuffer(terraState_,
                     (char*)bootstrap->data,
                     bootstrap->data_length,
                     "core.t");
    truss_release_message(bootstrap);
    if(res != 0) {
        core().logPrint(TRUSS_LOG_ERROR, "Error parsing core.t: %s",
                        lua_tostring(terraState_, -1));
        core().setError(1001);
        state_ = THREAD_ERROR;
        return;        
    }

    res = lua_pcall(terraState_, 0, 0, 0);
    if(res != 0) {
        core().logPrint(TRUSS_LOG_ERROR, "Error in core.t: %s",
                        lua_tostring(terraState_, -1));
        core().setError(1001);
        state_ = THREAD_ERROR;
        return;
    }

    // Init all the addons
    for(size_t i = 0; i < addons_.size(); ++i) {
        addons_[i]->init(this);
    }

    // Call init
    if (!call("_core_init", arg)) {
        core().logPrint(TRUSS_LOG_ERROR, "Error in core_init, stopping interpreter [%d].", id_);
        core().setError(1002);
        state_ = THREAD_ERROR;
    }

	state_ = THREAD_IDLE;
	if (multithreaded) {
		thread_ = new std::thread(run_interpreter_thread, this);
	}
}

void Interpreter::stop() {
	std::lock_guard<std::mutex> statelock(stateLock_);
	state_ = THREAD_TERMINATED;
	if (thread_ != NULL && thread_->joinable()) {
		thread_->join();
		delete thread_;
		thread_ = NULL;
	}
}

truss_interpreter_state Interpreter::step() {
	if (thread_ == NULL) {
		return step_();
	}
	if (getState() != THREAD_IDLE) {
		return state_;
	}
	{
		std::lock_guard<std::mutex> lock(stepLock_);
		std::lock_guard<std::mutex> statelock(stateLock_);
		state_ = THREAD_RUNNING;
		stepRequested_ = true;
	}
	stepCV_.notify_one();
	return state_;
}

truss_interpreter_state Interpreter::step_() {
	// update addons
	for (unsigned int i = 0; i < addons_.size(); ++i) {
		addons_[i]->update(1.0 / 60.0);
	}

	// update lua
	if (!call("_core_update")) {
		core().logPrint(TRUSS_LOG_ERROR, "Uncaught error reached C++, quitting.");
		core().setError(2000);
		state_ = THREAD_ERROR;
	}

	return state_;
}

truss_interpreter_state Interpreter::getState() {
	std::lock_guard<std::mutex> lock(stateLock_);
	return state_;
}

void Interpreter::threadLoop_() {
	while (true) {
		std::unique_lock<std::mutex> lock(stepLock_);
		{
			std::lock_guard<std::mutex> statelock(stateLock_);
			if (state_ == THREAD_TERMINATED || state_ == THREAD_ERROR) {
				break;
			}
			state_ = THREAD_IDLE;
		}
		stepCV_.wait(lock);
		if (!stepRequested_) {
			continue; // handle spurious unlocks
		}
		step_();
		stepRequested_ = false;
	}
}

void Interpreter::sendMessage(truss_message* message) {
    std::lock_guard<std::mutex> lock(messageLock_);
    truss_acquire_message(message);
    curMessages_->push_back(message);
}

int Interpreter::fetchMessages() {
    std::lock_guard<std::mutex> Lock(messageLock_);

    // swap messages
    std::vector<truss_message*>* temp = curMessages_;
    curMessages_ = fetchedMessages_;
    fetchedMessages_ = temp;

    // clear the 'current' messages (i.e., the old fetched messages)
    for(unsigned int i = 0; i < curMessages_->size(); ++i) {
        truss_release_message((*curMessages_)[i]);
    }
    curMessages_->clear();
    return fetchedMessages_->size();
}

truss_message* Interpreter::getMessage(int index) {
    // Note: don't need to lock because only 'our' thread
    // should call fetchMessages (which is the only other function
    // that touches fetchedMessages_)
    return (*fetchedMessages_)[index];
}

bool Interpreter::call(const char* funcname, const char* argstr) {
    int nargs = 0;
    lua_getglobal(terraState_, funcname);
    if(argstr != NULL) {
        nargs = 1;
        lua_pushstring(terraState_, argstr);
    }
    int res = lua_pcall(terraState_, nargs, 0, 0);
    if(res != 0) {
        core().logMessage(TRUSS_LOG_ERROR, lua_tostring(terraState_, -1));
    }
    lua_settop(terraState_, 0); // clear stack to avoid overflows
    return res == 0; // return true is no errors
}
