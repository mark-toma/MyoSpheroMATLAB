function S = skewBlock(B)
% tiles matrix block B into the skew pattern to create S
Z = B*0;
S = [Z,-B,B;B,Z,-B;-B,B,Z];
if isa(B,'sym'),S = sym(S); end

