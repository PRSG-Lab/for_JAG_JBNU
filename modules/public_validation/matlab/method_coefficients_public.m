function methods = method_coefficients_public(a,b,Gamma)
%METHOD_COEFFICIENTS_PUBLIC Coefficients and uncertainty rules for public validation.
a=double(a(:));b=double(b(:));Gamma=double(Gamma);P=numel(a);nu=0;
if P==0||numel(b)~=P||any(~isfinite(a))||any(a<=0)||any(~isfinite(b))||any(b<0)|| ...
        ~isscalar(Gamma)||~isfinite(Gamma)||Gamma<0
    error('method_coefficients_public:InvalidInput','Require finite a>0, b>=0, Gamma>=0.');
end
methods=struct('Name',{},'Weight',{},'FormalCandidateVariance',{},'RobustCandidateVariance',{},'InformationSet',{});
add('Unweighted',ones(P,1)/P,sum(a)/P^2,sum(a)/P^2,'baseline only');
w=(1./a)/sum(1./a);add('Baseline formal',w,sum(a.*w.^2),sum(a.*w.^2),'baseline only');
add('Baseline same-set',w,sum(a.*w.^2),sum(a.*w.^2)+Gamma*max(b.*w.^2)+nu,'aggregate set for reporting');
d=a+Gamma*b/P;w=(1./d)/sum(1./d);add('Simplex-centroid GLS',w,sum(d.*w.^2),sum(a.*w.^2)+Gamma*max(b.*w.^2)+nu,'centroid coefficients; aggregate-set reporting');
[w,~]=minimax_route_weights(a,b,Gamma);r=sum(a.*w.^2)+Gamma*max(b.*w.^2)+nu;add('Aggregate minimax',w,r,r,'aggregate set');
d=a+Gamma*b;w=(1./d)/sum(1./d);r=sum(d.*w.^2)+nu;add('Rectangular upper GLS',w,r,r,'componentwise upper covariance');
    function add(name,w,formal,robust,info)
        methods(end+1)=struct('Name',string(name),'Weight',w(:),'FormalCandidateVariance',formal,'RobustCandidateVariance',robust,'InformationSet',string(info)); %#ok<AGROW>
    end
end
