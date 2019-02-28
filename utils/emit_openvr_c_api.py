import sys
import json

TRUSS_PREFIX = "tr_ovw_"
#TRUSS_API_PREFIX = "TRUSS_C_API "
TRUSS_API_PREFIX = ""

def get_substituted_type(subtable, rawtype):
    if rawtype.strip() in subtable:
        return subtable[rawtype.strip()]
    else:
        return rawtype.strip().replace("vr::", "").replace("const","").replace("struct","").strip()
        #return rawtype.strip().replace("const","").replace("struct","").strip()
        #return rawtype.strip().replace("struct","").strip()

def get_substituted_self(subtable, selftype):
    return get_substituted_type(subtable, selftype) + "*"

def create_declaration(method, type_sub_table):
    selftype = get_substituted_self(type_sub_table, method["classname"])
    outtype = get_substituted_type(type_sub_table, method["returntype"])
    methodname = TRUSS_PREFIX + method["methodname"]
    print(methodname)
    if "params" in method:
        params = [(get_substituted_type(type_sub_table, p["paramtype"]), p["paramname"])
                    for p in method["params"]]
    else:
        params = []
    argterms = [(selftype, "self")] + params
    argstring = ", ".join(["{} {}".format(ptype, pname) for (ptype, pname) in argterms])
    declaration = "{} {}({})".format(outtype, methodname, argstring)
    return declaration

def emit_declarations(methods, type_sub_table):
    return [TRUSS_API_PREFIX + create_declaration(method, type_sub_table) + ";"
            for method in methods]

def emit_definitions(methods, type_sub_table):
    ret = []
    for method in methods:
        ret.append(create_declaration(method, type_sub_table) + " {")
        if "params" in method:
            params = [p["paramname"] for p in method["params"]]
        else:
            params = []
        arglist = ", ".join(params)
        scall = "self->{}({});".format(method["methodname"], arglist)
        outtype = get_substituted_type(type_sub_table, method["returntype"])
        if outtype != "void":
            scall = "return " + scall
        ret.append("\t" + scall)
        ret.append("}")
        ret.append("")
    return ret


if __name__ == '__main__':
    subtable = {"const char *": "const char *"} #{"vr::IVRSystem": "IVRSystem"}

    with open(sys.argv[1], "rt") as src:
        data = json.load(src)
        decls = emit_declarations(data["methods"], subtable)
        defls = emit_definitions(data["methods"], subtable)
    with open(sys.argv[2], "wt") as dest:
        for decl in decls:
            dest.write(decl + "\n")
    with open(sys.argv[3], "wt") as dest:
        for defl in defls:
            dest.write(defl + "\n")
