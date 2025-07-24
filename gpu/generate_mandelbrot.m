function [mandelbrot_img, execution_time] = generate_mandelbrot()
    % Inicia o cronômetro para medir o tempo de execução
    tic;

    %% 1. Definição dos Parâmetros
    % Parâmetros empíricos sugeridos
    grid_size = 1000;    % Resolução da imagem (1000x1000 pixels)
    max_iter = 500;      % Número máximo de iterações por ponto

    % Limites do plano complexo (região de visualização)
    % O conjunto de Mandelbrot está contido principalmente entre -2 e 1 no eixo real
    % e -1.5 e 1.5 no eixo imaginário.
    x_lim = [-2.0, 1.0];
    y_lim = [-1.5, 1.5];

    %% 2. Mapeamento do Plano Complexo para o Plano de Imagem
    % Cria vetores para os eixos real (x) e imaginário (y).
    % linspace cria um vetor de 'grid_size' pontos igualmente espaçados.
    x = linspace(x_lim(1), x_lim(2), grid_size);
    y = linspace(y_lim(1), y_lim(2), grid_size);

    % Inicializa a matriz que irá conter a imagem final.
    % Cada elemento guardará o número de iterações para o ponto correspondente escapar.
    % Inicializamos com 'max_iter' para que os pontos que pertencem ao conjunto
    % (que nunca escapam) fiquem com a cor máxima.
    mandelbrot_matrix = max_iter * ones(grid_size, grid_size);

    %% 3. Iteração sobre cada Ponto (Pixel) da Grade
    % Este é o núcleo do algoritmo. Vamos testar cada ponto 'c'.
    for row = 1:grid_size
        for col = 1:grid_size
            % Pega o valor do eixo imaginário (y) e real (x) para este pixel.
            % Note que 'row' corresponde ao eixo Y e 'col' ao eixo X.
            % Em MATLAB, o eixo Y é invertido em matrizes, então usamos y(grid_size - row + 1)
            % para a orientação correta da imagem, ou simplesmente transpomos no final.
            % Vamos fazer da forma mais simples:
            c_imag = y(row);
            c_real = x(col);
            c = c_real + 1i * c_imag; % Forma o número complexo 'c'

            % Inicializa a sequência de Mandelbrot para este 'c'
            z = 0; % Z0 = 0 é a definição padrão do conjunto de Mandelbrot

            % Loop de iteração para a sequência Z(n+1) = Z(n)^2 + c
            for n = 1:max_iter
                % Aplica a fórmula
                z = z^2 + c;

                % Verifica a condição de escape
                if abs(z) > 2
                    % O ponto escapou! Armazena o número de iterações 'n'
                    mandelbrot_matrix(row, col) = n;
                    % Interrompe o loop interno, pois não precisamos mais testar este ponto
                    break;
                end
            end
        end
        % Opcional: Mostrar progresso na janela de comando
        % if mod(row, 50) == 0
        %     fprintf('Processando linha %d de %d...\n', row, grid_size);
        % end
    end

    %% 4. Medição do Tempo e Geração da Imagem
    execution_time = toc; % Para o cronômetro e armazena o tempo
    fprintf('Tempo de execução (CPU Serial): %.4f segundos.\n', execution_time);

    % Cria o objeto da imagem
    mandelbrot_img = mandelbrot_matrix;

    % Exibe a imagem resultante
    figure; % Cria uma nova janela de figura
    imagesc(x, y, mandelbrot_img); % Usa imagesc para mapear valores para cores
    colormap(jet); % Aplica um mapa de cores (experimente 'hot', 'parula', 'turbo')
    colorbar; % Mostra a barra de cores
    axis equal; % Garante que a proporção da imagem não seja distorcida
    axis tight;
    title(sprintf('Conjunto de Mandelbrot (%d iterações)', max_iter));
    xlabel('Parte Real');
    ylabel('Parte Imaginária');
end