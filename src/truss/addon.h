#ifndef TRUSS_ADDON_H_
#define TRUSS_ADDON_H_

#include <string>

namespace truss {

class Interpreter;

// Pure virtual class for addons
class Addon {
public:
    // These have to return a string by reference so that
    // e.g. getName().c_str() doesn't go out of scope when
    // the function returns
    virtual const std::string& getName() = 0;

    // Note: the header should use Addon* rather than
    // SubclassAddon* as "this" so that terra doesn't
    // have to deal with casts
    virtual const std::string& getCHeader() = 0;
    virtual const std::string& getVersionString() = 0;

    virtual void init(Interpreter* owner) = 0;
    virtual void shutdown() = 0;
    virtual void update(double dt) = 0;

    virtual ~Addon() = default;
};

} // namespace truss

#endif // TRUSS_ADDON_H_
