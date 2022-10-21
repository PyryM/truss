"""
proto_gen.py
-------------

Generate lua sample data for a proto structure
using the Python serialization to benchmark against.
"""
import string
import numpy as np

# import our built proto messages
from messages import test_pb2 as msg


# maximum values of 32 and 64 bit integers
m32 = 2**31 - 1
m64 = 2**63 - 2


def dict_to_lua(blob):
    """
    String wangling of a dict into
    lines of lua.

    Parameters
    -----------
    blob : dict
      Bag of items

    Returns
    -----------
    lua : str
      Lines of a lua dict
    """

    indent = '  '
    lines = []

    def int_to_str(value):
        """
        Apply the flag to negative integers.
        """
        if value < 0:
            kind = 'LL'
        else:
            kind = 'ULL'
        return f'{value}{kind}'

    for k, v in blob.items():

        if isinstance(v, bool):
            v = str(v).lower()
            lines.append(f'{indent}{k}={v}')
        elif isinstance(v, int):
            lines.append(f'{indent}{k}={int_to_str(v)}')
        elif isinstance(v, str):
            lines.append(f'{indent}{k}="{v}"')
        elif isinstance(v, bytes):
            lines.append(f'{indent}{k}="{v.hex()}"')
        elif isinstance(v, float):
            v = f'{v:0.50f}'
            lines.append(f'{indent}{k}={v}')
        elif hasattr(v, 'DESCRIPTOR'):
            # recursively convert
            dump = dict_to_lua(msg_to_dict(v))
            lines.append(f'{indent}{k}={{ {dump} }}')
        elif hasattr(v, 'append') and hasattr(v, 'sort'):
            if len(v) == 0:
                lines.append(f'{k}={{ }}')
            elif isinstance(v[0], float):
                # convert the repeated floats
                dump = ', '.join(f'{i:.50f}' for i in v)
                lines.append(f'{k}={{ {dump} }}')
            elif isinstance(v[0], int):
                # convert the repeated integers
                dump = ', '.join(int_to_str(i) for i in v)
                lines.append(f'{k}={{ {dump} }}')
            elif isinstance(v[0], str):
                # handle list of str
                dump = ', '.join(f'"{i}"' for i in v)
                lines.append(f'{k}={{ {dump} }}')
            elif isinstance(v[0], bytes):
                # handle list of str
                dump = ', '.join(f'"{i.hex()}"' for i in v)
                lines.append(f'{k}={{ {dump} }}')
            elif hasattr(v[0], 'DESCRIPTOR'):
                # we have a repeated list of proto messages
                # repeatedly recurse that shit
                dump = ',\n'.join(
                    f'{{ {dict_to_lua(msg_to_dict(i))} }}'
                    for i in v)
                lines.append(f'{indent}{k}={{ {dump} }}')
            else:
                raise ValueError(f'weird repeated type {type(v[0])}')
        else:
            raise ValueError(f'unknown kind: {type(v)}')

    return ',\n'.join(lines)


def msg_to_dict(message):
    """
    Convert a protobuf object into a dict.
    """
    return {k.name: v for k, v in message.ListFields()}


def message_to_lua(message):
    """
    Convert a protobuf message to a lua-dict with
    two fields, `serialized` and `truth`.

    Parameters
    ------------
    message : protobuf
      Source message to encode

    Returns
    -----------
    lua : str
      Lua code for values
    """

    # serialize to a bytes value
    serial = message.SerializeToString()
    serial_str = serial.hex()

    # use our own dict conversion to avoid mutating values
    truth = dict_to_lua(msg_to_dict(message))
    name = message.DESCRIPTOR.full_name

    # join into a lua file
    lines = ''.join(['{\n',
                     f'message="{name}",\n',
                     'truth={\n',
                     truth,
                     '\n},\nserial="',
                     serial_str,
                     '"\n}'])

    return lines


def r_bool():
    # random boolean
    return np.random.random() > 0.5


