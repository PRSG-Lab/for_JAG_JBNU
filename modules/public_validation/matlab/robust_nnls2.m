function fit = robust_nnls2(X,y,baseWeights,cfg)
%ROBUST_NNLS2 Huber IRLS with exact two-parameter nonnegative LS inner step.
if nargin<3||isempty(baseWeights),baseWeights=ones(size(y));end
X=double(X);y=double(y(:));baseWeights=double(baseWeights(:));
valid=all(isfinite(X),2)&isfinite(y)&isfinite(baseWeights)&baseWeights>0;X=X(valid,:);y=y(valid);baseWeights=baseWeights(valid);
if size(X,2)~=2||size(X,1)<2,error('robust_nnls2:InvalidData','Need at least two valid rows and two predictors.');end
w=baseWeights;beta=nnls2_weighted(X,y,w);history=zeros(cfg.model.irlsMaxIterations,3);
for it=1:cfg.model.irlsMaxIterations
    r=y-X*beta;med=median(r);scale=1.4826*median(abs(r-med));
    if ~isfinite(scale)||scale<eps,scale=max(sqrt(mean(r.^2)),eps);end
    u=abs(r)/(cfg.model.huberConstant*scale);h=ones(size(u));h(u>1)=1./u(u>1);wNew=baseWeights.*h;
    betaNew=nnls2_weighted(X,y,wNew);history(it,:)=[betaNew(:)' norm(betaNew-beta)];
    if norm(betaNew-beta)<=cfg.model.irlsTolerance*(1+norm(beta)),beta=betaNew;w=wNew;history=history(1:it,:);break;end
    beta=betaNew;w=wNew;
    if it==cfg.model.irlsMaxIterations,history=history(1:it,:);end
end
res=y-X*beta;fit=struct('beta',beta,'sigma2',beta(1),'kappa',beta(2),'weights',w,'residuals',res,'n',numel(y),'history',history,'weightedSSE',sum(w.*res.^2));
end
function beta=nnls2_weighted(X,y,w)
s=sqrt(max(w,0));Xw=X.*s;yw=y.*s;cands=zeros(2,4);
A=Xw'*Xw;b=Xw'*yw;
if rcond(A)>1e-14,cands(:,1)=A\b;else,cands(:,1)=pinv(A)*b;end
cands(:,2)=[max((Xw(:,1)'*yw)/max(Xw(:,1)'*Xw(:,1),eps),0);0];
cands(:,3)=[0;max((Xw(:,2)'*yw)/max(Xw(:,2)'*Xw(:,2),eps),0)];cands(:,4)=[0;0];
best=Inf;beta=[0;0];for j=1:4
    z=cands(:,j);if any(z<0),continue;end;v=sum((yw-Xw*z).^2);if v<best,best=v;beta=z;end
end
end
