'''
Created on Nov 18, 2011

@author: wilson
'''

# This code is needed for FISM, not LISIRD per se.  TODO: rename and reorg to reflect that.
class f10_7_Merger:
  from config_lisird import LISIRD_DATA_ROOT
  from config_lisird import LISIRD_F10_7_HISTORIC, LISIRD_F10_7_RECENT
  from config_lisird import LISIRD_F10_7_MERGED
    
  _localRoot = LISIRD_DATA_ROOT
  # The source of these files to be merged is the destination
  # of a previous fetch, as defined in the config_lisird file
  _historicSource   = LISIRD_F10_7_HISTORIC
  _mostRecentSource = LISIRD_F10_7_RECENT
  _outputFileName   = LISIRD_F10_7_MERGED
  
  # For handling NOAA's format of "most recent" data file
  # mapping to columns in "most recent" data file, constant
  # Below, code currently assumes this is a range
  _mrYear  = 0
  _mrMonth = 1
  _mrDay   = 2
  _mrValue = 3
  
  # For handling NOAA's format of "historic" data file
  # mapping to columns in "historic" data file, constant
  # Below, code currently assumes this is a range
  #_hYMD = 0
  #_hValue = 1
  
  # mapping to new _output format, constant
  _outputYear   = 0
  _outputMonth  = 1
  _outputDay    = 2
  _outputValue  = 3
  _outputOrigin = 4
  
  # temporary fill value for missing data
  _tempFillData = "-99999"
  # temporary fill value for missing origin
  _tempFillOrigin = "unknown"
   
    
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def __init__(self):
      from util import appendSlash    
      self._localRoot = appendSlash(self._localRoot)

  # -----------------------------------------------------------------------------
  # The two data files have different formats.  Merge them.
  # Returns: an ordered list of tuples of form: (year, month, day, value) 
  # -----------------------------------------------------------------------------
  def mergeDataFiles(self):
     # create correctly formatted list from historic data
     hList = self.readHistoricalToList()
     hList = self.reformatHList(hList)     
     # Create correctly formatted list from most recent data
     mrList = self.readMostRecentToList()
     # Create a merged list of the two
     list = self.mergeLists(hList, mrList)
     return list
 
    
  # -----------------------------------------------------------------------------
  # Merges the two lists.
  # Assumes both lists are correctly formatted and ordered.
  # Returns: merged list
  # -----------------------------------------------------------------------------
  def mergeLists(self, hList, mrList): 
      list = []      
      mrListIndex = 0
#      print "len mrList: " + str(len(mrList))
      for hListIndex in range(0, len(hList)):  # check every data point in historic 
#          print "Checking historical " + str(hList[hListIndex])
          # Do historic and most recent dates match?
          if (mrList[mrListIndex][0] == hList[hListIndex][0] and 
              mrList[mrListIndex][1] == hList[hListIndex][1] and 
              mrList[mrListIndex][2] == hList[hListIndex][2]): 
              # Found a match
#              print "MATCH: Appending historical" + str(hList[hListIndex])
              list.append(hList[hListIndex])
              # we're done with this item from the most recent list
              mrListIndex = mrListIndex + 1
          else:
#              print "hListIndex: " + str(hListIndex)
              # No, just copy the historic
#              print "Appending historical " + str(hList[hListIndex])
              list.append(hList[hListIndex])              
      # Include remaining values from historic List
      # Case instance: historic list goes into the future, to end of current year
      hListIndex = hListIndex + 1
      for i in range(hListIndex, len(hList)):
#          print "Appending historical " + str(hList[i])
          list.append(hList[i])
      
      # Including any remaining from mrList 
      # Case instance: as of today, 8/30/2011 historical goes through 7/31/2011
      # while most recent goes through the latest, yesterday.  
      # Thus, must include remaining most recent.
      for i in range(mrListIndex, len(mrList)):
#          print "Appending most recent " + str(mrList[i])
          list.append(mrList[i])
          
      # sanity check
      # I really don't know what time ranges these two files might cover
      # at any point in time.  Thus, I don't know that the algorithm above
      # is sufficient.
#      print "DEBUG final list"
#      for i in range(0, len(list)):
#          print "==> " + str(list[i]) 
      return list
    
    
  # -----------------------------------------------------------------------------
  # Transforms historic data point format to desired format,
  # i.e., each (yyyymmdd val) becomes a (yyyy mm dd val)
  # Returns: list of  (yyyy mm dd val) values.
  # -----------------------------------------------------------------------------
  def reformatHList(self, hList):
      list = []
      for item in hList:
          dataPoint = self.reformat(item)
          list.append(dataPoint)
      return list   
          

  # -----------------------------------------------------------------------------
  # Reformats (yyyymmdd val) to (yyyy mm dd val)
  # Returns: one (yyyy mm dd val)
  # -----------------------------------------------------------------------------
  def reformat(self, item):
      yyyymmdd = item[0]
      year  = yyyymmdd[:4] 
      month = yyyymmdd[4:6] 
      day   = yyyymmdd[6:] 
      return (year, month, day, item[1])
    

  # -----------------------------------------------------------------------------
  # Reads historic data file, returns filled list of those values.
  # Fill value is self._tempFillData.
  # Returns: list of tuples of form (yyyymmdd val)
  # -----------------------------------------------------------------------------
  def readHistoricalToList(self):     
      # lines in file are of form:
      # yyyymmdd
      #    (having missing values) ... or ...
      # yyyymmdd ddd.d
      #
      # Doesn't seem to have any comment chars...           
      list = []      
      inputfile = open(self.historicSource(), "r")
      for line in inputfile:
          if line.strip(): # Return a copy of the string with leading and trailing characters removed.
              myTuple = tuple(line.strip().split())
              if len(myTuple) == 1:
                  newTuple = tuple((myTuple[0], self._tempFillData))
                  list.append(newTuple)
              elif myTuple[1] == '.':  # sometimes values of '.' show up, don't know what that means!
                  newTuple = tuple((myTuple[0], self._tempFillData))
                  list.append(newTuple)    
