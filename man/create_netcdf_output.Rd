% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create_netcdf_output.R
\name{create_netcdf_output}
\alias{create_netcdf_output}
\title{Create netcdf output from model-specific model runs}
\usage{
create_netcdf_output(
  output_lists,
  folder = ".",
  model,
  out_time,
  longitude = 0,
  latitude = 0,
  compression = 4,
  members = 25,
  out_file = "ensemble_output.nc"
)
}
\arguments{
\item{output_lists}{list; list containing lists of output (e.g. temperature, ice_height)}

\item{folder}{filepath; to folder which contains the model folders generated by export_config()}

\item{model}{vector; model to export driving data. Options include c("GOTM", "GLM", "Simstrat",
"FLake", "MyLake")}

\item{out_time}{data frame; data frame with column ("datetime"),
describing at what times output should be generated}

\item{longitude}{numeric; longitude of lake to be added to netCDF file}

\item{latitude}{numeric; latitude of lake to be added to netCDF file}

\item{compression}{integer;between 1 (least compression) and 9 (most compression),
this enables compression for the variable as it is written to the file.
Turning compression on forces the created file to be in netcdf version 4 format.}

\item{members}{integer; number of members to have in the netCDF file.}

\item{out_file}{filepath; to save netCDF file defaults to "ensemble_output.nc"}
}
\description{
Create a netcdf from lists of output, generated by run_ensemble
}
\keyword{internal}
