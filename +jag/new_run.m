function runDir = new_run(outputDir,kind)
%NEW_RUN Create a unique run folder without overwriting earlier outputs.
if ~isfolder(outputDir), mkdir(outputDir); end
[~,suffix]=fileparts(tempname(outputDir));
runDir=fullfile(outputDir,[kind '_' datestr(now,'yyyymmdd_HHMMSS_FFF') '_' suffix]); %#ok<DATST,TNOW1>
[ok,msg]=mkdir(runDir);
if ~ok,error('JAG:CreateRun','Cannot create run directory: %s',msg);end
end
