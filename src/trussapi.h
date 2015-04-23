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
	unsigned int message_length;
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

/* Top level window management */
TRSS_C_API int trss_create_window(const char* title_str, int width, int height, int fullscreen);
TRSS_C_API int trss_destroy_window(int window_id);
TRSS_C_API void trss_shutdown(); // shut it all down

/* Interpreter management functions */
TRSS_C_API int trss_spawn_interpreter(trss_interpreter_id target_id, trss_message* arg_message);
TRSS_C_API int trss_stop_interpreter(trss_interpreter_id target_id);

TRSS_C_API void trss_send_message(trss_interpreter_id dest, trss_message* message);

/* Message management functions */
TRSS_C_API trss_message* trss_create_message(unsigned int data_length);
TRSS_C_API trss_message* trss_release_message(trss_message* msg);
TRSS_C_API trss_message* trss_copy_message(trss_message* src);

#endif