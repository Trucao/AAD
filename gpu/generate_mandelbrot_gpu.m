function [mandelbrot_img_gpu, execution_time_gpu] = generate_mandelbrot_gpu()
    % Verifica se uma GPU compatível está disponível
    if ~canUseGPU
        error('GPU não encontrada ou não suportada. Verifique sua instalação do Parallel Computing Toolbox.');
    end
    
    fprintf('Iniciando cálculo na GPU...\n');
    
    % Inicia o cronômetro para medir o tempo de execução
    tic;

    %% 1. Definição dos Parâmetros (os mesmos da versão CPU para uma comparação justa)
    grid_size = 1000;
    max_iter = 500;
    x_lim = [-2.0, 1.0];
    y_lim = [-1.5, 1.5];

    %% 2. Mapeamento do Plano Complexo (ainda na CPU)
    x = linspace(x_lim(1), x_lim(2), grid_size);
    y = linspace(y_lim(1), y_lim(2), grid_size);
    [X, Y] = meshgrid(x, y);
    
    % A matriz de pontos 'c' é criada na CPU.
    % Note que Y é transposto para corresponder à orientação da imagem
    C = X + 1i * Y'; 

    %% 3. Transferência de Dados para a GPU
    % Usamos gpuArray para mover as matrizes para a memória da GPU.
    % A partir daqui, todas as operações nessas matrizes ocorrerão na GPU.
    C_gpu = gpuArray(C);
    Z_gpu = gpuArray(zeros(grid_size, grid_size));
    mandelbrot_gpu = gpuArray(max_iter * ones(grid_size, grid_size));

    %% 4. Loop de Iteração Paralelo na GPU
    % O loop agora itera de 'n=1' a 'max_iter', e dentro do loop,
    % a operação é aplicada a TODA a matriz de uma só vez.
    for n = 1:max_iter
        % Z = Z^2 + C, executado para todos os 1 milhão de pontos em paralelo na GPU
        Z_gpu = Z_gpu.^2 + C_gpu;

        % Cria uma máscara lógica para encontrar os pontos que escaparam NESTA iteração
        % Condições:
        % 1. O módulo de Z é > 2
        % 2. O ponto ainda não foi marcado como "escapado" (seu valor ainda é max_iter)
        mask = abs(Z_gpu) > 2 & mandelbrot_gpu == max_iter;
        
        % Usa a máscara para atualizar APENAS os pontos que acabaram de escapar,
        % marcando-os com a iteração atual 'n'.
        mandelbrot_gpu(mask) = n;
    end

    %% 5. Recuperação dos Dados da GPU
    % Para visualizar a imagem, precisamos trazer os resultados de volta
    % para a memória principal da CPU com a função gather().
    mandelbrot_img_gpu = gather(mandelbrot_gpu);

    execution_time_gpu = toc; % Para o cronômetro
    fprintf('Tempo de execução (GPU Paralelo): %.4f segundos.\n', execution_time_gpu);
    
    % A parte de visualização é a mesma da versão CPU
    figure;
    imagesc(x, y, mandelbrot_img_gpu);
    colormap(jet);
    colorbar;
    axis equal;
    axis tight;
    title(sprintf('Conjunto de Mandelbrot (GPU, %d iterações)', max_iter));
    xlabel('Parte Real');
    ylabel('Parte Imaginária');
end