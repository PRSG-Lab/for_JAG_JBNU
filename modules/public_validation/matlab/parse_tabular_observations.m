function [T,rowsRead] = parse_tabular_observations(filePath,cfg)
%PARSE_TABULAR_OBSERVATIONS Parse standardized or alias-compatible tables.
[~,~,ext]=fileparts(filePath);
if any(strcmpi(ext,{'.xlsx','.xls'}))
    R=readtable(filePath,'VariableNamingRule','preserve');
else
    try,R=readtable(filePath,'VariableNamingRule','preserve','TextType','string');
    catch,R=readtable(filePath,'VariableNamingRule','preserve');end
end
rowsRead=height(R); names=R.Properties.VariableNames; idx=@(a)find_alias_column(names,a);
cProject=idx({'ProjectID','Project','HGZ','Accession'}); cObs=idx({'ObservationID','Observation','EdgeID','ID'});
cFrom=idx({'FromID','FromSSN','From','Start','BeginStation','FromStation'});
cTo=idx({'ToID','ToSSN','To','End','EndStation','ToStation'});
cDh=idx({'DeltaH_m','DeltaH','ElevDif','ElevDiff','ElevationDifference','HeightDifference','DH'});
cDhUnit=idx({'DeltaHUnit','ElevDifUnit','ElevDiffUnit','HeightUnit','UnitsHeight'});
cLen=idx({'Length_km','Length','RunLength','Distance','Dist'});
cLenUnit=idx({'LengthUnit','RunLengthUnit','DistanceUnit','UnitsLength'});
if isempty(cFrom)||isempty(cTo)||isempty(cDh)||isempty(cLen)
    error('parse_tabular_observations:MissingColumns', ...
        'Required from/to/height-difference/length columns were not detected in %s.',filePath);
end
n=height(R); ProjectID=strings(n,1);ObservationID=strings(n,1);FromID=strings(n,1);ToID=strings(n,1);
DeltaH_m=nan(n,1);Length_km=nan(n,1);
for r=1:n
    if isempty(cProject),ProjectID(r)=infer_project_id(filePath,struct());else,ProjectID(r)=value_to_string(table_scalar(R,r,cProject));end
    if isempty(cObs),ObservationID(r)=ProjectID(r)+"_R"+compose('%06d',r);else,ObservationID(r)=value_to_string(table_scalar(R,r,cObs));end
    FromID(r)=value_to_string(table_scalar(R,r,cFrom)); ToID(r)=value_to_string(table_scalar(R,r,cTo));
    dh=value_to_double(table_scalar(R,r,cDh)); len=value_to_double(table_scalar(R,r,cLen));
    if isempty(cDhUnit),uDh=cfg.data.defaultHeightUnit;else,uDh=value_to_string(table_scalar(R,r,cDhUnit));end
    if isempty(cLenUnit),uLen=cfg.data.defaultLengthUnit;else,uLen=value_to_string(table_scalar(R,r,cLenUnit));end
    DeltaH_m(r)=convert_height_to_m(dh,uDh); Length_km(r)=convert_length_to_km(len,uLen);
end
Order=get_string_column(R,names,{'Order','SurveyOrder'},n);
Class=get_string_column(R,names,{'Class','SurveyClass'},n);
SetupCount=get_numeric_column(R,names,{'SetupCount','SetupNum','SetupNumber','Setups'},n);
Date=get_string_column(R,names,{'Date','ObservationDate','RunDate'},n);
FromLat=get_numeric_column(R,names,{'FromLat','StartLat'},n); FromLon=get_numeric_column(R,names,{'FromLon','StartLon'},n);
ToLat=get_numeric_column(R,names,{'ToLat','EndLat'},n); ToLon=get_numeric_column(R,names,{'ToLon','EndLon'},n);
SourceFile=repmat(string(filePath),n,1);
T=table(ProjectID,ObservationID,FromID,ToID,DeltaH_m,Length_km,Order,Class,SetupCount,Date,FromLat,FromLon,ToLat,ToLon,SourceFile);
end
function idx=find_alias_column(names,aliases)
normNames=cellfun(@normalize_field_name,names,'UniformOutput',false);idx=[];
for i=1:numel(aliases),key=normalize_field_name(aliases{i});j=find(strcmp(normNames,key),1);if ~isempty(j),idx=j;return;end,end
end
function v=table_scalar(R,r,c)
try,v=R{r,c};catch,v=R.(R.Properties.VariableNames{c})(r);end
if iscell(v)&&isscalar(v),v=v{1};end
end
function s=get_string_column(R,names,aliases,n)
i=find_alias_column(names,aliases);s=strings(n,1);if isempty(i),return;end
for k=1:n,s(k)=value_to_string(table_scalar(R,k,i));end
end
function x=get_numeric_column(R,names,aliases,n)
i=find_alias_column(names,aliases);x=nan(n,1);if isempty(i),return;end
for k=1:n,x(k)=value_to_double(table_scalar(R,k,i));end
end
