#include "core.h"
#include "addon.h"

// TODO: switch to a better logging framework
#include <array>
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstring>
#include "external/bx_utils.h" // has to be included early or else luaconfig.h will clobber winver
#include "trussapi.h"
#include <physfs.h>

using namespace truss;

// Extracts the contents of these folders to the PhysFS write directory.
void recursiveExtract(void *data, const char *parent_path, const char *filename)
{
    std::array<char, 65535> buffer;

    // Construct the virtual source path to this file.
    std::stringstream source_path_ss;
    source_path_ss << parent_path << "/" << filename;
    const std::string source_path = source_path_ss.str();

    // Determine if this path is a real or virtual one by checking if the
    // real path ends in a path separator (directory) or not (archive).
    // If it is a real path, we do not need to extract it.
    const std::string real_path = PHYSFS_getRealDir(source_path.c_str());
    const std::string path_separator = PHYSFS_getDirSeparator();
    if (!real_path.compare(real_path.size() - path_separator.size(),
                           path_separator.size(), path_separator)) {
        return;
    }

    // Iterate through any virtual directories recursively.
    if (PHYSFS_isDirectory(source_path.c_str())) {
        PHYSFS_enumerateFilesCallback(source_path.c_str(), recursiveExtract, data);
        return;
    }

    // Construct the virtual parent destination containing this file.
    std::stringstream dest_parent_ss;
    dest_parent_ss << parent_path;
    const std::string dest_parent = dest_parent_ss.str();

    // Construct the virtual destination path to this file.
    std::stringstream dest_path_ss;
    dest_path_ss << dest_parent << "/" << filename;
    const std::string dest_path = dest_path_ss.str();

    // At this point, we need to extract this file into the write directory.
    truss::core().logPrint(TRUSS_LOG_DEBUG, "Extracting '%s'.", source_path.c_str());

    // Create the parent directory for files that need to be extracted.
    PHYSFS_mkdir(dest_parent.c_str());

    // Copy the virtual file to a real location on disk in chunks.
    PHYSFS_File *infile = PHYSFS_openRead(source_path.c_str());
    PHYSFS_File *outfile = PHYSFS_openWrite(dest_path.c_str());

    PHYSFS_sint64 bytes_read;
    while ((bytes_read = PHYSFS_read(infile, buffer.data(), 1, buffer.size())) > 0) {
        PHYSFS_write(outfile, buffer.data(), 1, bytes_read);
    }

    PHYSFS_close(outfile);
    PHYSFS_close(infile);
}

Core& Core::instance() {
    static Core core;
    return core;
}

void Core::initFS(char* argv0, bool mountBaseDir) {
    if (physFSInitted_) {
        logMessage(TRUSS_LOG_WARNING, "PhysFS already initialized.");
        return;
    }

    int retval = PHYSFS_init(argv0);
    if (mountBaseDir) {
        PHYSFS_mount(PHYSFS_getBaseDir(), "/", 0);
    }

    physFSInitted_ = true;
}

void Core::addFSPath(const char* pathname, const char* mountname, bool append) {
    std::stringstream ss;
    ss << PHYSFS_getBaseDir() << PHYSFS_getDirSeparator() << pathname;
    logPrint(TRUSS_LOG_DEBUG, "Adding physFS path: %s", ss.str().c_str());

    int retval = PHYSFS_mount(ss.str().c_str(), mountname, append);
    if (retval == 0) {
        logPrint(TRUSS_LOG_ERROR, "addFSPath failed: %s", PHYSFS_getLastError());
    }
}

// Extract contents of include and lib directories just-in-time.
// NOTE: Not thread-safe due to changing write-dir()
void Core::extractLibraries() {
    int retval;

    // The write directory might be NULL if unset.  So we will store both
    // the original pointer and a std::string with its contents.  That way,
    // we can later tell if we should set the path back to the value of the
    // string, or set it back to NULL.
    const char *originalWritePtr = PHYSFS_getWriteDir();
    std::string originalWriteDir = originalWritePtr ? originalWritePtr : "";

    retval = PHYSFS_setWriteDir(PHYSFS_getBaseDir());
    if (retval == 0) {
        logPrint(TRUSS_LOG_ERROR, "Changing write dir to '%s' failed: %s",
                 PHYSFS_getBaseDir(), PHYSFS_getLastError());
        return;
    }

    PHYSFS_enumerateFilesCallback("include", recursiveExtract, nullptr);
    PHYSFS_enumerateFilesCallback("bin", recursiveExtract, nullptr);
    PHYSFS_enumerateFilesCallback("lib", recursiveExtract, nullptr);

    retval = PHYSFS_setWriteDir(originalWritePtr ? originalWriteDir.c_str() : NULL);
    if (retval == 0) {
        logPrint(TRUSS_LOG_ERROR, "Restoring write dir to '%s' failed: %s",
                 PHYSFS_getBaseDir(), PHYSFS_getLastError());
    }
}

void Core::setWriteDir(const char* writepath) {
    std::stringstream ss;
    ss << PHYSFS_getBaseDir() << PHYSFS_getDirSeparator() << writepath;
    logPrint(TRUSS_LOG_DEBUG, "Setting physFS write path: %s", ss.str().c_str());

    int retval = PHYSFS_setWriteDir(ss.str().c_str());
    if (retval == 0) {
        logPrint(TRUSS_LOG_ERROR, "setWriteDir failed: %s", PHYSFS_getLastError());
    }
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

void Core::logPrint(int log_level, const char* format, ...) {
    std::array<char, 4096> buffer;

    va_list args;
    va_start(args, format);
    vsnprintf(buffer.data(), buffer.size(), format, args);
    logMessage(log_level, buffer.data());
    va_end(args);
}

Interpreter* Core::getInterpreter(int idx) {
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);

    if(idx < 0)
        return NULL;
    if (idx >= interpreters_.size())
        return NULL;
    return interpreters_[idx];
}

