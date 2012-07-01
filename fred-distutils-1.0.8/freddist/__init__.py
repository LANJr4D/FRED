# git-buildpackage is stupid
import sys
if sys.version_info < (2, 5):
    raise SystemExit("Must use python 2.5 or greater")
