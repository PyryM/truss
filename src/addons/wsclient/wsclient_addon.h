#ifndef WSCLIENT_ADDON_HEADER_GUARD
#define WSCLIENT_ADDON_HEADER_GUARD

#include "../../truss.h"
#include <vector>
#include <string>

typedef void (*messageCallback)(const char*);

class WSClientAddon;

TRUSS_C_API bool truss_wsclient_open(WSClientAddon* addon, const char* url);
TRUSS_C_API void truss_wsclient_close(WSClientAddon* addon);
TRUSS_C_API void truss_wsclient_send(WSClientAddon* addon, const char* msg);
TRUSS_C_API void truss_wsclient_receive_callback(WSClientAddon* addon, messageCallback callback);
TRUSS_C_API int truss_wsclient_receive(WSClientAddon* addon);
TRUSS_C_API const char* truss_wsclient_getmessage(WSClientAddon* addon, int msgindex);

class WSClientAddon : public truss::Addon {
public:
	WSClientAddon();
	const std::string& getName();
	const std::string& getCHeader();
	const std::string& getVersionString();
	void init(truss::Interpreter* owner);
	void shutdown();
	void update(double dt);

	bool open(const std::string& url);
	void close();
	void send(const std::string& msg);
	void receiveCallback(messageCallback callback);
	int receive();
	const std::string& getMessage(int index);

	~WSClientAddon(); // needed so it can be deleted cleanly
private:
	std::string name_;
	std::string version_;
	std::string header_;

	std::vector<std::string> messages_;
	// The websocket pointer is kept around as a global (unideal, I know)
	// which is why there isn't anything here
};

#endif //WSCLIENT_ADDON_HEADER_GUARD