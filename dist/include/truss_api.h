/* truss api for embedding */
#include <stdint.h>
#include <stddef.h>

#define truss_message_UNKNOWN 0
#define truss_message_CSTR    1
#define truss_message_BLOB    2

#define TRUSS_LOG_CRITICAL    0
#define TRUSS_LOG_ERROR       1
#define TRUSS_LOG_WARNING     2
#define TRUSS_LOG_INFO        3
#define TRUSS_LOG_DEBUG       4

typedef struct {
  unsigned int message_type;
  size_t data_length;
  unsigned char* data;
  unsigned int refcount;
} truss_message;
typedef struct Addon Addon;

typedef int truss_interpreter_id;

const char* truss_get_version();
void truss_test();
void truss_log(int log_level, const char* str);
void truss_set_error(int errcode);
int truss_get_error();
void truss_shutdown();
uint64_t truss_get_hp_time();
uint64_t truss_get_hp_freq();
void truss_sleep(unsigned int ms);
int truss_check_file(const char* filename);
const char* truss_get_file_real_path(const char* filename);
truss_message* truss_load_file(const char* filename);
int truss_save_file(const char* filename, truss_message* data);
int truss_save_data(const char* filename, const char* data, unsigned int datalength);
int truss_add_fs_path(const char* path, const char* mountpath, int append);
int truss_set_fs_savedir(const char* path);
int truss_set_raw_write_dir(const char* path);
int truss_list_directory(truss_interpreter_id interpreter, const char* path);
const char* truss_get_string_result(truss_interpreter_id interpreter, int idx);
void truss_clear_string_results(truss_interpreter_id interpreter);
truss_message* truss_get_store_value(const char* key);
int truss_set_store_value(const char* key, truss_message* val);
int truss_set_store_value_str(const char* key, const char* msg);
int truss_spawn_interpreter(const char* name, truss_message* arg_message);
void truss_stop_interpreter(truss_interpreter_id target_id);
void truss_execute_interpreter(truss_interpreter_id target_id);
int truss_find_interpreter(const char* name);
int truss_get_addon_count(truss_interpreter_id target_id);
Addon* truss_get_addon(truss_interpreter_id target_id, int addon_idx);
const char* truss_get_addon_name(truss_interpreter_id target_id, int addon_idx);
const char* truss_get_addon_header(truss_interpreter_id target_id, int addon_idx);
const char* truss_get_addon_version(truss_interpreter_id target_id, int addon_idx);
void truss_send_message(truss_interpreter_id dest, truss_message* message);
int truss_fetch_messages(truss_interpreter_id interpreter);
truss_message* truss_get_message(truss_interpreter_id interpreter, int message_index);
truss_message* truss_create_message(size_t data_length);
void truss_acquire_message(truss_message* msg);
void truss_release_message(truss_message* msg);
truss_message* truss_copy_message(truss_message* src);
