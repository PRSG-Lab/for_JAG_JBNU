function RUN_OPEN_NGS_PROJECT_PAGES()
%RUN_OPEN_NGS_PROJECT_PAGES Open official NOAA NGS project pages in a browser.
rootDir=fileparts(mfilename('fullpath'));addpath(fullfile(rootDir,'matlab'));open_ngs_project_pages(rootDir);
end
