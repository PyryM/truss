/* trussapi.h
 *
 * Defines the c api of truss for inclusion by Terra
 */

#ifndef TRUSSAPI_H_HEADER_GUARD
#define TRUSSAPI_H_HEADER_GUARD

#define TRUSS_VERSION_STRING "0.2.1"

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
#else
#   define TRUSS_C_API
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

typedef enum { 
	THREAD_NONE,
	THREAD_NOT_STARTED,
	THREAD_IDLE,
	THREAD_RUNNING,
	THREAD_TERMINATED,
	THREAD_SCRIPT_ERROR,
	THREAD_FATAL_ERROR
} truss_interpreter_state;

/* Message struct */
typedef struct {
	unsigned int message_type;
	size_t data_length;
	unsigned char* data;
	unsigned int refcount;
} truss_message;

/* Interpreter IDs are just ints for now */
typedef int truss_interpreter_id;

/* Info */
TRUSS_C_API const char* truss_get_version();

TRUSS_C_API void truss_test();
TRUSS_C_API void truss_log(int log_level, const char* str);
TRUSS_C_API void truss_set_error(int errcode);

/* Quit program by stopping all interpreters */
TRUSS_C_API void truss_shutdown();

/* High precision timer */
TRUSS_C_API uint64_t truss_get_hp_time();
TRUSS_C_API uint64_t truss_get_hp_freq();
TRUSS_C_API void truss_sleep(unsigned int ms);

/* FileIO */
/* Note that when saving the message_type field is not saved */
TRUSS_C_API int truss_check_file(const char* filename); /* returns 1 if file exists, 2 if directory, 0 otherwise */
TRUSS_C_API const char* truss_get_file_real_path(const char* filename);
TRUSS_C_API truss_message* truss_load_file(const char* filename);
TRUSS_C_API int truss_save_file(const char* filename, truss_message* data);
TRUSS_C_API int truss_save_data(const char* filename, const char* data, unsigned int datalength);
TRUSS_C_API int truss_add_fs_path(const char* path, const char* mountpath, int append, int relative);
TRUSS_C_API int truss_set_fs_savedir(const char* path);
TRUSS_C_API int truss_set_raw_write_dir(const char* path);
TRUSS_C_API int truss_list_directory(truss_interpreter_id interpreter, const char* path);
TRUSS_C_API const char* truss_get_string_result(truss_interpreter_id interpreter, int idx);
TRUSS_C_API void truss_clear_string_results(truss_interpreter_id interpreter);

/* Datastore functions */
TRUSS_C_API truss_message* truss_get_store_value(const char* key);
TRUSS_C_API int truss_set_store_value(const char* key, truss_message* val);
TRUSS_C_API int truss_set_store_value_str(const char* key, const char* msg);

/* Interpreter management functions */
TRUSS_C_API int truss_spawn_interpreter(int debug_level, const char* init_script_name);
TRUSS_C_API void truss_stop_interpreter(truss_interpreter_id target_id);
TRUSS_C_API int truss_step_interpreter(truss_interpreter_id target_id);
TRUSS_C_API truss_interpreter_state truss_get_interpreter_state(truss_interpreter_id target_id);

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