Interpreter* Core::getNamedInterpreter(const char* name) {
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);

    std::string sname(name);
    for(size_t i = 0; i < interpreters_.size(); ++i) {
        if(interpreters_[i]->getName() == sname) {
            return interpreters_[i];
        }
    }
    return NULL;
}

Interpreter* Core::spawnInterpreter(const char* name) {
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
    return static_cast<int>(interpreters_.size());
}

void Core::dispatchMessage(int targetIdx, truss_message* msg) {
    Interpreter* interpreter = getInterpreter(targetIdx);
    if(interpreter) {
        interpreter->sendMessage(msg);
    }
}

void Core::acquireMessage(truss_message* msg) {
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    ++(msg->refcount);
}

void Core::releaseMessage(truss_message* msg) {
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    --(msg->refcount);
    if(msg->refcount <= 0) {
        deallocateMessage(msg);
    }
}

truss_message* Core::copyMessage(truss_message* src) {
    tthread::lock_guard<tthread::mutex> Lock(coreLock_);
    truss_message* newmsg = allocateMessage(src->data_length);
    newmsg->message_type = src->message_type;
    std::memcpy(newmsg->data, src->data, newmsg->data_length);
    return newmsg;
}

truss_message* Core::allocateMessage(size_t dataLength) {
    truss_message* ret = new truss_message;
    ret->data = new unsigned char[dataLength];
    ret->data_length = dataLength;
    ret->refcount = 1;
    return ret;
}

void Core::deallocateMessage(truss_message* msg) {
    delete[] msg->data;
    delete msg;
}

int Core::checkFile(const char* filename) {
    if (!physFSInitted_) {
        logMessage(TRUSS_LOG_WARNING, "PhysFS not initialized: checkFile always returns 0.");
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

truss_message* Core::loadFileRaw(const char* filename) {
    std::streampos size;
    std::ifstream file(filename, std::ios::in|std::ios::binary|std::ios::ate);
    if (file.is_open()) {
        size = file.tellg();
        truss_message* ret = allocateMessage((int)size);
        file.seekg (0, std::ios::beg);
        file.read ((char*)(ret->data), size);
        file.close();

        return ret;
    } else {
        logPrint(TRUSS_LOG_ERROR, "Unable to open file '%s'.", filename);
        return NULL;
    }
}

truss_message* Core::loadFile(const char* filename) {
    if (!physFSInitted_) {
        logPrint(TRUSS_LOG_ERROR, "Cannot load file '%s': PhysFS not initialized.", filename);
        return NULL;
    }

    if (PHYSFS_exists(filename) == 0) {
        logPrint(TRUSS_LOG_ERROR, "Error opening file '%s': does not exist.", filename);
        return NULL;
    }

    if (PHYSFS_isDirectory(filename) != 0) {
        logPrint(TRUSS_LOG_ERROR, "Attempted to read directory '%s' as a file.", filename);
        return NULL;
    }

    PHYSFS_file* myfile = PHYSFS_openRead(filename);
    PHYSFS_sint64 file_size = PHYSFS_fileLength(myfile);
    truss_message* ret = allocateMessage(file_size);
    PHYSFS_read(myfile, ret->data, 1, file_size);
    PHYSFS_close(myfile);

    return ret;
}

void Core::saveData(const char* filename, const char* data, unsigned int datalength) {
    if (!physFSInitted_) {
        logPrint(TRUSS_LOG_ERROR, "Cannot save file '%s': PhysFS not initialized.", filename);
        return;
    }

    PHYSFS_file* myfile = PHYSFS_openWrite(filename);
    PHYSFS_write(myfile, data, 1, datalength);
    PHYSFS_close(myfile);
}

void Core::saveDataRaw(const char* filename, const char* data, unsigned int datalength) {
    std::ofstream outfile;
    outfile.open(filename, std::ios::binary | std::ios::out);
    outfile.write(data, datalength);
    outfile.close();
}

void Core::saveFile(const char* filename, truss_message* data) {
    saveData(filename, (char*)(data->data),
             static_cast<unsigned int>(data->data_length));
}

void Core::saveFileRaw(const char* filename, truss_message* data) {
    saveDataRaw(filename, (char*)(data->data),
                static_cast<unsigned int>(data->data_length));
}

truss_message* Core::getStoreValue(const std::string& key) {
    if (store_.count(key) > 0) {
        return store_[key];
    } else {
        return NULL;
    }
}

int Core::setStoreValue(const std::string& key, truss_message* val) {
    acquireMessage(val);
    if (store_.count(key) > 0) {
        truss_message* oldmsg = store_[key];
        store_[key] = val;
        releaseMessage(oldmsg);
        return 1;
    } else {
        store_[key] = val;
        return 0;
    }
}

int Core::setStoreValue(const std::string& key, const std::string& val) {
    truss_message* newmsg = allocateMessage(val.length());
    const char* src = val.c_str();
    std::memcpy(newmsg->data, src, newmsg->data_length);
    int result = setStoreValue(key, newmsg);
    releaseMessage(newmsg); // avoid double-acquiring this message
    return result;
}

Core::~Core() {
    // destroy physfs
    if (physFSInitted_) {
        PHYSFS_deinit();
    }
    logfile_.close();
}

Core::Core() {
    physFSInitted_ = false;

    // open log file
    logfile_.open("trusslog.txt", std::ios::out);
}
