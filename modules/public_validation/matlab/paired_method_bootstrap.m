function Btab = paired_method_bootstrap(T,cfg)
%PAIRED_METHOD_BOOTSTRAP Case-resampled differences versus simplex-centroid GLS.
baseName="Simplex-centroid GLS";methods=unique(T.Method,'stable');methods(methods==baseName)=[];
caseIDs=unique(T.CaseID,'stable');R=cfg.validation.bootstrapReplicates;rng(cfg.randomSeed+53,'twister');
rows=struct('Comparator',{},'Metric',{},'DifferenceDefinition',{},'ObservedDifference',{}, ...
 'BootstrapMedian',{},'Lower95',{},'Upper95',{},'ProbabilityComparatorExceedsCentroid',{});
for i=1:numel(methods)
    for metric=["SquaredDiscrepancy_m2","AbsoluteDiscrepancy_m","IntervalWidth_m"]
        d=paired_case_diff(T,caseIDs,methods(i),baseName,metric);boot=nan(R,1);
        for r=1:R
            ids=caseIDs(randi(numel(caseIDs),numel(caseIDs),1));
            boot(r)=mean(paired_case_diff(T,ids,methods(i),baseName,metric),'omitnan');
        end
        ci=simple_percentile(boot,[2.5 50 97.5]);
        rows(end+1)=struct('Comparator',methods(i),'Metric',metric, ...
          'DifferenceDefinition',"comparator minus simplex-centroid GLS", ...
          'ObservedDifference',mean(d,'omitnan'),'BootstrapMedian',ci(2),'Lower95',ci(1),'Upper95',ci(3), ...
          'ProbabilityComparatorExceedsCentroid',mean(boot>0,'omitnan')); %#ok<AGROW>
    end
end
Btab=struct2table(rows);
end
function d=paired_case_diff(T,caseIDs,method,base,metric)
d=nan(numel(caseIDs),1);
for k=1:numel(caseIDs)
    a=T(T.CaseID==caseIDs(k)&T.Method==method,:);b=T(T.CaseID==caseIDs(k)&T.Method==base,:);
    if ~isempty(a)&&~isempty(b),d(k)=a.(char(metric))(1)-b.(char(metric))(1);end
end
end
