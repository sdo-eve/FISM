'''
Created on Nov 17, 2011

@author: wilson
'''
from URLFetcher import URLFetcher
from config_lisird import F10_7_HISTORIC_SOURCE, LISIRD_F10_7_HISTORIC
from config import SUCCESS

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class f10_7_HistoricFetcher(URLFetcher):
  
  _source = F10_7_HISTORIC_SOURCE
  _dest = LISIRD_F10_7_HISTORIC
  
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
  def __init__(self):
      super(f10_7_HistoricFetcher, self).__init__()

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
       
    previewOnly = False
    print "================================= f10.7 Historic ====="

    x = f10_7_HistoricFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching f10.7 Historic data.  Aborting."
        sys.exit(1)
