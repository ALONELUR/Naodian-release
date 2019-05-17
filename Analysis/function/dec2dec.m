function y = dec2dec(a,b,c)
% Calculate the SSVEP data to signal decimal 
% function [ y ] = dec2dec(a,b,c)
% 
% Input:
%   a   : first byte (dec)
%   b   : second byte (dec)
%   c   : third byte (dec)
%
% Output:
%   y : Combination three byte to decimal

y = a * 65536 + b * 256 + c;
if a  > 128
    y = y - 2^24;
end
