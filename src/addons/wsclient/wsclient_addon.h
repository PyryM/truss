#ifndef WSCLIENT_ADDON_HEADER_GUARD
#define WSCLIENT_ADDON_HEADER_GUARD

#include "../../truss.h"
#include <vector>
#include <string>

typedef void (*messageCallback)(const char*);

class WSClientAddon;

#define WS_ADDON_MAX_SOCKET_SLOTS 16

TRUSS_C_API int truss_wsclient_open(WSClientAddon* addon, const char* url);
TRUSS_C_API void truss_wsclient_close(WSClientAddon* addon, int slot);
TRUSS_C_API void truss_wsclient_send(WSClientAddon* addon, int slot, const char* msg);
TRUSS_C_API void truss_wsclient_receive_callback(WSClientAddon* addon, int slot, messageCallback callback);
TRUSS_C_API int truss_wsclient_receive(WSClientAddon* addon, int slot);
TRUSS_C_API const char* truss_wsclient_getmessage(WSClientAddon* addon, int slot, int msgindex);

struct WSClientAddonSocket;

class WSClientAddon : public truss::Addon {
public:
	WSClientAddon();
	const std::string& getName();
	const std::string& getHeader();
	const std::string& getVersion();
	void init(truss::Interpreter* owner);
	void shutdown();
	void update(double dt);

	int open(const std::string& url);
	void close(int slot);
	void send(int slot, const std::string& msg);
	void receiveCallback(int slot, messageCallback callback);
	int receive(int slot);
	const std::string& getMessage(int slot, int index);

	~WSClientAddon(); // needed so it can be deleted cleanly
private:
	std::string name_;
	std::string version_;
	std::string header_;

	WSClientAddonSocket* slots_;
	// The websocket pointer is kept around as a global (unideal, I know)
	// which is why there isn't anything here
};

#endif //WSCLIENT_ADDON_HEADER_GUARD