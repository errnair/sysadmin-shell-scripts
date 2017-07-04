#### Script to add a new user to an Nginx server

The `newuser` script adds a new user to an Nginx server, and creates the appropriate directories,   
sets the correct ownerships and permissions, so that content can be served from the user's home  
directory, rather than the default Nginx location. Additionally, it creates a virtual environment  
within the user's home directory and also copies a test index file to the new webroot.  
  
*Requirements*  

- `root` access to the Nginx webserver.
- Python 3 (to create the virtual environment).
