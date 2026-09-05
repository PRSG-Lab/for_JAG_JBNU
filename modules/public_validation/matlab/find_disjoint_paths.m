function paths = find_disjoint_paths(net,terminalA,terminalB,k,mode,maxPathEdges)
%FIND_DISJOINT_PATHS Greedy positive-length node- or edge-disjoint paths.
if nargin<6,maxPathEdges=Inf;end
mode=lower(char(mode));
if ~ismember(mode,{'node','edge'})
    error('find_disjoint_paths:InvalidMode','Mode must be node or edge.');
end
Gwork=net.G; paths=struct('Nodes',{},'SourceRows',{},'LengthKm',{});
for r=1:k
    if findnode(Gwork,char(terminalA))==0 || findnode(Gwork,char(terminalB))==0,paths=[];return;end
    try
        [nodePath,dist,edgePath]=shortestpath(Gwork,char(terminalA),char(terminalB),'Method','positive');
    catch
        paths=[];return;
    end
    if isempty(nodePath)||~isfinite(dist)||numel(edgePath)>maxPathEdges,paths=[];return;end
    srcRows=Gwork.Edges.SourceRow(edgePath);
    paths(end+1)=struct('Nodes',string(nodePath(:)),'SourceRows',srcRows(:),'LengthKm',dist); %#ok<AGROW>
    if strcmp(mode,'node')
        internal=string(nodePath(2:end-1));
        if ~isempty(internal),Gwork=rmnode(Gwork,cellstr(internal));end
        % Remove all used physical edges as an additional safeguard.
        [tf,loc]=ismember(Gwork.Edges.SourceRow,srcRows); %#ok<ASGLU>
        if any(tf),Gwork=rmedge(Gwork,find(tf));end
    elseif strcmp(mode,'edge')
        tf=ismember(Gwork.Edges.SourceRow,srcRows);
        if any(tf),Gwork=rmedge(Gwork,find(tf));end
    end
end
end
