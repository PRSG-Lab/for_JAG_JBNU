Place public NOAA NGS files in this directory.
This README file is ignored by the input scanner.

For each project, download both from the official Leveling Projects Page:
  1) Download Observations (.geojson)
  2) Download Bench Marks (.geojson)

Suggested local names:
  L20346_observations.geojson
  L20346_benchmarks.geojson

Multiple connected projects are normally required to obtain three candidate routes plus
an edge-independent reference route between the same terminal marks.

The Full workflow refuses to run without public files. Quick mode uses the bundled
fixture only when no public files are present and labels the run OFFLINE_FIXTURE.
