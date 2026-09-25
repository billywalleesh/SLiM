#!/usr/bin/env python3
"""
GRIB -> two NetCDF grids for the GMT climate figure.

    python prep_climate_grids.py

Reads  data/raw/2m_temp_1940-2026.grib   (ERA5 daily 2 m temperature)
Writes data/processed/t2m_norm.nc        mean annual temperature, 1991-2020
       data/processed/t2m_change.nc      mean(1996-2025) - mean(1940-1969)

Needs: pip install xarray cfgrib eccodes netcdf4
(terra in R can also read this GRIB - see 1_load_visualize_environmental_data.R -
 but the time handling in cfgrib is what was tested here.)
"""
import os, pathlib, xarray as xr

ROOT = pathlib.Path(os.environ.get("MSC_WORKSPACE",
                                   pathlib.Path.home() / "msc_workspace"))
SLIM = ROOT / "SLiM"
SRC  = SLIM / "data" / "raw" / "2m_temp_1940-2026.grib"
OUT  = SLIM / "data" / "processed"
OUT.mkdir(parents=True, exist_ok=True)

NORM   = ("1991-01-01", "2020-12-31")   # WMO 30-year normal
EARLY  = ("1940-01-01", "1969-12-31")
LATE   = ("1996-01-01", "2025-12-31")

ds = xr.open_dataset(SRC, engine="cfgrib", backend_kwargs={"indexpath": ""})
t  = (ds.t2m - 273.15).rename({"latitude": "lat", "longitude": "lon"})

fields = {
    "t2m_norm":   t.sel(time=slice(*NORM)).mean("time"),
    "t2m_change": t.sel(time=slice(*LATE)).mean("time")
                  - t.sel(time=slice(*EARLY)).mean("time"),
}
for name, da in fields.items():
    da = da.sortby("lat").astype("float32")
    da.name = "z"; da.attrs["units"] = "degC"
    da.to_dataset().to_netcdf(OUT / f"{name}.nc")
    print(f"{name}: {float(da.min()):6.2f} to {float(da.max()):6.2f} degC"
          f"   -> {OUT / (name + '.nc')}")
