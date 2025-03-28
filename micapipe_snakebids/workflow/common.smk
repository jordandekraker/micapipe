def process_flags(key, name):
    if key.lower() == "true":
        return "-" + name
    else:
        return ""

def process_multi_inputs(key):
    if isinstance(key, list):
        return ",".join(key)
    else:
        return key

def process_2_flags(key, name1, name2):
    if key.lower() == "false":
        return ""
    else:
        return "-" + name1 + " " + name2

def process_optional_flags(key, name):
    if key.lower() == "false":
        return ""
    else:
        return "-" + name + " " + key