// C++ truss implementation

// TODO: switch to a better logging framework
#include <iostream>
#include <fstream>
#include "bx_utils.h" // has to be included early or else luaconfig.h will clobber winver
#include "trussapi.h"
#include "truss.h"
#include "terra.h"

using namespace trss;

Interpreter::Interpreter(int id, const char* name) {
		thread_ = NULL;
		messageLock_ = SDL_CreateMutex();
		execLock_ = SDL_CreateMutex();
		terraState_ = NULL;
		running_ = false;
		name_ = name;
		id_ = id;
		curMessages_ = new std::vector < trss_message* > ;
		fetchedMessages_ = new std::vector < trss_message* >;
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
	if(!running_ && thread_ == NULL) {
		addons_.push_back(addon);
	} else {
		std::cout << "Cannot attach addon to running interpreter.\n";
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
		std::cout << "Warning: Changing debug level on a running interpreter has no effect!\n";
	}

	if (debugLevel > 0) {
		verboseLevel_ = debugLevel;
		debugEnabled_ = 1;
	} else {
		verboseLevel_ = 0;
		debugEnabled_ = 0;
	}
}

int run_interpreter_thread(void* interpreter) {
	Interpreter* target = (Interpreter*)interpreter;
	target->threadEntry();
	return 0;
}

void Interpreter::start(const char* arg) {
	if(thread_ != NULL || running_) {
		std::cout << "Can't start interpreter twice: already running\n"; 
		return;
	}

	arg_ = arg;
	running_ = true;
	thread_ = SDL_CreateThread(run_interpreter_thread, 
								name_.c_str(), 
								(void*)this);
}

void Interpreter::startUnthreaded(const char* arg) {
	if(thread_ != NULL || running_) {
		std::cout << "Can't start interpreter twice: already running\n"; 
		return;
	}

	arg_ = arg;
	running_ = true;
	threadEntry();
}

void Interpreter::stop() {
	running_ = false;
}

void Interpreter::execute() {
	std::cout << "Interpreter::execute not implemented!\n";
	// TODO: make this do something
}

void Interpreter::threadEntry() {
	terraState_ = luaL_newstate();
	luaL_openlibs(terraState_);
	terra_Options* opts = new terra_Options;
	opts->verbose = verboseLevel_;
	opts->debug = debugEnabled_;
	terra_initwithoptions(terraState_, opts);
	delete opts; // not sure if necessary or desireable

	// Set some globals
	lua_pushnumber(terraState_, id_);
	lua_setglobal(terraState_, "TRSS_INTERPRETER_ID");

	// load and execute the bootstrap script
	trss_message* bootstrap = trss_load_file("scripts/core/bootstrap.t", TRSS_CORE_PATH);
	if (!bootstrap) {
		std::cout << "Error loading bootstrap script.\n";
		running_ = false;
		return;
	}
	terra_loadbuffer(terraState_, 
                     (char*)bootstrap->data, 
                     bootstrap->data_length, 
                     "bootstrap.t");
	trss_release_message(bootstrap);
	int res = lua_pcall(terraState_, 0, 0, 0);
	if(res != 0) {
		std::cout << "Error bootstrapping interpreter: " 
				  << lua_tostring(terraState_, -1) << std::endl;
		running_ = false;
		return;
	}

	// Init all the addons
	for(size_t i = 0; i < addons_.size(); ++i) {
		addons_[i]->init(this);
	}

	// Call init
	if (!safeLuaCall("_coreInit", arg_.c_str())) {
		std::cout << "Error in coreInit, stopping interpreter [" << id_ << "]\n";
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
		safeLuaCall("_coreUpdate");
	}

	// Shutdown
	std::cout << "Shutting down.\n";
	// TODO: actually shutdown stuff here
}

void Interpreter::sendMessage(trss_message* message) {
	SDL_LockMutex(messageLock_);
	trss_acquire_message(message);
	curMessages_->push_back(message);
	SDL_UnlockMutex(messageLock_);
}

int Interpreter::fetchMessages() {
	SDL_LockMutex(messageLock_);
	// swap messages
	std::vector<trss_message*>* temp = curMessages_;
	curMessages_ = fetchedMessages_;
	fetchedMessages_ = temp;

	// clear the 'current' messages (i.e., the old fetched messages)
	for(unsigned int i = 0; i < curMessages_->size(); ++i) {
		trss_release_message((*curMessages_)[i]);
	}
	curMessages_->clear();
	size_t numMessages = fetchedMessages_->size();

	SDL_UnlockMutex(messageLock_);
	return (int)(numMessages);
}

trss_message* Interpreter::getMessage(int index) {
	// Note: don't need to lock because only 'our' thread
	// should call fetchMessages (which is the only other function
	// that touches fetchedMessages_)
	return (*fetchedMessages_)[index];
}

bool Interpreter::safeLuaCall(const char* funcname, const char* argstr) {
	int nargs = 0;
	lua_getglobal(terraState_, funcname);
	if(argstr != NULL) {
		nargs = 1;
		lua_pushstring(terraState_, argstr);	
	}
	int res = lua_pcall(terraState_, nargs, 0, 0);
	if(res != 0) {
		std::cout << lua_tostring(terraState_, -1) << std::endl;
	}
	return res == 0; // return true is no errors
}

