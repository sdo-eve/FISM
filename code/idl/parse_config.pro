pro parse_config, file
    openr, lun, file, /get_lun
    line = ''
    while ~ eof(lun) do begin
        readf, lun, line

        ; Ignore empty lines or lines that start with "#".
        if (line eq "") or (strmid(line, 0, 1) eq "#") then continue $
        else setenv, line

        ; Print for logging purposes.
        print, line
    endwhile
    free_lun, lun
end
