#include "wsclient_addon.h"
#include <iostream>

#include "easywsclient.hpp"

#ifdef _WIN32
#pragma comment( lib, "ws2_32" )
#include <WinSock2.h>
#endif

using easywsclient::WebSocket;

bool initWSA() {
#ifdef _WIN32
    INT rc;
    WSADATA wsaData;

    rc = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (rc) {
        truss_log(TRUSS_LOG_ERROR, "WSAStartup Failed.");
        return false;
	} else {
		truss_log(TRUSS_LOG_INFO, "WSAStartup Succeeded.");
		return true;
	}
#endif
}

void cleanupWSA() {
#ifdef _WIN32
    WSACleanup();
#endif	
}

struct WSClientAddonSocket {
	WebSocket::pointer ws;
	std::vector<std::string> messages;
};

WSClientAddon::WSClientAddon() {
	initWSA();
	name_ = "wsclient";
	version_ = "0.0.1";
	header_ = R"(
		/* WSClient Addon Embedded Header */

		#include <stdbool.h>

		typedef struct Addon Addon;
		typedef void(*messageCallback)(const char*);

		int truss_wsclient_open(Addon* addon, const char* url);
		void truss_wsclient_close(Addon* addon, int slot);
		void truss_wsclient_send(Addon* addon, int slot, const char* msg);
		void truss_wsclient_receive_callback(Addon* addon, int slot, messageCallback callback);
		int truss_wsclient_receive(Addon* addon, int slot);
		const char* truss_wsclient_getmessage(Addon* addon, int slot, int msgindex);
	)";
	slots_ = new WSClientAddonSocket[WS_ADDON_MAX_SOCKET_SLOTS];
	for (int i = 0; i < WS_ADDON_MAX_SOCKET_SLOTS; ++i) {
		slots_[i].ws = NULL;
	}
}

const std::string& WSClientAddon::getName() {
	return name_;
}

const std::string& WSClientAddon::getHeader() {
	return header_;
}

const std::string& WSClientAddon::getVersion() {
	return version_;
}

void WSClientAddon::init(truss::Interpreter* owner) {
	// nothing special to do
}

void WSClientAddon::shutdown() {
	// nothing special to do
}

void WSClientAddon::update(double dt) {
	// nothing special to do
}

int WSClientAddon::open(const std::string& url) {
	// try to find an open slot
	for (int i = 0; i < WS_ADDON_MAX_SOCKET_SLOTS; ++i) {
		if (slots_[i].ws == NULL) {
			slots_[i].ws = WebSocket::from_url(url);
			slots_[i].messages.clear();
			if (slots_[i].ws != NULL) {
				return i;
			} else {
				truss_log(TRUSS_LOG_ERROR, "WSClientAddon::open: Error opening websocket.");
				return -1;
			}
		}
	}
	return -1; // no open slot
}

void WSClientAddon::close(int slot) {
	if (slot < 0 || slot >= WS_ADDON_MAX_SOCKET_SLOTS) return;
	if(slots_[slot].ws == NULL) {
		return;
	}
	slots_[slot].ws->close();
	slots_[slot].ws = NULL;
	slots_[slot].messages.clear();
}

void WSClientAddon::send(int slot, const std::string& msg) {
	if (slot < 0 || slot >= WS_ADDON_MAX_SOCKET_SLOTS) return;
	WebSocket::pointer& ws = slots_[slot].ws;
	if(ws == NULL || ws->getReadyState() == WebSocket::CLOSED) {
		truss_log(TRUSS_LOG_ERROR, "WSClientAddon::send: socket not open");
		return;
	}
	ws->send(msg);
}

static messageCallback c_callback_ = NULL;

void dispatch_to_c_callback(const std::string& msg) {
	c_callback_(msg.c_str());
}

void WSClientAddon::receiveCallback(int slot, messageCallback callback) {
	if (slot < 0 || slot >= WS_ADDON_MAX_SOCKET_SLOTS) return;
	WebSocket::pointer& ws = slots_[slot].ws;
    if(ws && ws->getReadyState() != WebSocket::CLOSED) {
		ws->poll();
		c_callback_ = callback;
		ws->dispatch(dispatch_to_c_callback);
    } else {
    	ws = NULL;
    	truss_log(TRUSS_LOG_ERROR, "WSClientAddon::receiveCallback: cannot receive from closed socket.");
    }
}

static std::vector<std::string>* target_ = NULL;

void push_message(const std::string& message)
{
	target_->push_back(message);
}

int WSClientAddon::receive(int slot) {
	if (slot < 0 || slot >= WS_ADDON_MAX_SOCKET_SLOTS) return -1;
	WebSocket::pointer& ws = slots_[slot].ws;
	slots_[slot].messages.clear();
    if(ws && ws->getReadyState() != WebSocket::CLOSED) {
		ws->poll();
		target_ = &(slots_[slot].messages);
		ws->dispatch(push_message);
		return (unsigned int)(slots_[slot].messages.size());
    } else {
    	slots_[slot].ws = NULL;
    	truss_log(TRUSS_LOG_WARNING, "WSClientAddon::receive: socket is closed.");
		return -1;
    }
}

static const std::string& EMPTY_STRING = "";

const std::string& WSClientAddon::getMessage(int slot, int index) {
	if (slot < 0 || slot >= WS_ADDON_MAX_SOCKET_SLOTS) return EMPTY_STRING;
	WebSocket::pointer& ws = slots_[slot].ws;
	if(index < 0 || index >= slots_[slot].messages.size()) {
		return EMPTY_STRING;
	} else {
		return slots_[slot].messages[index];
	}
}

WSClientAddon::~WSClientAddon() {
	delete[] slots_;
	cleanupWSA();
}

int truss_wsclient_open(WSClientAddon* addon, const char* url) {
	std::string temp(url);
	return addon->open(temp);
}

void truss_wsclient_close(WSClientAddon* addon, int slot) {
	addon->close(slot);
}

void truss_wsclient_send(WSClientAddon* addon, int slot, const char* msg) {
	std::string temp(msg);
	addon->send(slot, temp);
}

void truss_wsclient_receive_callback(WSClientAddon* addon, int slot, messageCallback callback) {
	addon->receiveCallback(slot, callback);
}

int truss_wsclient_receive(WSClientAddon* addon, int slot) {
	return addon->receive(slot);
}

const char* truss_wsclient_getmessage(WSClientAddon* addon, int slot, int msgindex) {
	return addon->getMessage(slot, msgindex).c_str();
}
