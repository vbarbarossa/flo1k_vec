#sbatch --array=1-10

g <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))

library(sf); library(raster)
# # split the big drainage lines file prior to running the script
# riv <- read_sf('/vol/milkunarc/vbarbarossa/xGlobio-aqua/flo1k_hydrography/drainage_lines24.shp')
# riv_spl <- split(riv, rep(1:10, each=ceiling(nrow(riv)/10), length.out=nrow(riv)))
# for(j in 1:10) saveRDS(riv_spl[[j]],paste0('proc/drainage_lines24_spl',j,'.rds'))

if(!dir.exists('proc')) dir.create('proc') # create proc folder

# number of cores used for the parallelized calculations
NC <- 10
riv <- readRDS(paste0('proc/drainage_lines24_spl',g,'.rds'))

move1up <- function(riv_segment){
  
  arcid <- riv_segment$arcid
  rivg <- st_geometry(riv_segment)
  warn <- 0
  
  # 1- get the nodes of the segment
  p <- st_cast(rivg, "POINT")
  
  # 2- draw a line from the most downstream node to the one immediately upstream
  l  <- st_sfc(st_linestring(st_coordinates(p[c(length(p),(length(p)-1))])))
  
  # 3- determine new point
  dist <- st_length(l)
  if(dist <= sqrt(2)*1/120){ #if node falls within ~one cell distance simply take that node
    p_new <- p[(length(p)-1)]
  }else{ # otherwise segmentize the line and take the one closest to the most downstream
    p_sgm <- st_cast(  st_segmentize(l,dfMaxLength = 0.015),'POINT')
    p_new <- p_sgm[2]
    # check distance is not smaller than sqrt(2)*1/120/2 and record it as a warning to output in the table
    if(!c(st_distance(p_sgm[1],p_new)) > sqrt(2)*1/120/2) warn <- 1
    
  }
  # coordinates corrected downstream point
  d_dw <- st_coordinates(p_new)
  colnames(d_dw) <- paste0(colnames(d_dw),'_dw')
  # coordinates most upstream point
  d_up <- st_coordinates(p[1])
  colnames(d_up) <- paste0(colnames(d_up),'_up')
  # total length of segment in m
  riv_length <- round(as.numeric(st_length(rivg))/1000,3)
  
  return(
    cbind(
      data.frame(arcid = arcid, length_km = riv_length, warn = warn),d_dw,d_up
    )
  )
  
}

tab <- do.call('rbind',parallel::mclapply(split(riv, rep(1:NC, each=ceiling(nrow(riv)/NC), length.out=nrow(riv))),function(df){
  return(do.call('rbind',lapply(split(df,df$arcid),move1up)))
},mc.cores = NC
))

saveRDS(tab,paste0('proc/sampling_points',g,'.rds'))

