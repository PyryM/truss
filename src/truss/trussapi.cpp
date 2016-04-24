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

using namespace trss;

const char* trss_get_version_string() {
    return TRUSS_VERSION_STRING;
}

void trss_test() {
    std::cout << ">>>>>>>>>>>>>> TRUSS_TEST CALLED <<<<<<<<<<<<<\n";
    core()->logMessage(TRUSS_LOG_CRITICAL, ">>>>>>>>>>>>>> TRUSS_TEST CALLED <<<<<<<<<<<<<");
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
