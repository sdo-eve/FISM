'''
Created on Jun 17, 2011

@author: wilson
'''
import time

from config import SUCCESS
from eveftpFiles import *


from lymanAlphaDataFetcher import *
from goesXRSDataFetcher import *
from tsFlareCatalog import *
from nerDataFetcher import *
from f10_7_MostRecentFetcher import *
from bremen_composite_mg_iiDataFetcher import *
from sorceSolsticeDataFetcher import *
from sorceXPSDataFetcher import *
from sorceXPS5DataFetcher import *
from sohoSemDataFetcher import *

from config_lisird import LISIRD_DATA_ROOT, GET_ALL
from config_lisird import GET_LYA, GET_GOES_XRS, GET_TIMED_SEE_FLARE_CAT
from config_lisird import GET_NOAA_EVENT_REPORTS, GET_F10_7
from config_lisird import GET_EVE
from config_lisird import GET_BREMEN_COMPOSITE_MG_II
from config_lisird import GET_SORCE_SOLSTICE_DAILY, GET_SORCE_XPS, GET_SORCE_XPS5
from config_lisird import GET_SOHO_SEM 
getAll = GET_ALL
getEVE = GET_EVE

getLymanAlphaComposite = GET_LYA
getGoesXRS = GET_GOES_XRS
getTimedSeeFlareCat = GET_TIMED_SEE_FLARE_CAT
getNoaaEventReports = GET_NOAA_EVENT_REPORTS
getF10_7 = GET_F10_7
getBremen_composite_mg_ii = GET_BREMEN_COMPOSITE_MG_II

from config_lisird import PREVIEW_ONLY
previewOnly = PREVIEW_ONLY
# -----------------------------------------------------------------------------
# main
#
# We fetch and propigate the datasets listed in the code below.
# -----------------------------------------------------------------------------
#LOCAL_ROOT = "/lisird/private/fism/data_sets"  # where FISM expects them
#print "Overriding LOCAL_DATA_ROOT to write to " + LOCAL_ROOT

print "Storing data under " + LISIRD_DATA_ROOT

format = "%H:%M  %m/%d/%y"
print "stageData start time: " + time.strftime(format, time.localtime()) + " (UTC on wren)"

# ------------------------------------------------------------------------
if getAll or GET_SORCE_SOLSTICE_DAILY:
    print "=============================== SOLSTICE DAILY ========="
    x = sorceSolsticeDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching solstice daily data.  Aborting."
        sys.exit(1)
# ------------------------------------------------------------------------
if getAll or getLymanAlphaComposite:
    print "================================= lya ====="
    x = lymanAlphaDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching lyman alpha data.  Aborting."
        sys.exit(1)
# ------------------------------------------------------------------------
if getAll or GET_SORCE_XPS:
    print "================================= sorce xps ====="
    x = sorceXPSDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching sorce xps data.  Aborting."
        sys.exit(1)
# ------------------------------------------------------------------------ 
if getAll or GET_SORCE_XPS5:
    print "================================= sorce xps 5s====="
    x = sorceXPS5DataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching sorce xps data.  Aborting."
        sys.exit(1)
# ------------------------------------------------------------------------ 
if getAll or getGoesXRS:
    print "================================= GOES XRS ====="
    from config_lisird import LOGIN_NAME
    x = goesXRSDataFetcher()#LOGIN_NAME)
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching GOES XRS data.  Aborting."
        sys.exit(1)
# ------------------------------------------------------------------------ 
if getAll or GET_SOHO_SEM:
    print "================================= soho sem ====="
    x = sohoSemDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching sorce xps data.  Aborting."
        sys.exit(1)

#           
# ------------------------------------------------------------------------
if getAll or getTimedSeeFlareCat:      
    print "================================= TIMED SEE flare catalog ====="
    x = tsFlareCatalog()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching timed see flare catalog.  Aborting."
        sys.exit(1)
        
# ------------------------------------------------------------------------
if getAll or getEVE:      
    print "================================= EVE ====="
    x = eveftpFiles()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching eve data.  Aborting."
        sys.exit(1)
        # ------------------------------------------------------------------------

if getAll or getF10_7:    
#   print "================================= F10.7 historic ====="
#    x = f10_7_HistoricFetcher()
#    if x.get(previewOnly) != SUCCESS:
#        print "Problem encountered in fetching F10.7 historic data.  Aborting."
#        sys.exit(1)
        
    print "================================= F10.7 most recent ====="
    x = f10_7_MostRecentFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching F10.7 most recent data.  Aborting."
        sys.exit(1)
        
#    print "=============== merging f10.7 historic and recent ====="
#    x = f10_7_Merger()
#    if x.createMergedFile(previewOnly) != SUCCESS:
#        print "Problem encountered in fetching f10.7 MostRecent data.  Aborting."
#        sys.exit(1)
    
# ------------------------------------------------------------------------
if getAll or getBremen_composite_mg_ii:
    print "================================= Bremen composite mg ii ====="
    x = bremen_composite_mg_iiDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching Bremen Composite MgII.  Aborting."
        #sys.exit(1)

#------------------------------------------------------------------------
if getAll or getNoaaEventReports:
    print "================================= NOAA event reports ====="
    x = nerDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        # for now, not calling missing 2014_events.tar an error.  1/20/15
        # print "Problem encountered in fetching NOAA event reports data.  Aborting."
        print "Problem encountered in fetching NOAA event reports data."
        # sys.exit(1)


 