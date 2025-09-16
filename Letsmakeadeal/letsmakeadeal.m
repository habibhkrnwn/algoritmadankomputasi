function monty_hall_simulator()
% MONTY HALL SIMULATOR - MATLAB Version
% =====================================
% Shows results in command window and creates plot only

    fprintf('🚪 Monty Hall Problem - MATLAB Simulator\n');
    fprintf('==========================================\n\n');
    
    % Parameters
    min_doors = 3;
    max_doors = 15;
    trials = 50000;
    
    % Initialize results arrays
    doors_range = min_doors:max_doors;
    n_tests = length(doors_range);
    
    stay_actual = zeros(1, n_tests);
    switch_actual = zeros(1, n_tests);
    stay_theory = zeros(1, n_tests);
    switch_theory = zeros(1, n_tests);
    
    % Run simulations for each number of doors
    fprintf('Running simulations...\n');
    fprintf('Doors | Stay (Act/Thy) | Switch (Act/Thy) | Advantage\n');
    fprintf('------|----------------|------------------|----------\n');
    
    for i = 1:n_tests
        n_doors = doors_range(i);
        
        % Run simulation with full door tracking
        [stay_rate, switch_rate] = simulate_monty_hall(n_doors, trials);
        
        % Calculate theoretical probabilities
        [stay_th, switch_th] = calculate_theoretical(n_doors);
        
        % Store results
        stay_actual(i) = stay_rate;
        switch_actual(i) = switch_rate;
        stay_theory(i) = stay_th;
        switch_theory(i) = switch_th;
        
        % Display results in formatted table
        fprintf('%4d  | %.3f/%.3f   | %.3f/%.3f    | %.1fx\n', ...
                n_doors, stay_rate, stay_th, switch_rate, switch_th, ...
                switch_rate/stay_rate);
    end
    
    % Display key insights
    fprintf('\n🎯 KEY INSIGHTS: What Happens When We Add More Doors?\n');
    fprintf('=====================================================\n');
    
    % Show specific examples
    idx_3 = find(doors_range == 3);
    idx_5 = find(doors_range == 5);
    idx_10 = find(doors_range == 10);
    idx_15 = find(doors_range == 15);
    
    fprintf('🚪 3 doors:  Switch = %.1f%%, Stay = %.1f%% (%.1fx better)\n', ...
            switch_actual(idx_3)*100, stay_actual(idx_3)*100, switch_actual(idx_3)/stay_actual(idx_3));
    fprintf('🚪 5 doors:  Switch = %.1f%%, Stay = %.1f%% (%.1fx better)\n', ...
            switch_actual(idx_5)*100, stay_actual(idx_5)*100, switch_actual(idx_5)/stay_actual(idx_5));
    fprintf('🚪 10 doors: Switch = %.1f%%, Stay = %.1f%% (%.1fx better)\n', ...
            switch_actual(idx_10)*100, stay_actual(idx_10)*100, switch_actual(idx_10)/stay_actual(idx_10));
    fprintf('🚪 15 doors: Switch = %.1f%%, Stay = %.1f%% (%.1fx better)\n', ...
            switch_actual(idx_15)*100, stay_actual(idx_15)*100, switch_actual(idx_15)/stay_actual(idx_15));
    
    fprintf('\n📈 PATTERN OBSERVED:\n');
    fprintf('   • Stay probability decreases: 1/N = %.3f → %.3f\n', stay_actual(1), stay_actual(end));
    fprintf('   • Switch probability increases: (N-1)/N = %.3f → %.3f\n', switch_actual(1), switch_actual(end));
    fprintf('   • Switch advantage grows: %.1fx → %.1fx\n', switch_actual(1)/stay_actual(1), switch_actual(end)/stay_actual(end));
    
    fprintf('\n💡 CONCLUSION: With more doors, switching becomes even more powerful!\n');
    fprintf('   If we had 100 doors: Switch would win 99%% of the time!\n\n');
    
    % Create plot
    create_plot(doors_range, stay_actual, switch_actual, stay_theory, switch_theory);
end

