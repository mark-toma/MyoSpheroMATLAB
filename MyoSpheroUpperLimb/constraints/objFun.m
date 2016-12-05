function [f,Df] = objFun(x,params)
A = params.Ag;
b = params.bg;
f = 0.5*x'*A'*A*x - x'*A'*b+b'*b;
df = A'*A*x - A'*b;
end