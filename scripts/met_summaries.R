#------------------------------------
# Script Information
#------------------------------------
# Purpose: Create daily and monthly summaries of met data 
# Creator: Drew Duckett, 11 January 2017
# Contact: duckettdj@g.cofc.edu
#------------------------------------

#------------------------------------
# Description
#------------------------------------
# Two functions: One to summarize hourly met data into daily met data (daily_sums)
#   and one to summarize that daily met data into monthly met data (monthly_sums.

# Note: The input data must be a netcdf file 

# daily_sums input:
# 1. netcdf file; open this outside of the function to avoid complicaitons of file path

# daily_sums output:
# dataframe with met variables as columns and days as rows

# monthly_sums input:
# 1. The dataframe produced by daily_sums

# monthly_sums output:
# dataframe with variables as columns and months as rows

# Input variables (and type of summary):
# 1. tair (mean, min, max)
# 2. precipf (total)
# 3. swdown (mean and average hours of sun per day, hours sun = hours when swdown > 0)
# 4. lwdown (mean)
# 5. qair (mean)
# 6. psurf (mean)
# 7. wind (mean)

#------------------------------------
# Workflow Overview
#------------------------------------
# daily_sums:
# 1) Import data and set bounds for each day
# 2) Create functions to calculate daily sumaries
#   - segregate data by day, calculate summary, and put data in new dataframe
# 3) Get data for each variable and use functions from step 2

# monthly_sums:
# 1) Set bounds for each month
#   - leap years are accounted for based on the number of rows (days) in the input dataframe
# 2) Segregate data by month, calculate summaries, and put in new dataframe
#------------------------------------


#------------------------------------
# Daily
#------------------------------------

