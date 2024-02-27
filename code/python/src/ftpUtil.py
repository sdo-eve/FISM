'''
Created on Nov 14, 2011

@author: wilson
'''
from config import SUCCESS
from util import ensurePath, timeStamp
from urlparse import urlparse

import os
from ftplib import FTP
import re

# -----------------------------------------------------------------------------
# For fetching TIMED SEE data
# -----------------------------------------------------------------------------
class ftpUtil:

  _calmonths = dict( (x, i+1) for i, x in
                   enumerate(('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')) )
  _verbose = False
  # -----------------------------------------------------------------------------
  # 
  # -----------------------------------------------------------------------------
  def ftp_listdir(self, ftp):
      import datetime, time
      """
      List the contents of the FTP opbject's cwd and return two tuples of
  
         (filename, size, mtime, mode, link)

      one for subdirectories, and one for non-directories (normal files and other
      stuff).  If the path is a symbolic link, 'link' is set to the target of the
      link (note that both files and directories can be symbolic links).

      Note: we only parse Linux/UNIX style listings; this could easily be
      extended.
      """
      dirs, nondirs = [], []
      listing = []
      ftp.retrlines('LIST', listing.append)
      for line in listing:
#          print line
          # Parse, assuming a UNIX listing
          words = line.split(None, 8)
          if len(words) < 6:
#              print >> sys.stderr, 'Warning: Error reading short line', line
              continue

          # Get the filename.
          filename = words[-1].lstrip()
          if filename in ('.', '..'):
              continue

          # Get the link target, if the file is a symlink.
          extra = None
          i = filename.find(" -> ")
          if i >= 0:
              # words[0] had better start with 'l'...
              extra = filename[i+4:]
              filename = filename[:i]

          # Get the file size.
          size = int(words[4])

          # Get the date.
          today = datetime.date.today()
          year =  int(today.strftime("%Y"))
          month = self._calmonths[words[5]]
          day = int(words[6])
          mo = re.match('(\d+):(\d+)', words[7])
          if mo:
              hour, min = map(int, mo.groups())
          else:
              mo = re.match('(\d\d\d\d)', words[7])
              if mo:
                  year = int(mo.group(1))
                  hour, min = 0, 0
              else:
                  raise ValueError("Could not parse time/year in line: '%s'" % line)
#          print "yMdhm: " + str(year) + ", " + str(month) + ", " + str(day) + ", " + str(hour) + ", " + str(min)
          dt = datetime.datetime(year, month, day, hour, min)
          mtime = time.mktime(dt.timetuple())

          # Get the type and mode.
          mode = words[0]

          entry = (filename, size, mtime, mode, extra)
          if mode[0] == 'd':
              dirs.append(entry)
          else:
              nondirs.append(entry)
      return dirs, nondirs


  # -----------------------------------------------------------------------------
  # 
  # -----------------------------------------------------------------------------
  def ftpwalk(self, ftp, top, topdown=True, onerror=None):
    """ Generator that yields tuples of (root, dirs, nondirs)."""

#    print "In ftpwalk, top: " + top
    if not top[-1] == "/":
       top = top + "/"

    # Make the FTP object's current directory to the top dir.
    ftp.cwd(top)
    
    # We may not have read permission for top, in which case we can't
    # get a list of the files the directory contains.  os.path.walk
    # always suppressed the exception then, rather than blow up for a
    # minor reason when (say) a thousand readable directories are still
    # left to visit.  That logic is copied here.
    try:
      dirs, nondirs = self.ftp_listdir(ftp)
    except os.error, err:
      if onerror is not None:
        onerror(err)
      return

    if topdown:
      yield top, dirs, nondirs
    for entry in dirs:
      dname = entry[0]
