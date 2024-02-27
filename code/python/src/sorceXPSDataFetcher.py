from URLFetcher import URLFetcher
from config_lisird import SORCE_XPS_SOURCE, LISIRD_SORCE_XPS_DIR
import sys

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class sorceXPSDataFetcher(URLFetcher):

  # Configuration of dataset source info
  _source = SORCE_XPS_SOURCE
  _dest = LISIRD_SORCE_XPS_DIR

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def __init__(self):
      super(sorceXPSDataFetcher, self).__init__()

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS
            
    previewOnly = False
    print "================================= sorce xps ====="
 
    x = sorceXPSDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching sorce xps data.  Aborting."
        sys.exit(1)
        