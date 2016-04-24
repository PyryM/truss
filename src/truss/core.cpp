#include "core.h"
#include "addon.h"

// TODO: switch to a better logging framework
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstring>
#include "external/bx_utils.h" // has to be included early or else luaconfig.h will clobber winver
#include "trussapi.h"
#include <physfs.h>

using namespace trss;

Core* Core::core__ = NULL;

Core* Core::getCore() {
    if(core__ == NULL) {
        core__ = new Core();
    }
    return core__;
}

void Core::initFS(char* argv0, bool mountBaseDir) {
    if (physFSInitted_) {
        logMessage(TRUSS_LOG_WARNING, "PhysFS already initted.");
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
    logMessage(TRUSS_LOG_DEBUG, "Adding physFS path: ");
    logMessage(TRUSS_LOG_DEBUG, ss.str().c_str());

    int retval = PHYSFS_mount(ss.str().c_str(), mountname, append);
    // TODO: do something with the return value (e.g., if it's an error)
}

void Core::setWriteDir(const char* writepath) {
    std::stringstream ss;
    ss << PHYSFS_getBaseDir() << PHYSFS_getDirSeparator() << writepath;
    logMessage(TRUSS_LOG_DEBUG, "Setting physFS write path: ");
    logMessage(TRUSS_LOG_DEBUG, ss.str().c_str());

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
        logMessage(TRUSS_LOG_WARNING, "PhysFS not initted: checkFile always returns 0.");
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
        logStream(TRUSS_LOG_ERROR) << "Unable to open file " << filename << "\n";
        return NULL;
    }
}

trss_message* Core::loadFile(const char* filename) {
    if (!physFSInitted_) {
        logMessage(TRUSS_LOG_ERROR, "Cannot load file: PhysFS not initted.");
        logMessage(TRUSS_LOG_ERROR, filename);
        return NULL;
    }

    if (PHYSFS_exists(filename) == 0) {
        logMessage(TRUSS_LOG_ERROR, "Error opening file: does not exist.");
        logMessage(TRUSS_LOG_ERROR, filename);
        return NULL;
    }

    if (PHYSFS_isDirectory(filename) != 0) {
        logMessage(TRUSS_LOG_ERROR, "Attempted to read directory as a file.");
        logMessage(TRUSS_LOG_ERROR, filename);
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
        logMessage(TRUSS_LOG_ERROR, "Cannot save file; PhysFS not initted.");
        logMessage(TRUSS_LOG_ERROR, filename);
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
