// C++ truss implementation

// TODO: switch to a better logging framework
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstring>
#include "bx_utils.h" // has to be included early or else luaconfig.h will clobber winver
#include "trussapi.h"
#include "truss.h"
#include "physfs.h"

using namespace trss;

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
    if(!running_) {
        addons_.push_back(addon);
    } else {
        core()->logMessage(TRSS_LOG_ERROR, "Cannot attach addon to running interpreter.");
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
        core()->logMessage(TRSS_LOG_WARNING, "Warning: Changing debug level on a running interpreter has no effect!");
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
        core()->logMessage(TRSS_LOG_ERROR, "Can't start interpreter twice: already running");
        return;
    }

    // TODO: should this be locked?
    arg_ = arg;
    running_ = true;
    thread_ = new tthread::thread(run_interpreter_thread, this);
}

void Interpreter::startUnthreaded(const char* arg) {
    if(running_ || thread_ != NULL) {
        core()->logMessage(TRSS_LOG_ERROR, "Can't start interpreter twice: already running");
        return;
    }

    // TODO: should this be locked?
    arg_ = arg;
    running_ = true;
    threadEntry();
}

void Interpreter::stop() {
    running_ = false;
    thread_->join();
    delete thread_;
}

void Interpreter::execute() {
    core()->logMessage(TRSS_LOG_ERROR, "Interpreter::execute not implemented!");
    // TODO: make this do something
}

