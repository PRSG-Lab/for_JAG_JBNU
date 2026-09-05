function S = parse_gsvs17_lvl(dataDir)
%PARSE_GSVS17_LVL  Parse NGS GSVS17 digital-levelling *.lvl files into sections.
%
%   S = PARSE_GSVS17_LVL(DATADIR) scans DATADIR for *.lvl files and returns a
%   struct array S with one element per levelling SECTION (one B...S...E block).
%
%   File record types used
%   ----------------------
%     B  <obs> <rec> <fromSSN> <fromDes> ...        begin section
%     S  <k> <Brdg> <Bnobs> <Bstd> <Bdist> ...
%              <Frdg> <Fnobs> <Fstd> <Fdist> <T1> <T2>     one instrument set-up
%     E  <toSSN> <toDes...> ... <nsetups> <imb> <dist> <dH> ...   end section
%
%   The section height difference and accumulated distance are recomputed from
%   the S records (sum of backsights minus sum of foresights; sum of all sight
%   distances) rather than read from the E record.  This was verified against
%   the E record for every parsable section in the GSVS17 archive (agreement to
%   1e-14 m) and is robust to the trailing extra fields that appear on a small
%   number of E records and break fixed back-indexing.
%
%   Output fields (per section)
%     file      char    source file name
%     dateStr   char    YYMMDD from the file name
%     dateNum   double  MATLAB datenum of dateStr
%     runCode   char    A / B / Z direction letter from the file name
%     obs       char    observer initials
%     fromSSN   char    survey station number at section start
%     toSSN     char    survey station number at section end
%     fromDes   char    designation at section start
%     toDes     char    designation at section end
%     nSetups   double  number of instrument set-ups
%     distKm    double  accumulated sight distance (km)
%     dH_m      double  observed height difference from -> to (m)
%     imb_m     double  backsight minus foresight distance (m), sight imbalance
%     sumBstd   double  sum of reported backsight reading std devs (mm units as
%                       recorded in the file; kept for optional weighting)
%     sumFstd   double  same for foresights
%
%   Part of the GSVS17 minimum-viable validation package.

if nargin < 1 || isempty(dataDir)
    dataDir = pwd;
end

files = dir(fullfile(dataDir, '*.lvl'));
assert(~isempty(files), 'parse_gsvs17_lvl:noFiles', ...
    'No *.lvl files found in "%s".', dataDir);

% Pre-allocate generously; trimmed at the end.
maxSec = 20 * numel(files);
S = repmat(emptySection(), maxSec, 1);
ns = 0;

for ii = 1:numel(files)
    fname = files(ii).name;
    fpath = fullfile(files(ii).folder, fname);

    [dateStr, runCode] = nameParts(fname);

    fid = fopen(fpath, 'r');
    if fid < 0
        warning('parse_gsvs17_lvl:openFail', 'Could not open %s', fpath);
        continue
    end

    cur    = [];       % current open section accumulator
    isOpen = false;

    while true
        ln = fgetl(fid);
        if ~ischar(ln), break, end
        if numel(ln) < 2, continue, end

        rec = ln(1);
        tok = strsplit(strtrim(ln));

        switch rec
            case 'B'
                % ---- begin a new section -------------------------------
                if numel(tok) >= 4
                    cur = emptySection();
                    cur.file    = fname;
                    cur.dateStr = dateStr;
                    cur.dateNum = str2dateNum(dateStr);
                    cur.runCode = runCode;
                    cur.obs     = tok{2};
                    cur.fromSSN = tok{4};
                    if numel(tok) >= 5
                        cur.fromDes = tok{5};
                    end
                    isOpen = true;
                end

            case 'S'
                % ---- one instrument set-up -----------------------------
                if isOpen && numel(tok) >= 10
                    Brdg  = str2double(tok{3});   % backsight rod reading  (m)
                    Bstd  = str2double(tok{5});   % backsight reading std
                    Bdist = str2double(tok{6});   % backsight distance     (m)
                    Frdg  = str2double(tok{7});   % foresight rod reading  (m)
                    Fstd  = str2double(tok{9});   % foresight reading std
                    Fdist = str2double(tok{10});  % foresight distance     (m)
                    if all(isfinite([Brdg Bdist Frdg Fdist]))
                        cur.sumB    = cur.sumB    + Brdg;
                        cur.sumF    = cur.sumF    + Frdg;
                        cur.sumBd   = cur.sumBd   + Bdist;
                        cur.sumFd   = cur.sumFd   + Fdist;
                        cur.nSetups = cur.nSetups + 1;
                        if isfinite(Bstd), cur.sumBstd = cur.sumBstd + Bstd; end
                        if isfinite(Fstd), cur.sumFstd = cur.sumFstd + Fstd; end
                    end
                end

            case 'E'
                % ---- close the section ---------------------------------
                if isOpen && numel(tok) >= 2 && cur.nSetups > 0
                    cur.toSSN  = tok{2};
                    if numel(tok) >= 3
                        cur.toDes = tok{3};
                    end
                    cur.dH_m   = cur.sumB  - cur.sumF;
                    cur.distKm = (cur.sumBd + cur.sumFd) / 1000;
                    cur.imb_m  =  cur.sumBd - cur.sumFd;

                    ns    = ns + 1;
                    S(ns) = cur;
                end
                cur    = [];
                isOpen = false;
        end
    end
    fclose(fid);
end

S = S(1:ns);

fprintf('parse_gsvs17_lvl: %d file(s), %d section(s) parsed.\n', numel(files), ns);

end % ===================== main function =====================


% ------------------------------------------------------------------------
function s = emptySection()
s = struct('file','', 'dateStr','', 'dateNum',NaN, 'runCode','', 'obs','', ...
           'fromSSN','', 'toSSN','', 'fromDes','', 'toDes','', ...
           'nSetups',0, 'distKm',NaN, 'dH_m',NaN, 'imb_m',NaN, ...
           'sumB',0, 'sumF',0, 'sumBd',0, 'sumFd',0, ...
           'sumBstd',0, 'sumFstd',0);
end


% ------------------------------------------------------------------------
function [dateStr, runCode] = nameParts(fname)
% GSVS17 file names look like 170601Atah.lvl  ->  YYMMDD | run letter | initials
dateStr = '';
runCode = '';
if numel(fname) >= 7
    dateStr = fname(1:6);
    runCode = fname(7);
end
end


% ------------------------------------------------------------------------
function dn = str2dateNum(dateStr)
dn = NaN;
if numel(dateStr) == 6
    yy = str2double(dateStr(1:2));
    mm = str2double(dateStr(3:4));
    dd = str2double(dateStr(5:6));
    if all(isfinite([yy mm dd]))
        dn = datenum(2000 + yy, mm, dd);
    end
end
end
