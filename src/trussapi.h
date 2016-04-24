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
namespace trss {
	class Addon;
}
#else
#   define TRUSS_C_API
typedef struct Addon Addon;
#endif

/* Message types */
#define TRUSS_MESSAGE_UNKNOWN 0
#define TRUSS_MESSAGE_CSTR 1
#define TRUSS_MESSAGE_BLOB 2

/* Message struct */
typedef struct {
	unsigned int message_type;
	size_t data_length;
	unsigned char* data;
	unsigned int refcount;
} trss_message;

/* Info */
TRUSS_C_API const char* trss_get_version_string();

/* Logging */
#define TRUSS_LOG_CRITICAL 0
#define TRUSS_LOG_ERROR 1
#define TRUSS_LOG_WARNING 2
#define TRUSS_LOG_INFO 3
#define TRUSS_LOG_DEBUG 4

TRUSS_C_API void trss_test();
TRUSS_C_API void trss_log(int log_level, const char* str);

/* Quit program by stopping all interpreters */
TRUSS_C_API void trss_shutdown();

/* High precision timer */
TRUSS_C_API uint64_t trss_get_hp_time();
TRUSS_C_API uint64_t trss_get_hp_freq();

/* FileIO */
/* Note that when saving the message_type field is not saved */
TRUSS_C_API int trss_check_file(const char* filename); /* returns 1 if file exists, 2 if directory, 0 otherwise */
TRUSS_C_API trss_message* trss_load_file(const char* filename);
TRUSS_C_API int trss_save_file(const char* filename, trss_message* data);
TRUSS_C_API int trss_add_fs_path(const char* path, const char* mountpath, int append);
TRUSS_C_API int trss_set_fs_savedir(const char* path);

/* Datastore functions */
TRUSS_C_API trss_message* trss_get_store_value(const char* key);
TRUSS_C_API int trss_set_store_value(const char* key, trss_message* val);
TRUSS_C_API int trss_set_store_value_str(const char* key, const char* msg);

/* Interpreter IDs are just ints for now */
typedef int trss_interpreter_id;

/* Interpreter management functions */
TRUSS_C_API int trss_spawn_interpreter(const char* name);
TRUSS_C_API void trss_set_interpreter_debug(trss_interpreter_id target_id, int debug_level);
TRUSS_C_API void trss_start_interpreter(trss_interpreter_id target_id, const char* msgstr);
TRUSS_C_API void trss_stop_interpreter(trss_interpreter_id target_id);
TRUSS_C_API void trss_execute_interpreter(trss_interpreter_id target_id);
TRUSS_C_API int trss_find_interpreter(const char* name);

/* Addon management */
TRUSS_C_API int trss_get_addon_count(trss_interpreter_id target_id);
TRUSS_C_API trss::Addon* trss_get_addon(trss_interpreter_id target_id, int addon_idx);
TRUSS_C_API const char* trss_get_addon_name(trss_interpreter_id target_id, int addon_idx);
TRUSS_C_API const char* trss_get_addon_header(trss_interpreter_id target_id, int addon_idx);
TRUSS_C_API const char* trss_get_addon_version_string(trss_interpreter_id target_id, int addon_idx);

/* Message transport */
TRUSS_C_API void trss_send_message(trss_interpreter_id dest, trss_message* message);
TRUSS_C_API int trss_fetch_messages(trss_interpreter_id interpreter);
TRUSS_C_API trss_message* trss_get_message(trss_interpreter_id interpreter, int message_index);

/* Message management functions */
TRUSS_C_API trss_message* trss_create_message(size_t data_length);
TRUSS_C_API void trss_acquire_message(trss_message* msg);
TRUSS_C_API void trss_release_message(trss_message* msg);
TRUSS_C_API trss_message* trss_copy_message(trss_message* src);

#endif