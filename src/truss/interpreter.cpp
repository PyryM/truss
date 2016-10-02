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
    target->threadEntry();
}

Interpreter::Interpreter(int id, const char* name)
    : thread_(NULL)
    , running_(false)
    , terraState_(NULL)
    , name_(name)
    , id_(id)
{
    // TODO: Is any of this necessary?
    curMessages_ = new std::vector < truss_message* > ;
    fetchedMessages_ = new std::vector < truss_message* >;
    arg_ = "";
}

Interpreter::~Interpreter() {
    // TODO: delete message queues here
}

const std::string& Interpreter::getName() const {
    return name_;
}

int Interpreter::getID() const {
    return id_;
}

void Interpreter::attachAddon(Addon* addon) {
    if(!running_) {
        addons_.push_back(addon);
    } else {
        core().logMessage(TRUSS_LOG_ERROR, "Cannot attach addon to running interpreter.");
        delete addon;
    }
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
    if (running_) {
        core().logMessage(TRUSS_LOG_WARNING, "Warning: Changing debug level on a running interpreter has no effect!");
    }

    if (debugLevel > 0) {
        verboseLevel_ = debugLevel;
        debugEnabled_ = 1;
    } else {
        verboseLevel_ = 0;
        debugEnabled_ = 0;
    }
}

void Interpreter::start(const char* arg) {
    if(running_ || thread_ != NULL) {
        core().logMessage(TRUSS_LOG_ERROR, "Can't start interpreter twice: already running");
        return;
    }

    // TODO: should this be locked?
    arg_ = arg;
    running_ = true;
    thread_ = new tthread::thread(run_interpreter_thread, this);
}

void Interpreter::startUnthreaded(const char* arg) {
    if(running_ || thread_ != NULL) {
        core().logMessage(TRUSS_LOG_ERROR, "Can't start interpreter twice: already running");
        return;
    }

    // TODO: should this be locked?
    arg_ = arg;
    running_ = true;
    threadEntry();
}

void Interpreter::stop() {
    running_ = false;
    if (thread_ != NULL && thread_->joinable()) {
        thread_->join();
        delete thread_;
    }
}

void Interpreter::execute() {
    core().logMessage(TRUSS_LOG_ERROR, "Interpreter::execute not implemented!");
    // TODO: make this do something
}

void Interpreter::threadEntry() {
    terraState_ = luaL_newstate();
    if (!terraState_) {
        core().logMessage(TRUSS_LOG_ERROR, "Error creating a new Lua state.");
        running_ = false;
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
    truss_message* bootstrap = core().loadFile("scripts/core/bootstrap.t");
    if (!bootstrap) {
        core().logMessage(TRUSS_LOG_ERROR, "Error loading bootstrap script.");
        core().setError(1000);
        running_ = false;
        return;
    }
    terra_loadbuffer(terraState_,
                     (char*)bootstrap->data,
                     bootstrap->data_length,
                     "bootstrap.t");
    truss_release_message(bootstrap);
    int res = lua_pcall(terraState_, 0, 0, 0);
    if(res != 0) {
        core().logPrint(TRUSS_LOG_ERROR, "Error bootstrapping interpreter: %s",
                        lua_tostring(terraState_, -1));
        core().setError(1001);
        running_ = false;
        return;
    }

    // Init all the addons
    for(size_t i = 0; i < addons_.size(); ++i) {
        addons_[i]->init(this);
    }

    // Call init
    if (!call("_coreInit", arg_.c_str())) {
        core().logPrint(TRUSS_LOG_ERROR, "Error in coreInit, stopping interpreter [%d].", id_);
        core().setError(1002);
        running_ = false;
    }

    double dt = 1.0 / 60.0; // just fudge this at the moment

    // Enter thread main loop
    while(running_) {
        // update addons
        for(unsigned int i = 0; i < addons_.size(); ++i) {
            addons_[i]->update(dt);
        }

        // update lua
        if (!call("_coreUpdate")) {
          core().logPrint(TRUSS_LOG_ERROR, "Uncaught error reached C++, quitting.");
          core().setError(2000);
          running_ = false;
        }
    }

    // Shutdown
    core().logMessage(TRUSS_LOG_INFO, "Shutting down.");
    // TODO: actually shutdown stuff here
}

void Interpreter::sendMessage(truss_message* message) {
    tthread::lock_guard<tthread::mutex> Lock(messageLock_);
    truss_acquire_message(message);
    curMessages_->push_back(message);
}

int Interpreter::fetchMessages() {
    tthread::lock_guard<tthread::mutex> Lock(messageLock_);

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
