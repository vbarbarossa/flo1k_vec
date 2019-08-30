#sbatch --array=1-10

g <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))

library(raster); library(sf); library(foreach)

tab <- readRDS(paste0('proc/sampling_points',g,'.rds'))

area <- raster('/vol/milkunarc/vbarbarossa/xGlobio-aqua/flo1k_hydrography/upstreamArea.tif') # better use the no. of cells? flowAcc_30sec.tif

# extract upstream area
tab$dw_area <- extract(area,tab[,c('X_dw','Y_dw')])
tab$up_area <- extract(area,tab[,c('X_up','Y_up')])

NC <- 10
year_seq <- 1960:2015
Qnames = c('qav','qma','qmi')
dir_flo1k <- '/vol/milkundata/FLO1K/TIFF/'

to.export <- list()
for(var.n in 1:length(Qnames)){
  
  Qname = Qnames[var.n]
  dir.rasters <- paste0(dir_flo1k,Qname,'/')
  ext1year <- function(year,xytab){
    
    e <- round(extract(raster(paste0(dir.rasters,year,'.tif')),xytab),3)
    e[which(e < 0)] <- NA
    
    return(e)
  }
  
  df_binded <- foreach(ending = c('_dw','_up'),.combine = 'cbind') %do% {
    
    ext <- parallel::mcmapply(ext1year,year = year_seq,xytab = rep(list(tab[,c(paste0('X',ending),paste0('Y',ending))]),length(year_seq)),SIMPLIFY = FALSE,mc.cores=NC)
    df <- data.frame(matrix(unlist(ext),nrow=length(ext[[1]])))
    colnames(df) <- year_seq
    
    df$av <- apply(df,1,function(x) round(mean(x,na.rm = TRUE),3))
    df$me <- apply(df,1,function(x) round(median(x,na.rm = TRUE),3))
    df$sd <- apply(df,1,function(x) round(sd(x,na.rm = TRUE),3))
    
    colnames(df) <- paste0(Qname,'_',colnames(df),ending)
    
    return(df)
    
  }
  
  to.export[[var.n]] <- df_binded
}

btab <- cbind(tab,to.export[[1]],to.export[[2]],to.export[[3]])
saveRDS(btab,paste0('proc/sampling_points',g,'_wFLO1K.rds'))

riv <- readRDS(paste0('proc/drainage_lines24_spl',g,'.rds'))
riv_ <- merge(riv,btab,by='arcid')

saveRDS(riv_,paste0('proc/drainage_lines24_spl',g,'_wFLO1K.rds'))

# # to run once the array is done
# riv <- foreach(j = 1:10,.combine = 'rbind') %do% readRDS(paste0('proc/drainage_lines24_spl',j,'_wFLO1K.rds'))
# # before saving also other filtering should be done
# # filter out all NAs and below a certain flow threshold
# st_write(riv,'proc/drainage_lines24_wFLO1K.gpkg',delete_layer = T)
# 
# riv50 <- riv[!is.na(riv$qav_av_dwn) && riv$qav_av_dwn >= 50,]
# st_write(riv50,'proc/drainage_lines24_wFLO1K_maj50qav.shp')


