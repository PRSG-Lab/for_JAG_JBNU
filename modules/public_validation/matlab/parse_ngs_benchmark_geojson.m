function T = parse_ngs_benchmark_geojson(filePath)
%PARSE_NGS_BENCHMARK_GEOJSON Parse benchmark points for SSN-to-PID mapping.
T=table(strings(0,1),strings(0,1),strings(0,1),zeros(0,1),zeros(0,1), ...
    'VariableNames',{'ProjectID','SSN','PID','Lat','Lon'});
J=jsondecode(fileread(filePath));if ~isfield(J,'features')||isempty(J.features),return;end
F=J.features;if iscell(F),F=[F{:}];end;if ~isstruct(F),return;end
rows=struct('ProjectID',{},'SSN',{},'PID',{},'Lat',{},'Lon',{});
for i=1:numel(F)
    if ~isfield(F(i),'properties')||~isstruct(F(i).properties),continue;end
    P=F(i).properties;[ssn,fs]=get_alias_value(P,{'ssn','stationserialnumber','stationnumber'});
    [pid,fp]=get_alias_value(P,{'pid','permanentidentifier','permanentid'});if ~fs&&~fp,continue;end
    projectID=infer_project_id(filePath,P);lat=NaN;lon=NaN;
    [la,fla]=get_alias_value(P,{'latitude','lat'});[lo,flo]=get_alias_value(P,{'longitude','lon','lng'});
    if fla,lat=value_to_double(la);end;if flo,lon=value_to_double(lo);end
    if isfield(F(i),'geometry')&&isstruct(F(i).geometry)&&isfield(F(i).geometry,'coordinates')
        c=F(i).geometry.coordinates;while iscell(c)&&numel(c)==1,c=c{1};end
        if isnumeric(c)&&numel(c)>=2,lon=double(c(1));lat=double(c(2));end
    end
    rows(end+1)=struct('ProjectID',projectID,'SSN',value_to_string(ssn), ...
        'PID',value_to_string(pid),'Lat',lat,'Lon',lon); %#ok<AGROW>
end
if ~isempty(rows),T=struct2table(rows);end
end
