function S = public_scale_sensitivity(cases,calibration,cfg)
%PUBLIC_SCALE_SENSITIVITY Re-evaluate minimax versus centroid across coherent scales.
mult=cfg.validation.scaleMultipliers(:);
rows=struct('ScaleMultiplier',{},'MeanMinimaxMinusCentroidSE_m2',{}, ...
 'MeanMinimaxMinusCentroidAE_m',{},'MeanRobustVarianceGain',{},'MedianWeightChangeL1',{});
for j=1:numel(mult)
    dse=[];dae=[];gain=[];wch=[];
    for i=1:numel(cases)
        c=cases(i);P=numel(c.Candidate);Y=zeros(P,1);A=zeros(P,1);B=zeros(P,1);
        for p=1:P,Y(p)=c.Candidate(p).Y;A(p)=c.Candidate(p).A;B(p)=c.Candidate(p).B;end
        a=max(calibration.sigma2*A,cfg.model.minimumVariance);b=max(calibration.kappa*mult(j)*B,0);
        M=method_coefficients_public(a,b,cfg.model.gammaFixed);names=string({M.Name});
        mm=M(names=="Aggregate minimax");ce=M(names=="Simplex-centroid GLS");
        emm=mm.Weight'*Y-c.Reference.Y;ece=ce.Weight'*Y-c.Reference.Y;
        dse(end+1)=emm^2-ece^2;dae(end+1)=abs(emm)-abs(ece); %#ok<AGROW>
        gain(end+1)=1-mm.RobustCandidateVariance/ce.RobustCandidateVariance; %#ok<AGROW>
        wch(end+1)=sum(abs(mm.Weight-ce.Weight)); %#ok<AGROW>
    end
    rows(end+1)=struct('ScaleMultiplier',mult(j),'MeanMinimaxMinusCentroidSE_m2',mean(dse,'omitnan'), ...
      'MeanMinimaxMinusCentroidAE_m',mean(dae,'omitnan'),'MeanRobustVarianceGain',mean(gain,'omitnan'), ...
      'MedianWeightChangeL1',median(wch,'omitnan')); %#ok<AGROW>
end
S=struct2table(rows);
end
