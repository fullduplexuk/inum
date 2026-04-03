
import os, sys
base = os.path.expanduser("~/Developer/inum")
def wf(p, c):
    fp = os.path.join(base, p)
    os.makedirs(os.path.dirname(fp), exist_ok=True)
    with open(fp, "w") as fh:
        fh.write(c)
    print("OK:", p, len(c), "bytes")
# Read all file contents from a manifest
# This is just setup
print("Generator ready")