function [stay_win_rate, switch_win_rate] = simulate_monty_hall(n_doors, n_trials)
% Simulate Monty Hall with full door tracking

    stay_wins = 0;
    switch_wins = 0;
    
    for trial = 1:n_trials
        % Setup game
        prize_door = randi(n_doors);
        initial_choice = randi(n_doors);
        
        % Host opens doors (complex tracking)
        [final_stay_door, final_switch_door] = simulate_host_actions(n_doors, prize_door, initial_choice);
        
        % Check wins
        if final_stay_door == prize_door
            stay_wins = stay_wins + 1;
        end
        
        if final_switch_door == prize_door
            switch_wins = switch_wins + 1;
        end
    end
    
    stay_win_rate = stay_wins / n_trials;
    switch_win_rate = switch_wins / n_trials;
end

function [final_stay_door, final_switch_door] = simulate_host_actions(n_doors, prize_door, initial_choice)
% Complex door tracking - simulates exactly what the host does

    all_doors = 1:n_doors;
    
    % Doors that host can open (not prize, not initial choice)
    available_to_open = all_doors(all_doors ~= prize_door & all_doors ~= initial_choice);
    
    % Host opens n_doors-2 doors, leaving initial choice and one other
    doors_to_open = n_doors - 2;
    
    % Track which doors remain closed
    closed_doors = all_doors;
    
    % Host opens doors one by one
    for i = 1:doors_to_open
        if ~isempty(available_to_open)
            % Host randomly picks a door to open
            open_idx = randi(length(available_to_open));
            door_to_open = available_to_open(open_idx);
            
            % Remove opened door from closed list
            closed_doors = closed_doors(closed_doors ~= door_to_open);
            
            % Remove from available list
            available_to_open = available_to_open(available_to_open ~= door_to_open);
        end
    end
    
    % Final doors: initial choice (stay) and one other (switch)
    final_stay_door = initial_choice;
    
    remaining_doors = closed_doors(closed_doors ~= initial_choice);
    if ~isempty(remaining_doors)
        final_switch_door = remaining_doors(1);
    else
        final_switch_door = initial_choice;
    end
end

function [stay_prob, switch_prob] = calculate_theoretical(n_doors)
% Calculate theoretical probabilities
    stay_prob = 1 / n_doors;
    switch_prob = (n_doors - 1) / n_doors;
end

function create_plot(doors_range, stay_actual, switch_actual, stay_theory, switch_theory)
% Create single comprehensive plot

    figure('Position', [100, 100, 1000, 700]);
    
    % Main plot
    subplot(2, 1, 1);
    plot(doors_range, stay_actual*100, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
    hold on;
    plot(doors_range, switch_actual*100, 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
    plot(doors_range, stay_theory*100, 'b--', 'LineWidth', 1.5);
    plot(doors_range, switch_theory*100, 'r--', 'LineWidth', 1.5);
    
    xlabel('Number of Doors', 'FontSize', 12);
    ylabel('Win Probability (%)', 'FontSize', 12);
    title('Monty Hall: Effect of Adding More Doors', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Stay (Simulation)', 'Switch (Simulation)', 'Stay (Theory)', 'Switch (Theory)', ...
           'Location', 'best', 'FontSize', 11);
    grid on;
    ylim([0 100]);
    
    % Add text annotations
    text(8, 80, sprintf('Switch Strategy:\nWins %.0f%% with 3 doors\nWins %.0f%% with 15 doors', ...
         switch_actual(1)*100, switch_actual(end)*100), ...
         'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    % Advantage plot
    subplot(2, 1, 2);
    advantage = switch_actual ./ stay_actual;
    plot(doors_range, advantage, 'go-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('Number of Doors', 'FontSize', 12);
    ylabel('Switch Advantage (Times Better)', 'FontSize', 12);
    title('How Much Better is Switching?', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % Add text annotation
    text(8, max(advantage)*0.8, sprintf('With 15 doors:\nSwitching is %.0fx better!', advantage(end)), ...
         'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    fprintf('📊 Plot created successfully!\n');
end

% Run the simulation
monty_hall_simulator();