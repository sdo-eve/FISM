'''
Created on Nov 17, 2011

@author: wilson
'''
from URLFetcher import URLFetcher
from config_lisird import F10_7_RECENT_SOURCE, LISIRD_F10_7_MERGED

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class f10_7_MostRecentFetcher(URLFetcher):
  
  _source = F10_7_RECENT_SOURCE
  _dest = LISIRD_F10_7_MERGED #changed to account for new f107
  
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def __init__(self):
      super(f10_7_MostRecentFetcher, self).__init__()

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS
    import sys
       
    previewOnly = False
    print "================================= f10.7 MostRecent ====="

    x = f10_7_MostRecentFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching f10.7 MostRecent data.  Aborting."
        sys.exit(1)
