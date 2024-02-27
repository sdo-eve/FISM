function unix_to_jd, unix_s

  jd_0=double(date_conv2013('01-jan-1970 00:00:00','jul'))

  jd=jd_0+unix_s/24d/3600d

return,jd
end
