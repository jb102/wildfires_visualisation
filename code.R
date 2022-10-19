  fia <- read.csv("fire_nrt_M6_96062.csv", sep=",")
  fia <- data.frame(fia$latitude,fia$longitude)

  library( maps )
  library( mapdata ) 
  
  library(sp)
  library(sf)
  
  #Ignore hotspots below certain latitude for clustering so clusters do not
  #span ocean between Tasmania and mainland
  fiap <- fia[fia[['fia.latitude']] > -39, ]
  
  #Create data frame to store high-level data about clustering results
  cluster_data <- data.frame(k=integer(),
                             cluster=integer(),
                             n=integer(),
                             area_kms=integer(),
                             area_covered=double(),
                             area_covered_and_size=double())
  
  #Create list to store coordinates of convex hull for every cluster 
  coords_list = list()
  
  #Clustering for k=2..25
  set.seed(50)
  for (k in 2:25) {
    
    kmeans <- kmeans(data.frame(fiap$fia.longitude, fiap$fia.latitude),
                     k,
                     nstart=25)
    #For every value of k, add column to main data for cluster membership
    fiap <- cbind(fiap, clusterk = kmeans$cluster)
    names(fiap)[names(fiap) == 'clusterk'] <- paste("cluster",k,sep="")
  
    #Generate high-level data about clustering results and store it
    for (i in 1:k) {
      cluster_subset <- fiap[fiap[[paste("cluster",k,sep="")]] == i, ]
      lat_long <- data.frame(cluster_subset$fia.longitude,
                             cluster_subset$fia.latitude)
      ch <- chull(lat_long)
      coords <- lat_long[c(ch, ch[1]), ]
      coords_list <- append(coords_list,list(coords))
      geographic_polygon <- st_set_crs(st_sfc(st_polygon(
        list(as.matrix(coords)))),4326)
      area_kms <- st_area(geographic_polygon)/1000000
      n <- nrow(cluster_subset)
      area_covered <- n/area_kms
      area_covered_and_size <- area_covered * area_kms
      cluster_data[nrow(cluster_data) + 1,] = c(k,
                                                i,
                                                nrow(cluster_subset),
                                                area_kms,
                                                area_covered,
                                                area_covered_and_size)
    }
    
  }
  
  #Order clusters by their density
  highest_covered <- cluster_data[order(1/cluster_data$area_covered),]

  #Create data frame for clusters ordered by density with overlap between clusters
  #removed - for each conflict between clusters, the one with the highest density
  #is kept.
  highest_covered_no_overlap <- data.frame(  k=integer(),
                                                  cluster=integer(),
                                                  n=integer(),
                                                  area_kms=integer(),
                                                  area_covered=double(),
                                                  area_covered_and_size=double())
  highest_covered_no_overlap[1,] = highest_covered[1,]
  
  #Iterate through clusters in descending order of density to check for overlaps
  #with others, using nested for loop.
  for (i in 2:nrow(cluster_data)) {
    column_name <- paste('cluster',highest_covered[i,'k'],sep="")
    i_cluster <- fiap[fiap[[column_name]] == highest_covered[i,'cluster'], ]
    overlap <- FALSE
    for (j in 1:nrow(highest_covered_no_overlap)) {
      j_row <- rownames(highest_covered_no_overlap)[j]
      i_row <- rownames(highest_covered)[i]
      if (j_row != i_row) {
        cluster_col <- paste('cluster',
                             highest_covered_no_overlap[j,'k'],
                             sep="")
        cluster_number <- highest_covered_no_overlap[j,'cluster']
        j_cluster <- fiap[fiap[[cluster_col]] == cluster_number, ]
        #Overlap is determined by common coordinates in two groups
        if (length(intersect(as.numeric(rownames(i_cluster)),
                             as.numeric(rownames(j_cluster)))) > 0) {
          overlap <- TRUE
        }
      }
    }
    if (!(overlap)) {
      new_index <- nrow(highest_covered_no_overlap)+1
      highest_covered_no_overlap[new_index,] = highest_covered[i,]
    }
  }

  #This is the calculation of of clusters ranked by the fire density multiplied
  #by the area. Uncomment the below to see the results.
  
  #highest_covered_and_size <- cluster_data[order(1/cluster_data$area_covered_and_size),]

  #highest_covered_and_size_no_overlap <- data.frame( k=integer(),
  #                                                         cluster=integer(),
  #                                                         n=integer(),
  #                                                         area_kms=integer(),
  #                                                         area_covered=double(),
  #                                                         area_covered_and_size=double())
  # highest_covered_and_size_no_overlap[1,] = highest_covered_and_size[1,]
  # 
  # for (i in 2:nrow(cluster_data)) {
  #   column_name <- paste('cluster',highest_covered_and_size_no_overlap[i,'k'],sep="")
  #   i_cluster <- fiap[fiap[[column_name]] == highest_covered_and_size_no_overlap[i,'cluster'], ]
  #   overlap <- FALSE
  #   for (j in 1:nrow(highest_covered_no_overlap)) {
  #     j_row <- rownames(highest_covered_no_overlap)[j]
  #     i_row <- rownames(highest_covered)[i]
  #     if (j_row != i_row) {
  #       cluster_col <- paste('cluster',
  #                            highest_covered_and_size_no_overlap[j,'k'],
  #                            sep="")
  #       cluster_number <- highest_covered_and_size_no_overlap[j,'cluster']
  #       j_cluster <- fiap[fiap[[cluster_col]] == cluster_number, ]
  #       if (length(intersect(as.numeric(rownames(i_cluster)),
  #                            as.numeric(rownames(j_cluster)))) > 0) {
  #         overlap <- TRUE
  #       }
  #     }
  #   }
  #   if (!(overlap)) {
  #     new_index <- nrow(highest_covered_and_size_no_overlap)+1
  #     highest_covered_and_size_no_overlap[new_index,] = highest_covered_and_size_no_overlap[i,]
  #   }
  # }

  #Show results of clusters ordered by density and with overlaps removed
  highest_covered_no_overlap
  #highest_covered_and_size_no_overlap
  
  dev.off()
  #Create layout of visualisation, Australia takes up two columns and two rows,
  #other countries use one row and two columns to make space for blown up cluster.
  layout(matrix(c(1, 1, 2, 2,
                  1, 1, 3, 3,
                  5, 5, 4, 4), nrow=3, byrow=TRUE))
  #layout.show(n=5)
  
  #Establishing relevant clusters and getting them from the density data frame
  cluster_1 <- coords_list[[as.numeric(rownames(highest_covered_no_overlap))[1]]]
  cluster_2 <- coords_list[[as.numeric(rownames(highest_covered_no_overlap))[6]]]
  cluster_3 <- coords_list[[as.numeric(rownames(highest_covered_no_overlap))[11]]]
  cluster_4 <- coords_list[[as.numeric(rownames(highest_covered_no_overlap))[12]]]
  
  #Plot Australia
  par(mar = c(0,0,0,0), bg='gray')
  map( database="worldHires",
       regions="Australia",
       xlim=c(112.5,157.5),
       ylim=c(-44.1,10),
       col='white',
       fill=TRUE)
  
  #Write title and subtitle
  text(x=135,
       y=7,
       "The Scale of Wildfires\nin Australia, 2019-2020",font=2,cex=2.75)
  text(x=112.5,
       y=-4,
       pos=4,
       labels=paste("  The bushfire season which lasted from August 2019 to",
                    "April 2020\nin Australia spanned enormous amounts of land.",
                    "A single snapshot\nof these wildfires taken from satellite",
                    "data is visualised here, with\nareas with particularly high",
                    "concentrations of fire blown up and\ncompared to countries of",
                    "similar size for reference. Fire is shown\nin red",
                    "in high-concentration areas, orange elsewhere."))
  
  #Plot main hotspot data in Australia
  points(fia$fia.longitude,fia$fia.latitude,pch=19,cex=0.1,col="orange")
  
  #Fetch hotspot data for the clusters from the main data frame
  clusters_points <- list()
  for (i in c(1,6,11,12)) {
    k <- highest_covered_no_overlap[i,][['k']]
    c <- highest_covered_no_overlap[i,][['cluster']]
    cluster_points <- fiap[fiap[[paste("cluster",k,sep="")]] == c, ]
    cluster_points <- data.frame(cluster_points$fia.longitude,cluster_points$fia.latitude)
    clusters_points <- append(clusters_points,list(cluster_points))
    points(cluster_points,pch=19,cex=0.1,col="red")
  }
  
  #Draw the clusters
  polygon(cluster_1)
  polygon(cluster_2)
  polygon(cluster_3)
  polygon(cluster_4)
  
  #Draw arrows from the clusters pointing to where their blown up versions will be
  arrows(mean(cluster_3$cluster_subset.fia.longitude),
         mean(cluster_3$cluster_subset.fia.latitude),
         157.5,-7)
  arrows(mean(cluster_2$cluster_subset.fia.longitude),
         mean(cluster_2$cluster_subset.fia.latitude),
         157.5,-32)
  arrows(mean(cluster_1$cluster_subset.fia.longitude),
         mean(cluster_1$cluster_subset.fia.latitude),
         157.5,-43)
  arrows(mean(cluster_4$cluster_subset.fia.longitude),
         mean(cluster_4$cluster_subset.fia.latitude),
         122.5,-44.1)

  #Plot South Korea and cluster 11 (3)
  par(mar = c(0,0,0,0))
  long_translation = -20
  lat_translation = 54
  cluster_3_south_korea <- data.frame(cluster_3$cluster_subset.fia.longitude+long_translation,
                                      cluster_3$cluster_subset.fia.latitude+lat_translation)
  map( database="worldHires",
       regions="South Korea",
       xlim=c(121,131),
       col="green",
       fill=TRUE)
  polygon(cluster_3_south_korea,col='white')
  points(clusters_points[[3]]$cluster_points.fia.longitude+long_translation,
         clusters_points[[3]]$cluster_points.fia.latitude+lat_translation,
         pch=19,cex=0.01,col="red")
  text(x=124.5,y=35.5,"Land area:\n108,119km²")
  text(x=124.5,y=35,"3.2% covered in fire",font=2)
  text(x=128,y=36.5,"South Korea",font=2)
  text(x=128,y=36,"Land area:\n100,210km²")
  
  #Plot Belgium and cluster 6 (2)
  par(mar = c(0,0,0,0))
  long_translation = -151.5
  lat_translation = 82
  cluster_2_belgium <- data.frame(cluster_2$cluster_subset.fia.longitude+long_translation,
                                  cluster_2$cluster_subset.fia.latitude+lat_translation)
  map( database="worldHires",
       regions="Belgium",
       xlim=c(-1,7),
       ylim=c(49.48,51.52),
       col="green",
       fill=TRUE)
  polygon(cluster_2_belgium,col='white')
  points(clusters_points[[2]]$cluster_points.fia.longitude+long_translation,
         clusters_points[[2]]$cluster_points.fia.latitude+lat_translation,
         pch=19,cex=1,col="red")
  text(x=2.6,y=50,"Land area:\n29,902km²")
  text(x=2.6,y=49.7,"19.5% covered in fire",font=2)
  text(x=4.5,y=51,"Belgium",font=2)
  text(x=4.5,y=50.7,"Land area:\n30,528km²")
  
  #Plot Puerto Rico and cluster 1 (1)
  par(mar = c(0,0,0,0))
  long_translation = -218.5
  lat_translation = 52.5
  cluster_1_puerto_rico <- data.frame(cluster_1$cluster_subset.fia.longitude+long_translation,
                                      cluster_1$cluster_subset.fia.latitude+lat_translation)
  map( database="worldHires",
       regions="Puerto Rico",
       xlim=c(-69.1,-65),
       ylim=c(17.6,18),
       col="green",
       fill=TRUE)
  polygon(cluster_1_puerto_rico,col='white')
  points(clusters_points[[1]]$cluster_points.fia.longitude+long_translation,
         clusters_points[[1]]$cluster_points.fia.latitude+lat_translation,
         pch=19,cex=1,col="red")
  text(x=-69,y=18.7,"Land area:\n8,021km²")
  text(x=-68,y=17.7,"65.7% covered in fire",font=2)
  text(x=-66.5,y=18.4,"Puerto Rico",font=2)
  text(x=-66.5,y=18.15,"Land area:\n9,104km²")
  
  #Plot Greece and cluster 12 (4)
  par(mar = c(0,0,0,0))
  long_translation = -105
  lat_translation = 69
  cluster_4_greece <- data.frame(cluster_4$cluster_subset.fia.longitude+long_translation,
                                 cluster_4$cluster_subset.fia.latitude+lat_translation)
  map( database="worldHires",
       regions="Greece",
       xlim=c(10.5,27),
       ylim=c(30.8,42.1),
       col="green",
       fill=TRUE)
  polygon(cluster_4_greece,col='white')
  points(clusters_points[[4]]$cluster_points.fia.longitude+long_translation,
         clusters_points[[4]]$cluster_points.fia.latitude+lat_translation,
         pch=19,cex=0.1,col="red")
  text(x=11.5,y=36.5,"Land area:\n136,287km²")
  text(x=15,y=35,"2.8% covered in fire",font=2)
  text(x=20,y=37,"Greece",font=2)
  text(x=20,y=36,"Land area:\n131,957km²")
  
  #Write data citation
  text(x=8.5,
       y=31.5,
       pos=4,
       paste("Source: NASA. Modis/aqua+terra thermal anomalies/fire locations\n",
             "1km firms v006 nrt (vector data).\n",
             "doi: 10.5067/FIRMS/MODIS/MCD14DL.NRT.006",sep=""))
