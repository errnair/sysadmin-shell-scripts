#!/usr/bin/env python
"""
Script to check the number of CPU cores.
Usage: python checkcpu.py
"""
import multiprocessing

cpu_count = multiprocessing.cpu_count()
print cpu_count
