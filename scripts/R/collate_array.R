library(raster); library(sf); library(foreach)

################################################################################################################
# make global table
tab <- foreach(j = 1:10,.combine = 'rbind') %do% readRDS(paste0('proc/sampling_points',j,'_wFLO1K.rds'))
# filter out records that have long term Qav = 0 or NAs
tab <- tab[!is.na(tab$qav_av_dw) & tab$qav_av_dw > 0,]
# save the table as rds object
saveRDS(tab,'proc/flo1k_table_ts.rds')

################################################################################################################
# collate river shapes together
riv <- foreach(j = 1:10,.combine = 'rbind') %do% readRDS(paste0('proc/drainage_lines24_spl',j,'_wFLO1K.rds'))

# save only the flo1k rivers with long-term Qav [LITE version]
riv_av <- riv[,c('arcid','length_km','dw_area','up_area','qav_av_dw')]
riv_av <- riv_av[!is.na(riv_av$qav_av_dw) & riv_av$qav_av_dw > 1,] #filter for Q>1m3/s (~1/3 of total records selected)
colnames(riv_av)[1:5] <- c('arcid','length_km','area_dw_km','area_up_km','Qav_1960-2015')
saveRDS(riv_av,'proc/flo1k_rivers_maj1.rds')
st_write(riv_av,'proc/flo1k_rivers_maj1.gpkg')

# save the entire time series
riv_ts <- riv[!is.na(riv$qav_av_dw) & riv$qav_av_dw > 1,] #filter for Q>1m3/s (~1/3 of total records selected)
riv_ts <- riv_ts[,c(1:13,13+which(sapply(strsplit(colnames(riv_ts)[14:(ncol(riv_ts)-1)],'_'),function(x) x[3]) == "dw"))] # slect only "dw" columns
saveRDS(riv_ts,'proc/flo1k_rivers_maj1_ts.rds')
st_write(riv_ts,'proc/flo1k_rivers_maj1_ts.gpkg')

###############################################################################################################
# crop to a specified extent and filter for specified Qav
# xmin, ymin, xmax, ymax
e <-  c(61.25,-8.75,143.75,56.25)
# Q threshold
qt <- 50 #m3/s
names(e) <- c('xmin','ymin','xmax','ymax')
riv_c <- st_crop(riv,e)
riv_c <- riv_c[,1:which(colnames(riv_c) == 'qav_av_dw')]
riv_c <- riv_c[!is.na(riv_c$qav_av_dw),]
saveRDS(riv_c,'proc/drainage_lines24_wFLO1K_cropped4Hung_noNAs.rds')

riv_c50 <- riv_c[riv_c$qav_av_dw >= qt,]
saveRDS(riv_c50,'proc/drainage_lines24__wFLO1K_cropped4Hung_noNAs_maj50qav.rds')
st_write(riv_c50,'proc/drainage_lines24__wFLO1K_cropped4Hung_noNAs_maj50qav.gpkg')

