#include "core.h"
#include "addon.h"

// TODO: switch to a better logging framework
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstring>
#include <external/bx_utils.h> // has to be included early or else luaconfig.h will clobber winver
#include <trussapi.h>
#include <physfs.h>

using namespace truss;

const char* truss_get_version() {
    return TRUSS_VERSION_STRING;
}

void truss_test() {
    std::cout << ">>>>>>>>>>>>>> TRUSS_TEST CALLED <<<<<<<<<<<<<\n";
    core()->logMessage(TRUSS_LOG_CRITICAL, ">>>>>>>>>>>>>> TRUSS_TEST CALLED <<<<<<<<<<<<<");
}

void truss_log(int log_level, const char* str) {
    Core::getCore()->logMessage(log_level, str);
}

void truss_shutddown() {
    Core::getCore()->stopAllInterpreters();
}

uint64_t truss_get_hp_time() {
    return bx::getHPCounter();
}

uint64_t truss_get_hp_freq() {
    return bx::getHPFrequency();
}

int truss_check_file(const char* filename) {
    return Core::getCore()->checkFile(filename);
}

truss_message* truss_load_file(const char* filename) {
    return Core::getCore()->loadFile(filename);
}

/* Note that when saving the message_type field is not saved */
int truss_save_file(const char* filename, truss_message* data) {
    Core::getCore()->saveFile(filename, data);
    return 0; // TODO: actually check for errors
}

int truss_add_fs_path(const char* path, const char* mountpath, int append) {
    core()->addFSPath(path, mountpath, append);
    return 0;
}

int truss_set_fs_savedir(const char* path) {
    core()->setWriteDir(path);
    return 0;
}

/* Datastore functions */
truss_message* truss_get_store_value(const char* key) {
    std::string tempkey(key);
    return Core::getCore()->getStoreValue(tempkey);
}

int truss_set_store_value(const char* key, truss_message* val) {
    std::string tempkey(key);
    return Core::getCore()->setStoreValue(tempkey, val);
}

int truss_set_store_value_str(const char* key, const char* msg) {
    std::string tempkey(key);
    std::string tempmsg(msg);
    return Core::getCore()->setStoreValue(tempkey, tempmsg);
}

/* Interpreter management functions */
int truss_spawn_interpreter(const char* name) {
    Interpreter* spawned = Core::getCore()->spawnInterpreter(name);
    return spawned->getID();
}

void truss_set_interpreter_debug(truss_interpreter_id target_id, int debug_level) {
    Core::getCore()->getInterpreter(target_id)->setDebug(debug_level);
}

void truss_start_interpreter(truss_interpreter_id target_id, const char* msgstr) {
    Core::getCore()->getInterpreter(target_id)->start(msgstr);
}

void truss_stop_interpreter(truss_interpreter_id target_id) {
    Core::getCore()->getInterpreter(target_id)->stop();
}

void truss_execute_interpreter(truss_interpreter_id target_id) {
    return Core::getCore()->getInterpreter(target_id)->execute();
}

int truss_find_interpreter(const char* name) {
    return Core::getCore()->getNamedInterpreter(name)->getID();
}

void truss_send_message(truss_interpreter_id dest, truss_message* message) {
    Core::getCore()->dispatchMessage(dest, message);
}

int truss_fetch_messages(truss_interpreter_id idx) {
    Interpreter* interpreter = Core::getCore()->getInterpreter(idx);
    if(interpreter) {
        return interpreter->fetchMessages();
    } else {
        return -1;
    }
}

truss_message* truss_get_message(truss_interpreter_id idx, int message_index) {
    Interpreter* interpreter = Core::getCore()->getInterpreter(idx);
    if(interpreter) {
        return interpreter->getMessage(message_index);
    } else {
        return NULL;
    }
}

int truss_get_addon_count(truss_interpreter_id target_id) {
    Interpreter* interpreter = Core::getCore()->getInterpreter(target_id);
    if(interpreter) {
        return interpreter->numAddons();
    } else {
        return -1;
    }
}

Addon* truss_get_addon(truss_interpreter_id target_id, int addon_idx) {
    Interpreter* interpreter = Core::getCore()->getInterpreter(target_id);
    if(interpreter) {
        return interpreter->getAddon(addon_idx);
    } else {
        return NULL;
    }
}

const char* truss_get_addon_name(truss_interpreter_id target_id, int addon_idx) {
    Addon* addon = truss_get_addon(target_id, addon_idx);
    if (addon) {
        return addon->getName().c_str();
    }
    else {
        return "";
    }
}

const char* truss_get_addon_header(truss_interpreter_id target_id, int addon_idx) {
    Addon* addon = truss_get_addon(target_id, addon_idx);
    if(addon) {
        return addon->getHeader().c_str();
    } else {
        return "";
    }
}

const char* truss_get_addon_version(truss_interpreter_id target_id, int addon_idx) {
    Addon* addon = truss_get_addon(target_id, addon_idx);
    if (addon) {
        return addon->getVersion().c_str();
    }
    else {
        return "";
    }
}

/* Message management functions */
truss_message* truss_create_message(size_t data_length) {
    return Core::getCore()->allocateMessage(data_length);
}

void truss_acquire_message(truss_message* msg) {
    if (msg != NULL) {
        ++(msg->refcount);
    }
}

void truss_release_message(truss_message* msg) {
    if (msg != NULL) {
        --(msg->refcount);
        if (msg->refcount <= 0) {
            Core::getCore()->deallocateMessage(msg);
        }
    }
}

truss_message* truss_copy_message(truss_message* src) {
    if (src == NULL) {
        return NULL;
    }

    truss_message* newmsg = Core::getCore()->allocateMessage(src->data_length);
    newmsg->message_type = src->message_type;
    std::memcpy(newmsg->data, src->data, newmsg->data_length);
    return newmsg;
}
