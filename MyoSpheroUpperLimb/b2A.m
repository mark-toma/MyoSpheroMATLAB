function [A,r] = b2A(b,x)
% A*x + r = b
r = expand(b);
M = length(b);
N = length(x);
A = sym(zeros(M,N));
for ii=1:M
  for jj=1:N
    [c,t] = coeffs(b(ii),x(jj));
    for kk=1:length(t)
      if t(kk)==x(jj)
        A(ii,jj) = A(ii,jj) + c(kk);
        r = r - c(kk)*t(kk);
      end
    end
  end
end