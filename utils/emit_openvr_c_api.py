import sys
import json

TRUSS_PREFIX = "tr_ovw_"
TRUSS_API_PREFIX = "TRUSS_C_API "
#TRUSS_API_PREFIX = ""

def get_substituted_type(subtable, rawtype, is_include):
    if rawtype.strip() in subtable:
        return subtable[rawtype.strip()]
    elif is_include:
        return rawtype.strip().replace("vr::", "").replace("const","").replace("struct","").strip()
    else:
        return rawtype.strip().replace("const","").replace("struct","").strip()
        return rawtype.strip().replace("struct","").strip()

def get_substituted_self(subtable, selftype, is_include):
    return get_substituted_type(subtable, selftype, is_include) + "*"

def create_declaration(method, type_sub_table, is_include):
    selftype = get_substituted_self(type_sub_table, method["classname"], is_include)
    outtype = get_substituted_type(type_sub_table, method["returntype"], is_include)
    methodname = TRUSS_PREFIX + method["methodname"]
    print(methodname)
    if "params" in method:
        params = [(get_substituted_type(type_sub_table, p["paramtype"], is_include), p["paramname"])
                    for p in method["params"]]
    else:
        params = []
    argterms = [(selftype, "self")] + params
    argstring = ", ".join(["{} {}".format(ptype, pname) for (ptype, pname) in argterms])
    declaration = "{} {}({})".format(outtype, methodname, argstring)
    return declaration

def emit_declarations(methods, type_sub_table, is_include):
    prefix = ""
    if not is_include:
        prefix = TRUSS_API_PREFIX
    return [prefix + create_declaration(method, type_sub_table, is_include) + ";"
            for method in methods]

def emit_definitions(methods, type_sub_table, is_include):
    ret = []
    for method in methods:
        ret.append(create_declaration(method, type_sub_table, is_include) + " {")
        if "params" in method:
            params = [p["paramname"] for p in method["params"]]
        else:
            params = []
        arglist = ", ".join(params)
        scall = "self->{}({});".format(method["methodname"], arglist)
        outtype = get_substituted_type(type_sub_table, method["returntype"], is_include)
        if outtype != "void":
            scall = "return " + scall
        ret.append("\t" + scall)
        ret.append("}")
        ret.append("")
    return ret


if __name__ == '__main__':
    subtable = {"const char *": "const char *"} #{"vr::IVRSystem": "IVRSystem"}

    with open("openvr_api.json", "rt") as src:
        data = json.load(src)

    decls = emit_declarations(data["methods"], subtable, False)
    defls = emit_definitions(data["methods"], subtable, False)
    with open("wrapper.h", "wt") as dest:
        dest.write("\n".join(decls))
    with open("wrapper.cpp", "wt") as dest:
        dest.write("\n".join(defls))

    decls = emit_declarations(data["methods"], subtable, True)
    with open("include.h", "wt") as dest:
        dest.write("\n".join(decls))