const char* trss_get_version_string() {
	return TRSS_VERSION_STRING;
}

void trss_test() {
	std::cout << ">>>>>>>>>>>>>> TRSS_TEST CALLED <<<<<<<<<<<<<\n";
}

void trss_log(int log_level, const char* str){
	Core::getCore()->logMessage(log_level, str);
}

void trss_shutddown() {
	Core::getCore()->stopAllInterpreters();
}

uint64_t trss_get_hp_time() {
	return bx::getHPCounter();
}

uint64_t trss_get_hp_freq() {
	return bx::getHPFrequency();
}

trss_message* trss_load_file(const char* filename, int path_type){
	return Core::getCore()->loadFile(filename, path_type);
}

/* Note that when saving the message_type field is not saved */
int trss_save_file(const char* filename, int path_type, trss_message* data){
	Core::getCore()->saveFile(filename, path_type, data);
	return 0; // TODO: actually check for errors
}

/* Datastore functions */
trss_message* trss_get_store_value(const char* key) {
	std::string tempkey(key);
	return Core::getCore()->getStoreValue(tempkey);
}

int trss_set_store_value(const char* key, trss_message* val) {
	std::string tempkey(key);
	return Core::getCore()->setStoreValue(tempkey, val);
}

int trss_set_store_value_str(const char* key, const char* msg) {
	std::string tempkey(key);
	std::string tempmsg(msg);
	return Core::getCore()->setStoreValue(tempkey, tempmsg);
}

/* Interpreter management functions */
int trss_spawn_interpreter(const char* name){
	Interpreter* spawned = Core::getCore()->spawnInterpreter(name);
	return spawned->getID();
}

void trss_set_interpreter_debug(trss_interpreter_id target_id, int debug_level) {
	Core::getCore()->getInterpreter(target_id)->setDebug(debug_level);
}

void trss_start_interpreter(trss_interpreter_id target_id, const char* msgstr) {
	Core::getCore()->getInterpreter(target_id)->start(msgstr);
}

void trss_stop_interpreter(trss_interpreter_id target_id){
	Core::getCore()->getInterpreter(target_id)->stop();
}

void trss_execute_interpreter(trss_interpreter_id target_id){
	return Core::getCore()->getInterpreter(target_id)->execute();
}

int trss_find_interpreter(const char* name){
	return Core::getCore()->getNamedInterpreter(name)->getID();
}

void trss_send_message(trss_interpreter_id dest, trss_message* message){
	Core::getCore()->dispatchMessage(dest, message);
}

int trss_fetch_messages(trss_interpreter_id idx){
	Interpreter* interpreter = Core::getCore()->getInterpreter(idx);
	if(interpreter) {
		return interpreter->fetchMessages();
	} else {
		return -1;
	}
}

trss_message* trss_get_message(trss_interpreter_id idx, int message_index){
	Interpreter* interpreter = Core::getCore()->getInterpreter(idx);
	if(interpreter) {
		return interpreter->getMessage(message_index);
	} else {
		return NULL;
	}
}

int trss_get_addon_count(trss_interpreter_id target_id) {
	Interpreter* interpreter = Core::getCore()->getInterpreter(target_id);
	if(interpreter) {
		return interpreter->numAddons();
	} else {
		return -1;
	}
}

Addon* trss_get_addon(trss_interpreter_id target_id, int addon_idx) {
	Interpreter* interpreter = Core::getCore()->getInterpreter(target_id);
	if(interpreter) {
		return interpreter->getAddon(addon_idx);
	} else {
		return NULL;
	}
}

const char* trss_get_addon_name(trss_interpreter_id target_id, int addon_idx) {
	Addon* addon = trss_get_addon(target_id, addon_idx);
	if (addon) {
		return addon->getName().c_str();
	}
	else {
		return "";
	}
}

const char* trss_get_addon_header(trss_interpreter_id target_id, int addon_idx) {
	Addon* addon = trss_get_addon(target_id, addon_idx);
	if(addon) {
		return addon->getCHeader().c_str();
	} else {
		return "";
	}
}

/* Message management functions */
trss_message* trss_create_message(unsigned int data_length){
	return Core::getCore()->allocateMessage(data_length);
}

void trss_acquire_message(trss_message* msg){
	if (msg != NULL) {
		++(msg->refcount);
	}
}

void trss_release_message(trss_message* msg){
	if (msg != NULL) {
		--(msg->refcount);
		if (msg->refcount <= 0) {
			Core::getCore()->deallocateMessage(msg);
		}
	}
}

trss_message* trss_copy_message(trss_message* src){
	if (src == NULL) {
		return NULL;
	}

	trss_message* newmsg = Core::getCore()->allocateMessage(src->data_length);
	newmsg->message_type = src->message_type;
	memcpy(newmsg->data, src->data, newmsg->data_length);
	return newmsg;
}

Core* Core::core__ = NULL;

Core* Core::getCore() {
	if(core__ == NULL) {
		core__ = new Core();
	}
	return core__;
}

