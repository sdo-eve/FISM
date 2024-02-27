'''
Created on May 2, 2011

@author: wilson
'''
import os
import time

import errno

import httplib
import urllib2  # Python 3 deprecates urllib.urlopen for urllib2.urlopen
from config import SUCCESS, FAILURE

# -----------------------------------------------------------------------------
# Ensure directory exists
# -----------------------------------------------------------------------------
def ensurePath(dir, previewOnly):
#  print "Ensuring path " + dir  
  if not os.path.exists(dir):
      if not previewOnly:
          os.makedirs(dir)
          print "Made new directories for " + dir
          
  # -----------------------------------------------------------------------------
  # 
  # -----------------------------------------------------------------------------
def timeStamp():
    """returns a formatted current time/date"""
    import time
    return str(time.strftime("%a %d %b %Y %I:%M:%S %p"))

# -----------------------------------------------------------------------------
# 
# -----------------------------------------------------------------------------
def getNowYear():
    return time.localtime()[0] 

# -----------------------------------------------------------------------------
# 
# -----------------------------------------------------------------------------
def getNowyyyyMMdd():
#    print "getNowyyyyMMdd:  " + str(time.localtime())
    s = time.strftime('%Y%m%d', time.localtime())
    return s

# -----------------------------------------------------------------------------
# TODO: This should be renamed as append is conditional,
# Perhaps "ensureTrailingSlash"...
# -----------------------------------------------------------------------------
def appendSlash(string):
    temp = string
    if not temp.endswith("/"): temp += "/"
    return temp
    
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
def deleteTrailingSlash(string):
    temp = string
    if temp.endswith("/"): temp = temp[:-1]
    return temp
    

# -----------------------------------------------------------------------------
# Read from the source, write to the destination
# Side effect: creates a data file on this disk
# -----------------------------------------------------------------------------
def readHTTP(sourceURL, destination):
    httplib.HTTPConnection.debuglevel = 1
    try:
        pagehandler = urllib2.urlopen(sourceURL)
        outputfile = open(destination, "w")
        while 1:
#            print "info: " + str(pagehandler.info())
            data = pagehandler.read(512)
            if not data:
                break
            outputfile.write(data)
        outputfile.close()        
        pagehandler.close()
#        print "Returning success"
        return SUCCESS
    except (urllib2.HTTPError, urllib2.URLError, IOError), e:
        print "Error caught! ",
        if hasattr(e, 'reason'):
            print 'Reason: ', e.reason
        if hasattr(e, 'code'):
            print 'Error code: ', e.code
        if hasattr(e, 'read'):
             print 'read(): ', e.read()
        print str(e)
        return FAILURE
 
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
def unTar(destination):
  import subprocess
  
  # uncompress and untar the file
  dir = destination[: destination.rfind("/")]
  file = destination[destination.rfind("/") + 1 :]
  command = "tar -xf " + destination + " --directory " + dir
  print 'untar command: ' + command
  subprocess.call([command], shell=True)  
 
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
def deleteTar(tarFile):
  import subprocess
  
  # Can't do the following, another 2.4 anacronism, sigh...
#  if tarFile.endswith((".tar.gz", ".tar")):
  if tarFile.endswith(".tar.gz") or tarFile.endswith(".tar"):
      print "Deleting tar file " + tarFile
      command = "rm " + tarFile
      subprocess.call([command], shell=True)  
  else:
      print tarFile + " does not appear to be a tar file.  Aborting delete tar file."
 
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
def getDir(string):
    # assumes string ends with "yyy/xxxxx", and returns yyy
      path = string[:string.rfind("/")]
      return path
    
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
def getFileName(path):
    # assumes string ends with "yyy/xxxxx", and returns xxxxx
      fileName = path[path.rfind("/"):]
      return fileName
    
def symlink_force(target, link_name):
    try:
        os.symlink(target, link_name)
    except OSError, e:
        if e.errno == errno.EEXIST:
            os.remove(link_name)
            os.symlink(target, link_name)
        else:
            raise e 


