#include "wsclient_addon.h"
#include <iostream>

#include "easywsclient.hpp"

#ifdef _WIN32
#pragma comment( lib, "ws2_32" )
#include <WinSock2.h>
#endif

using easywsclient::WebSocket;
static WebSocket::pointer ws_ = NULL;

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

WSClientAddon::WSClientAddon() {
	initWSA();
	name_ = "wsclient";
	version_ = "0.0.1";
	header_ = "/*WSClientAddon Embedded Header*/\n"
		"#include <stdbool.h>\n"
		"typedef struct Addon Addon;\n"
		"typedef void(*messageCallback)(const char*);\n"
		"bool truss_wsclient_open(Addon* addon, const char* url);\n"
		"void truss_wsclient_close(Addon* addon);\n"
		"void truss_wsclient_send(Addon* addon, const char* msg);\n"
		"void truss_wsclient_receive_callback(Addon* addon, messageCallback callback);\n"
		"int truss_wsclient_receive(Addon* addon);\n"
		"const char* truss_wsclient_getmessage(Addon* addon, int msgindex);\n";
}

const std::string& WSClientAddon::getName() {
	return name_;
}

const std::string& WSClientAddon::getHeader() {
	return header_;
}

const std::string& WSClientAddon::getVersionString() {
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

bool WSClientAddon::open(const std::string& url) {
	if(ws_ != NULL) {
		truss_log(TRUSS_LOG_WARNING, "WSClientAddon::open: Websocket already open.");
		return true;
	}
	ws_ = WebSocket::from_url(url);
	if(ws_ == NULL) {
		truss_log(TRUSS_LOG_ERROR, "WSClientAddon::open: Error opening websocket.");
		return false;
	} else {
		return true;
	}
}

void WSClientAddon::close() {
	if(ws_ == NULL) {
		return;
	}
	ws_->close();
	ws_ = NULL;
}

void WSClientAddon::send(const std::string& msg) {
	if(ws_ == NULL || ws_->getReadyState() == WebSocket::CLOSED) {
		truss_log(TRUSS_LOG_ERROR, "WSClientAddon::send: socket not open");
		return;
	}
	ws_->send(msg);
}

static messageCallback c_callback_ = NULL;

void dispatch_to_c_callback(const std::string& msg) {
	c_callback_(msg.c_str());
}

void WSClientAddon::receiveCallback(messageCallback callback) {
    if(ws_ && ws_->getReadyState() != WebSocket::CLOSED) {
		ws_->poll();
		c_callback_ = callback;
		ws_->dispatch(dispatch_to_c_callback);
    } else {
    	ws_ = NULL;
    	truss_log(TRUSS_LOG_ERROR, "WSClientAddon::receiveCallback: cannot receive from closed socket.");
    }
}

static std::vector<std::string>* target_ = NULL;

void push_message(const std::string& message)
{
	target_->push_back(message);
}

int WSClientAddon::receive() {
	messages_.clear();
    if(ws_ && ws_->getReadyState() != WebSocket::CLOSED) {
		ws_->poll();
		target_ = &messages_;
		ws_->dispatch(push_message);
		return (unsigned int)messages_.size();
    } else {
    	ws_ = NULL;
    	truss_log(TRUSS_LOG_WARNING, "WSClientAddon::receive: socket is closed.");
		return -1;
    }
}

static const std::string& EMPTY_STRING = "";

const std::string& WSClientAddon::getMessage(int index) {
	if(index < 0 || index >= messages_.size()) {
		return EMPTY_STRING;
	} else {
		return messages_[index];
	}
}

WSClientAddon::~WSClientAddon(){
	cleanupWSA();
}

bool truss_wsclient_open(WSClientAddon* addon, const char* url){
	std::string temp(url);
	return addon->open(temp);
}

void truss_wsclient_close(WSClientAddon* addon){
	addon->close();
}

void truss_wsclient_send(WSClientAddon* addon, const char* msg){
	std::string temp(msg);
	addon->send(temp);
}

void truss_wsclient_receive_callback(WSClientAddon* addon, messageCallback callback){
	addon->receiveCallback(callback);
}

int truss_wsclient_receive(WSClientAddon* addon){
	return addon->receive();
}

const char* truss_wsclient_getmessage(WSClientAddon* addon, int msgindex){
	return addon->getMessage(msgindex).c_str();
}
