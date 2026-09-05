function [E,report] = clean_and_collapse_observations(T,cfg)
%CLEAN_AND_COLLAPSE_OBSERVATIONS Validate, orient, and collapse repeated links.
initial = height(T);
T.ProjectID = strtrim(string(T.ProjectID));
T.ObservationID = strtrim(string(T.ObservationID));
T.FromID = strtrim(string(T.FromID));
T.ToID = strtrim(string(T.ToID));
valid = strlength(T.FromID)>0 & strlength(T.ToID)>0 & T.FromID~=T.ToID & ...
    isfinite(T.DeltaH_m) & isfinite(T.Length_km) & T.Length_km>=cfg.data.minPositiveLengthKm;
T = T(valid,:); afterInvalid = height(T);
[node1,node2,sgn] = canonicalize_station_pairs(T.FromID,T.ToID);
T.Node1 = node1; T.Node2 = node2; T.SignedDH = sgn.*T.DeltaH_m;
T.PhysicalKey = node1 + "|" + node2;
if ~cfg.data.collapseParallelPhysicalEdges
    E=T; report=struct('InitialRows',initial,'AfterInvalidRemoval',afterInvalid, ...
        'RemovedInvalid',initial-afterInvalid,'PhysicalEdges',height(E),'CollapsedReplicates',0); return;
end
[keys,~,g] = unique(T.PhysicalKey,'stable'); n = numel(keys);
ProjectID=strings(n,1);ObservationID=strings(n,1);FromID=strings(n,1);ToID=strings(n,1);
DeltaH_m=zeros(n,1);Length_km=zeros(n,1);Order=strings(n,1);Class=strings(n,1);
SetupCount=zeros(n,1);Date=strings(n,1);FromLat=nan(n,1);FromLon=nan(n,1);
ToLat=nan(n,1);ToLon=nan(n,1);SourceFile=strings(n,1);ReplicateCount=zeros(n,1);
ReplicateVariance_m2=nan(n,1);BaseVarianceProxy=zeros(n,1);
for i=1:n
    idx=find(g==i); ProjectID(i)=strjoin(unique(T.ProjectID(idx)),';'); ObservationID(i)="PE"+string(i);
    FromID(i)=T.Node1(idx(1)); ToID(i)=T.Node2(idx(1));
    DeltaH_m(i)=mean(T.SignedDH(idx),'omitnan'); Length_km(i)=median(T.Length_km(idx),'omitnan');
    Order(i)=first_nonempty(T.Order(idx)); Class(i)=first_nonempty(T.Class(idx));
    SetupCount(i)=sum(T.SetupCount(idx),'omitnan'); Date(i)=first_nonempty(T.Date(idx));
    SourceFile(i)=strjoin(unique(T.SourceFile(idx)),';');
    [FromLat(i),FromLon(i)]=coords_for_node(T,idx,FromID(i));
    [ToLat(i),ToLon(i)]=coords_for_node(T,idx,ToID(i));
    ReplicateCount(i)=numel(idx);
    if numel(idx)>=2, ReplicateVariance_m2(i)=var(T.SignedDH(idx),0,'omitnan'); end
    BaseVarianceProxy(i)=max(Length_km(i),cfg.data.minPositiveLengthKm);
end
PhysicalKey=keys; EdgeID=(1:n)';
E=table(EdgeID,ProjectID,ObservationID,FromID,ToID,PhysicalKey,DeltaH_m,Length_km, ...
    BaseVarianceProxy,ReplicateCount,ReplicateVariance_m2,Order,Class,SetupCount,Date, ...
    FromLat,FromLon,ToLat,ToLon,SourceFile);
report=struct('InitialRows',initial,'AfterInvalidRemoval',afterInvalid, ...
    'RemovedInvalid',initial-afterInvalid,'PhysicalEdges',height(E), ...
    'CollapsedReplicates',afterInvalid-height(E));
end
function s=first_nonempty(x)
x=string(x); i=find(strlength(strtrim(x))>0,1); if isempty(i),s="";else,s=x(i);end
end
function [lat,lon]=coords_for_node(T,idx,node)
lat=NaN;lon=NaN;
for k=idx(:)'
    if T.FromID(k)==node,lat=T.FromLat(k);lon=T.FromLon(k);
    elseif T.ToID(k)==node,lat=T.ToLat(k);lon=T.ToLon(k);end
    if isfinite(lat)&&isfinite(lon),return;end
end
end
