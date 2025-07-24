clear; clc; close all;

% --- 1. Execução da Versão Serial (CPU) ---
disp('--- Iniciando Versão Serial (CPU) ---');
try
    [~, time_cpu] = generate_mandelbrot();
catch ME
    disp(['Falha na execução da CPU: ' ME.message]);
    time_cpu = NaN;
end

disp(repmat('-', 1, 50));

% --- 2. Execução da Versão Paralela Vetorizada (GPU) ---
disp('--- Iniciando Versão Paralela Vetorizada (GPU) ---');
if gpuDeviceCount > 0
    try
        [~, time_gpu_vec] = generate_mandelbrot_gpu();
    catch ME
        disp(['Falha na execução da GPU Vetorizada: ' ME.message]);
        time_gpu_vec = NaN;
    end
else
    disp('GPU não encontrada. Pulando execuções de GPU.');
    time_gpu_vec = NaN;
end

disp(repmat('-', 1, 50));

% --- 3. Execução da Versão Paralela com arrayfun (GPU) ---
disp('--- Iniciando Versão Paralela com arrayfun (GPU) ---');
if gpuDeviceCount > 0
    try
        [~, time_gpu_af] = generate_mandelbrot_gpu_arrayfun();
    catch ME
        disp(['Falha na execução da GPU com arrayfun: ' ME.message]);
        time_gpu_af = NaN;
    end
else
    time_gpu_af = NaN;
end

disp(repmat('=', 1, 50));
disp('                RESULTADO FINAL DA COMPARAÇÃO');
disp(repmat('=', 1, 50));

% --- Análise dos Resultados ---
fprintf('Tempo de execução da CPU Serial:          %.4f s\n', time_cpu);
fprintf('Tempo de execução da GPU Vetorizada:      %.4f s\n', time_gpu_vec);
fprintf('Tempo de execução da GPU com arrayfun:    %.4f s\n', time_gpu_af);
fprintf('\n');

if ~isnan(time_cpu) && ~isnan(time_gpu_vec)
    speedup_vec_vs_cpu = time_cpu / time_gpu_vec;
    fprintf('-> Speedup (GPU Vetorizada vs. CPU):         %.2fx\n', speedup_vec_vs_cpu);
end

if ~isnan(time_cpu) && ~isnan(time_gpu_af)
    speedup_af_vs_cpu = time_cpu / time_gpu_af;
    fprintf('-> Speedup (GPU arrayfun vs. CPU):           %.2fx\n', speedup_af_vs_cpu);
end

if ~isnan(time_gpu_vec) && ~isnan(time_gpu_af)
    comparison = time_gpu_af / time_gpu_vec;
    fprintf('-> Comparação (arrayfun vs. Vetorizada):   A versão arrayfun foi %.2fx o tempo da vetorizada.\n', comparison);
    if comparison < 1
        fprintf('   (arrayfun foi mais rápida)\n');
    else
        fprintf('   (A versão vetorizada foi mais rápida)\n');
    end
end