library(raster); library(sf); library(foreach)

# make global table
tab <- foreach(j = 1:10,.combine = 'rbind') %do% readRDS(paste0('proc/drainage_lines24_spl',j,'_wFLO1K.rds'))


# to run once the array is done
riv <- foreach(j = 1:10,.combine = 'rbind') %do% readRDS(paste0('proc/drainage_lines24_spl',j,'_wFLO1K.rds'))
riv50 <- riv[!is.na(riv$qav_av_dw) && riv$qav_av_dw >= 50,]
st_write(riv50,'proc/drainage_lines24_wFLO1K_maj50qav.shp')

saveRDS(riv,'proc/drainage_lines24_wFLO1K.rds')

st_write(riv,'proc/drainage_lines24_wFLO1K.shp',delete_layer = T)


riv <- readRDS('proc/drainage_lines24_wFLO1K.rds')

# take only asia fr Hung
# xmin, ymin, xmax, ymax
e <-  c(61.25,-8.75,143.75,56.25)
names(e) <- c('xmin','ymin','xmax','ymax')
riv_c <- st_crop(riv,e)
riv_c <- riv_c[,1:which(colnames(riv_c) == 'qav_av_dw')]
riv_c <- riv_c[!is.na(riv_c$qav_av_dw),]
saveRDS(riv_c,'proc/drainage_lines24_wFLO1K_cropped4Hung_noNAs.rds')

riv_c50 <- riv_c[riv_c$qav_av_dw >= 50,]
saveRDS(riv_c50,'proc/drainage_lines24__wFLO1K_cropped4Hung_noNAs_maj50qav.rds')
st_write(riv_c50,'proc/drainage_lines24__wFLO1K_cropped4Hung_noNAs_maj50qav.gpkg')

