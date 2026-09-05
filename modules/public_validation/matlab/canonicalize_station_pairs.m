function [node1,node2,signMultiplier] = canonicalize_station_pairs(fromID,toID)
%CANONICALIZE_STATION_PAIRS Lexically orient undirected station pairs.
fromID = string(fromID(:));
toID = string(toID(:));
if numel(fromID) ~= numel(toID)
    error('canonicalize_station_pairs:SizeMismatch','fromID and toID sizes differ.');
end
n = numel(fromID);
node1 = strings(n,1); node2 = strings(n,1); signMultiplier = ones(n,1);
for i = 1:n
    pair = sort([fromID(i),toID(i)]);
    node1(i) = pair(1); node2(i) = pair(2);
    if fromID(i) ~= node1(i), signMultiplier(i) = -1; end
end
end
