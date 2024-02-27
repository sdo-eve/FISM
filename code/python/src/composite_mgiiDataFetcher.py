from URLFetcher import URLFetcher
from config_lisird import COMPOSITE_MGII_SOURCE, LISIRD_COMPOSITE_MGII

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class composite_mgiiDataFetcher(URLFetcher):
    
  # Values from config file
  _source = COMPOSITE_MGII_SOURCE
  _dest   = LISIRD_COMPOSITE_MGII
  
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def __init__(self):
      super(composite_mgiiDataFetcher, self).__init__()

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS
       
    previewOnly = True
    print "================================= composite mgII ====="

    x = composite_mgiiDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching mgII data.  Aborting."
        sys.exit(1)
        
        
        
    