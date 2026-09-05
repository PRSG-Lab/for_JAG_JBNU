# Public data source

The workflow targets the NOAA National Geodetic Survey (NGS) Leveling Projects Page. That official service provides project-level observed height differences and benchmark information and offers observation, benchmark, metadata, and R6 downloads. The website states that the downloadable files are supplied in GeoJSON, JSON, or R6 format.

Official page:

https://geodesy.noaa.gov/datasheets/leveling-projects/index.html

The package does not hard-code undocumented dynamic download endpoints. Use `RUN_OPEN_NGS_PROJECT_PAGES` and the official download buttons, then place the observation and benchmark GeoJSON files in `data/raw/ngs/`.

The selected projects in `data/config/ngs_projects.csv` are starting points, not a guarantee that four disjoint routes will be found. Multiple intersecting projects may be required. Every selected source file is hashed and recorded in each run.
