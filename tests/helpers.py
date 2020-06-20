import contextlib
import os


def create_d_structure(root, name, data):
    """Create a directory structure with the .d format

    Parameters:
    ===========
    root : str / path
        Folder the structure should be create (must exist)
    name : str
        Name of the .d folder to create (excluding .d)
    data : dict
        {device_name: filedata}

    """
    d_folder = os.path.join(root, name + ".d")
    os.mkdir(d_folder)
    for k, v in data.items():
        base, ext = os.path.splitext(name)
        fn = "{}.{}{}".format(base, k, ext)
        with open(os.path.join(d_folder, fn), 'w') as f:
            f.write(v)


def file_contents(filename):
    with open(filename, 'r') as f:
        return f.read()

@contextlib.contextmanager
def working_directory(path):
    cwd = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(cwd)


def create_file(filename, data):
    with open(filename, 'w') as f:
        f.write(data)


