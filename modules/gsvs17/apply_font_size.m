function apply_font_size(figHandle, fs)
%APPLY_FONT_SIZE  Force every piece of text in a figure to one font size.
%
%   APPLY_FONT_SIZE(FIGHANDLE, FS) sets the font size of all axes, tick
%   labels, axis labels, titles, legends, colorbars, text objects and
%   annotations in FIGHANDLE to exactly FS points.
%
%   MATLAB scales axis labels and titles relative to the axes font size via
%   LabelFontSizeMultiplier and TitleFontSizeMultiplier (1.1 by default), so
%   these multipliers are reset to 1 first.  Otherwise "FontSize = 20" would
%   silently render labels at 22 pt.
%
%   Part of the GSVS17 minimum-viable validation package.

if nargin < 2 || isempty(fs), fs = 20; end

% ---- axes ---------------------------------------------------------------
ax = findall(figHandle, 'Type', 'axes');
for k = 1:numel(ax)
    a = ax(k);
    try
        a.LabelFontSizeMultiplier = 1;
        a.TitleFontSizeMultiplier = 1;
    catch
        % older releases: properties may not exist
    end
    set(a, 'FontSize', fs);
    if ~isempty(a.XLabel), set(a.XLabel, 'FontSize', fs); end
    if ~isempty(a.YLabel), set(a.YLabel, 'FontSize', fs); end
    if ~isempty(a.ZLabel), set(a.ZLabel, 'FontSize', fs); end
    if ~isempty(a.Title),  set(a.Title,  'FontSize', fs); end
end

% ---- legends, colorbars, text, annotations ------------------------------
types = {'legend', 'colorbar', 'text', 'textbox', 'textarrow'};
for t = 1:numel(types)
    h = findall(figHandle, 'Type', types{t});
    for k = 1:numel(h)
        try
            set(h(k), 'FontSize', fs);
        catch
        end
    end
end

% ---- anything else that exposes a FontSize property ---------------------
h = findall(figHandle, '-property', 'FontSize');
for k = 1:numel(h)
    try
        set(h(k), 'FontSize', fs);
    catch
    end
end

end
