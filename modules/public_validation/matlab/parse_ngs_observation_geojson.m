function [T,rowsRead] = parse_ngs_observation_geojson(filePath,bench,cfg)
%PARSE_NGS_OBSERVATION_GEOJSON Parse NGS-style line observation GeoJSON.
T=empty_table(); J=jsondecode(fileread(filePath));
if ~isfield(J,'features')||isempty(J.features),rowsRead=0;return;end
F=J.features; if iscell(F),F=[F{:}];end; rowsRead=numel(F); rows=cell(0,15);
for i=1:numel(F)
    if ~isfield(F(i),'properties')||~isstruct(F(i).properties),continue;end
    P=F(i).properties; projectID=infer_project_id(filePath,P);
    [fromV,ff]=get_alias_value(P,{'fromssn','fromstation','fromid','startssn','beginssn','from'});
    [toV,ft]=get_alias_value(P,{'tossn','tostation','toid','endssn','to'});
    [dhV,fd]=get_alias_value(P,{'elevdif','elevdiff','elevationdifference','heightdifference','deltah','dh'});
    [lenV,fl]=get_alias_value(P,{'runlength','length','distance','dist'});
    if ~(ff&&ft&&fd&&fl),continue;end
    fromSSN=value_to_string(fromV);toSSN=value_to_string(toV);
    fromID=map_ssn_to_pid(projectID,fromSSN,bench);toID=map_ssn_to_pid(projectID,toSSN,bench);
    [uDh,fuDh]=get_alias_value(P,{'elevdifunits','elevdiffunits','heightunits','elevationunits','dhunits','elevdifunit'});
    [uLen,fuLen]=get_alias_value(P,{'runlengthunits','lengthunits','distanceunits','runlengthunit'});
    if ~fuDh,uDh=cfg.data.defaultHeightUnit;end;if ~fuLen,uLen=cfg.data.defaultLengthUnit;end
    dh=convert_height_to_m(value_to_double(dhV),uDh);len=convert_length_to_km(value_to_double(lenV),uLen);
    [ord,fo]=get_alias_value(P,{'order','surveyorder'});if ~fo,ord='';end
    [cls,fc]=get_alias_value(P,{'class','surveyclass'});if ~fc,cls='';end
    [setup,fs]=get_alias_value(P,{'setupnum','setupnumber','setups'});if ~fs,setup=NaN;end
    [dateV,fdate]=get_alias_value(P,{'date','rundate','observationdate'});if ~fdate,dateV='';end
    [idV,fid]=get_alias_value(P,{'observationid','id','runid','sequence'});if ~fid,idV=sprintf('%s_F%06d',char(projectID),i);end
    [fromLat,fromLon]=lookup_coords(projectID,fromSSN,bench);[toLat,toLon]=lookup_coords(projectID,toSSN,bench);
    if isfield(F(i),'geometry')&&isstruct(F(i).geometry)&&isfield(F(i).geometry,'coordinates')
        [gFromLat,gFromLon,gToLat,gToLon,ok]=line_endpoints(F(i).geometry.coordinates);
        if ok,fromLat=gFromLat;fromLon=gFromLon;toLat=gToLat;toLon=gToLon;end
    end
    rows(end+1,:)={projectID,value_to_string(idV),fromID,toID,dh,len,value_to_string(ord), ...
        value_to_string(cls),value_to_double(setup),value_to_string(dateV),fromLat,fromLon,toLat,toLon,string(filePath)}; %#ok<AGROW>
end
if isempty(rows),return;end
T=cell2table(rows,'VariableNames',T.Properties.VariableNames);
numCols={'DeltaH_m','Length_km','SetupCount','FromLat','FromLon','ToLat','ToLon'};
for k=1:numel(numCols),T.(numCols{k})=numeric_column(T.(numCols{k}));end
strCols={'ProjectID','ObservationID','FromID','ToID','Order','Class','Date','SourceFile'};
for k=1:numel(strCols),T.(strCols{k})=string(T.(strCols{k}));end
end
function T=empty_table()
T=table(strings(0,1),strings(0,1),strings(0,1),strings(0,1),zeros(0,1),zeros(0,1), ...
 strings(0,1),strings(0,1),zeros(0,1),strings(0,1),nan(0,1),nan(0,1),nan(0,1),nan(0,1),strings(0,1), ...
 'VariableNames',{'ProjectID','ObservationID','FromID','ToID','DeltaH_m','Length_km','Order','Class','SetupCount','Date','FromLat','FromLon','ToLat','ToLon','SourceFile'});
end
function x=numeric_column(v)
if iscell(v),x=cellfun(@value_to_double,v);else,x=double(v);end
x=x(:);
end
function id=map_ssn_to_pid(projectID,ssn,bench)
id="";if ~isempty(bench),idx=find(bench.ProjectID==projectID & bench.SSN==ssn,1);if ~isempty(idx)&&strlength(bench.PID(idx))>0,id=bench.PID(idx);end,end
if strlength(id)==0,id=projectID+":"+ssn;end
end
function [lat,lon]=lookup_coords(projectID,ssn,bench)
lat=NaN;lon=NaN;if isempty(bench),return;end;idx=find(bench.ProjectID==projectID & bench.SSN==ssn,1);if ~isempty(idx),lat=bench.Lat(idx);lon=bench.Lon(idx);end
end
function [lat1,lon1,lat2,lon2,ok]=line_endpoints(c)
lat1=NaN;lon1=NaN;lat2=NaN;lon2=NaN;ok=false;
try
    while iscell(c)&&numel(c)==1,c=c{1};end
    if iscell(c)
        pts=[];for j=1:numel(c),v=c{j};if isnumeric(v)&&numel(v)>=2,pts(end+1,:)=[double(v(1)),double(v(2))];end,end %#ok<AGROW>
    elseif isnumeric(c)
        pts=double(c);if size(pts,2)<2&&size(pts,1)>=2,pts=pts';end
    else,pts=[];end
    if size(pts,1)>=2&&size(pts,2)>=2,lon1=pts(1,1);lat1=pts(1,2);lon2=pts(end,1);lat2=pts(end,2);ok=true;end
catch,ok=false;end
end
