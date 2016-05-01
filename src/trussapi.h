/* trussapi.h
 * 
 * Defines the c api of truss for inclusion by Terra
 */

#ifndef TRUSSAPI_H_HEADER_GUARD
#define TRUSSAPI_H_HEADER_GUARD

#define TRUSS_VERSION_STRING "0.0.1"

#include <cstdint> // Needed for uint64_t etc.
#include <cstddef> // Needed for size_t etc.

/* Windows needs dllexports for Terra / luajit ffi to be able
   to link against the truss api functions (even when statically built) */
#if defined(__cplusplus)
#if defined(_WIN32)
#   define TRUSS_C_API extern "C" __declspec(dllexport)
#else
#	define TRUSS_C_API extern "C"
#endif
namespace truss {
	class Addon;
}
#else
#   define TRUSS_C_API
typedef struct Addon Addon;
#endif

/* Message types */
#define TRUSS_MESSAGE_UNKNOWN 0
#define TRUSS_MESSAGE_CSTR    1
#define TRUSS_MESSAGE_BLOB    2

/* Logging */
#define TRUSS_LOG_CRITICAL 0
#define TRUSS_LOG_ERROR    1
#define TRUSS_LOG_WARNING  2
#define TRUSS_LOG_INFO     3
#define TRUSS_LOG_DEBUG    4

/* Message struct */
typedef struct {
	unsigned int message_type;
	size_t data_length;
	unsigned char* data;
	unsigned int refcount;
} truss_message;

/* Info */
TRUSS_C_API const char* truss_get_version();

TRUSS_C_API void truss_test();
TRUSS_C_API void truss_log(int log_level, const char* str);

/* Quit program by stopping all interpreters */
TRUSS_C_API void truss_shutdown();

/* High precision timer */
TRUSS_C_API uint64_t truss_get_hp_time();
TRUSS_C_API uint64_t truss_get_hp_freq();

/* FileIO */
/* Note that when saving the message_type field is not saved */
TRUSS_C_API int truss_check_file(const char* filename); /* returns 1 if file exists, 2 if directory, 0 otherwise */
TRUSS_C_API truss_message* truss_load_file(const char* filename);
TRUSS_C_API int truss_save_file(const char* filename, truss_message* data);
TRUSS_C_API int truss_add_fs_path(const char* path, const char* mountpath, int append);
TRUSS_C_API int truss_set_fs_savedir(const char* path);

/* Datastore functions */
TRUSS_C_API truss_message* truss_get_store_value(const char* key);
TRUSS_C_API int truss_set_store_value(const char* key, truss_message* val);
TRUSS_C_API int truss_set_store_value_str(const char* key, const char* msg);

/* Interpreter IDs are just ints for now */
typedef int truss_interpreter_id;

/* Interpreter management functions */
TRUSS_C_API int truss_spawn_interpreter(const char* name);
TRUSS_C_API void truss_set_interpreter_debug(truss_interpreter_id target_id, int debug_level);
TRUSS_C_API void truss_start_interpreter(truss_interpreter_id target_id, const char* msgstr);
TRUSS_C_API void truss_stop_interpreter(truss_interpreter_id target_id);
TRUSS_C_API void truss_execute_interpreter(truss_interpreter_id target_id);
TRUSS_C_API int truss_find_interpreter(const char* name);

/* Addon management */
TRUSS_C_API int truss_get_addon_count(truss_interpreter_id target_id);
TRUSS_C_API truss::Addon* truss_get_addon(truss_interpreter_id target_id, int addon_idx);
TRUSS_C_API const char* truss_get_addon_name(truss_interpreter_id target_id, int addon_idx);
TRUSS_C_API const char* truss_get_addon_header(truss_interpreter_id target_id, int addon_idx);
TRUSS_C_API const char* truss_get_addon_version(truss_interpreter_id target_id, int addon_idx);

/* Message transport */
TRUSS_C_API void truss_send_message(truss_interpreter_id dest, truss_message* message);
TRUSS_C_API int truss_fetch_messages(truss_interpreter_id interpreter);
TRUSS_C_API truss_message* truss_get_message(truss_interpreter_id interpreter, int message_index);

/* Message management functions */
TRUSS_C_API truss_message* truss_create_message(size_t data_length);
TRUSS_C_API void truss_acquire_message(truss_message* msg);
TRUSS_C_API void truss_release_message(truss_message* msg);
TRUSS_C_API truss_message* truss_copy_message(truss_message* src);

#endif