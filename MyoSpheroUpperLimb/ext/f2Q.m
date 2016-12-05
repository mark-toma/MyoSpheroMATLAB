function [Q,r] = f2Q(f,x)
% 1/2*x'*Q*x + r = f(x)
r = expand(f);
N = length(x);
Q = sym(zeros(N));
for ii=1:N
  for jj=ii:N
    [c1,t1] = coeffs(r,x(ii));
    for kk1 = 1:length(t1)
      if t1(kk1)==sym('1'), continue; end
      if t1(kk1)==x(ii)*x(jj)
        Q(ii,jj) = Q(ii,jj) + c1(kk1);
        r = r - c1(kk1)*t1(kk1);
        continue;
      end
      [c2,t2] = coeffs(c1(kk1),x(jj));
      for kk2 = 1:length(t2)
        if t2(kk2)==sym('1'), continue; end
        Q(ii,jj) = Q(ii,jj) + c2(kk2);
        r = r - c2(kk2)*t2(kk2)*t1(kk1);
      end
    end
  end
end
Q = transpose(Q)+Q;