pro mgii_dat_to_save
    print, 'Running mgii_dat_to_save ',!stime
    ;change directory so you can retrieve the latest file
    cd, expand_path('$fism_data') + '/bremen'
    files = FILE_SEARCH()
    ;files[0] should be the path for the data needed 
    ;print, 'files: ' + files
    ;print, FILE_INFO(expand_path('$fism_data') + '/bremen/latest')
    a=read_ascii(files[0])
    num_el=n_elements(a.field1[0,*])

    mgii_yd_tmp=lonarr(num_el)
    mgii_ind_tmp=fltarr(num_el) 

    x=0d
    y=0.0
    chk=''
    trp=0

    openr, lun, files[0], /get_lun

    for i=0l, num_el-1 do begin
        readf, lun, chk
        t=strsplit(strcompress(chk),' ,',/extract)
        if t[0] eq ';' or t[0] eq 'time' then goto, bdmgii ; header data
        if n_elements(t) le 4 then goto, bdmgii
        if t[5] eq 17 then goto, bdmgii                    ; f10.7 modeled MgII data
        ymd_to_yd, t[0], t[1], t[2], nwyd
        mgii_yd_tmp[i]=nwyd; fix(ymd_to_yd(double(t[0])), type=3) ;ymd_to_yd, year, month, day, yyyydoy
        mgii_ind_tmp[i]=float(t[3])
        bdmgii:
    endfor

    ; Eliminate zeros
    gd=where(mgii_ind_tmp gt 0.01)
    mgii_yd=mgii_yd_tmp[gd]
    mgii_ind=mgii_ind_tmp[gd]
    FILE_MKDIR, expand_path('$fism_data') + '/lasp/mgii/'
    save, mgii_yd, mgii_ind, file=expand_path('$fism_data') + '/lasp/mgii/mgii_idx.sav'
    print, 'End Time mgii_dat_to_save: ', !stime
end
