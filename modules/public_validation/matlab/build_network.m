function net = build_network(E)
%BUILD_NETWORK Build a simple physical-edge graph and retain source row IDs.
G = graph(cellstr(E.FromID),cellstr(E.ToID),E.Length_km);
if numedges(G) ~= height(E)
    error('build_network:EdgeCountMismatch', ...
        'Graph has %d edges but standardized table has %d. Check duplicate physical pairs.',numedges(G),height(E));
end
sourceRow = zeros(numedges(G),1);
for i=1:height(E)
    eidx = findedge(G,char(E.FromID(i)),char(E.ToID(i)));
    if isempty(eidx) || eidx==0
        error('build_network:MissingEdge','Could not map standardized edge row %d into graph.',i);
    end
    if sourceRow(eidx)~=0
        error('build_network:DuplicateEdge','Multiple standardized rows map to one graph edge.');
    end
    sourceRow(eidx)=i;
end
if any(sourceRow==0),error('build_network:UnmappedEdges','One or more graph edges lack a source row.');end
G.Edges.SourceRow = sourceRow;
nodeNames = string(G.Nodes.Name); lat=nan(numnodes(G),1); lon=nan(numnodes(G),1);
for i=1:numnodes(G)
    n=nodeNames(i); idx=find(E.FromID==n,1);
    if ~isempty(idx),lat(i)=E.FromLat(idx);lon(i)=E.FromLon(idx);end
    if ~isfinite(lat(i))||~isfinite(lon(i))
        idx=find(E.ToID==n,1); if ~isempty(idx),lat(i)=E.ToLat(idx);lon(i)=E.ToLon(idx);end
    end
end
net=struct('G',G,'Edges',E,'NodeNames',nodeNames,'Lat',lat,'Lon',lon);
end
