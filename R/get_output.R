#' Get output data for each model
#'@description
#' Get output data for each model
#'
#' @name get_output
#' @param config_file filepath; To LER config yaml file. Only used if model = 'GOTM'
#' @param model character; Model for which scaling parameters will be applied. Options include
#'    c('GOTM', 'GLM', 'Simstrat', 'FLake')
#' @param vars vector; variables to extract from FLake output. Currently just temp and ice
#' @param obs_depths vector; Observation depths. Defaults to NULL
#' @param folder filepath; to folder which contains the model folders generated by export_config().
#'    Defaults to '.'
#' @param out_time vector; of output time values to subset data by.
#' @param out_hour numeric; hour of output time values to subset data. Only used for FLake if model
#'    time step is 86400s.
#' @return dataframe or list of output variables
#' @importFrom reshape2 dcast
#' @importFrom gotmtools get_vari setmodDepths
#' @importFrom glmtools get_ice get_var
#' @export
get_output <- function(config_file, model, vars, obs_depths = NULL, folder = ".", out_time,
                       out_hour){

##--------------------------- FLake -----------------------------------------
  if("FLake" %in% model) {

    # Extract output
    fold <- file.path(folder, "FLake")
    nml_file <- file.path(folder, get_yaml_value(config_file, "config_files", "FLake"))

    mean_depth <- suppressWarnings(get_nml_value(arg_name = "depth_w_lk", nml_file = nml_file))
    out_depths <- get_yaml_value(config_file, "output", "depths")
    depths <- seq(0, mean_depth, by = out_depths)

    # Add in obs depths which are not in depths and less than mean depth
    add_deps <- obs_depths[!(obs_depths %in% depths)]
    add_deps <- add_deps[which(add_deps < mean_depth)]
    depths <- c(add_deps, depths)
    depths <- depths[order(depths)]

    fla_out <- read_flake_out(output = file.path(folder, "FLake", "output", "output.dat"),
                              vars = vars, depths = depths, folder = fold, nml_file = nml_file,
                              out_time = out_time, out_hour = out_hour)

    return(fla_out)
  }

##--------------------------------- GLM ---------------------------------------
  
  if("GLM" %in% model){
    # Extract output
    glm_out <- list()
    if("temp" %in% vars){

      # Add in obs depths which are not in depths and less than mean depth
      depth <- suppressWarnings(get_nml_value(nml_file = file.path(folder,
                                                                   get_yaml_value(config_file,
                                                                                  "config_files",
                                                                                  "GLM")),
                                              arg_name = "lake_depth"))
      depths <- seq(0, depth, by = get_yaml_value(config_file, "output", "depths"))
      add_deps <- obs_depths[!(obs_depths %in% depths)]
      depths <- c(add_deps, depths)
      depths <- depths[order(depths)]

      glm_out[[length(glm_out) + 1]] <- glmtools::get_var(file = file.path(folder, "GLM", "output",
                                                                 "output.nc"),
                                                var_name = "temp", reference = "surface",
                                                z_out = depths)
      colnames(glm_out[[length(glm_out)]]) <- c("datetime", paste("wtr_", depths, sep = ""))
      names(glm_out)[length(glm_out)] <- "temp"
    }

    if("ice_height" %in% vars){
      glm_out[[length(glm_out) + 1]] <- get_ice(file = file.path(folder, "GLM", "output",
                                                                 "output.nc"))
      colnames(glm_out[[length(glm_out)]]) <- c("datetime", "ice_height")
      names(glm_out)[length(glm_out)] <- "ice_height"

    }
    
    if("dens" %in% vars){
      
      # Add in obs depths which are not in depths and less than mean depth
      depth <- suppressWarnings(get_nml_value(nml_file = file.path(folder,
                                                                   get_yaml_value(config_file,
                                                                                  "config_files",
                                                                                  "GLM")),
                                              arg_name = "lake_depth"))
      depths <- seq(0, depth, by = get_yaml_value(config_file, "output", "depths"))
      add_deps <- obs_depths[!(obs_depths %in% depths)]
      depths <- c(add_deps, depths)
      depths <- depths[order(depths)]
      
      glm_out[[length(glm_out) + 1]] <- glmtools::get_var(file = file.path(folder, "GLM", "output",
                                                                           "output.nc"),
                                                          var_name = "rho", reference = "surface",
                                                          z_out = depths)
      colnames(glm_out[[length(glm_out)]]) <- c("datetime", paste("dens_", depths, sep = ""))
      names(glm_out)[length(glm_out)] <- "dens"
    }
    
    if("salt" %in% vars){
      
      # Add in obs depths which are not in depths and less than mean depth
      depth <- suppressWarnings(get_nml_value(nml_file = file.path(folder,
                                                                   get_yaml_value(config_file,
                                                                                  "config_files",
                                                                                  "GLM")),
                                              arg_name = "lake_depth"))
      depths <- seq(0, depth, by = get_yaml_value(config_file, "output", "depths"))
      add_deps <- obs_depths[!(obs_depths %in% depths)]
      depths <- c(add_deps, depths)
      depths <- depths[order(depths)]
      
      glm_out[[length(glm_out) + 1]] <- glmtools::get_var(file = file.path(folder, "GLM", "output",
                                                                           "output.nc"),
                                                          var_name = "salt", reference = "surface",
                                                          z_out = depths)
      colnames(glm_out[[length(glm_out)]]) <- c("datetime", paste("sal_", depths, sep = ""))
      names(glm_out)[length(glm_out)] <- "salt"
    }

    # If only one variable return a dataframe
    if(length(glm_out) == 1){
      glm_out <- glm_out[1]
    }

    return(glm_out)

  }

##--------------------------- GOTM ------------------------------------------------
  
  if("GOTM" %in% model){

    got_out <- list()
    if("temp" %in% vars){

      temp <- get_vari(ncdf = file.path(folder, "GOTM", "output", "output.nc"), var = "temp",
                       print = FALSE)
      z <- get_vari(ncdf = file.path(folder, "GOTM", "output", "output.nc"), var = "z",
                    print = FALSE)

      # Add in obs depths which are not in depths and less than mean depth
      depths <- seq(0, min(z[1, -1]), by = -1 * get_yaml_value(config_file, "output", "depths"))
      if(is.null(obs_depths)) {
        obs_dep_neg <- NULL
      } else {
        obs_dep_neg <- -obs_depths
      }
      add_deps <- obs_dep_neg[!(obs_dep_neg %in% depths)]
      depths <- c(add_deps, depths)
      depths <- depths[order(-depths)]

      message("Interpolating GOTM temp to include obs depths... ",
              paste0("[", Sys.time(), "]"))
      got <- setmodDepths(temp, z, depths = depths, print = T)
      message("Finished interpolating! ",
              paste0("[", Sys.time(), "]"))

      got <- dcast(got, date ~ depths)
      got <- got[, c(1, (ncol(got):2))]
      str_depths <- abs(as.numeric(colnames(got)[2:ncol(got)]))
      colnames(got) <- c("datetime", paste("wtr_", str_depths, sep = ""))

      got_out[[length(got_out) + 1]] <- got
      names(got_out)[length(got_out)] <- "temp"

    }

    if("ice_height" %in% vars){
      ice_height <- get_vari(ncdf = file.path(folder, "GOTM", "output", "output.nc"), var = "Hice",
                             print = FALSE)
      # ice_frazil <- get_vari(ncdf = file.path(folder, "GOTM", "output", "output.nc"),
      #                        var = "Hfrazil", print = FALSE)
      # ice_height[,2] <- ice_height[,2] + ice_frazil[,2]
      colnames(ice_height) <- c("datetime", "ice_height")

      got_out[[length(got_out) + 1]] <- ice_height
      names(got_out)[length(got_out)] <- "ice_height"

    }
    
    if("dens" %in% vars){
      
      density <- get_vari(ncdf = file.path(folder, "GOTM", "output", "output.nc"), var = "rho",
                       print = FALSE)
      z <- get_vari(ncdf = file.path(folder, "GOTM", "output", "output.nc"), var = "z",
                    print = FALSE)
      
      # Add in obs depths which are not in depths and less than mean depth
      depths <- seq(0, min(z[1, -1]), by = -1 * get_yaml_value(config_file, "output", "depths"))
      if(is.null(obs_depths)) {
        obs_dep_neg <- NULL
      } else {
        obs_dep_neg <- -obs_depths
      }
      add_deps <- obs_dep_neg[!(obs_dep_neg %in% depths)]
      depths <- c(add_deps, depths)
      depths <- depths[order(-depths)]
      
      message("Interpolating GOTM temp to include obs depths... ",
              paste0("[", Sys.time(), "]"))
      got <- setmodDepths(density, z, depths = depths, print = T)
      message("Finished interpolating! ",
              paste0("[", Sys.time(), "]"))
      
      got <- dcast(got, date ~ depths)
      got <- got[, c(1, (ncol(got):2))]
      str_depths <- abs(as.numeric(colnames(got)[2:ncol(got)]))
      colnames(got) <- c("datetime", paste("dens_", str_depths, sep = ""))
      
      got_out[[length(got_out) + 1]] <- got
      names(got_out)[length(got_out)] <- "dens"
      
    }
    
    if("salt" %in% vars){
      
      salinity <- get_vari(ncdf = file.path(folder, "GOTM", "output", "output.nc"), var = "salt",
                          print = FALSE)
      z <- get_vari(ncdf = file.path(folder, "GOTM", "output", "output.nc"), var = "z",
                    print = FALSE)
      
      # Add in obs depths which are not in depths and less than mean depth
      depths <- seq(0, min(z[1, -1]), by = -1 * get_yaml_value(config_file, "output", "depths"))
      if(is.null(obs_depths)) {
        obs_dep_neg <- NULL
      } else {
        obs_dep_neg <- -obs_depths
      }
      add_deps <- obs_dep_neg[!(obs_dep_neg %in% depths)]
      depths <- c(add_deps, depths)
      depths <- depths[order(-depths)]
      
      message("Interpolating GOTM temp to include obs depths... ",
              paste0("[", Sys.time(), "]"))
      got <- setmodDepths(salinity, z, depths = depths, print = T)
      message("Finished interpolating! ",
              paste0("[", Sys.time(), "]"))
      
      got <- dcast(got, date ~ depths)
      got <- got[, c(1, (ncol(got):2))]
      str_depths <- abs(as.numeric(colnames(got)[2:ncol(got)]))
      colnames(got) <- c("datetime", paste("sal_", str_depths, sep = ""))
      
      got_out[[length(got_out) + 1]] <- got
      names(got_out)[length(got_out)] <- "salt"
      
    }

    return(got_out)
  }
  
##------------------- Simstrat ----------------------------------------------------

  if("Simstrat" %in% model){

    ### Convert decimal days to yyyy-mm-dd HH:MM:SS
    par_file <- file.path(folder, get_yaml_value(config_file, "config_files", "Simstrat"))
    timestep <- get_json_value(file.path(folder, par_file), "Simulation", "Timestep s")
    reference_year <- get_json_value(file.path(folder, par_file), "Simulation", "Start year")

    sim_out <- list()

    if("temp" %in% vars){

      temp <- read.table(file.path(folder, "Simstrat", "output", "T_out.dat"), header = TRUE,
                         sep = ",", check.names = FALSE)
      temp[, 1] <- as.POSIXct(temp[, 1] * 3600 * 24, origin = paste0(reference_year, "-01-01"))
      # In case sub-hourly time steps are used, rounding might be necessary
      temp[, 1] <- round_date(temp[, 1], unit = seconds_to_period(timestep))

      # First column datetime, then depth from shallow to deep
      temp <- temp[, c(1, ncol(temp):2)]

      # Remove columns without any value
      temp <- temp[, colSums(is.na(temp)) < nrow(temp)]

      # Add in obs depths which are not in depths and less than mean depth
      mod_depths <- as.numeric(colnames(temp)[-1])
      if(is.null(obs_depths)){
        obs_dep_neg <- NULL
      }else{
        obs_dep_neg <- -obs_depths
      }
      add_deps <- obs_dep_neg[!(obs_dep_neg %in% mod_depths)]
      depths <- c(add_deps, mod_depths)
      depths <- depths[order(-depths)]

      if(length(depths) != (ncol(temp) - 1)){
        message("Interpolating Simstrat temp to include obs depths... ",
                paste0("[", Sys.time(), "]"))


        # Create empty matrix and interpolate to new depths
        wat_mat <- matrix(NA, nrow = nrow(temp), ncol = length(depths))
        for(i in seq_len(nrow(temp))) {
          y <- as.vector(unlist(temp[i, -1]))
          wat_mat[i, ] <- approx(mod_depths, y, depths, rule = 2)$y
        }
        message("Finished interpolating! ",
                paste0("[", Sys.time(), "]"))
        df <- data.frame(wat_mat)
        df$datetime <- temp[, 1]
        df <- df[, c(ncol(df), 1:(ncol(df) - 1))]
        colnames(df) <- c("datetime", paste0("wtr_", abs(depths)))
        temp <- df
      }else{
        # Set column headers
        str_depths <- abs(as.numeric(colnames(temp)[2:ncol(temp)]))
        colnames(temp) <- c("datetime", paste0("wtr_", str_depths))
      }

      sim_out[[length(sim_out) + 1]] <- temp
      names(sim_out)[length(sim_out)] <- "temp"

    }

    if("ice_height" %in% vars){
      ice_height <- read.table(file.path(folder, "Simstrat", "output", "TotalIceH_out.dat"),
                               header = TRUE, sep = ",", check.names = FALSE)
      ice_height[, 1] <- as.POSIXct(ice_height[, 1] * 3600 * 24,
                                   origin = paste0(reference_year, "-01-01"))
      # In case sub-hourly time steps are used, rounding might be necessary
      ice_height[, 1] <- round_date(ice_height[, 1], unit = seconds_to_period(timestep))
      colnames(ice_height) <- c("datetime", "ice_height")

      sim_out[[length(sim_out) + 1]] <- ice_height
      names(sim_out)[length(sim_out)] <- "ice_height"
    }
    
    
    
    if("dens" %in% vars){
      
      temp <- read.table(file.path(folder, "Simstrat", "output", "T_out.dat"), header = TRUE,
                         sep = ",", check.names = FALSE)
      temp[, 1] <- as.POSIXct(temp[, 1] * 3600 * 24, origin = paste0(reference_year, "-01-01"))
      # In case sub-hourly time steps are used, rounding might be necessary
      temp[, 1] <- round_date(temp[, 1], unit = seconds_to_period(timestep))
      
      # First column datetime, then depth from shallow to deep
      temp <- temp[, c(1, ncol(temp):2)]
      
      # Remove columns without any value
      temp <- temp[, colSums(is.na(temp)) < nrow(temp)]
      
      # Add in obs depths which are not in depths and less than mean depth
      mod_depths <- as.numeric(colnames(temp)[-1])
      if(is.null(obs_depths)){
        obs_dep_neg <- NULL
      }else{
        obs_dep_neg <- -obs_depths
      }
      add_deps <- obs_dep_neg[!(obs_dep_neg %in% mod_depths)]
      depths <- c(add_deps, mod_depths)
      depths <- depths[order(-depths)]
      
      if(length(depths) != (ncol(temp) - 1)){
        message("Interpolating Simstrat temp to include obs depths... ",
                paste0("[", Sys.time(), "]"))
        
        
        # Create empty matrix and interpolate to new depths
        wat_mat <- matrix(NA, nrow = nrow(temp), ncol = length(depths))
        for(i in seq_len(nrow(temp))) {
          y <- as.vector(unlist(temp[i, -1]))
          wat_mat[i, ] <- approx(mod_depths, y, depths, rule = 2)$y
        }
        message("Finished interpolating! ",
                paste0("[", Sys.time(), "]"))
        df <- data.frame(wat_mat)
        df$datetime <- temp[, 1]
        df <- df[, c(ncol(df), 1:(ncol(df) - 1))]
        colnames(df) <- c("datetime", paste0("wtr_", abs(depths)))
        temp <- df
      }else{
        # Set column headers
        str_depths <- abs(as.numeric(colnames(temp)[2:ncol(temp)]))
        colnames(temp) <- c("datetime", paste0("wtr_", str_depths))
      }
      
      
      
      sal <- read.table(file.path(folder, "Simstrat", "output", "S_out.dat"), header = TRUE,
                        sep = ",", check.names = FALSE)
      sal[, 1] <- as.POSIXct(sal[, 1] * 3600 * 24, origin = paste0(reference_year, "-01-01"))
      # In case sub-hourly time steps are used, rounding might be necessary
      sal[, 1] <- round_date(sal[, 1], unit = seconds_to_period(timestep))
      
      # First column datetime, then depth from shallow to deep
      sal <- sal[, c(1, ncol(sal):2)]
      
      # Remove columns without any value
      sal <- sal[, colSums(is.na(sal)) < nrow(sal)]
      
      # Add in obs depths which are not in depths and less than mean depth
      mod_depths <- as.numeric(colnames(sal)[-1])
      if(is.null(obs_depths)){
        obs_dep_neg <- NULL
      }else{
        obs_dep_neg <- -obs_depths
      }
      add_deps <- obs_dep_neg[!(obs_dep_neg %in% mod_depths)]
      depths <- c(add_deps, mod_depths)
      depths <- depths[order(-depths)]
      
      if(length(depths) != (ncol(sal) - 1)){
        message("Interpolating Simstrat sal to include obs depths... ",
                paste0("[", Sys.time(), "]"))
        
        
        # Create empty matrix and interpolate to new depths
        wat_mat <- matrix(NA, nrow = nrow(sal), ncol = length(depths))
        for(i in seq_len(nrow(sal))) {
          y <- as.vector(unlist(sal[i, -1]))
          wat_mat[i, ] <- approx(mod_depths, y, depths, rule = 2)$y
        }
        message("Finished interpolating! ",
                paste0("[", Sys.time(), "]"))
        df <- data.frame(wat_mat)
        df$datetime <- sal[, 1]
        df <- df[, c(ncol(df), 1:(ncol(df) - 1))]
        colnames(df) <- c("datetime", paste0("wtr_", abs(depths)))
        sal <- df
        remb_col = 1
      }else{
        # Set column headers
        str_depths <- abs(as.numeric(colnames(sal)[2:ncol(sal)]))
        colnames(sal) <- c("datetime", paste0("wtr_", str_depths))
        remb_col = 0
      }
      
      dens = sal
      # calculations from FRANK J, MILLERO and ALAIN POISSON (1980): International one-atmosphere equation of state of seawater. 
      dens[, -c(1)] = 999.842594 + (6.793952 * 10^-2 * temp[, -c(1)]) - (9.095290 * 10^-3 * temp[, -c(1)]^2) +
      (1.001685 * 10^-4 * temp[, -c(1)]^3) - (1.120083 * 10^-6 * temp[, -c(1)]^4) + (6.536336 * 10^-9 * temp[, -c(1)]^5) +
        (8.24493 * 10^-1 -4.0899 * 10^-3 * temp[, -c(1)]+ 7.6438 * 10^-5 * temp[, -c(1)]^2 - 8.2467 * 10^-7 * temp[, -c(1)]^3 + 5.3875 * 10^-9* temp[, -c(1)]^4) * sal[,-c(1)]+
        (-5.72466 *  10^-3 + 1.0227 * 10^-4 * temp[, -c(1)] -1.6546 * 10^-6 * temp[, -c(1)]^2) * sal[,-c(1)]^(3/2) +
        (4.8314*  10^-4 ) * sal[,-c(1)]
      
      if(remb_col == 1){
        colnames(dens) <- c("datetime", paste0("dens_", abs(depths)))
      } else {
        str_depths <- abs(as.numeric(colnames(sal)[2:ncol(sal)]))
        colnames(dens) <- c("datetime", paste0("dens__", str_depths))
      }
      
      sim_out[[length(sim_out) + 1]] <- dens
      names(sim_out)[length(sim_out)] <- "dens"
      
    }
    
    if("salt" %in% vars){
      
      temp <- read.table(file.path(folder, "Simstrat", "output", "S_out.dat"), header = TRUE,
                         sep = ",", check.names = FALSE)
      temp[, 1] <- as.POSIXct(temp[, 1] * 3600 * 24, origin = paste0(reference_year, "-01-01"))
      # In case sub-hourly time steps are used, rounding might be necessary
      temp[, 1] <- round_date(temp[, 1], unit = seconds_to_period(timestep))
      
      # First column datetime, then depth from shallow to deep
      temp <- temp[, c(1, ncol(temp):2)]
      
      # Remove columns without any value
      temp <- temp[, colSums(is.na(temp)) < nrow(temp)]
      
      # Add in obs depths which are not in depths and less than mean depth
      mod_depths <- as.numeric(colnames(temp)[-1])
      if(is.null(obs_depths)){
        obs_dep_neg <- NULL
      }else{
        obs_dep_neg <- -obs_depths
      }
      add_deps <- obs_dep_neg[!(obs_dep_neg %in% mod_depths)]
      depths <- c(add_deps, mod_depths)
      depths <- depths[order(-depths)]
      
      if(length(depths) != (ncol(temp) - 1)){
        message("Interpolating Simstrat temp to include obs depths... ",
                paste0("[", Sys.time(), "]"))
        
        
        # Create empty matrix and interpolate to new depths
        wat_mat <- matrix(NA, nrow = nrow(temp), ncol = length(depths))
        for(i in seq_len(nrow(temp))) {
          y <- as.vector(unlist(temp[i, -1]))
          wat_mat[i, ] <- approx(mod_depths, y, depths, rule = 2)$y
        }
        message("Finished interpolating! ",
                paste0("[", Sys.time(), "]"))
        df <- data.frame(wat_mat)
        df$datetime <- temp[, 1]
        df <- df[, c(ncol(df), 1:(ncol(df) - 1))]
        colnames(df) <- c("datetime", paste0("sal_", abs(depths)))
        temp <- df
      }else{
        # Set column headers
        str_depths <- abs(as.numeric(colnames(temp)[2:ncol(temp)]))
        colnames(temp) <- c("datetime", paste0("sal_", str_depths))
      }
      
      sim_out[[length(sim_out) + 1]] <- temp
      names(sim_out)[length(sim_out)] <- "salt"
      
    }
    

    return(sim_out)

  }

##--------------------- MyLake ------------------------------------------------
  
  if("MyLake" %in% model){

    mylake_out <- list()

    load(file.path(folder, "MyLake", "output", "output.RData"))

    if("temp" %in% vars){

      output_depths <- get_yaml_value(config_file, "output", "depths")
      #max_depth <- get_yaml_value(config_file, "location", "depth")

      init_depths <- res$zz
      seq_depths <- seq(0, max(init_depths), by = output_depths)
      add_deps <- obs_depths[!(obs_depths %in% seq_depths)]
      depths <- c(add_deps, seq_depths)
      depths <- depths[order(depths)]

      temps <- res$Tzt
      dates <- as.POSIXct((as.numeric(res$tt) - 719529) * 86400, origin = "1970-01-01")

      temp_interp <- matrix(NA, nrow = length(dates),
                            ncol = length(depths))

      for(i in seq_len(ncol(temps))) {
        temp_interp[i, ] <- approx(x = init_depths,
                                  y = temps[, i],
                                  xout = depths,
                                  yleft = dplyr::first(na.omit(temps)),
                                  yright = dplyr::last(na.omit(temps)))$y
      }

      mylake_out[[length(mylake_out) + 1]] <- data.frame("datetime" = dates, temp_interp)
      colnames(mylake_out[[length(mylake_out)]]) <- c("datetime",
                                                      paste("wtr_", depths, sep = ""))

      names(mylake_out)[length(mylake_out)] <- "temp"

    }

    if("ice_height" %in% vars){

      mylake_out[[length(mylake_out) + 1]] <-
        data.frame("datetime" = as.POSIXct((as.numeric(res$tt) - 719529) * 86400,
                                           origin = "1970-01-01"), "ice_height" = res$His[1, ])
      names(mylake_out)[length(mylake_out)] <- "ice_height"

    }
    
    if("dens" %in% vars){
      
      output_depths <- get_yaml_value(config_file, "output", "depths")
      #max_depth <- get_yaml_value(config_file, "location", "depth")
      
      init_depths <- res$zz
      seq_depths <- seq(0, max(init_depths), by = output_depths)
      add_deps <- obs_depths[!(obs_depths %in% seq_depths)]
      depths <- c(add_deps, seq_depths)
      depths <- depths[order(depths)]
      
      temps <- res$Tzt
      dates <- as.POSIXct((as.numeric(res$tt) - 719529) * 86400, origin = "1970-01-01")
      
      temp_interp <- matrix(NA, nrow = length(dates),
                            ncol = length(depths))
      
      for(i in seq_len(ncol(temps))) {
        temp_interp[i, ] <- approx(x = init_depths,
                                   y = temps[, i],
                                   xout = depths,
                                   yleft = dplyr::first(na.omit(temps)),
                                   yright = dplyr::last(na.omit(temps)))$y
      }
      dens_interp <- 999.842594 + (6.793952 * 10^-2 * temp_interp) - (9.095290 * 10^-3 * temp_interp^2) +
        (1.001685 * 10^-4 * temp_interp^3) - (1.120083 * 10^-6 * temp_interp^4) + (6.536336 * 10^-9 * temp_interp^5) 
      
      mylake_out[[length(mylake_out) + 1]] <- data.frame("datetime" = dates, dens_interp)
      colnames(mylake_out[[length(mylake_out)]]) <- c("datetime",
                                                      paste("dens_", depths, sep = ""))
      
      names(mylake_out)[length(mylake_out)] <- "dens"
      
    }
    
    if("salt" %in% vars){
      message('MyLake does not support simulation of salinity dynamics.')
      
      output_depths <- get_yaml_value(config_file, "output", "depths")
      #max_depth <- get_yaml_value(config_file, "location", "depth")
      
      init_depths <- res$zz
      seq_depths <- seq(0, max(init_depths), by = output_depths)
      add_deps <- obs_depths[!(obs_depths %in% seq_depths)]
      depths <- c(add_deps, seq_depths)
      depths <- depths[order(depths)]
      
      temps <- res$Tzt
      dates <- as.POSIXct((as.numeric(res$tt) - 719529) * 86400, origin = "1970-01-01")
      
      temp_interp <- matrix(NA, nrow = length(dates),
                            ncol = length(depths))
      
      for(i in seq_len(ncol(temps))) {
        temp_interp[i, ] <- approx(x = init_depths,
                                   y = temps[, i],
                                   xout = depths,
                                   yleft = dplyr::first(na.omit(temps)),
                                   yright = dplyr::last(na.omit(temps)))$y
      }
      salt_interp <- temp_interp * NaN
      
      mylake_out[[length(mylake_out) + 1]] <- data.frame("datetime" = dates, salt_interp)
      colnames(mylake_out[[length(mylake_out)]]) <- c("datetime",
                                                      paste("salt_", depths, sep = ""))
      
      names(mylake_out)[length(mylake_out)] <- "salt"
      
    }

    # If only one variable return a dataframe
    if(length(mylake_out) == 1){
      mylake_out <- mylake_out[1]
    }

    return(mylake_out)
  }
}
