"""
Reformat GRPC imports to module-relative so we can use
them in a python binding.
"""
import os
import subprocess


from grpc_tools import protoc

pwd = os.path.abspath(os.path.expanduser(
    os.path.dirname(__file__)))
target = os.path.abspath(os.path.join(
    pwd, './messages'))


def build():
    """
    Build the proto files in the current directory.
    """
    for file_name in os.listdir(pwd):
        if not file_name.lower().endswith('.proto'):
            continue
        protoc.main((
            '',
            '-I.',
            f'--python_out={target}',
            f'--grpc_python_out={target}',
            file_name))
        print(f'built: {file_name}')


def fix_imports():
    """
    Change to relative imports in generated protobuff
    bindings for in-module use:
    i.e. "import load_pb2" -> "from . import load_pb2"
    """
    for file_name in os.listdir(target):
        if not file_name.lower().endswith('.py'):
            continue
        if not '_pb2' in file_name:
            continue

        file_path = os.path.join(target, file_name)
        with open(file_path, 'r') as f:
            reformat = []
            changed = False
            for line in str.splitlines(f.read()):
                if not line.strip().startswith('import'):
                    reformat.append(line)
                    continue
                if 'grpc' in line:
                    reformat.append(line)
                    continue
                reformat.append(f'from . {line}')
                # show the change
                print(f'`{line}` ->\n\t`{reformat[-1]}`')
                changed = True
        if changed:
            print(f'writing: {file_path}\n')
            with open(file_path, 'w') as f:
                f.write('\n'.join(reformat))


if __name__ == '__main__':
    build()
    fix_imports()
