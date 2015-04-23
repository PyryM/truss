// C++ truss implementation

using namespace trss;

void Interpreter::init(trss_message* arg) {
	_terraState = luaL_newstate();
	luaL_openlibs(_terraState);
	terra_Options* opts = new terra_Options;
	opts->verbose = 2; // very verbose
	opts->debug = 1; // debug enabled
	terra_initwithoptions(_terraState, opts);
	delete opts; // not sure if necessary or desireable

	// load and execute the bootstrap script
	trss_message* bootstrap = trss_load_file("bootstrap.t", TRSS_CORE_PATH);
	terra_loadbuffer(_terraState, 
                     bootstrap->data, 
                     bootstrap->message_length, 
                     "bootstrap.t");
	lua_pcall(_terraState, 0, 0, 0);
}