void Interpreter::threadEntry() {
    terraState_ = luaL_newstate();
    if (!terraState_) {
        core()->logMessage(TRSS_LOG_ERROR, "Error creating a new Lua state.");
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
    lua_setglobal(terraState_, "TRSS_INTERPRETER_ID");

    // load and execute the bootstrap script
    trss_message* bootstrap = core()->loadFile("scripts/core/bootstrap.t");
    if (!bootstrap) {
        core()->logMessage(TRSS_LOG_ERROR, "Error loading bootstrap script.");
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
        core()->logStream(TRSS_LOG_ERROR) << "Error bootstrapping interpreter: "
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
        core()->logStream(TRSS_LOG_ERROR) << "Error in coreInit, stopping interpreter [" << id_ << "]\n";
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
    core()->logMessage(TRSS_LOG_INFO, "Shutting down.");
    // TODO: actually shutdown stuff here
}

void Interpreter::sendMessage(trss_message* message) {
    tthread::lock_guard<tthread::mutex> Lock(messageLock_);
    trss_acquire_message(message);
    curMessages_->push_back(message);
}

int Interpreter::fetchMessages() {
    tthread::lock_guard<tthread::mutex> Lock(messageLock_);

    // swap messages
    std::vector<trss_message*>* temp = curMessages_;
    curMessages_ = fetchedMessages_;
    fetchedMessages_ = temp;

    // clear the 'current' messages (i.e., the old fetched messages)
    for(unsigned int i = 0; i < curMessages_->size(); ++i) {
        trss_release_message((*curMessages_)[i]);
    }
    curMessages_->clear();
    return fetchedMessages_->size();
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
        core()->logMessage(TRSS_LOG_ERROR, lua_tostring(terraState_, -1));
    }
    return res == 0; // return true is no errors
}

const char* trss_get_version_string() {
    return TRSS_VERSION_STRING;
}

void trss_test() {
    std::cout << ">>>>>>>>>>>>>> TRSS_TEST CALLED <<<<<<<<<<<<<\n";
    core()->logMessage(TRSS_LOG_CRITICAL, ">>>>>>>>>>>>>> TRSS_TEST CALLED <<<<<<<<<<<<<");
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

int trss_check_file(const char* filename) {
    return Core::getCore()->checkFile(filename);
}

trss_message* trss_load_file(const char* filename){
    return Core::getCore()->loadFile(filename);
}

/* Note that when saving the message_type field is not saved */
int trss_save_file(const char* filename, trss_message* data){
    Core::getCore()->saveFile(filename, data);
    return 0; // TODO: actually check for errors
}

int trss_add_fs_path(const char* path, const char* mountpath, int append) {
    core()->addFSPath(path, mountpath, append);
    return 0;
}

int trss_set_fs_savedir(const char* path) {
    core()->setWriteDir(path);
    return 0;
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

const char* trss_get_addon_version_string(trss_interpreter_id target_id, int addon_idx){
    Addon* addon = trss_get_addon(target_id, addon_idx);
    if (addon) {
        return addon->getVersionString().c_str();
    }
    else {
        return "";
    }
}

/* Message management functions */
trss_message* trss_create_message(size_t data_length){
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
    std::memcpy(newmsg->data, src->data, newmsg->data_length);
    return newmsg;
}

Core* Core::core__ = NULL;

Core* Core::getCore() {
    if(core__ == NULL) {
        core__ = new Core();
    }
    return core__;
}

void Core::initFS(char* argv0, bool mountBaseDir) {
    if (physFSInitted_) {
        logMessage(TRSS_LOG_WARNING, "PhysFS already initted.");
        return;
    }

    int retval = PHYSFS_init(argv0);
    if (mountBaseDir) {
        PHYSFS_mount(PHYSFS_getBaseDir(), "/", 0);
    }

    physFSInitted_ = true;
}

void Core::addFSPath(const char* pathname, const char* mountname, int append) {
    std::stringstream ss;
    ss << PHYSFS_getBaseDir() << PHYSFS_getDirSeparator() << pathname;
    logMessage(TRSS_LOG_DEBUG, "Adding physFS path: ");
    logMessage(TRSS_LOG_DEBUG, ss.str().c_str());

    int retval = PHYSFS_mount(ss.str().c_str(), mountname, append);
    // TODO: do something with the return value (e.g., if it's an error)
}

void Core::setWriteDir(const char* writepath) {
    std::stringstream ss;
    ss << PHYSFS_getBaseDir() << PHYSFS_getDirSeparator() << writepath;
    logMessage(TRSS_LOG_DEBUG, "Setting physFS write path: ");
    logMessage(TRSS_LOG_DEBUG, ss.str().c_str());

    int retval = PHYSFS_setWriteDir(ss.str().c_str());
    // TODO: do something with the return value (e.g., if it's an error)
}

// NOT THREAD SAFE!!!
std::ostream& Core::logStream(int log_level) {
    logfile_ << "[" << log_level << "] ";
    return logfile_;
}

void Core::logMessage(int log_level, const char* msg) {
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    // dump to logfile
    logfile_ << "[" << log_level << "] " << msg << std::endl;
}

Interpreter* Core::getInterpreter(int idx){
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);

    if(idx < 0)
        return NULL;
    if (idx >= interpreters_.size())
        return NULL;
    return interpreters_[idx];
}

Interpreter* Core::getNamedInterpreter(const char* name){
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);

    std::string sname(name);
    for(size_t i = 0; i < interpreters_.size(); ++i) {
        if(interpreters_[i]->getName() == sname) {
            return interpreters_[i];
        }
    }
    return NULL;
}

Interpreter* Core::spawnInterpreter(const char* name){
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    Interpreter* interpreter = new Interpreter((int)(interpreters_.size()), name);
    interpreters_.push_back(interpreter);
    return interpreter;
}

void Core::stopAllInterpreters() {
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    for (unsigned int i = 0; i < interpreters_.size(); ++i) {
        interpreters_[i]->stop();
    }
}

int Core::numInterpreters() {
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    return interpreters_.size();
}

void Core::dispatchMessage(int targetIdx, trss_message* msg){
    Interpreter* interpreter = getInterpreter(targetIdx);
    if(interpreter) {
        interpreter->sendMessage(msg);
    }
}

void Core::acquireMessage(trss_message* msg){
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    ++(msg->refcount);
}

void Core::releaseMessage(trss_message* msg){
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    --(msg->refcount);
    if(msg->refcount <= 0) {
        deallocateMessage(msg);
    }
}

trss_message* Core::copyMessage(trss_message* src){
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    trss_message* newmsg = allocateMessage(src->data_length);
    newmsg->message_type = src->message_type;
    std::memcpy(newmsg->data, src->data, newmsg->data_length);
    return newmsg;
}

trss_message* Core::allocateMessage(size_t dataLength){
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

int Core::checkFile(const char* filename) {
    if (!physFSInitted_) {
        logMessage(TRSS_LOG_WARNING, "PhysFS not initted: checkFile always returns 0.");
        return false;
    }

    if (PHYSFS_exists(filename) == 0) {
        return 0;
    } else if (PHYSFS_isDirectory(filename) == 0) {
        return 1;
    } else {
        return 2;
    }
}

trss_message* Core::loadFileRaw(const char* filename) {
    std::streampos size;
    std::ifstream file(filename, std::ios::in|std::ios::binary|std::ios::ate);
    if (file.is_open()) {
        size = file.tellg();
        trss_message* ret = allocateMessage((int)size);
        file.seekg (0, std::ios::beg);
        file.read ((char*)(ret->data), size);
        file.close();

        return ret;
    } else {
        logStream(TRSS_LOG_ERROR) << "Unable to open file " << filename << "\n";
        return NULL;
    }
}

trss_message* Core::loadFile(const char* filename) {
    if (!physFSInitted_) {
        logMessage(TRSS_LOG_ERROR, "Cannot load file: PhysFS not initted.");
        logMessage(TRSS_LOG_ERROR, filename);
        return NULL;
    }

    if (PHYSFS_exists(filename) == 0) {
        logMessage(TRSS_LOG_ERROR, "Error opening file: does not exist.");
        logMessage(TRSS_LOG_ERROR, filename);
        return NULL;
    }

    if (PHYSFS_isDirectory(filename) != 0) {
        logMessage(TRSS_LOG_ERROR, "Attempted to read directory as a file.");
        logMessage(TRSS_LOG_ERROR, filename);
        return NULL;
    }

    PHYSFS_file* myfile = PHYSFS_openRead(filename);
    PHYSFS_sint64 file_size = PHYSFS_fileLength(myfile);
    trss_message* ret = allocateMessage(file_size);
    PHYSFS_read(myfile, ret->data, 1, file_size);
    PHYSFS_close(myfile);

    return ret;
}

void Core::saveFile(const char* filename, trss_message* data) {
    if (!physFSInitted_) {
        logMessage(TRSS_LOG_ERROR, "Cannot save file; PhysFS not initted.");
        logMessage(TRSS_LOG_ERROR, filename);
        return;
    }

    PHYSFS_file* myfile = PHYSFS_openWrite(filename);
    PHYSFS_write(myfile, data->data, 1, data->data_length);
    PHYSFS_close(myfile);
}

void Core::saveFileRaw(const char* filename, trss_message* data) {
    std::ofstream outfile;
    outfile.open(filename, std::ios::binary | std::ios::out);
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
    std::memcpy(newmsg->data, src, newmsg->data_length);
    int result = setStoreValue(key, newmsg);
    releaseMessage(newmsg); // avoid double-acquiring this message
    return result;
}

Core::~Core(){
    // destroy physfs
    if (physFSInitted_) {
        PHYSFS_deinit();
    }
    logfile_.close();
}

Core::Core(){
    physFSInitted_ = false;

    // open log file
    logfile_.open("trusslog.txt", std::ios::out);
}
