function calibration = calibrate_public_covariance(trainCases,cfg,runDir,logFile)
%CALIBRATE_PUBLIC_COVARIANCE Fit baseline and effective coherent scales on training cases.
[X,y,w,caseID]=calibration_rows(trainCases);
fit=robust_nnls2(X,y,w,cfg);
B=cfg.validation.calibrationBootstrapReplicates;boot=zeros(B,2);uniqueCases=unique(caseID,'stable');rng(cfg.randomSeed+31,'twister');
for b=1:B
    sampled=uniqueCases(randi(numel(uniqueCases),numel(uniqueCases),1));Xb=[];yb=[];wb=[];
    for j=1:numel(sampled)
        idx=find(caseID==sampled(j));Xb=[Xb;X(idx,:)];yb=[yb;y(idx)];wb=[wb;w(idx)]; %#ok<AGROW>
    end
    try,f=robust_nnls2(Xb,yb,wb,cfg);boot(b,:)=f.beta';catch,boot(b,:)=[NaN NaN];end
end
ciSigma=simple_percentile(boot(:,1),[2.5 50 97.5]);ciKappa=simple_percentile(boot(:,2),[2.5 50 97.5]);
calibration=struct('sigma2',fit.sigma2,'kappa',fit.kappa,'fit',fit,'bootstrap',boot,'sigma2CI',ciSigma,'kappaCI',ciKappa,'GammaFixed',cfg.model.gammaFixed,'Rows',numel(y),'Cases',numel(uniqueCases));
outDir=fullfile(runDir,'03_calibration');safe_mkdir(outDir);
params=table(fit.sigma2,fit.kappa,cfg.model.gammaFixed,ciSigma(1),ciSigma(2),ciSigma(3),ciKappa(1),ciKappa(2),ciKappa(3), ...
    'VariableNames',{'Sigma2','Kappa','GammaFixed','Sigma2_L95','Sigma2_Median','Sigma2_U95','Kappa_L95','Kappa_Median','Kappa_U95'});
writetable(params,fullfile(outDir,'calibration_parameters.csv'));
writetable(array2table(boot,'VariableNames',{'Sigma2','Kappa'}),fullfile(outDir,'calibration_bootstrap.csv'));
writetable(table(caseID,X(:,1),X(:,2),y,w,fit.residuals,'VariableNames',{'CaseID','BaselinePredictor','CoherentPredictor','SquaredDiscrepancy','BaseWeight','Residual'}),fullfile(outDir,'calibration_rows.csv'));
log_message(logFile,'Calibration: sigma2=%.6g, kappa=%.6g; training cases=%d.',fit.sigma2,fit.kappa,numel(uniqueCases));
end
function [X,y,w,caseID]=calibration_rows(cases)
X=zeros(0,2);y=zeros(0,1);w=zeros(0,1);caseID=strings(0,1);
for i=1:numel(cases)
    c=cases(i);P=numel(c.Candidate);
    for p=1:P
        d=c.Candidate(p).Y-c.Reference.Y;
        X(end+1,:)=[c.Candidate(p).A+c.Reference.A,c.Candidate(p).B+c.Reference.B]; %#ok<AGROW>
        y(end+1,1)=d^2;w(end+1,1)=1/P;caseID(end+1,1)=string(c.CaseID); %#ok<AGROW>
    end
end
end
