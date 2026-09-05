function figIndex = generate_public_figures(E,cases,trainCases,testCases,calibration,validation,cfg,runDir,logFile) %#ok<INUSD>
%GENERATE_PUBLIC_FIGURES Create manuscript-oriented validation figures.
figDir=fullfile(runDir,'05_figures');safe_mkdir(figDir);figIndex=strings(0,1);
if ~cfg.plot.enabled,return;end

% Figure 1: network and selected held-out cases.
fig=figure('Visible',cfg.plot.visible,'Position',[100 100 1100 700]);hold on;
validGeo=isfinite(E.FromLon)&isfinite(E.ToLon)&isfinite(E.FromLat)&isfinite(E.ToLat);
if mean(validGeo)>=0.50
    for i=find(validGeo)'
        plot([E.FromLon(i) E.ToLon(i)],[E.FromLat(i) E.ToLat(i)],'-','Color',[0.75 0.75 0.75],'LineWidth',0.5);
    end
    for k=1:min(numel(testCases),6)
        rows=testCases(k).AllSourceRows(:)';rows=rows(validGeo(rows));
        for r=rows,plot([E.FromLon(r) E.ToLon(r)],[E.FromLat(r) E.ToLat(r)],'LineWidth',cfg.plot.lineWidth);end
    end
    xlabel('Longitude (degrees)');ylabel('Latitude (degrees)');axis equal;
else
    net=build_network(E);p=plot(net.G,'Layout','force','NodeLabel',{});p.EdgeColor=[0.75 0.75 0.75];p.NodeColor=[0.3 0.3 0.3];
    xlabel('Graph-layout x');ylabel('Graph-layout y');
end
title('Levelling network and selected held-out route cases');grid on;set(gca,'FontSize',cfg.plot.fontSize);
base=fullfile(figDir,'Fig01_public_network');save_figure_bundle(fig,base,cfg);figIndex(end+1)=string(base);

% Figure 2: calibration diagnostic.
C=readtable(fullfile(runDir,'03_calibration','calibration_rows.csv'));pred=calibration.sigma2*C.BaselinePredictor+calibration.kappa*C.CoherentPredictor;
fig=figure('Visible',cfg.plot.visible,'Position',[100 100 800 650]);scatter(pred,C.SquaredDiscrepancy,34,'filled');hold on;
mx=max([pred;C.SquaredDiscrepancy]);if ~isfinite(mx)||mx<=0,mx=1;end
plot([0 mx],[0 mx],'--','LineWidth',cfg.plot.lineWidth);xlabel('Fitted discrepancy variance (m^2)');
ylabel('Observed squared route-reference discrepancy (m^2)');title('Training-case covariance-scale calibration');grid on;set(gca,'FontSize',cfg.plot.fontSize);
base=fullfile(figDir,'Fig02_calibration_diagnostic');save_figure_bundle(fig,base,cfg);figIndex(end+1)=string(base);

% Figure 3: held-out RMSE and MAE.
S=validation.summary;fig=figure('Visible',cfg.plot.visible,'Position',[100 100 1150 680]);x=1:height(S);bar(x,[S.RMSE_m S.MAE_m]);
set(gca,'XTick',x,'XTickLabel',cellstr(S.Method),'XTickLabelRotation',28,'FontSize',cfg.plot.fontSize);
ylabel('Route-reference discrepancy (m)');title('Held-out reference-route consistency');legend({'RMSE','MAE'},'Location','best');grid on;
base=fullfile(figDir,'Fig03_method_performance');save_figure_bundle(fig,base,cfg);figIndex(end+1)=string(base);

% Figure 4: consistency versus width.
fig=figure('Visible',cfg.plot.visible,'Position',[100 100 900 680]);scatter(S.MeanIntervalWidth_m,S.Consistency95,55,'filled');hold on;
for i=1:height(S),text(S.MeanIntervalWidth_m(i),S.Consistency95(i),"  "+short_method_name(S.Method(i)),'FontSize',cfg.plot.fontSize-1);end
yline(0.95,'--','95% reference');xlabel('Mean comparison-interval width (m)');ylabel('Held-out reference-consistency rate');
title('Consistency-width trade-off');grid on;set(gca,'FontSize',cfg.plot.fontSize);
base=fullfile(figDir,'Fig04_consistency_width_tradeoff');save_figure_bundle(fig,base,cfg);figIndex(end+1)=string(base);

% Figure 5: casewise minimax-versus-centroid empirical trade-off.
T=validation.casewise;ids=unique(T.CaseID,'stable');vr=nan(numel(ids),1);d=nan(numel(ids),1);
for i=1:numel(ids)
    mm=T(T.CaseID==ids(i)&T.Method=="Aggregate minimax",:);ce=T(T.CaseID==ids(i)&T.Method=="Simplex-centroid GLS",:);
    if ~isempty(mm)&&~isempty(ce),vr(i)=mm.VulnerabilityRatio(1);d(i)=mm.SquaredDiscrepancy_m2(1)-ce.SquaredDiscrepancy_m2(1);end
end
ok=isfinite(vr)&vr>0&isfinite(d);fig=figure('Visible',cfg.plot.visible,'Position',[100 100 850 650]);
scatter(vr(ok),d(ok),50,'filled');yline(0,'--');set(gca,'XScale','log','FontSize',cfg.plot.fontSize);
xlabel('Relative vulnerability ratio, max(q_p)/min(q_p)');ylabel('Minimax minus centroid squared discrepancy (m^2)');
title('Casewise empirical trade-off');grid on;
base=fullfile(figDir,'Fig05_casewise_tradeoff');save_figure_bundle(fig,base,cfg);figIndex(end+1)=string(base);

% Figure 6: coherent-scale sensitivity.
Q=validation.scaleSensitivity;fig=figure('Visible',cfg.plot.visible,'Position',[100 100 920 660]);
yyaxis left;plot(Q.ScaleMultiplier,100*Q.MeanRobustVarianceGain,'-o','LineWidth',cfg.plot.lineWidth,'MarkerSize',cfg.plot.markerSize);
ylabel('Mean same-set variance gain (%)');yyaxis right;
plot(Q.ScaleMultiplier,1000*Q.MeanMinimaxMinusCentroidAE_m,'--s','LineWidth',cfg.plot.lineWidth,'MarkerSize',cfg.plot.markerSize);
ylabel('Mean minimax-centroid absolute-error difference (mm)');set(gca,'XScale','log','FontSize',cfg.plot.fontSize);
xlabel('Multiplier applied to fitted coherent-mode scale');title('Sensitivity to effective coherent-mode scale');grid on;
base=fullfile(figDir,'Fig06_scale_sensitivity');save_figure_bundle(fig,base,cfg);figIndex(end+1)=string(base);

write_text_file(fullfile(figDir,'FIGURE_INDEX.txt'),strjoin(figIndex,newline));
log_message(logFile,'Figures generated: %d',numel(figIndex));
end
function s=short_method_name(x)
s=string(x);s=replace(s,'Simplex-centroid GLS','Centroid GLS');s=replace(s,'Rectangular upper GLS','Rectangular GLS');
s=replace(s,'Aggregate minimax','Minimax');s=replace(s,'Baseline same-set','Baseline robust');
end
