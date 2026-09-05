function save_figure_bundle(fig,basePath,cfg)
%SAVE_FIGURE_BUNDLE Save PNG, vector PDF, 600-dpi TIFF, and MATLAB FIG.
[folder,~,~]=fileparts(basePath);safe_mkdir(folder);
set(fig,'Color','w');drawnow;
try,exportgraphics(fig,[basePath '.png'],'Resolution',cfg.plot.pngDpi);catch,print(fig,[basePath '.png'],'-dpng',sprintf('-r%d',cfg.plot.pngDpi));end
try,exportgraphics(fig,[basePath '.pdf'],'ContentType','vector');catch,print(fig,[basePath '.pdf'],'-dpdf','-painters');end
try,exportgraphics(fig,[basePath '.tif'],'Resolution',cfg.plot.tiffDpi);catch,print(fig,[basePath '.tif'],'-dtiff',sprintf('-r%d',cfg.plot.tiffDpi));end
try,savefig(fig,[basePath '.fig']);catch,saveas(fig,[basePath '.fig']);end
figure_readability_audit(fig,[basePath '_readability.txt'],cfg);
close(fig);
end