void Core::logMessage(int log_level, const char* msg) {
	SDL_LockMutex(coreLock_);
	// just dump to standard out for the moment
	std::cout << log_level << "|" << msg << std::endl;
	SDL_UnlockMutex(coreLock_);
}

Interpreter* Core::getInterpreter(int idx){
	Interpreter* ret = NULL;
	SDL_LockMutex(coreLock_);
	if(idx >= 0 && idx < interpreters_.size()) {
		ret = interpreters_[idx];
	}
	SDL_UnlockMutex(coreLock_);
	return ret;
}

Interpreter* Core::getNamedInterpreter(const char* name){
	std::string sname(name);
	Interpreter* ret = NULL;
	SDL_LockMutex(coreLock_);
	for(size_t i = 0; i < interpreters_.size(); ++i) {
		if(interpreters_[i]->getName() == sname) {
			ret = interpreters_[i];
			break;
		}
	}
	SDL_UnlockMutex(coreLock_);
	return ret;
}

Interpreter* Core::spawnInterpreter(const char* name){
	SDL_LockMutex(coreLock_);
	Interpreter* interpreter = new Interpreter((int)(interpreters_.size()), name);
	interpreters_.push_back(interpreter);
	SDL_UnlockMutex(coreLock_);
	return interpreter;
}

void Core::stopAllInterpreters() {
	SDL_LockMutex(coreLock_);
	for (unsigned int i = 0; i < interpreters_.size(); ++i) {
		interpreters_[i]->stop();
	}
	SDL_UnlockMutex(coreLock_);
}

int Core::numInterpreters(){
	int ret = 0;
	SDL_LockMutex(coreLock_);
	ret = (int)(interpreters_.size());
	SDL_UnlockMutex(coreLock_);
	return ret;
}

void Core::dispatchMessage(int targetIdx, trss_message* msg){
	Interpreter* interpreter = getInterpreter(targetIdx);
	if(interpreter) {
		interpreter->sendMessage(msg);
	}
}

void Core::acquireMessage(trss_message* msg){
	SDL_LockMutex(coreLock_);
	++(msg->refcount);
	SDL_UnlockMutex(coreLock_);
}

void Core::releaseMessage(trss_message* msg){
	SDL_LockMutex(coreLock_);
	--(msg->refcount);
	if(msg->refcount <= 0) {
		deallocateMessage(msg);
	}
	SDL_UnlockMutex(coreLock_);
}

trss_message* Core::copyMessage(trss_message* src){
	SDL_LockMutex(coreLock_);
	trss_message* newmsg = allocateMessage(src->data_length);
	newmsg->message_type = src->message_type;
	memcpy(newmsg->data, src->data, newmsg->data_length);
	SDL_UnlockMutex(coreLock_);
	return newmsg;
}

trss_message* Core::allocateMessage(int dataLength){
	trss_message* ret = new trss_message;
	ret->data = new unsigned char[dataLength];
	ret->data_length = dataLength;
	ret->refcount = 1;
	return ret;
}

void Core::deallocateMessage(trss_message* msg){
	delete[] msg->data;
	delete msg;
}

std::string Core::resolvePath(const char* filename, int path_type) {
	// just return the filename for now
	std::string ret(filename);
	return ret;
}

trss_message* Core::loadFile(const char* filename, int path_type) {
	std::string truepath = resolvePath(filename, path_type);

	std::streampos size;
	std::ifstream file(truepath.c_str(), std::ios::in|std::ios::binary|std::ios::ate);
	if (file.is_open())
	{
		size = file.tellg();
		trss_message* ret = allocateMessage((int)size);
		file.seekg (0, std::ios::beg);
		file.read ((char*)(ret->data), size);
		file.close();

		return ret;
	} else {
		std::cout << "Unable to open file " << filename << "\n";
		return NULL;	
	} 
}

void Core::saveFile(const char* filename, int path_type, trss_message* data) {
	std::string truepath = resolvePath(filename, path_type);

	std::ofstream outfile;
	outfile.open(truepath.c_str(), std::ios::binary | std::ios::out);
	outfile.write((char*)(data->data), data->data_length);
	outfile.close();
}

trss_message* Core::getStoreValue(const std::string& key) {
	if (store_.count(key) > 0) {
		return store_[key];
	} else {
		return NULL;
	}
}

int Core::setStoreValue(const std::string& key, trss_message* val) {
	acquireMessage(val);
	if (store_.count(key) > 0) {
		trss_message* oldmsg = store_[key];
		store_[key] = val;
		releaseMessage(oldmsg);
		return 1;
	} else {
		store_[key] = val;
		return 0;
	}
}

int Core::setStoreValue(const std::string& key, const std::string& val) {
	trss_message* newmsg = allocateMessage(val.length());
	const char* src = val.c_str();
	memcpy(newmsg->data, src, newmsg->data_length);
	int result = setStoreValue(key, newmsg);
	releaseMessage(newmsg); // avoid double-acquiring this message
	return result;
}

Core::~Core(){
	// eeeehn
}

Core::Core(){
	coreLock_ = SDL_CreateMutex();
}
