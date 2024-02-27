'''
Created on Jun 16, 2011

@author: wilson
'''


import os

class ProxyCopier:

    sourceRoot = "/lisird/private/fism/data_sets/"
    destRoot = "/public/lisird/fism/input_data_sets/"

    def copy(self, source, dest):
        # Cp to /public/lisird on webapp1
        # rsync to /public/lisird on pi512001
        copyTo_webapp1 = "cp " + source + " " + dest
        copyTo_pi512001 = "rsync " + source + " lisird@pi512001:" + dest
        print "** " + copyTo_webapp1
        print "** " + copyTo_pi512001
        os.system(copyTo_webapp1)
        os.system(copyTo_pi512001)
 
    def copyf107(self):
        src = "f107/final.txt"
        dest = "f107"
        self.copy(self.sourceRoot + src, self.destRoot + dest)
        
    def copymgII(self):
        src = "mgii/composite_mg2.dat"
        dest = "mgii"
        self.copy(self.sourceRoot + src, self.destRoot + dest)
    
    def copyLymanAlpha(self):
        src = "lya/lymanAlpha.dat"
        dest = "lya"
        self.copy(self.sourceRoot + src, self.destRoot + dest)

    def copySEE(self):
        dest = "SEE"
        src = "SEE/latest_see_L3_merged.ncdf"
        self.copy(self.sourceRoot + src, self.destRoot + dest)

        src = "SEE/latest_egs_L2_merged.ncdf"
        self.copy(self.sourceRoot + src, self.destRoot + dest)

        src = "SEE/latest_xps_L2_merged.ncdf"
        self.copy(self.sourceRoot + src, self.destRoot + dest)

        src = "SEE/latest_see_L3A_merged.ncdf"
        self.copy(self.sourceRoot + src, self.destRoot + dest)

        src = "SEE/latest_see_L4A_merged.ncdf"
        self.copy(self.sourceRoot + src, self.destRoot + dest)

        src = "SEE/latest_see_L4_merged.ncdf"
        self.copy(self.sourceRoot + src, self.destRoot + dest)

        src = "SEE/see_flare_catalog.csv"
        self.copy(self.sourceRoot + src, self.destRoot + dest)

    
# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    
    from config import LOCAL_ROOT
       
    previewOnly = True
    x = ProxyCopier()
    x.copyf107()  
    x.copymgII()
    x.copyLymanAlpha()
    x.copySEE()     