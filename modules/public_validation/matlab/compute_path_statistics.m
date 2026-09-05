function st = compute_path_statistics(net,path)
%COMPUTE_PATH_STATISTICS Directed route total and variance proxies.
E=net.Edges; rows=path.SourceRows(:); nodes=path.Nodes(:);
if numel(nodes)~=numel(rows)+1,error('compute_path_statistics:InvalidPath','Node/edge path sizes disagree.');end
signs=zeros(numel(rows),1);
for i=1:numel(rows)
    e=rows(i); a=nodes(i); b=nodes(i+1);
    if E.FromID(e)==a && E.ToID(e)==b, signs(i)=1;
    elseif E.FromID(e)==b && E.ToID(e)==a, signs(i)=-1;
    else,error('compute_path_statistics:Orientation','Path orientation does not match source edge.');end
end
edgeA=E.BaseVarianceProxy(rows);
A=sum(edgeA);
B=max(sum(sqrt(max(edgeA,0)))^2-A,0);
st=struct();st.Y=sum(signs.*E.DeltaH_m(rows));st.A=A;st.B=B;st.LengthKm=sum(E.Length_km(rows));
st.EdgeCount=numel(rows);st.SourceRows=rows;st.Nodes=nodes;st.ProjectIDs=strjoin(unique(E.ProjectID(rows)),";");
end
