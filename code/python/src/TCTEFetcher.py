from URLFetcher import URLFetcher
from config_lisird import LISIRD_DATA_ROOT
from config_lisird import TCTE_SOURCE_DIR, LISIRD_TCTE_DIR, TCTE_FILE_LIST
import sys, os

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class TCTE_Fetcher(URLFetcher):

  # Configuration of dataset source info

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def __init__(self):
      self._localRoot = LISIRD_DATA_ROOT
      self._sourceDir = TCTE_SOURCE_DIR
      self._destDir = LISIRD_TCTE_DIR
      self._fileList = TCTE_FILE_LIST

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getSource(self, dataset):
      return self._sourceDir + dataset
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getDest(self, destEnd):
      return self._localRoot + self._destDir + destEnd
  
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def get(self, previewOnly):  
      from config import SUCCESS
      for dataset in self._fileList:
          source = self.getSource(dataset)
          dest = self.getDest(dataset)
          command = "cp " + source + " " + dest
          print command
          if not previewOnly:
              if os.system(command) != SUCCESS:
                print "Problem encountered in fetching " + source + ".  Aborting."
                sys.exit(1)               
      return SUCCESS

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS
            
    previewOnly = False
    print "================================= TCTE ====="
 
    x = TCTE_Fetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching TCTE data.  Aborting."
        sys.exit(1)
        