function P = build_fb_pairs(S)
%BUILD_FB_PAIRS  Form forward/backward run pairs from parsed GSVS17 sections.
%
%   P = BUILD_FB_PAIRS(S) takes the section struct array returned by
%   PARSE_GSVS17_LVL and returns a struct array P with one element per bench
%   mark pair that was run in BOTH directions.
%
%   For a pair (A,B) with a forward run  dH_f = H_B - H_A  and a backward run
%   dH_b = H_A - H_B, the closure discrepancy is
%
%       d = ( dH_f + dH_b ) * 1000        [mm]
%
%   which has expectation zero and variance
%
%       Var(d) = Var(forward) + Var(backward) = 2 * v(L, n)
%
%   under the assumption that the two runs are independent.  This is the
%   quantity used to calibrate the route-total variance model.
%
%   IMPORTANT INTERPRETATION NOTE
%   -----------------------------
%   A forward/backward discrepancy CANCELS any systematic effect that repeats
%   identically in both runs (e.g. a stable rod-scale error).  The coherent
%   variance component recovered from d is therefore a LOWER bound on the true
%   route-coherent component.  Since the manuscript defines b_p as an UPPER
%   variance scale, the estimate obtained here should be quoted as a
%   conservative empirical floor, not as a calibrated value of b_p.
%
%   Output fields (per pair)
%     ssnA, ssnB   char    the two bench mark SSNs (sorted, for identity)
%     desA, desB   char    designations
%     d_mm         double  closure discrepancy (mm)
%     L_km         double  mean accumulated distance of the two runs (km)
%     nSetups      double  mean number of set-ups of the two runs
%     sameDay      logical true if both runs were observed on the same date
%     gapDays      double  |date difference| between the two runs (days)
%     imbSum_m     double  |imbalance_f| + |imbalance_b| (m), sight asymmetry
%     nRunsTotal   double  how many runs exist for this pair in the archive
%     idxF, idxB   double  indices into S of the two runs used
%
%   Part of the GSVS17 minimum-viable validation package.

n = numel(S);
assert(n > 0, 'build_fb_pairs:empty', 'No sections supplied.');

% ---- group section indices by unordered bench mark pair ------------------
% Canonical key: the two SSN strings sorted lexicographically.
keys = cell(n, 1);
for i = 1:n
    a = S(i).fromSSN; b = S(i).toSSN;
    if isempty(a) || isempty(b)
        keys{i} = '';
        continue
    end
    two = sort({a, b});
    keys{i} = [two{1} '|' two{2}];
end

valid  = ~cellfun(@isempty, keys);
uKeys  = unique(keys(valid));

P  = repmat(emptyPair(), numel(uKeys), 1);
np = 0;

for k = 1:numel(uKeys)
    idx = find(strcmp(keys, uKeys{k}));
    if numel(idx) < 2, continue, end

    % first run defines the "forward" direction, then find its reverse
    iF = idx(1);
    iB = 0;
    for j = 2:numel(idx)
        t = idx(j);
        if strcmp(S(t).fromSSN, S(iF).toSSN) && strcmp(S(t).toSSN, S(iF).fromSSN)
            iB = t;
            break
        end
    end
    if iB == 0, continue, end     % no opposing run -> unusable

    p            = emptyPair();
    two          = sort({S(iF).fromSSN, S(iF).toSSN});
    p.ssnA       = two{1};
    p.ssnB       = two{2};
    p.desA       = S(iF).fromDes;
    p.desB       = S(iF).toDes;
    p.d_mm       = (S(iF).dH_m + S(iB).dH_m) * 1000;
    p.L_km       = (S(iF).distKm + S(iB).distKm) / 2;
    p.nSetups    = (S(iF).nSetups + S(iB).nSetups) / 2;
    p.sameDay    = strcmp(S(iF).dateStr, S(iB).dateStr);
    p.gapDays    = abs(S(iF).dateNum - S(iB).dateNum);
    p.imbSum_m   = abs(S(iF).imb_m) + abs(S(iB).imb_m);
    p.nRunsTotal = numel(idx);
    p.idxF       = iF;
    p.idxB       = iB;

    np    = np + 1;
    P(np) = p;
end

P = P(1:np);

% ---- basic sanity screening ---------------------------------------------
bad = ~isfinite([P.d_mm]) | ~isfinite([P.L_km]) | ([P.L_km] <= 0) | ...
      ([P.nSetups] <= 0);
if any(bad)
    fprintf('build_fb_pairs: dropped %d non-finite / degenerate pair(s).\n', sum(bad));
    P = P(~bad);
end

fprintf(['build_fb_pairs: %d forward/backward pair(s); ', ...
         'total single-run length %.2f km; rms discrepancy %.4f mm.\n'], ...
        numel(P), sum([P.L_km]), sqrt(mean([P.d_mm].^2)));

end % ===================== main function =====================


% ------------------------------------------------------------------------
function p = emptyPair()
p = struct('ssnA','', 'ssnB','', 'desA','', 'desB','', ...
           'd_mm',NaN, 'L_km',NaN, 'nSetups',NaN, ...
           'sameDay',false, 'gapDays',NaN, 'imbSum_m',NaN, ...
           'nRunsTotal',0, 'idxF',0, 'idxB',0);
end
