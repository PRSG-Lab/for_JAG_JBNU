function [trainCases,testCases,splitReport] = split_public_cases(cases,cfg,runDir,logFile)
%SPLIT_PUBLIC_CASES Split cases before calibration and prevent edge leakage.
rng(cfg.randomSeed+17,'twister');n=numel(cases);ord=randperm(n);
targetTest=max(cfg.split.minimumTestCases,round((1-cfg.split.trainingFraction)*n));
testIdx=[];usedTest=[];
for ii=ord
    if numel(testIdx)>=targetTest,break;end
    rows=cases(ii).AllSourceRows(:);
    if isempty(intersect(rows,usedTest)),testIdx(end+1)=ii;usedTest=union(usedTest,rows);end %#ok<AGROW>
end
trainIdx=[];usedTrain=[];
for ii=ord
    if ismember(ii,testIdx),continue;end
    rows=cases(ii).AllSourceRows(:);
    if cfg.split.preventTrainTestEdgeSharing&&~isempty(intersect(rows,usedTest)),continue;end
    if isempty(intersect(rows,usedTrain)),trainIdx(end+1)=ii;usedTrain=union(usedTrain,rows);end %#ok<AGROW>
end
if numel(trainIdx)<cfg.split.minimumTrainingCases||numel(testIdx)<cfg.split.minimumTestCases
    error('split_public_cases:InsufficientIndependentCases', ...
        'Independent split yielded %d training and %d test cases.',numel(trainIdx),numel(testIdx));
end
trainCases=cases(trainIdx);testCases=cases(testIdx);trainRows=collect_case_rows(trainCases);testRows=collect_case_rows(testCases);
shared=intersect(trainRows,testRows);if ~isempty(shared),error('split_public_cases:Leakage','Training and test cases share %d physical edges.',numel(shared));end
splitReport=struct('AllCases',n,'TrainingCases',numel(trainCases),'TestCases',numel(testCases), ...
    'SharedEdges',numel(shared),'Seed',cfg.randomSeed+17);
outDir=fullfile(runDir,'02_cases');[ts,~]=local_case_tables(trainCases);[vs,~]=local_case_tables(testCases);
writetable(ts,fullfile(outDir,'training_cases.csv'));writetable(vs,fullfile(outDir,'test_cases.csv'));
write_json_file(fullfile(outDir,'split_report.json'),splitReport);
log_message(logFile,'Independent split: training=%d, test=%d, shared physical edges=%d.',numel(trainCases),numel(testCases),numel(shared));
end
function rows=collect_case_rows(cases)
rows=[];for i=1:numel(cases),rows=[rows;cases(i).AllSourceRows(:)];end;rows=unique(rows); %#ok<AGROW>
end
function [S,R]=local_case_tables(cases)
n=numel(cases);CaseID=strings(n,1);TerminalA=strings(n,1);TerminalB=strings(n,1);Disjointness=strings(n,1);AllEdgeCount=zeros(n,1);R=table();
for i=1:n,CaseID(i)=cases(i).CaseID;TerminalA(i)=cases(i).TerminalA;TerminalB(i)=cases(i).TerminalB;Disjointness(i)=cases(i).Disjointness;AllEdgeCount(i)=numel(cases(i).AllSourceRows);end
S=table(CaseID,TerminalA,TerminalB,Disjointness,AllEdgeCount);
end