daily_sums <- function(nc_data){
  
  #Load required libraries
  library(ncdf4)
  library(stringr)
  
  #download time data 
  # nc_data <- nc_open(file_name) #create connection to datafile
  nc_time <- ncvar_get(nc = nc_data, varid = "time") #Extract time data
  
  #calculate intervals for grouping hours into days
  day_seq <- seq(1, length(nc_time), by = 24) #starting indices
  
  if(length(day_seq)<365 | length(day_seq)>366) stop("Not working with hourly data for full year; need to adjust script")
  
  day_seq2 <- day_seq - 1 #ending indices
  day_seq3 <- day_seq2[2:length(day_seq2)] #omit first ending index
  day_seq4 <- append(day_seq3, day_seq3[length(day_seq3)] + 24, after = length(day_seq3)) #add last hour
  
  day_num <- seq(1, length(day_seq), by = 1) #get numbers for days
  
  #group hours into days
  day_list <- list()
  # d = 1 #set counter
  for (d in day_num){
    day_name <- paste0("Day", str_pad(d, 3, "left", pad="0") ) #create day name
    day_name <- list(assign(day_name, nc_time[day_seq[d]:day_seq4[d]])) #assign data for day to day name
    day_list <- append(day_list, day_name, after = length(day_list)) #create list of day lists
  }
  
  sums <- data.frame(row.names = day_num) #create empty df for data
  
  
  #function to calculate daily means
  
  calc_mean <- function(measure_name){  
    
    ave_df <- data.frame(row.names = day_num) #create empty df for data
    day_list <- list()
    
    #group data by day
    d = 1 #set counter
    for (day in day_num){
      day_name <- paste0("Day", d ) #create day name
      day_name <- list(assign(day_name, measure_name[day_seq[d]:day_seq4[d]])) #assign data for day to day name
      day_list <- append(day_list, day_name, after = length(day_list)) #create list of day lists
      d = d + 1
    }
    
    #calculate daily mean
    daily_mean <- list()
    for (day in day_list){
      hourly_mean <- mean(day) #calculate the mean for the day
      daily_mean <- append(daily_mean, hourly_mean, after = length(daily_mean)) #compile all daily means into a list
    }
    
    #put data in a df
    ave_df <- cbind(ave_df, unlist(daily_mean)) #append daily mean to df
    measure_id <- deparse(substitute(measure_name)) #get just the name of measure_id
    measure_id <- gsub("nc_", "", measure_id) #remove the nc prefix
    colnames(ave_df) <- paste0(measure_id, "_mean") #rename columns
    return(ave_df)
  }
  
  #function to calculate tair data
  
  tair_df <- data.frame(row.names = day_num) #create empty df for tair data
  
  calc_tair <- function(){  
    
    #group data by day
    day_list <- list()
    d = 1 #set counter
    for (day in day_num){
      day_name <- paste0("Day", d ) #create day name
      day_name <- list(assign(day_name, nc_tair[day_seq[d]:day_seq4[d]])) #assign data for day to day name
      day_list <- append(day_list, day_name, after = length(day_list)) #create list of day lists
      d = d + 1
    }
    
    daily_mean <- list()
    daily_min <- list()
    daily_max <- list()
    
    #calculate summary stats for each day
    for (day in day_list){
      hourly_mean <- mean(day) #calculate the mean for the day
      daily_mean <- append(daily_mean, hourly_mean, after = length(daily_mean)) #compile all daily means into a list
      
      hourly_min <- min(day) #calculate min for each day
      daily_min <- append(daily_min, hourly_min, after = length(daily_min)) #compile all daily mins into a list
      
      hourly_max <- max(day) #calculate max for each day
      daily_max <- append(daily_max, hourly_max, after = length(daily_max)) #compile daily maxes into a list
    }
    
    #put data in df
    tair_df <- cbind(tair_df, unlist(daily_mean)) #append daily mean data to tair df
    tair_df <- cbind(tair_df, unlist(daily_min)) #append daily min data to df
    tair_df <- cbind(tair_df, unlist(daily_max)) #append daily max data to df
    colnames(tair_df) <- c("tair_mean", "tair_min", "tair_max") #rename columns
    return(tair_df)
  }
  
  
  #function to calculate precip data
  
  precip_df <- data.frame(row.names = day_num)
  
  calc_precip <- function(){
    
    #group data by day
    day_list <- list()
    d = 1 #set counter
    for (day in day_num){
      day_name <- paste0("Day", d ) #create day name
      day_name <- list(assign(day_name, nc_precipf[day_seq[d]:day_seq4[d]])) #assign data for day to day name
      day_list <- append(day_list, day_name, after = length(day_list)) #create list of day lists
      d = d + 1
    }
    
    #calculate summary stats for each day
    # input = kg/m2/s * 60*60 = kg/m2/hr
    daily_tot <- list() 
    for (day in day_list){
      hourly_tot <- sum(day) #calculate the total for the day
      hourly_tot <- hourly_tot * 3600 #convert to hourly
      daily_tot <- append(daily_tot, hourly_tot, after = length(daily_tot)) #compile daily totals into a list
    }
    
    #put data in df
    precip_df <- cbind(precip_df, unlist(daily_tot)) #add total to df
    colnames(precip_df) <- c("precip_tot") #rename column
    return(precip_df)
  }
  
  
  #function to calculate sw data
  
  sw_df <- data.frame(row.names = day_num)
  
  calc_sw <- function(){
    
    #group data by day
    day_list <- list()
    d = 1 #set counter
    for (day in day_num){
      day_name <- paste0("Day", d ) #create day name
      day_name <- list(assign(day_name, nc_swdown[day_seq[d]:day_seq4[d]])) #assign data for day to day name
      day_list <- append(day_list, day_name, after = length(day_list)) #create list of day lists
      d = d + 1
    }
    
    #calculate summary stats for each day
    daily_mean <- list() 
    daily_sun <- list()
    for (day in day_list){
      hourly_mean <- mean(day) #calculate the mean for the day
      daily_mean <- append(daily_mean, hourly_mean, after = length(daily_mean)) #compile all daily means into a list
      
      s = 0 #set counter
      for (hour in day){
        if (hour > 0){ #if hour had sun (swdown >0)
          s = s + 1 #count how many hours had sun
        }
      }
      daily_sun <- append(daily_sun, s, after = length(daily_sun)) #compile daily totals into a list
    }
    
    #put data in df
    sw_df <- cbind(sw_df, unlist(daily_mean)) #add mean to df
    sw_df <- cbind(sw_df, unlist(daily_sun)) #add hrs sun to df
    colnames(sw_df) <- c("swdown_mean", "hrs_sun") #rename columns
    return(sw_df)
  }
  
  
  #Use functions to calculate daily stats
  nc_tair <- ncvar_get(nc = nc_data, varid = "tair") #Extract tair data
  tair_data <- calc_tair() #calculate tair mean, min, max
  sums <- cbind(tair_data, sums) #append tair data to sums df
  
  nc_precipf <- ncvar_get(nc = nc_data, varid = "precipf") #Extract precip data
  precip_data <- calc_precip() #calculate total precip
  sums <- cbind(sums, precip_data) #append precip data to sums df
  
  nc_swdown <- ncvar_get(nc = nc_data, varid = "swdown") #Extract shortwave radiation data
  sw_data <- calc_sw() #calculate sw mean and hrs of sunlight per day
  sums <- cbind(sums, sw_data) #append swdown data to sums df
  
  nc_lwdown <- ncvar_get(nc = nc_data, varid = "lwdown") #Extract longwave radiation
  lw_data <- calc_mean(nc_lwdown) #calculate lw mean
  sums <- cbind(sums, lw_data) #append lwdown mean to sums df
  
  nc_press <- ncvar_get(nc = nc_data, varid = "press") #Extract pressure data
  press_data <- calc_mean(nc_press) #calculate pressure mean
  sums <- cbind(sums, press_data) #append press mean to sums df
  
  nc_qair <- ncvar_get(nc = nc_data, varid = "qair") #Extract specific humidity data
  qair_data <- calc_mean(nc_qair) #calculate humidity mean
  sums <- cbind(sums, qair_data) #append qair mean to sums df
  
  nc_wind <- ncvar_get(nc = nc_data, varid = "wind") #Extract wind data
  wind_data <- calc_mean(nc_wind) #calculate wind mean
  sums <- cbind(sums, wind_data) #append wind mean to sums df
  
  return(sums)
}


