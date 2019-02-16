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

// c++ 11 timing functions
#include <chrono>
#include <thread>

using namespace truss;

const char* truss_get_version() {
    return TRUSS_VERSION_STRING;
}

void truss_test() {
    std::cout << ">>>>>>>>>>>>>> TRUSS_TEST CALLED <<<<<<<<<<<<<\n";
    core().logMessage(TRUSS_LOG_CRITICAL, ">>>>>>>>>>>>>> TRUSS_TEST CALLED <<<<<<<<<<<<<");
}

void truss_log(int log_level, const char* str) {
    Core::instance().logMessage(log_level, str);
}

void truss_set_error(int errcode) {
	Core::instance().setError(errcode);
}

void truss_shutdown() {
    Core::instance().stopAllInterpreters();
}

uint64_t truss_get_hp_time() {
    return bx::getHPCounter();
}

uint64_t truss_get_hp_freq() {
    return bx::getHPFrequency();
}

void truss_sleep(unsigned int ms) {
	std::this_thread::sleep_for(std::chrono::milliseconds(ms));
}

int truss_check_file(const char* filename) {
    return Core::instance().checkFile(filename);
}

const char* truss_get_file_real_path(const char* filename) {
	return Core::instance().getFileRealPath(filename);
}

truss_message* truss_load_file(const char* filename) {
    return Core::instance().loadFile(filename);
}

/* Note that when saving the message_type field is not saved */
int truss_save_file(const char* filename, truss_message* data) {
    Core::instance().saveFile(filename, data);
    return 0; // TODO: actually check for errors
}

int truss_save_data(const char* filename, const char* data, unsigned int datalength) {
	Core::instance().saveData(filename, data, datalength);
	return 0;
}

int truss_add_fs_path(const char* path, const char* mountpath, int append) {
    core().addFSPath(path, mountpath, append);
    return 0;
}

int truss_set_fs_savedir(const char* path) {
    core().setWriteDir(path);
    return 0;
}

int truss_set_raw_write_dir(const char* path) {
	core().setRawWriteDir(path);
	return 0;
}

int truss_list_directory(truss_interpreter_id interpreter, const char* path) {
    return Core::instance().listDirectory(interpreter, path);
}

const char* truss_get_string_result(truss_interpreter_id interpreter, int idx) {
    return Core::instance().getStringResult(interpreter, idx);
}

void truss_clear_string_results(truss_interpreter_id interpreter) {
    Core::instance().clearStringResults(interpreter);
}


/* Datastore functions */
truss_message* truss_get_store_value(const char* key) {
    std::string tempkey(key);
    return Core::instance().getStoreValue(tempkey);
}

int truss_set_store_value(const char* key, truss_message* val) {
    std::string tempkey(key);
    return Core::instance().setStoreValue(tempkey, val);
}

int truss_set_store_value_str(const char* key, const char* msg) {
    std::string tempkey(key);
    std::string tempmsg(msg);
    return Core::instance().setStoreValue(tempkey, tempmsg);
}

/* Interpreter management functions */
int truss_spawn_interpreter(int debug_level, const char* init_script_name) {
	Interpreter* spawned = Core::instance().spawnInterpreter();
	spawned->setDebug(debug_level);
	spawned->start(init_script_name, true);
	return spawned->getID();
}

void truss_stop_interpreter(truss_interpreter_id target_id) {
	Core::instance().getInterpreter(target_id)->stop();
}

int truss_step_interpreter(truss_interpreter_id target_id) {
	return Core::instance().getInterpreter(target_id)->step();
}

truss_interpreter_state truss_get_interpreter_state(truss_interpreter_id target_id) {
	return Core::instance().getInterpreter(target_id)->getState();
}

void truss_send_message(truss_interpreter_id dest, truss_message* message) {
    Core::instance().dispatchMessage(dest, message);
}

int truss_fetch_messages(truss_interpreter_id idx) {
    Interpreter* interpreter = Core::instance().getInterpreter(idx);
    if(interpreter) {
        return interpreter->fetchMessages();
    } else {
        return -1;
    }
}

truss_message* truss_get_message(truss_interpreter_id idx, int message_index) {
    Interpreter* interpreter = Core::instance().getInterpreter(idx);
    if(interpreter) {
        return interpreter->getMessage(message_index);
    } else {
        return NULL;
    }
}

int truss_get_addon_count(truss_interpreter_id target_id) {
    Interpreter* interpreter = Core::instance().getInterpreter(target_id);
    if(interpreter) {
        return interpreter->numAddons();
    } else {
        return -1;
    }
}

Addon* truss_get_addon(truss_interpreter_id target_id, int addon_idx) {
    Interpreter* interpreter = Core::instance().getInterpreter(target_id);
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
    } else {
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
    } else {
        return "";
    }
}

/* Message management functions */
truss_message* truss_create_message(size_t data_length) {
    return Core::instance().allocateMessage(data_length);
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
            Core::instance().deallocateMessage(msg);
        }
    }
}

truss_message* truss_copy_message(truss_message* src) {
    if (src == NULL) {
        return NULL;
    }

    truss_message* newmsg = Core::instance().allocateMessage(src->data_length);
    newmsg->message_type = src->message_type;
    std::memcpy(newmsg->data, src->data, newmsg->data_length);
    return newmsg;
}
