function report = figure_readability_audit(fig,filePath,cfg)
%FIGURE_READABILITY_AUDIT Machine-check basic readability properties.
ax=findall(fig,'Type','axes');warnings=strings(0,1);minFont=Inf;maxLines=0;missingLabels=0;legendEntries=0;
for i=1:numel(ax)
    tag=string(get(ax(i),'Tag'));if contains(lower(tag),'colorbar'),continue;end
    fs=get(ax(i),'FontSize');minFont=min(minFont,fs);ln=findall(ax(i),'Type','line');maxLines=max(maxLines,numel(ln));
    xl=get(get(ax(i),'XLabel'),'String');yl=get(get(ax(i),'YLabel'),'String');
    if isempty(xl),missingLabels=missingLabels+1;end;if isempty(yl),missingLabels=missingLabels+1;end
end
lg=findall(fig,'Type','legend');for i=1:numel(lg),s=get(lg(i),'String');legendEntries=max(legendEntries,numel(s));end
if isinf(minFont),minFont=NaN;end
if isfinite(minFont)&&minFont<cfg.plot.fontSize-1,warnings(end+1)="axis font smaller than configured target";end
if maxLines>8,warnings(end+1)="more than eight lines on one axes";end
if legendEntries>8,warnings(end+1)="more than eight legend entries";end
if missingLabels>0,warnings(end+1)="one or more axes labels are empty";end
report=struct('AxesCount',numel(ax),'MinimumAxisFontSize',minFont,'MaximumLinesPerAxes',maxLines, ...
 'MaximumLegendEntries',legendEntries,'MissingAxisLabels',missingLabels,'Warnings',warnings,'Passed',isempty(warnings));
write_json_file(filePath,report);
end
