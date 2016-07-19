import re
import sys

def translate_lines(lines):
    patt_define     = re.compile(r"^#define\s*(\w*).*$")
    patt_func_macro = re.compile(r"^#define\s*(\w*)\(.*$")

    tokens = []
    for line in lines:
        sline = line.strip()
        m = patt_define.match(sline)
        macro_match = patt_func_macro.match(sline)
        if macro_match:
            print("ignoring '{}'".format(sline))
        elif m and not "HEADER_GUARD" in m.groups()[0]:
            tokens.append('"{}"'.format(m.groups()[0]))

    return "local defnames = {" + ",\n".join(tokens) + "}"

if __name__ == '__main__':
    with open(sys.argv[1], "rt") as src:
        newlines = translate_lines(src)

    with open(sys.argv[2], "wt") as dest:
        dest.write(newlines)
