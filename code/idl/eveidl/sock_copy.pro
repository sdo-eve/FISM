;+                                                                              
; Project     : HESSI                                                           
;                                                                               
; Name        : SOCK_COPY                                                       
;                                                                               
; Purpose     : copy file via sockets                                      
;                                                                               
; Category    : utility system sockets                                          
;                                                                               
; Syntax      : IDL> sock_copy,url,out_name,out_dir=out_dir                           
;                                                                               
; Inputs      : URL = remote file name to copy with URL path               
;               OUT_NAME = optional output name for copied file
;                                                                               
; Outputs     : None                                                           
;                                                                               
; Keywords    : OUT_DIR = output directory to copy file                         
;               ERR   = string error message                                    
;               LOCAL_FILE = local name of copied file
;               BACKGROUND = download in background
;                                                                  
; History     : 27-Dec-2001,  D.M. Zarro (EITI/GSFC) - Written                  
;               23-Dec-2005, Zarro (L-3Com/GSFC) - removed COMMON               
;               26-Dec-2005, Zarro (L-3Com/GSFC) 
;                - added /HEAD_FIRST to HTTP->COPY to ensure checking for              
;                  file before copying                               
;               18-May-2006, Zarro (L-3Com/GSFC) 
;                - added IDL-IDL bridge capability for background copying                  
;               10-Nov-2006, Zarro (ADNET/GSFC) 
;                - replaced read_ftp call by ftp object
;                1-Feb-2007, Zarro (ADNET/GSFC)
;                - allowed for vector OUT_DIR
;               4-June-2009, Zarro (ADNET)
;                - improved FTP support
;               27-Dec-2009, Zarro (ADNET)
;                - piped FTP copy thru sock_get
;               18-March-2010, Zarro (ADNET)
;                - moved err and out_dir keywords into _ref_extra
;                8-Oct-2010, Zarro (ADNET)
;                - dropped support for COPY_FILE. Use LOCAL_FILE to
;                  capture name of downloaded file.
;               30-March-2011, Zarro (ADNET)
;                - restored capability to download asynchronously 
;                  using /background
;               16-December-2011, Zarro (ADNET)
;                - force using sock_get if proxy server is being used
;               13-August-2012, Zarro (ADNET)
;                - added OLD_WAY and NETWORK (for testing purposes and
;                  backwards compatibility only)
;               27-Dec-2012, Zarro (ADNET)
;                 - added /NO_CHECK
;               25-February-2013, Zarro (ADNET)
;               - added call to REM_DUP_KEYWORDS to protect
;                against duplicate keyword strings (e.g. VERB vs
;                VERBOSE)
;               1-March-2015, Zarro (ADNET)
;               - added support for /OLD_WAY for FTP copies
;               16-June-2016, Zarro (ADNET)
;               - deprecated /OLD_WAY (caused recursion situations)
;               24-Sept-2016, Zarro (ADNET)
;               - call sock_get if HTTPS 
;               11-Oct-2016, Zarro (ADNET)
;               - made USE_NETWORK the default
;               7-Nov-2016, Zarr (ADNET)
;               - return error message for invalid input URL
;-                                                                              
                                                                                
pro sock_copy_main,url,out_name,_ref_extra=extra,local_file=local_file,$
                   use_network=use_network,err=err

err=''
local_file=''
if ~is_url(url) then begin
 pr_syntax,'sock_copy,url,out_dir=out_dir'
 err='Input must be valid URL.'
 return
endif
                     
use_get=since_version('6.4')
;if is_number(use_network) then if use_network eq 0 then use_get=0b
n_url=n_elements(url)                                                           
local_file=strarr(n_url)    
for i=0,n_url-1 do begin         
 if use_get then begin
  sock_get,url[i],out_name,_extra=extra,local_file=temp,err=err
 endif else begin
  if ~obj_valid(sock) then sock=obj_new('http',_extra=extra)             
  sock->copy,url[i],out_name,_extra=extra,local_file=temp,err=err
 endelse
 if is_string(temp) then if file_test(temp) then local_file[i]=temp
endfor                                                 
                         
if n_url eq 1 then local_file=local_file[0]
                                                                                
if obj_valid(sock) then obj_destroy,sock
                                                                                
return                                                                          
end                                                                             

;--------------------------------------------------------------------------
pro sock_copy,url,out_name,_ref_extra=extra,background=background

extra=rem_dup_keywords(extra)
if keyword_set(background) && since_version('6.3') then $
 thread,'sock_copy',url,out_name,_extra=extra else $
  sock_copy_main,url,out_name,_extra=extra

return & end
