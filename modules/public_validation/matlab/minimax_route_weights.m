function [w,info] = minimax_route_weights(a,b,Gamma)
%MINIMAX_ROUTE_WEIGHTS Closed-form minimax coefficients for diagonal simplex uncertainty.
a=double(a(:));b=double(b(:));Gamma=double(Gamma);P=numel(a);
if P==0||numel(b)~=P||any(~isfinite(a))||any(a<=0)||any(~isfinite(b))||any(b<0)|| ...
        ~isscalar(Gamma)||~isfinite(Gamma)||Gamma<0
    error('minimax_route_weights:InvalidInput','Require finite a>0, b>=0, Gamma>=0.');
end
if Gamma==0||all(b<=eps(max(1,max(b))))
    w=(1./a)/sum(1./a);info=struct('Phase',0,'Objective',sum(a.*w.^2),'SortedIndex',(1:P)','Exposure',max(b.*w.^2));return;
end
pos=find(b>eps(max(1,max(b))));zero=find(~(b>eps(max(1,max(b)))));
q=inf(P,1);q(pos)=a(pos)./sqrt(b(pos));[~,ord]=sort(q,'ascend');posOrd=ord(isfinite(q(ord)));zeroOrd=ord(~isfinite(q(ord)));
valid=false;w=zeros(P,1);phase=NaN;u=NaN;v=NaN;
for k=1:numel(posOrd)
    active=posOrd(1:k);inactive=[posOrd(k+1:end);zeroOrd];
    H=sum(1./sqrt(b(active)));C=sum(a(active)./b(active));S=sum(1./a(inactive));
    D=H^2+S*(Gamma+C);u0=H/D;v0=(Gamma+C)/D;ratio=v0/u0;
    qlo=max(q(active));if isempty(inactive),qhi=Inf;else,qhi=min(q(inactive));end
    if ratio>=qlo-1e-10*max(1,abs(qlo)) && ratio<=qhi+1e-10*max(1,abs(qhi))
        w(active)=u0./sqrt(b(active));w(inactive)=v0./a(inactive);valid=true;phase=k;u=u0;v=v0;break;
    end
end
if ~valid
    error('minimax_route_weights:NoPhase','No valid active-set phase found.');
end
w=max(w,0);w=w/sum(w);obj=sum(a.*w.^2)+Gamma*max(b.*w.^2);
info=struct('Phase',phase,'Objective',obj,'SortedIndex',ord,'Exposure',max(b.*w.^2),'u',u,'v',v,'ZeroExposureRoutes',zero);
end
