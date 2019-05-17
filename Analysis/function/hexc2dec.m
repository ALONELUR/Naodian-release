function y = hexc2dec_24(hex)

temp = hex2dec(hex);
bin = dec2bin(temp);

while(length(bin) < 24)
    bin = ['0',bin];
end

if(bin(1) == '1')%负数
    bin(2:24) = 97 - bin(2:24);%取反  为什么是97?
    y = -(bin2dec(bin(2:24))+1);
else
    %y = bin2dec(bin(2:24));
    y = temp;
end