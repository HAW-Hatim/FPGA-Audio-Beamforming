clear all;

N = 32; %FFT size
TwiddleFactor_real = zeros(1,N);
TwiddleFactor_imag = zeros(1,N);

    % Compute the k-th frequency component
    TwiddleFactor_val = exp(-2 * pi * 1i * (0:N) / N);
    TwiddleFactor_real(1:N+1) = real(TwiddleFactor_val);
    TwiddleFactor_imag(1:N+1) = imag(TwiddleFactor_val);
    
T24 = numerictype(1,24,23); % 1Q23
T16 = numerictype(1,16,15); % 1Q15
T8 = numerictype(1,8,7); % 1Q7
T12 = numerictype(1,12,11); % 1Q7
T10 = numerictype(1,10,9); % 1Q7

% Convert the twiddle factors to fixed-point representation
TwiddleFactor_real_fixed = fi(TwiddleFactor_real, T10);
TwiddleFactor_imag_fixed = fi(TwiddleFactor_imag, T10);

real_bi = arrayfun(@(x) bin(x), TwiddleFactor_real_fixed, 'UniformOutput', false);
imag_bi = arrayfun(@(x) bin(x), TwiddleFactor_imag_fixed, 'UniformOutput', false);


% Example inputs (replace with your actual variables)
% real_bi = arrayfun(@(x) bin(x), TwiddleFactor_real_fixed, 'UniformOutput', false);
% imag_bi = arrayfun(@(x) bin(x), TwiddleFactor_imag_fixed, 'UniformOutput', false);

% Ensure both are cell arrays of strings
if ischar(real_bi)
    real_cell = cellstr(real_bi);     % Nx1
else
    real_cell = real_bi(:);           % ensure column
end
if ischar(imag_bi)
    imag_cell = cellstr(imag_bi);
else
    imag_cell = imag_bi(:);
end

N = numel(real_cell);
if numel(imag_cell) ~= N
    error('real_bi and imag_bi must have the same number of elements.');
end

fname = 'twiddle_pairs.txt';
fid = fopen(fname, 'w');
if fid < 0
    error('Unable to open file for writing: %s', fname);
end

for k = 1:N
    % Format: (Real=> <real>, Imag => <imag>),
    fprintf(fid, '(Real=> "%s", Imag => "%s"),\n', real_cell{k}, imag_cell{k});
end

fclose(fid);
fprintf('Wrote %d entries to %s\n', N, fname);
