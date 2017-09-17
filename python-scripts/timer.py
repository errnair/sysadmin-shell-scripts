#!/usr/bin/env python
"""
Script to check the time taken to execute a set of commands.
Usage: python timer.py
"""
from timeit import default_timer as timer

start = timer()
ctr = 0

while ctr < 100:
    ctr += 1
    print ("\n" + str(ctr))

end = timer()
print("time to execute = " + str(end - start))