#      path = posixjoin(top, dname)
      path = top + dname
      if entry[-1] is None: # not a link
         for x in self.ftpwalk(ftp, path, topdown, onerror):
            yield x
    if not topdown:
      yield top, dirs, nondirs

  # -----------------------------------------------------------------------------
  # Time the copy of ftp fetch of contents of remotePath 
  # -----------------------------------------------------------------------------
  def ftpTimedFetch(self, remoteSubDir, localStart, onlyNewFiles, previewOnly):
    import time
    
    print "========= SEE " + remoteSubDir + " ====="    
    start = time.time()
    self.moveFTPFiles(remoteSubDir, localStart, onlyNewFiles, previewOnly)
    stop = time.time()
    print " " + remoteSubDir + " files took " + str(stop - start) + " secs"

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getServer(self, url):  
    sep1 = url.find("//")
    temp = url[sep1+2:]
    sep2 = temp.index("/")
    server = temp[:sep2]
    return server

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getPath(self, url):
    sep1 = url.find("//")
    temp = url[sep1+2:]
    sep2 = temp.index("/")
    path = temp[sep2:]
    return path

  # -----------------------------------------------------------------------------
  # Duplicate all contents of ftp server starting at remotePath root 
  # -----------------------------------------------------------------------------
  def moveFTPFiles(self, remoteSubDir, localStart, onlyNewFiles=False, previewOnly=True):
    """Connect to an FTP server and bring down files to a local directory"""

    # The root of the descent
    print "remoteSubDir = " + remoteSubDir
   
    if onlyNewFiles:
        print "Fetching missing files (no date checking) from " + remoteSubDir
    else:
        print "Fetching all files from " + remoteSubDir
    if previewOnly:
        print "    PREVIEW ONLY"
        
    # Try to connect, get to starting location
    # These only work with python 2.6, not 2.4, sigh...  Must parse it myself...
    #    url = urlparse(remoteSubDir)
    #    server = url.netloc
    #    path = url.path
    server = self.getServer(remoteSubDir)
    path = self.getPath(remoteSubDir)
    print "Connecting... to " + server + ", with path " + path + \
          " as user '<REDACTED>'"   
    try:
        ftp = FTP(server)
        ftp.login("<REDACTED>", "<REDACTED>")
        ftp.cwd(path)
        print " Connected"
    except:
        print "  Couldn't find server " + remoteSubDir + ", aborting"
        return

   # Ensure this top level directory exists
    localCurrent = localStart
    ensurePath(localCurrent, previewOnly) 
        
    # make the generator that accesses the items
    ftpwalkIt = self.ftpwalk(ftp, path)
    
    filesMoved = 0
    remoteTop = path
    # Iterate over ftp sub directories
    for item in ftpwalkIt:
        
        remoteCurrent = item[0]  # the root of where we are
        subDirs = item[1]        # the list of children that are sub dirs
        others = item[2]         # everything not a sub dir
        
#        print "=============================="
#        print "remoteCurrent: " + remoteCurrent    

        # Create a sub path that is our local start location + the current sub path
        # from the remote server that we want to duplicate
        
        # We expect remoteCurrent to end in "/", need to strip that here
        temp = remoteCurrent[:-1]  
        # Get the unique sub piece of the remote path that we want to duplicate
        # by stripping off the remote starting point
        discardPrefix = remoteCurrent[:len(remoteTop)+1]
#        print "discardPrefix: " + discardPrefix
        # ... and append the result to our local starting point
        localCurrentSubPath = localStart + remoteCurrent[len(remoteTop) + 1:]
#        print "localCurrentSubPath = " + localCurrentSubPath
        
        # Ensure all needed subdirectories exist locally        
        for dir in subDirs:
            dirName = dir[0]
            # mkdir on localhost if doesn't already exist
            localCurrent = localCurrentSubPath + dirName 
            print "ensure path: " + localCurrent
            ensurePath(localCurrent, previewOnly)
       
        # Copy other children
        for item in others:
#            print "item: " + str(item[0])
            itemName = item[0]
            localFullPath = localCurrentSubPath + itemName
                        
            remoteFullPath = remoteCurrent + itemName
            print "ftp  %-55s %-70s" % (remoteFullPath, localFullPath)
            # if we're only to copy new files, don't copy files of that name that already exist
            if onlyNewFiles and os.path.exists(localFullPath):
                if self._verbose: print localFullPath + "  already exists in directory, skipping"
                pass
            else:
#                if self._verbose: print "      Fetching " + localFullPath
                if not previewOnly:
                    try:
                        fileObj = open(localFullPath, 'wb')
                        ftp.retrbinary('RETR ' + remoteFullPath, fileObj.write)
                        fileObj.close()
                        filesMoved += 1
#                        break     # for debugging
                    except:
                         print "Connection Error - " + timeStamp()  
#            break   # for debugging
#            print "---"
    print "Files Moved: " + str(filesMoved) + " on " + timeStamp()
    ftp.close() # Close FTP connection
    ftp = None
    

