function [cases,caseSummary,routeDetails] = find_public_validation_cases(E,cfg,runDir,logFile)
%FIND_PUBLIC_VALIDATION_CASES Extract candidate routes and an independent reference route.
net=build_network(E);G=net.G;comps=conncomp(G);deg=degree(G);nodeNames=string(G.Nodes.Name);
pairIdx=zeros(0,2);
rng(cfg.randomSeed,'twister');
for c=unique(comps)
    eligible=find(comps(:)==c & deg(:)>=cfg.route.candidateNodeDegreeMin);
    if numel(eligible)<2,continue;end
    remaining=max(cfg.route.maximumCandidatePairs-size(pairIdx,1),0);if remaining==0,break;end
    pairIdx=[pairIdx;sample_pairs(eligible,remaining)]; %#ok<AGROW>
end
if isempty(pairIdx),error('find_public_validation_cases:NoTerminalPairs','No terminal pairs with adequate graph degree were found.');end
pairs=[nodeNames(pairIdx(:,1)),nodeNames(pairIdx(:,2))];
cases=struct('CaseID',{},'TerminalA',{},'TerminalB',{},'Disjointness',{},'Candidate',{},'Reference',{},'AllSourceRows',{},'ReferenceStretch',{});
for i=1:size(pairs,1)
    a=pairs(i,1);b=pairs(i,2);paths=[];kind='';
    if cfg.route.preferNodeDisjoint
        paths=find_disjoint_paths(net,a,b,cfg.route.totalDisjointPaths,'node',cfg.route.maximumPathEdges);
        if ~isempty(paths),kind='node-disjoint';end
    end
    if isempty(paths)&&cfg.route.allowEdgeDisjointFallback
        paths=find_disjoint_paths(net,a,b,cfg.route.totalDisjointPaths,'edge',cfg.route.maximumPathEdges);
        if ~isempty(paths),kind='edge-disjoint';end
    end
    if isempty(paths),continue;end
    lengths=[paths.LengthKm];if max(lengths)>cfg.route.maximumPathStretch*min(lengths),continue;end
    [~,refIdx]=min(lengths);candIdx=setdiff(1:numel(paths),refIdx,'stable');
    if numel(candIdx)<cfg.route.minimumCandidateRoutes,continue;end;candIdx=candIdx(1:cfg.route.minimumCandidateRoutes);
    cand=struct('Y',{},'A',{},'B',{},'LengthKm',{},'EdgeCount',{},'SourceRows',{},'Nodes',{},'ProjectIDs',{});
    for j=1:numel(candIdx),cand(j)=compute_path_statistics(net,paths(candIdx(j)));end
    ref=compute_path_statistics(net,paths(refIdx));allRows=ref.SourceRows;
    for j=1:numel(cand),allRows=[allRows;cand(j).SourceRows];end %#ok<AGROW>
    cases(end+1)=struct('CaseID',"CASE_"+compose('%04d',numel(cases)+1), ...
        'TerminalA',a,'TerminalB',b,'Disjointness',string(kind),'Candidate',cand,'Reference',ref, ...
        'AllSourceRows',unique(allRows),'ReferenceStretch',ref.LengthKm/min([cand.LengthKm])); %#ok<AGROW>
    if numel(cases)>=cfg.route.maximumCases,break;end
end
if isempty(cases)
    error('find_public_validation_cases:NoCases', ...
        'No four-path validation cases were found. Add connected projects or relax the documented route criteria.');
end
[caseSummary,routeDetails]=cases_to_tables(cases);outDir=fullfile(runDir,'02_cases');safe_mkdir(outDir);
writetable(caseSummary,fullfile(outDir,'all_candidate_cases.csv'));writetable(routeDetails,fullfile(outDir,'case_route_details.csv'));
log_message(logFile,'Usable route cases: %d (%d node-disjoint, %d edge-disjoint).',numel(cases), ...
    sum(caseSummary.Disjointness=="node-disjoint"),sum(caseSummary.Disjointness=="edge-disjoint"));
end
function pc=sample_pairs(idx,maxPairs)
n=numel(idx);total=n*(n-1)/2;
if total<=maxPairs,pc=nchoosek(idx,2);return;end
pc=zeros(0,2);seen=containers.Map('KeyType','char','ValueType','logical');attempts=0;maxAttempts=maxPairs*50;
while size(pc,1)<maxPairs && attempts<maxAttempts
    two=idx(randperm(n,2));two=sort(two);key=sprintf('%d_%d',two(1),two(2));attempts=attempts+1;
    if ~isKey(seen,key),seen(key)=true;pc(end+1,:)=two;end %#ok<AGROW>
end
end
function [S,R]=cases_to_tables(cases)
n=numel(cases);CaseID=strings(n,1);TerminalA=strings(n,1);TerminalB=strings(n,1);Disjointness=strings(n,1);
CandidateRoutes=zeros(n,1);ReferenceLengthKm=zeros(n,1);CandidateMeanLengthKm=zeros(n,1);ReferenceStretch=zeros(n,1);AllEdgeCount=zeros(n,1);
rr=struct('CaseID',{},'Role',{},'RouteIndex',{},'Y_m',{},'AProxy',{},'BProxy',{},'LengthKm',{},'EdgeCount',{},'ProjectIDs',{},'NodeSequence',{});
for i=1:n
    c=cases(i);CaseID(i)=c.CaseID;TerminalA(i)=c.TerminalA;TerminalB(i)=c.TerminalB;Disjointness(i)=c.Disjointness;
    CandidateRoutes(i)=numel(c.Candidate);ReferenceLengthKm(i)=c.Reference.LengthKm;CandidateMeanLengthKm(i)=mean([c.Candidate.LengthKm]);
    ReferenceStretch(i)=c.ReferenceStretch;AllEdgeCount(i)=numel(c.AllSourceRows);
    for j=1:numel(c.Candidate),rr(end+1)=route_row(c.CaseID,'candidate',j,c.Candidate(j));end %#ok<AGROW>
    rr(end+1)=route_row(c.CaseID,'reference',1,c.Reference); %#ok<AGROW>
end
S=table(CaseID,TerminalA,TerminalB,Disjointness,CandidateRoutes,ReferenceLengthKm,CandidateMeanLengthKm,ReferenceStretch,AllEdgeCount);
R=struct2table(rr);
end
function r=route_row(caseID,role,j,s)
r=struct('CaseID',string(caseID),'Role',string(role),'RouteIndex',j,'Y_m',s.Y,'AProxy',s.A,'BProxy',s.B, ...
    'LengthKm',s.LengthKm,'EdgeCount',s.EdgeCount,'ProjectIDs',string(s.ProjectIDs),'NodeSequence',strjoin(s.Nodes,'->'));
end