def r_str():
    # random printable string
    if np.random.random() < 0.2:
        return ''
    return ''.join(np.random.choice(
        printable, np.random.randint(0, 100)))


def r_bytes():
    # random bytes
    # return empty string more than probability
    if np.random.random() < 0.2:
        return b''

    return np.random.random(np.random.randint(
        0, 100)).tobytes()


def r_int(mult):
    # random normal-range integer
    return int((np.random.random() - 0.5) * mult)


def r_pos(mult):
    # random positive integer
    return int(np.random.random() * mult)


def random_allint():
    """
    Generate a random AllInt message.

    Returns
    ---------
    msg : msg.AllInt
      Message with random data
    """
    return msg.AllInt(
        one=r_int(m32),
        two=r_int(m64),
        three=r_int(m32),
        four=r_int(m64),
        five=r_pos(m32), six=r_pos(m64),  # fixed has to be positive
        seven=r_int(m32), eight=r_int(m64),
        nine=r_pos(m32), ten=r_pos(m64))  # unsigned int positive

# generate some float data


def r_float(mult):
    return float((np.random.random() - 0.5) * mult)


def random_allfloat():
    return msg.AllFloat(
        one=r_float(m32), two=r_float(m64))


printable = list(set(string.printable[:62]))


def random_allbag():
    """
    Generate a random AllInt message.

    Returns
    ---------
    msg : msg.AllInt
      Message with random data
    """
    return msg.AllBag(one=r_bool(),
                      two=r_str(),
                      three=r_bytes())


if __name__ == '__main__':

    # start with max range
    values = [msg.AllInt(one=m32,
                         two=m64,
                         three=m32,
                         four=m64,
                         five=m32,
                         six=m64,
                         seven=m32,
                         eight=m64,
                         nine=m32,
                         ten=m64),
              msg.AllInt(one=-m32,
                         two=-m64,
                         three=-m32,
                         four=-m64,
                         # fixed minimum value is zero
                         five=0,
                         six=0,
                         seven=-m32,
                         eight=-m64,
                         nine=0,
                         ten=0)]

    # add a bunch of random data
    count = 20
    for i in range(count):
        values.append(random_allint())
    for i in range(count):
        values.append(random_allfloat())
    for i in range(count):
        values.append(random_allbag())

    # send mixed messages
    values.append(msg.Mixed(one=random_allint(),
                            two=random_allfloat(),
                            three=random_allbag()))

    values.append(msg.MixedSimple(isAThing=True,
                                  thingKind='stuff',
                                  quality=1 / 3.0))

    # add a simple repeated array
    values.append(msg.RepeatSimple(
        vertices=np.random.random((10, 3)).ravel(),
        faces=np.arange(30).astype(int)))
    values.append(msg.RepeatSimple(
        vertices=(np.random.random((10, 3)) * m32).ravel(),
        faces=[r_int(m64) for i in range(30)]))
    values.append(msg.RepeatMixed(
        camelOne='sup',
        two=[random_allint() for i in range(5)],
        camThree=[random_allfloat() for i in range(10)],
        Four=[random_allbag() for i in range(11)]))

    # try nested objects
    values.append(msg.NestSimple(
        stuff=[msg.NestSimple.Stuff(
            one=[r_str() for i in range(100)],
            two=[r_float(m64) for i in range(10)])]))
    # with bytes
    values.append(msg.NestSimple(
        bloooobbbbs=[r_bytes() for i in range(211)]))
    # with both
    values.append(msg.NestSimple(
        stuff=[msg.NestSimple.Stuff(
            one=[r_str() for i in range(100)],
            two=[r_float(m64) for i in range(10)])],
        bloooobbbbs=[r_bytes() for i in range(211)]))

    # format into a lua block
    truth = 'return {\n' + ',\n'.join(
        message_to_lua(v) for v in values) + '\n}'

    # write to a test file
    with open('test_cases.t', 'w') as f:
        f.write(truth)
    print(truth)
