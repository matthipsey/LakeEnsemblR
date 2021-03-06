#' Inputs value into the MyLake config file
#'
#' Inputs value into the MyLake config file by locating the label and key within the file.
#' @param file filepath; to R object (loaded Rdata file)
#' @param label string; which corresponds to section where the key is located
#' @param key string; name of key in which to extract the value
#' @param value string; name of key in which to extract the value
#' @param out_file filepath; to write the output config file (optional); defaults to overwriting file if not specified
#' @export

input_mylakeconfig <- function(file, label, key, value, out_file = NULL){
  
  load(file)
  # filename is hard-coded: mylake_config
  
  if (is.null(out_file)) {
    out_file <- file
  }
  
  if(is.null(label)){
    # Check if label occurs in the list
    if(is.null(mylake_config[[key]])){
      stop(key, " not found in mylake_config")
    }
    old_val <- mylake_config[[key]]
    mylake_config[[key]] <- value
  }else{
    label_names <- paste0(label, ".names")
    
    # Check if label occurs in the list
    if(is.null(mylake_config[[label_names]])){
      stop(label_names, " not found in mylake_config")
    }
    # Check if the key occurs in the label
    if(!(key %in% unlist(mylake_config[[label_names]]))){
      stop(key, " not found in ", label_names, " in mylake_config")
    }
    
    ind_key <- which(unlist(mylake_config[[label_names]]) == key)
    
    old_val <- mylake_config[[label]][ind_key]
    mylake_config[[label]][ind_key] <- value
  }
  
  # Save the configuration file as out_file
  save(mylake_config, file = out_file)
  
  message("Replaced ", label, " ", key, " ",
          old_val, " with ", value)
  
}
