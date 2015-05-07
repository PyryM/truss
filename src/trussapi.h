/* trussapi.h
 * 
 * Defines the c api of truss for inclusion by Terra
 */

#ifndef TRSSAPI_H_HEADER_GUARD
#define TRSSAPI_H_HEADER_GUARD


#if defined(__cplusplus)
#   define TRSS_C_API extern "C"
#else
#   define TRSS_C_API
#endif

/* Message types */
#define TRSS_MESSAGE_UNKNOWN 0
#define TRSS_MESSAGE_CSTR 1
#define TRSS_MESSAGE_BLOB 2

/* Message struct */
typedef struct {
	unsigned int message_type;
	unsigned int data_length;
	unsigned char* data;
	unsigned int _refcount;
} trss_message;

/* Logging */
#define TRSS_LOG_CRITICAL 0
#define TRSS_LOG_ERROR 1
#define TRSS_LOG_WARNING 2
#define TRSS_LOG_INFO 3
#define TRSS_LOG_DEBUG 4

TRSS_C_API void trss_log(int log_level, const char* str);

/* File IO */
#define TRSS_ASSET_PATH 0 /* Path where assets are stored */
#define TRSS_SAVE_PATH 1  /* Path for saving stuff e.g. preferences */
#define TRSS_CORE_PATH 2  /* Path for core files e.g. bootstrap.t */

TRSS_C_API trss_message* trss_load_file(const char* filename, int path_type);

/* Note that when saving the message_type field is not saved */
TRSS_C_API int trss_save_file(const char* filename, int path_type, trss_message* data);

/* Interpreter management functions */
TRSS_C_API int trss_spawn_interpreter(const char* name, trss_message* arg_message);
TRSS_C_API int trss_stop_interpreter(trss_interpreter_id target_id);
TRSS_C_API void trss_execute_interpreter(trss_interpreter_id target_id);
TRSS_C_API int trss_find_interpreter(const char* name);

/* Addon management */
TRSS_C_API int trss_get_addon_count(trss_interpreter_id target_id);
TRSS_C_API Addon* trss_get_addon(trss_interpreter_id target_id, int addon_idx);
TRSS_C_API const char* trss_get_addon_header(trss_interpreter_id target_id, int addon_idx);

/* Message transport */
TRSS_C_API void trss_send_message(trss_interpreter_id dest, trss_message* message);
TRSS_C_API int trss_fetch_messages(trss_interpreter_id interpreter);
TRSS_C_API trss_message* trss_get_message(trss_interpreter_id interpreter, int message_index);

/* Message management functions */
TRSS_C_API trss_message* trss_create_message(unsigned int data_length);
TRSS_C_API void trss_acquire_message(trss_message* msg);
TRSS_C_API void trss_release_message(trss_message* msg);
TRSS_C_API trss_message* trss_copy_message(trss_message* src);

#endif