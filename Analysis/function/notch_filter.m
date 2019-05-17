function y = notch_filter(eeg, fs)
% Filter design for remove DC and industrial frequency component of EEG data .
%
% function y = notch_filter(eeg, fs, idx_fb)
%
% Input:
%   eeg             : Input eeg data
%                     (# of channels, Data length [sample], # of trials)
%   fs              : Sampling rate
%
% Output:
%   y               : Sub-band components decomposed by a filter bank.
%
%
% Mark 2018/03/08
% B504 of BeiHang University 

[num_chans, ~, num_trials] = size(eeg);
% Desigine for remove remove industrial frequency
Ts = 1/fs;
apha = -2*cos(2*pi*50*Ts);
beta = 0.96;
b = [1 apha 1];
a = [1 apha * beta beta^2];

% Desigine for remove remove DC component
f = fs/2;
Wp = [6/f, 90/f];
Ws = [4/f, 100/f];
[N, Wn]=cheb1ord(Wp, Ws, 3, 40);
[B, A] = cheby1(N, 0.5, Wn);

y = zeros(size(eeg));
if num_trials == 1
    for ch_i = 1:1:num_chans
        x(ch_i, :) = dlsim(b, a, filtfilt(B, A, eeg(ch_i, :)));
        y(ch_i, :) = dlsim(b, a, x(ch_i, :));
    end % ch_i
else
    for trial_i = 1:1:num_trials
        for ch_i = 1:1:num_chans
            x(ch_i, :, trial_i) = dlsim(b, a, filtfilt(B, A, eeg(ch_i, :, trial_i)));
            y(ch_i, :, trial_i) = dlsim(b, a, x(ch_i, :, trial_i));
        end % trial_i
    end % ch_i
end % if num_trials == 1