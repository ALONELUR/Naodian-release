function yef = cca_ref_4_13(targ_fre, fs, sample_num)
%UNTITLED2 此处显示有关此函数的摘要
%   此处显示详细说明
    targ_num = size(targ_fre,2);
    t = linspace(0,sample_num/fs,sample_num);
    yef = zeros(2, sample_num, targ_num);
    for targ_i = 1:targ_num
        stim_fre = targ_fre(targ_i);
        yef(: ,: ,targ_i) = ...
            [sin(2*pi*stim_fre*t)+0.3*cos(4*pi*stim_fre*t) + 0.3*cos(8*pi*stim_fre*t);cos(2*pi*stim_fre*t)+0.3*sin(4*pi*stim_fre*t)+0.3*cos(8*pi*stim_fre*t)];
    end
end

