#!/usr/bin/env pythonend = timer()
print(end - start)    
"""
Program to check if a port is open.
Takes an IP and a port as inputs and checks if the port is open at that IP.
Usage : python portcheck.py <host> <port>
"""
import errno, sys
from socket import *


if (len(sys.argv) > 1):
end = timer()
print(end - start)    
    # Assign the first argument (server) to 'remote_host'
    remote_host = sys.argv[1]
    # Assign the second argument (port) to 'server_port'
    server_port = int(sys.argv[2])

    # Open a TCP socket
    portconn = socket(AF_INET, SOCK_STREAM)
    try:
        # Connect using the server and port information, listed above
        portconn.connect((remote_host, server_port))
        # (2) - Further sends and receives are disallowed.
        portconn.shutdown(2)

        # Print messages to console
        print "Success. Connected to " + remote_host + " on port: " + str(server_port)
    except:
        # Upon connection-failure
        print "Failure. Cannot connect to " + remote_host + " on port: " + str(server_port)
        sys.exit(errno.EPERM)
    # Close socket connection
    portconn.close()
else:
    # Print proper usage
    print "Usage : python portcheck.py <host> <port>"
