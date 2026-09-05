function q = simple_percentile(x,p)
%SIMPLE_PERCENTILE Percentile without Statistics Toolbox.
x = sort(x(isfinite(x)));
if isempty(x), q = NaN(size(p)); return; end
p = max(0,min(100,p));
q = zeros(size(p));
for i = 1:numel(p)
    r = 1 + (numel(x)-1)*p(i)/100;
    lo = floor(r); hi = ceil(r);
    if lo == hi
        q(i) = x(lo);
    else
        q(i) = x(lo) + (r-lo)*(x(hi)-x(lo));
    end
end
end
