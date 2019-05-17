function results = test_fbcca_total(eeg, list_freqs, fs, num_harms, num_fbs)
% Steady-state visual evoked potentials (SSVEPs) detection using the filter
% bank canonical correlation analysis (FBCCA)-based method [1].
% 
% function results = test_fbcca(eeg, list_freqs, fs, num_harms, num_fbs)
%
% Input:
%   eeg             : Input eeg data 
%                     (# of targets, # of channels, Data length [sample])
%   list_freqs      : List for stimulus frequencies
%   fs              : Sampling frequency
%   num_harms       : # of harmonics
%   num_fbs         : # of filters in filterbank analysis
%
% Output:
%   results         : The target estimated by this method
%
%
% Mark, 2018/03/14

if nargin < 3
    error('stats:test_fbcca:LackOfInput', 'Not enough input arguments.'); 
end

if ~exist('num_harms', 'var') || isempty(num_harms), num_harms = 3; end

if ~exist('num_fbs', 'var') || isempty(num_fbs), num_fbs = 5; end

fb_coefs = (1:num_fbs).^(-1.25)+0.25;

% [ ~, num_smpls, num_targs] = size(eeg);
[ ~, num_smpls, ~] = size(eeg);
num_freqs = length(list_freqs);
y_ref = cca_reference(list_freqs, fs, num_smpls, num_harms);

results=zeros(1,num_freqs);
r = zeros(num_fbs,num_freqs);

for targ_i = 1:1:1
     test_tmp = eeg;
     for fb_i = 1:1:num_fbs
         testdata = filterbank(test_tmp, fs, fb_i);
         for class_i = 1:1:num_freqs
             refdata = squeeze(y_ref( :, :, class_i));         
             [~,~,r_tmp] = canoncorr(testdata', refdata');
             r(fb_i,class_i) = r_tmp(1,1);            
         end % class_i
     end % fb_i
%     results = fb_coefs * r; %rho  %%%20190309锟睫革拷
%     [~, tau] = max(rho);
%     results(targ_i) = tau;
    results(targ_i,:) = fb_coefs * r;
    
end% targ_i