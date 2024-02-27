'''
Created on Nov 21, 2011

@author: wilson
'''
# Copy from LISIRD internal content space to FISM space in ways FISM wants them.
# Essentially maps from lisird content space to fism space. 

from config_lisird import LISIRD_DATA_ROOT

from config_lisird import LISIRD_F10_7_HISTORIC, LISIRD_F10_7_RECENT, LISIRD_F10_7_MERGED
from config_lisird import LISIRD_TIMED_SEE, LISIRD_SEE_LEVEL3_DIR
from config_lisird import LISIRD_BREMEN_LATEST   # Now using Bremen instead of LISIRD_COMPOSITE_MGII (in config_lisird)
from config_lisird import LISIRD_LYA
from config_lisird import LISIRD_NER
from config_lisird import LISIRD_GOES_XRS

from config_fism import FISM_DEST_ROOT
from config_fism import FISM_F10_7_HISTORIC, FISM_F10_7_RECENT, FISM_F10_7_MERGED
from config_fism import FISM_SEE_LEVEL3_MERGED
from config_fism import FISM_MGII
from config_fism import FISM_LYA
from config_fism import FISM_NER
from config_fism import FISM_GOES_XRS


import os

class FISM_ProxyCopier:
    
    def __init__(self):
        from util import appendSlash
        self._sourceRoot = appendSlash(LISIRD_DATA_ROOT)
        
        
    def copyFile(self, source, dest):
        copyCommand = "cp " + source + " " + dest
        print "** " + copyCommand
        os.system(copyCommand)
 
    def copyf107(self):      
        # historic
        src = LISIRD_DATA_ROOT + LISIRD_F10_7_HISTORIC
        dest = FISM_DEST_ROOT + FISM_F10_7_HISTORIC
        self.copyFile(src, dest)
        
        # most recent
        src = LISIRD_DATA_ROOT + LISIRD_F10_7_RECENT
        dest = FISM_DEST_ROOT + FISM_F10_7_RECENT
        self.copyFile(src, dest)
        
        # merged
        src = LISIRD_DATA_ROOT + LISIRD_F10_7_MERGED
        dest = FISM_DEST_ROOT + FISM_F10_7_MERGED
        self.copyFile(src, dest)

               
    def copymgII(self):
        src = LISIRD_DATA_ROOT + LISIRD_BREMEN_LATEST    # Using Bremen composite for mg II
        dest = FISM_DEST_ROOT + FISM_MGII
        print "cp " + src + " " + dest
        self.copyFile(src, dest)
 
    
    def copyLymanAlpha(self):
        src = LISIRD_DATA_ROOT + LISIRD_LYA
        dest =  FISM_DEST_ROOT + FISM_LYA
        self.copyFile(src, dest)


    def copySEE_L3_merged(self):
        src = LISIRD_DATA_ROOT + LISIRD_TIMED_SEE + LISIRD_SEE_LEVEL3_DIR + "/latest_see_L3_merged.ncdf"
        dest = FISM_DEST_ROOT + FISM_SEE_LEVEL3_MERGED
        self.copyFile(src, dest)


    def copyNoaaEventReports(self):
        src = LISIRD_DATA_ROOT + LISIRD_NER
        dest =  FISM_DEST_ROOT + FISM_NER
        self.copyDirRename(src, dest)

 
    def copyGoes(self):
        # TODO: deal with the following:
        # Hack due to space problem.  Only copying 2013's file for now.
        # See goesXRSDataFetcher.py
        src = LISIRD_GOES_XRS
        self.copyDirRename(self._sourceRoot + src, FISM_DEST_ROOT + FISM_GOES_XRS)
        #src = LISIRD_DATA_ROOT +  LISIRD_GOES_XRS + "goes_1mdata_widx_2013.sav"
        #dest = FISM_DEST_ROOT + FISM_GOES_XRS
        #self.copyFile(src, dest)
        
              
    def copyDirRename(self, source, dest): 
        # Recursive directory copy.
        # This copy does not put the source directory *in* the destination directory.
        # Instead, the final directory name of the source is renamed to the final
        # directory name of the destination.
        # 
        # Don't want a trailing slash to treat paths uniformly and
        # also because system cp behavior may vary with trailing slash
        from util import deleteTrailingSlash
        source = deleteTrailingSlash(source)

        
        # Old must gone, else new dir will go into old dir
        command = "rm -rf " + dest
        print "** " + command
        os.system(command)
        
        # Copy to parent of destination
        from util import getDir
        toDir = getDir(dest)
        command = "cp -R " + source + " " + toDir
        print "** " + command
        os.system(command)

        # Rename it with the new name
        from util import getFileName
        
        oldDirName = getFileName(source)
        srcName = toDir + oldDirName
        
        newFileName = getFileName(dest)
        destName = toDir + newFileName
        
        command = "mv " + srcName + " " + destName
        print "** " + command
        os.system(command)

        
        
# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
       
    x = FISM_ProxyCopier()
    x.copyf107()  
    x.copymgII()
    x.copyLymanAlpha()
    x.copySEE_L3_merged()  
    x.copyGoes()
    x.copyNoaaEventReports()   


