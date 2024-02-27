; Given a string hhmm time, this will return a numeric representation of the
; second-of-day time.
function hhmm_to_sod, hhmm
    str = strtrim(hhmm, 2)

    ; This is difficult to convert.
    ; TODO: What should be returned?
    if str eq '////' then return, -1

    n = strlen(str)

    if n eq 4 then begin
        minute = fix(strmid(str, 1, 2, /reverse_offset))
        hour = fix(strmid(str, 3, 2, /reverse_offset))
    endif else if n eq 3 then begin
        minute = fix(strmid(str, 1, 2, /reverse_offset))
        hour = fix(strmid(str, 2, 1, /reverse_offset))
    endif else if n le 2 then begin
        minute = fix(strmid(str, 1, 2, /reverse_offset))
        hour = 0
    endif else begin
        new_str = strmid(str, 0, 4, /reverse_offset)
	return, hhmm_to_sod(new_str)
    endelse

    sod = minute * 60l + hour * 3600l
    return, sod
end