#------------------------------------
# Monthly
#------------------------------------

monthly_sums <- function(day_df){ #function to calculate monthly summaries from daily summaries
  
  #create intervals for grouping days into months
  d_in_yr <- nrow(day_df) #count number of days in year
  months <- list("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec") #list of month names
  mo_start <- c(1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335) #month start days
  mo_end <- mo_start - 1 #month end days
  mo_end <- mo_end[2:length(mo_end)] #remove preceeding 0
  mo_end <- append(mo_end, mo_end[11] + 31, after = length(mo_end)) #add end of December
  
  #adjust for leap years
  if (d_in_yr == 366){ #if it's a leap year
    mo_start[3:length(mo_start)] <- mo_start[3:length(mo_start)] + 1 #add one to start (after feb) and end (after jan) days 
  }
  
  if (d_in_yr != 365 & d_in_yr != 366){ #if number of days does not = 365 or 366
    print("Irregular number of days in dataset") #print message
    break #stop the function. Function will not work correctly without all days
  }
  
  #group data by month
  month_list <- list() #create empty list to store data by month
  m = 1 #set counter
  for (month in months){
    month_name <- paste0("", m ) #create month name
    month_name <- list(assign(month_name, day_df[mo_start[m]:mo_end[m],])) #assign data for month to month name
    month_list <- append(month_list, month_name, after = length(month_list)) #create list of month lists
    m = m + 1
  }
  
  
  #calculate monthly summaries
  monthly_data <- data.frame(row.names = months) #create df to house monthly data
  tair_monthly_mean <- list() #create list for tair mean data
  tair_monthly_min <- list() #create list for tair min data
  tair_monthly_max <- list() #create list for tair max data
  precip_monthly_tot <- list() #create list for total precip data
  swdown_monthly_mean <- list() #create list for swdown mean data
  sun_monthly_mean <- list() #create list for hrs sun data
  lwdown_monthly_mean <- list() #create list for lwdown data
  press_monthly_mean <- list() #create list for pressure data
  qair_monthly_mean <- list() #create list for qair data
  wind_monthly_mean <- list() #create list for wind data
  
  for (month in month_list){ #for each month
    tair_mean <- mean(month$tair_mean) #calculate tair mean
    tair_monthly_mean <- append(tair_monthly_mean, tair_mean, after = length(tair_monthly_mean)) #add tair mean to list
    tair_min <- min(month$tair_min) #calculate tair min
    tair_monthly_min <- append(tair_monthly_min, tair_min, after = length(tair_monthly_min)) #add tair min to list
    tair_max <- max(month$tair_max) #calculate tair max
    tair_monthly_max <- append(tair_monthly_max, tair_max, after = length(tair_monthly_max)) #add tair max to list
    
    precip_tot <- sum(month$precip_tot) #calculate precip total
    precip_monthly_tot <- append(precip_monthly_tot, precip_tot, after = length(precip_monthly_tot)) #add precip total to list
    
    swdown_mean <- mean(month$swdown_mean) #calculate swdown mean
    swdown_monthly_mean <- append(swdown_monthly_mean, swdown_mean, after = length(swdown_monthly_mean)) #add swdown mean to list
    hrs_sun <- mean(month$hrs_sun) #calculate mean hrs sun
    sun_monthly_mean <- append(sun_monthly_mean, hrs_sun, after = length(sun_monthly_mean)) #add mean hrs sun to list
    
    lwdown_mean <- mean(month$lwdown_mean) #calculate lwdown mean
    lwdown_monthly_mean <- append(lwdown_monthly_mean, lwdown_mean, after = length(lwdown_monthly_mean)) #add lwdown mean to list
    
    press_mean <- mean(month$press_mean) #calculate press mean
    press_monthly_mean <- append(press_monthly_mean, press_mean, after = length(press_monthly_mean)) #add press mean to list
    
    qair_mean <- mean(month$qair_mean) #calculate qair mean
    qair_monthly_mean <- append(qair_monthly_mean, qair_mean, after = length(qair_monthly_mean)) #add qair mean to list
    
    wind_mean <- mean(month$wind_mean) #calculate wind mean
    wind_monthly_mean <- append(wind_monthly_mean, wind_mean, after = length(wind_monthly_mean)) #add wind mean to list
  }
  
  
  #add all data to df
  monthly_data <- cbind(monthly_data, unlist(tair_monthly_mean)) #add monthly mean to df
  monthly_data <- cbind(monthly_data, unlist(tair_monthly_min)) #add monthly min to df
  monthly_data <- cbind(monthly_data, unlist(tair_monthly_max)) #add monthly max to df
  monthly_data <- cbind(monthly_data, unlist(precip_monthly_tot)) #add total monthly precip to df
  monthly_data <- cbind(monthly_data, unlist(swdown_monthly_mean)) #add mean swdown to df
  monthly_data <- cbind(monthly_data, unlist(sun_monthly_mean)) #add mean hrs sun to df
  monthly_data <- cbind(monthly_data, unlist(lwdown_monthly_mean)) #add mean lwdown to df
  monthly_data <- cbind(monthly_data, unlist(press_monthly_mean)) #add mean pressure to df
  monthly_data <- cbind(monthly_data, unlist(qair_monthly_mean)) #add mean qair to df
  monthly_data <- cbind(monthly_data, unlist(wind_monthly_mean)) #add mean wind to df
  
  colnames(monthly_data) <- c("tair_mean", "tair_min", "tair_max", "precip_tot", "swdown_mean", "hrs_sun", "lwdown_mean", "press_mean", "qair_mean", "wind_mean") #change df column names
  
  return(monthly_data)
}
