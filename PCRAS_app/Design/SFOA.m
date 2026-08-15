function [xposbest,error,used_time,AA,Curve] = SFOA(Npop,Max_it,lb,ub,nD,fobj,fit,iterCallback)
% =========================================================================
% SFOA - Starfish Optimization Algorithm for PMRICRAS-GDMS parameter fitting
%
% Inputs:
%   Npop         - Population size
%   Max_it       - Maximum iterations
%   lb, ub       - Lower/upper bounds for each dimension (scalar or vector)
%   nD           - Number of dimensions (optimization variables)
%   fobj         - Objective function handle (@P_MRICRAS_func)
%   fit          - Experimental data vector
%   iterCallback - (Optional) function handle called each iteration:
%                  stop = iterCallback(T, Max_it, fvalbest, xposbest, elapsed)
%                  Return true to stop optimization early.
%
% Outputs:
%   xposbest     - Best parameter vector found
%   error        - Final RMSE error (%)
%   used_time    - Total elapsed time (seconds)
%   AA           - Fit comparison data [index, experiment, fitted, difference]
%   Curve        - Convergence curve (row vector of best error per iteration)
% =========================================================================
global startpoint endpoint

%% Initialization
GP = 0.5;  % SFOA parameter: exploration/exploitation threshold

% Expand scalar bounds to vector
if size(ub, 2) == 1
    lb = lb * ones(1, nD);
    ub = ub * ones(1, nD);
end

fvalbest = inf;
Curve = zeros(1, Max_it);

% Initialize population
Xpos = rand(Npop, nD) .* (ub - lb) + lb;
Xpos(:, 3:4) = round(Xpos(:, 3:4), 1);

% Evaluate initial fitness
Fitness = zeros(1, Npop);
for i = 1:Npop
    I_MRI_cra = fobj(Xpos(i, :));
    Fitness(i) = 100 * sqrt(mean((I_MRI_cra(startpoint:endpoint) - fit(startpoint:endpoint)).^2));
end
[fvalbest, order] = min(Fitness);
xposbest = Xpos(order, :);

newX = zeros(Npop, nD);
Cumulative_time = zeros(Max_it, 1);
total_tic = tic;

%% Main iteration loop
T = 1;
while T <= Max_it
    theta = pi / 2 * T / Max_it;
    tEO = (Max_it - T) / Max_it * cos(theta);

    % ---- Exploration phase ----
    if rand < GP
        for i = 1:Npop
            if nD > 5
                jp1 = randperm(nD, 5);
                for j = 1:5
                    pm = (2 * rand - 1) * pi;
                    if rand < GP
                        newX(i, jp1(j)) = Xpos(i, jp1(j)) + pm * (xposbest(jp1(j)) - Xpos(i, jp1(j))) * cos(theta);
                    else
                        newX(i, jp1(j)) = Xpos(i, jp1(j)) - pm * (xposbest(jp1(j)) - Xpos(i, jp1(j))) * sin(theta);
                    end
                    if newX(i, jp1(j)) > ub(jp1(j)) || newX(i, jp1(j)) < lb(jp1(j))
                        newX(i, jp1(j)) = Xpos(i, jp1(j));
                    end
                end
            else
                jp2 = ceil(nD * rand);
                im = randperm(Npop);
                rand1 = 2 * rand - 1;
                rand2 = 2 * rand - 1;
                newX(i, jp2) = tEO * Xpos(i, jp2) + rand1 * (Xpos(im(1), jp2) - Xpos(i, jp2)) + rand2 * (Xpos(im(2), jp2) - Xpos(i, jp2));
                if newX(i, jp2) > ub(jp2) || newX(i, jp2) < lb(jp2)
                    newX(i, jp2) = Xpos(i, jp2);
                end
            end
            newX(i, :) = max(min(newX(i, :), ub), lb);
        end

    % ---- Exploitation phase ----
    else
        df = randperm(Npop, min(5, Npop));
        nArms = length(df);
        dm = zeros(nArms, nD);
        for k = 1:nArms
            dm(k, :) = xposbest - Xpos(df(k), :);
        end
        for i = 1:Npop
            r1 = rand; r2 = rand;
            if nArms >= 2
                kp = randperm(nArms, 2);
                newX(i, :) = Xpos(i, :) + r1 * dm(kp(1), :) + r2 * dm(kp(2), :);
            else
                newX(i, :) = Xpos(i, :) + r1 * dm(1, :);
            end
            if i == Npop
                newX(i, :) = exp(-T * Npop / Max_it) .* Xpos(i, :);
            end
            newX(i, :) = max(min(newX(i, :), ub), lb);
        end
    end

    newX(:, 3:4) = round(newX(:, 3:4), 1);

    % ---- Fitness evaluation & update ----
    for i = 1:Npop
        I_MRI_cra = fobj(newX(i, :));
        newFit = 100 * sqrt(mean((I_MRI_cra(startpoint:endpoint) - fit(startpoint:endpoint)).^2));
        if newFit < Fitness(i)
            Fitness(i) = newFit;
            Xpos(i, :) = newX(i, :);
            if newFit < fvalbest
                fvalbest = Fitness(i);
                xposbest = Xpos(i, :);
            end
        end
    end

    Curve(T) = fvalbest;
    Cumulative_time(T) = toc(total_tic);

    % ---- Iteration callback (real-time UI update / early stop) ----
    if nargin >= 8 && ~isempty(iterCallback) && isa(iterCallback, 'function_handle')
        try
            stopEarly = iterCallback(T, Max_it, fvalbest, xposbest, Cumulative_time(T));
            if stopEarly
                disp(['SFOA stopped by user at iteration ' num2str(T)]);
                Curve = Curve(1:T);
                Cumulative_time = Cumulative_time(1:T);
                break;
            end
        catch
            % If callback fails, continue optimization silently
        end
    end

    if nargin < 8 || isempty(iterCallback)
        disp(['Iteration ' num2str(T) ': Best Wucha = ' num2str(fvalbest) '%' ...
              ', Elapsed Time = ' num2str(Cumulative_time(T)) ' seconds' ...
              ', best sigema_0 sigema_k b_FR p_FR q_A q_B = ' num2str(xposbest(1:6)) ...
              ', best obj_tn = ' num2str(xposbest(7:end))]);
    end

    drawnow;  % Yield to UI event loop
    T = T + 1;
end

%% Extract results
result = fobj(xposbest);
error = 100 * sqrt(mean((result(startpoint:endpoint) - fit(startpoint:endpoint)).^2));
used_time = Cumulative_time(end);

%% Plotting (standalone mode — when no callback provided)
if nargin < 8 || isempty(iterCallback)
    figure;
    plot(1:length(Curve), Curve, 'LineWidth', 2);
    xlabel('Iteration');
    ylabel('Error');
    title('Error Convergence Curve');
    grid on;

    figure;
    x = 1:length(fit);
    plot(x, fit, '-b', 'DisplayName', 'Experiment');
    hold on;
    plot(x, result, '-r', 'DisplayName', 'Fitted');
    plot(x, fit - result, '-g', 'DisplayName', 'Difference');
    xlabel('Points');
    ylabel('Values');
    legend;
    title('Comparison: Experiment vs Fitted vs Difference');
    grid on;
    str = sprintf('RMSE = %.2f%%', error);
    text(0.6, 0.8, str, 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'red');
    hold off;
end

AA = [(1:length(fit))', fit, result, fit - result];

end
