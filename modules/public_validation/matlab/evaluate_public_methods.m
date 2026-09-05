function validation = evaluate_public_methods(testCases,calibration,cfg,runDir,logFile)
%EVALUATE_PUBLIC_METHODS Compare route rules against edge-independent reference routes.
rows=struct('CaseID',{},'Disjointness',{},'Method',{},'Estimate_m',{},'Reference_m',{}, ...
 'Discrepancy_m',{},'AbsoluteDiscrepancy_m',{},'SquaredDiscrepancy_m2',{}, ...
 'CandidateFormalVariance_m2',{},'CandidateReportedVariance_m2',{},'ReferenceVariance_m2',{}, ...
 'ComparisonVariance_m2',{},'StandardizedDiscrepancy',{},'Consistent95',{},'IntervalWidth_m',{}, ...
 'VulnerabilityRatio',{},'CoefficientVector',{});
for i=1:numel(testCases)
    c=testCases(i);P=numel(c.Candidate);Y=zeros(P,1);A=zeros(P,1);B=zeros(P,1);
    for p=1:P,Y(p)=c.Candidate(p).Y;A(p)=c.Candidate(p).A;B(p)=c.Candidate(p).B;end
    a=max(calibration.sigma2*A,cfg.model.minimumVariance);b=max(calibration.kappa*B,0);
    aRef=max(calibration.sigma2*c.Reference.A,cfg.model.minimumVariance);bRef=max(calibration.kappa*c.Reference.B,0);
    if strcmp(cfg.model.referenceVarianceRule,'rectangular-upper'),refVar=aRef+cfg.model.gammaFixed*bRef;else,refVar=aRef;end
    M=method_coefficients_public(a,b,cfg.model.gammaFixed);
    pos=b>cfg.model.minimumVariance;if all(pos),q=a./sqrt(b);vr=max(q)/min(q);elseif any(pos),vr=Inf;else,vr=1;end
    for m=1:numel(M)
        est=M(m).Weight'*Y;err=est-c.Reference.Y;compVar=M(m).RobustCandidateVariance+refVar;
        z=err/sqrt(max(compVar,cfg.model.minimumVariance));coefText=strjoin(compose('%.10g',M(m).Weight),';');
        rows(end+1)=struct('CaseID',string(c.CaseID),'Disjointness',string(c.Disjointness),'Method',M(m).Name, ...
          'Estimate_m',est,'Reference_m',c.Reference.Y,'Discrepancy_m',err,'AbsoluteDiscrepancy_m',abs(err), ...
          'SquaredDiscrepancy_m2',err^2,'CandidateFormalVariance_m2',M(m).FormalCandidateVariance, ...
          'CandidateReportedVariance_m2',M(m).RobustCandidateVariance,'ReferenceVariance_m2',refVar, ...
          'ComparisonVariance_m2',compVar,'StandardizedDiscrepancy',z,'Consistent95',abs(z)<=cfg.validation.zCritical, ...
          'IntervalWidth_m',2*cfg.validation.zCritical*sqrt(compVar),'VulnerabilityRatio',vr,'CoefficientVector',coefText); %#ok<AGROW>
    end
end
casewise=struct2table(rows);summary=summarize_method_table(casewise);boot=paired_method_bootstrap(casewise,cfg);
scale=public_scale_sensitivity(testCases,calibration,cfg);outDir=fullfile(runDir,'04_validation');safe_mkdir(outDir);
writetable(casewise,fullfile(outDir,'casewise_results.csv'));writetable(summary,fullfile(outDir,'method_summary.csv'));
writetable(boot,fullfile(outDir,'paired_bootstrap.csv'));writetable(scale,fullfile(outDir,'scale_sensitivity.csv'));
validation=struct('casewise',casewise,'summary',summary,'pairedBootstrap',boot,'scaleSensitivity',scale);
log_message(logFile,'Held-out evaluation completed: %d cases, %d method rows.',numel(testCases),height(casewise));
end
