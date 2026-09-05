function open_ngs_project_pages(rootDir)
%OPEN_NGS_PROJECT_PAGES Open official NGS project pages from the manifest.
if nargin<1,rootDir=fileparts(fileparts(mfilename('fullpath')));end
f=fullfile(rootDir,'data','config','ngs_projects.csv');T=readtable(f,'TextType','string');
fprintf('Opening %d NOAA NGS project pages in the system browser.\n',height(T));
for i=1:height(T)
    fprintf('%s  %s\n',T.ProjectID(i),T.PageURL(i));
    try,web(char(T.PageURL(i)),'-browser');catch ME,warning('%s',ME.message);end
    pause(0.25);
end
end
