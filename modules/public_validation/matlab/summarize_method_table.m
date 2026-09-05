function S = summarize_method_table(T)
%SUMMARIZE_METHOD_TABLE Aggregate empirical discrepancy and uncertainty metrics.
methods=unique(T.Method,'stable');n=numel(methods);Method=strings(n,1);Cases=zeros(n,1);RMSE_m=zeros(n,1);MAE_m=zeros(n,1);MedianAE_m=zeros(n,1);Q95AE_m=zeros(n,1);Consistency95=zeros(n,1);MeanIntervalWidth_m=zeros(n,1);MeanReportedVariance_m2=zeros(n,1);
for i=1:n
    idx=T.Method==methods(i);e=T.Discrepancy_m(idx);Method(i)=methods(i);Cases(i)=sum(idx);RMSE_m(i)=sqrt(mean(e.^2));MAE_m(i)=mean(abs(e));MedianAE_m(i)=median(abs(e));Q95AE_m(i)=simple_percentile(abs(e),95);Consistency95(i)=mean(T.Consistent95(idx));MeanIntervalWidth_m(i)=mean(T.IntervalWidth_m(idx));MeanReportedVariance_m2(i)=mean(T.CandidateReportedVariance_m2(idx));
end
S=table(Method,Cases,RMSE_m,MAE_m,MedianAE_m,Q95AE_m,Consistency95,MeanIntervalWidth_m,MeanReportedVariance_m2);
end
