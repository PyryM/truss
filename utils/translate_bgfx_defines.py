import re
import sys

def translate_lines(lines):
    ret = []

    patt_macro = re.compile(r"^#define\s*(\w*)\s*(\w*)\((.*)\)$")
    patt_number = re.compile(r"^#define\s*(\w*)\s*(\d*)$")

    suffixes = {"UINT8_C": "",
                "UINT16_C": "",
                "UINT32_C": "",
                "UINT64_C": "ULL"}

    for line in lines:
        sline = line.strip()
        if len(sline) == 0:
            continue
        m1 = patt_macro.match(line)
        m2 = patt_number.match(line)
        if m1:
            #print(m1.groups())
            if m1.groups()[1] in suffixes:
                litval = "{}{}".format(m1.groups()[2], 
                                       suffixes[m1.groups()[1]])
            else:
                print("Unknown type {}".format(m1.groups()[1]))
                continue
            v = "bgfx_const.{} = {}".format(m1.groups()[0],
                                            litval)
            ret.append(v)
        elif m2:
            v = "bgfx_const.{} = {}".format(m2.groups()[0],
                                m2.groups()[1])
            ret.append(v)
        else:
            print("Line [" + line + "] didn't match anything.")

    return ret

if __name__ == '__main__':
    with open(sys.argv[1], "rt") as src:
        newlines = translate_lines(src)

    with open(sys.argv[2], "wt") as dest:
        dest.write("\n".join(newlines))