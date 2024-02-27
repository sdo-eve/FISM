'''
Created on Nov 17, 2011

@author: wilson
'''
from URLFetcher import URLFetcher
from config_lisird import SEE_FLARE_SOURCE, LISIRD_SEE_FLARE

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class tsFlareCatalog(URLFetcher):
    
  _source = SEE_FLARE_SOURCE
  _dest   = LISIRD_SEE_FLARE
  
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def __init__(self):
      super(tsFlareCatalog, self).__init__()

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS
       
    previewOnly = False
    print "================================= SEE flare catalog ====="

    x = tsFlareCatalog()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching SEE flare data.  Aborting."
        sys.exit(1)
        
        