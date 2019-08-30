#sbatch --array=1-10

slurm_arrayid<-Sys.getenv("SLURM_ARRAY_TASK_ID")
nodenr<-as.numeric(slurm_arrayid)

for(g in nodenr:nodenr){
  
  library(sf); library(raster)
  # # split the big drainage lines file prior to running the script
  # riv <- read_sf('/vol/milkunarc/vbarbarossa/xGlobio-aqua/flo1k_hydrography/drainage_lines24.shp')
  # riv_spl <- split(riv, rep(1:10, each=ceiling(nrow(riv)/10), length.out=nrow(riv)))
  # for(j in 1:10) saveRDS(riv_spl[[j]],paste0('proc/drainage_lines24_spl',j,'.rds'))
  
  # number of cores used for the parallelized calculations
  NC <- 10
  riv <- readRDS(paste0('proc/drainage_lines24_spl',g,'.rds'))
  
  area <- raster('/vol/milkunarc/vbarbarossa/xGlobio-aqua/flo1k_hydrography/upstreamArea.tif') # better use the no. of cells? flowAcc_30sec.tif
  
  move1up <- function(riv_segment){
    
    arcid <- riv_segment$arcid
    rivg <- st_geometry(riv_segment)
    
    
    # 1- get the nodes of the segment
    p <- st_cast(rivg, "POINT")
    # 2- sample upstream area to determine the most up- and down-stream
    e <- extract(area,st_coordinates(p[c(1,length(p))]))
    if(which(e == max(e,na.rm = T)) == 1){ first_ <- 1; next_ <- +1 }else{ first_ <- length(p); next_ <- length(p)-1}
    # 3- draw a line between last two points
    l  <- st_sfc(st_linestring(st_coordinates(p[c(first_,next_)])))
    # 4- determine new point
    dist <- st_length(l)
    if(dist <= sqrt(2)*1/120){ #if node falls within one cell distance simply take that node
      p_new <- p[next_]
    }else{ # otherwise add points to the line and take the first
      p_new <- st_cast(  st_segmentize(l,dfMaxLength = 0.015),'POINT')[2]
      # check distance is not smaller than sqrt(2)*1/120/2 # need to output it as a warning!!
      if(!c(st_distance(st_cast(  st_segmentize(l,dfMaxLength = 0.015),'POINT')[1],p_new)) > sqrt(2)*1/120/2) cat('\npoint smaller than sqrt(2)*1/120/2\n')
      
    }
    return(cbind(data.frame(arcid = arcid),st_coordinates(p_new)))
    
  }
  
  move1up(riv[which(riv$arcid == 332593),])
  # move1up(riv[166294,])
  for(ii in 100:1000) print(move1up(df[ii,]))
  # if both cells have the same upstream area value then get warning message (which(e == max(e, na.rm=T)) == 1) ...
  # so the problem is probably another one when the thing fails
  
  
  tab <- do.call('rbind',parallel::mclapply(split(riv, rep(1:NC, each=ceiling(nrow(riv)/NC), length.out=nrow(riv))),function(df){
    return(do.call('rbind',lapply(split(df,df$arcid),move1up)))
  },mc.cores = NC
  ))
  
  saveRDS(tab,paste0('proc/sampling_points',g,'.rds'))
}
