function [mandelbrot_img_af, execution_time_af] = generate_mandelbrot_gpu_arrayfun()
    % Verifica se uma GPU compatível está disponível
    if ~canUseGPU
        error('GPU não encontrada ou não suportada. Verifique sua instalação do Parallel Computing Toolbox.');
    end
    
    fprintf('Iniciando cálculo na GPU com arrayfun...\n');
    
    % Inicia o cronômetro
    tic;

    %% 1. Definição dos Parâmetros (idênticos para uma comparação justa)
    grid_size = 1000;
    max_iter = 500;
    x_lim = [-2.0, 1.0];
    y_lim = [-1.5, 1.5];

    %% 2. Mapeamento do Plano Complexo (na CPU)
    x = linspace(x_lim(1), x_lim(2), grid_size);
    y = linspace(y_lim(1), y_lim(2), grid_size);
    [X, Y] = meshgrid(x, y);
    C = X + 1i * Y';

    %% 3. Transferência de Dados para a GPU
    % Apenas a matriz 'C' precisa ser explicitamente transferida
    C_gpu = gpuArray(C);

    %% 4. Execução Paralela com arrayfun
    % Chamamos arrayfun, passando um "function handle" (@mandelbrot_kernel)
    % e os argumentos para a função kernel.
    % O MATLAB executa o kernel para cada elemento de C_gpu em paralelo.
    mandelbrot_gpu = arrayfun(@mandelbrot_kernel, C_gpu, max_iter);

    %% 5. Recuperação dos Dados da GPU
    % Trazemos o resultado de volta para a memória da CPU com gather()
    mandelbrot_img_af = gather(mandelbrot_gpu);

    execution_time_af = toc; % Para o cronômetro
    fprintf('Tempo de execução (GPU com arrayfun): %.4f segundos.\n', execution_time_af);

    % A parte de visualização é a mesma das versões anteriores
    figure;
    imagesc(x, y, mandelbrot_img_af);
    colormap(jet);
    colorbar;
    axis equal;
    axis tight;
    title(sprintf('Conjunto de Mandelbrot (GPU com arrayfun, %d iterações)', max_iter));
    xlabel('Parte Real');
    ylabel('Parte Imaginária');
end

% --- Função Kernel ---
% Esta função contém a lógica para UM ÚNICO ponto 'c'.
% O MATLAB irá compilar esta função para ser executada na GPU.
function iterations = mandelbrot_kernel(c, max_iter)
    z = 0;
    for n = 1:max_iter
        z = z^2 + c;
        if abs(z) > 2
            iterations = n; % Retorna o número da iteração de escape
            return;         % Encerra a função para este ponto
        end
    end
    iterations = max_iter; % Se não escapou, retorna o máximo de iterações
end