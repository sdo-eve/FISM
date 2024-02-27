from URLFetcher import URLFetcher
from config_lisird import LYA_SOURCE, LISIRD_LYA
import sys

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class lymanAlphaDataFetcher(URLFetcher):

  # Configuration of dataset source info
  _source = LYA_SOURCE
  _dest = LISIRD_LYA

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def __init__(self):
      super(lymanAlphaDataFetcher, self).__init__()

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS
            
    previewOnly = False
    print "================================= lya ====="
 
    x = lymanAlphaDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching lyman alpha data.  Aborting."
        sys.exit(1)
        