#                  print myTuple[0] + ": replacing value of '.' with fill value"
#                  s = raw_input("Found a '.'! ")                                                  
              else:
                  list.append(myTuple)
      return list

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def historicSource(self):
      return self._localRoot + self._historicSource
        
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def mostRecentSource(self):
      return self._localRoot + self._mostRecentSource
 
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getDest(self):
      return self._localRoot + self._outputFileName
             
  # -----------------------------------------------------------------------------
  # Reads "most recent" data file, creates list of those values
  # Returns: list containing first four values of each line that
  # does not start with either char ":" or "#"
  # TODO: could this file have missing values?  Not handled.
  # -----------------------------------------------------------------------------
  def readMostRecentToList(self):      
      # lines in file are of form:
      # yyyy mm dd   val .... and a bunch of other fields
      # Also, starts with two header lines that start with ":"
      # Comment lines marked with "#"      
      list = []
      inputfile = open(self.mostRecentSource(), "r")
      for line in inputfile:
          if line.strip():
              # Toss lines that start with these chars
              if line.startswith(":") or line.startswith("#"):
                  continue
              # Get just the fields we need (assuming they are specified by a range)
              myTuple = tuple(line.strip().split()) [self._mrYear:self._mrValue + 1]
              list.append(myTuple)
      return list
 
       
  # -----------------------------------------------------------------------------
  # For each data point, if a value is missing calcuate <something>, and indicate
  # by each value whether it was measured ("m") or derived ("d").
  # 
  # Note: for now, is just using keeping existing fill values, and adding 
  # self._tempFillOrigin as default origin value
  #
  # Returns: list of items of form (yyyy mm dd val origin)
  # -----------------------------------------------------------------------------
  def fillMissingValues(self, inList):      
      # Need to talk with Phil about how to fill values
      # For now, just add _tempFillOrigin value      
      list = []
      for item in inList:
          # "append" new origin field to the data point 
          #  For now, its just a default
          newTuple = (item[self._mrYear], item[self._mrMonth], item[self._mrDay], 
                      item[self._mrValue], self._tempFillOrigin)
          list.append(newTuple)
      return list
       
  # -----------------------------------------------------------------------------
  # Formats and writes to list to file on the disk.
  # Side effect: new file on disk
  # -----------------------------------------------------------------------------
  def writeOutputFile(self, list, previewOnly):
     from util import ensurePath, getDir
     
     dest = self.getDest()
     print "Writing output file to " + dest

     dir = getDir(dest)
     ensurePath(dir, previewOnly)

     outputfile = open(self.getDest(), "w")
     for item in list:
         year  = item[self._outputYear]
         month = item[self._outputMonth]
         day   = item[self._outputDay]
         value = item[self._outputValue] 
         origin = item[self._outputOrigin]
         outString = year + " " + month + " " + day + " " + value + " " + origin
         outString = "%s\n" % outString
         if not previewOnly:
             outputfile.write(outString)
     outputfile.close()        

  # -----------------------------------------------------------------------------
  # From the two staged files, created a merged data file with missing values
  # filled and a origin tag added to each data point.
  # -----------------------------------------------------------------------------
  def createMergedFile(self, previewOnly):    
      from config import SUCCESS
      list = self.mergeDataFiles()
#      for myTuple in list:
#          print myTuple[self._mrYear]  + " " + \
#                myTuple[self._mrMonth] + " " + \
#                myTuple[self._mrDay]   + " " + \
#                myTuple[self._mrValue]
      list = self.fillMissingValues(list)
      self.writeOutputFile(list, previewOnly)
      return SUCCESS
      
# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    import sys
    from config import SUCCESS
    from f10_7_HistoricFetcher import f10_7_HistoricFetcher
    from f10_7_MostRecentFetcher import f10_7_MostRecentFetcher
       
    print "=============== merging f10.7 historic and recent ====="
    
    previewOnly = False
    
    print "================================= F10.7 historic ====="
    x = f10_7_HistoricFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching F10.7 historic data.  Aborting."
        sys.exit(1)
        
    print "================================= F10.7 most recent ====="
    x = f10_7_MostRecentFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching F10.7 most recent data.  Aborting."
        sys.exit(1)
    
    x = f10_7_Merger()
    if x.createMergedFile(previewOnly) != SUCCESS:
        print "Problem encountered in fetching f10.7 MostRecent data.  Aborting."
        sys.exit(1)
            
