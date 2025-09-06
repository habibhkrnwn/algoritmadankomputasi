function leapYearApp
% Leap Year Calculator - Versi Optimasi dan Redesain
% Mendukung input tunggal, multiple (comma/space-separated), dan rentang

    % Cek versi MATLAB untuk kompatibilitas
    matlabVersion = version('-release');
    yearNum = str2double(matlabVersion(1:4));
    if yearNum < 2018
        error('Aplikasi ini memerlukan MATLAB R2018a atau lebih baru untuk UI modern.');
    end

    % --- SETUP UI ---
    fig = uifigure('Name', 'Leap Year Calculator', ...
                   'Position', [300 300 600 480], ...
                   'Resize', 'off', ...
                   'Color', [0.95 0.97 1]);

    % Grid layout utama
    mainGrid = uigridlayout(fig, [8, 1]);
    mainGrid.RowHeight = {60, 30, 70, 250, 40, 30, 20, 20};
    mainGrid.Padding = [25 25 25 25];
    mainGrid.RowSpacing = 12;

    % Header
    titleLabel = uilabel(mainGrid, 'Text', 'Leap Year Calculator', ...
                        'FontSize', 26, 'FontWeight', 'bold', ...
                        'HorizontalAlignment', 'center', ...
                        'FontColor', [0.1 0.3 0.7]);
    titleLabel.Layout.Row = 1;

    % Instruksi
    instrLabel = uilabel(mainGrid, ...
                        'Text', ['Masukkan tahun dengan format:', newline, ...
                                 '- Tahun tunggal: 2024', newline, ...
                                 '- Multiple tahun (pisah koma/spasi): 2020, 2021 2024', newline, ...
                                 '- Rentang tahun: 2010-2015'], ...
                        'FontSize', 11, 'FontAngle', 'italic', ...
                        'HorizontalAlignment', 'center', ...
                        'FontColor', [0.4 0.4 0.4]);
    instrLabel.Layout.Row = 2;

    % Panel input
    inputPanel = uipanel(mainGrid, 'Title', 'Input Tahun', ...
                        'FontWeight', 'bold', ...
                        'BackgroundColor', [0.9 0.93 1]);
    inputPanel.Layout.Row = 3;

    inputGrid = uigridlayout(inputPanel, [2, 3]);
    inputGrid.RowHeight = {30, 30};
    inputGrid.ColumnWidth = {'1x', 120, 60};
    inputGrid.Padding = [15 15 15 10];
    inputGrid.RowSpacing = 10;
    inputGrid.ColumnSpacing = 15;

    % Edit field untuk input
    yearEditField = uieditfield(inputGrid, 'text', ...
                               'Value', '', ...
                               'Placeholder', 'Masukkan tahun...', ...
                               'FontSize', 14);
    yearEditField.Layout.Row = 1;
    yearEditField.Layout.Column = [1 2];

    % Tombol Check
    checkButton = uibutton(inputGrid, 'Text', 'Check', ...
                          'FontSize', 14, 'FontWeight', 'bold', ...
                          'BackgroundColor', [0.15 0.6 0.15], ...
                          'FontColor', 'white', ...
                          'ButtonPushedFcn', @(~,~) processInput());
    checkButton.Layout.Row = 1;
    checkButton.Layout.Column = 3;

    % Tombol Clear
    clearButton = uibutton(inputGrid, 'Text', 'Clear', ...
                          'FontSize', 12, ...
                          'BackgroundColor', [0.85 0.85 0.85], ...
                          'ButtonPushedFcn', @(~,~) clearAll());
    clearButton.Layout.Row = 2;
    clearButton.Layout.Column = [2 3];

    % Tabel hasil
    resultTable = uitable(mainGrid, ...
                         'ColumnName', {'Tahun', 'Status Kabisat'}, ...
                         'ColumnWidth', {120, 180}, ...
                         'RowName', {}, ...
                         'ColumnEditable', [false, false], ...
                         'FontSize', 13);
    resultTable.Layout.Row = 4;

    % Label status
    statusLabel = uilabel(mainGrid, ...
                         'Text', 'Status: Siap menerima input...', ...
                         'FontSize', 13, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center', ...
                         'FontColor', [0.2 0.2 0.6]);
    statusLabel.Layout.Row = 5;

    % Informasi tambahan
    infoLabel = uilabel(mainGrid, ...
                       'Text', 'Tahun kabisat: habis dibagi 400, atau habis dibagi 4 tapi tidak habis dibagi 100', ...
                       'FontSize', 10, 'FontAngle', 'italic', ...
                       'HorizontalAlignment', 'center', ...
                       'FontColor', [0.5 0.5 0.5]);
    infoLabel.Layout.Row = 6;

    % Footer
    footerLabel = uilabel(mainGrid, ...
                         'Text', '© Leap Year Calculator 2025', ...
                         'FontSize', 9, ...
                         'HorizontalAlignment', 'center', ...
                         'FontColor', [0.6 0.6 0.6]);
    footerLabel.Layout.Row = 7;

    % Spacer row (kosong)
    spacerLabel = uilabel(mainGrid, 'Text', '');
    spacerLabel.Layout.Row = 8;

    % --- CALLBACKS ---

    % Callback untuk Enter key di edit field
    yearEditField.ValueChangedFcn = @(src,~) processInput();

    % Fungsi proses input
    function processInput()
        inputText = strtrim(yearEditField.Value);

        if isempty(inputText)
            uialert(fig, 'Silakan masukkan tahun terlebih dahulu!', 'Input Kosong', 'Icon', 'warning');
            return;
        end

        try
            years = parseYearInput(inputText);

            if isempty(years)
                uialert(fig, 'Tidak ada tahun valid yang ditemukan!', 'Input Error', 'Icon', 'error');
                return;
            end

            % Proses dan tampilkan hasil
            [yearList, statusList] = checkLeapYears(years);

            % Update tabel
            tableData = [num2cell(yearList), statusList];
            resultTable.Data = tableData;

            % Update status
            leapCount = sum(strcmp(statusList, 'Kabisat'));
            notLeapCount = sum(strcmp(statusList, 'Bukan Kabisat'));
            invalidCount = sum(strcmp(statusList, 'Invalid'));

            statusText = sprintf('Hasil: %d Kabisat, %d Bukan Kabisat', leapCount, notLeapCount);
            if invalidCount > 0
                statusText = [statusText, sprintf(', %d Invalid', invalidCount)];
                statusLabel.FontColor = [0.85 0.45 0.1];  % Orange untuk warning
            else
                statusLabel.FontColor = [0.1 0.6 0.1];  % Hijau untuk sukses
            end

            statusLabel.Text = statusText;

        catch ME
            uialert(fig, ME.message, 'Error', 'Icon', 'error');
        end
    end

    % Fungsi clear semua input dan hasil
    function clearAll()
        yearEditField.Value = '';
        resultTable.Data = {};
        statusLabel.Text = 'Status: Siap menerima input...';
        statusLabel.FontColor = [0.2 0.2 0.6];

        % Fokus kembali ke input
        try
            focus(yearEditField);
        catch
            try
                uifocus(yearEditField);
            catch
                % Abaikan jika tidak bisa fokus
            end
        end
    end

end

% --- FUNGSI HELPER ---

function years = parseYearInput(inputStr)
    % Parse input string menjadi array tahun
    % Mendukung format: "2020", "2020,2021 2024", "2010-2015", campuran

    years = [];

    % Ganti semua koma dan spasi berturut-turut menjadi satu spasi
    inputStr = regexprep(inputStr, '[, ]+', ' ');

    % Pisahkan berdasarkan spasi
    parts = strsplit(strtrim(inputStr), ' ');

    for i = 1:length(parts)
        part = strtrim(parts{i});
        if isempty(part)
            continue;
        end

        % Cek apakah ada rentang (menggunakan dash/hyphen)
        if contains(part, '-')
            rangeParts = strsplit(part, '-');
            if numel(rangeParts) == 2
                startYear = str2double(strtrim(rangeParts{1}));
                endYear = str2double(strtrim(rangeParts{2}));

                if isnan(startYear) || isnan(endYear)
                    error('Format rentang tidak valid: %s', part);
                end

                if startYear <= endYear
                    years = [years, startYear:endYear]; %#ok<AGROW>
                else
                    years = [years, startYear:-1:endYear]; %#ok<AGROW>
                end
            else
                error('Format rentang tidak valid: %s', part);
            end
        else
            % Single year
            year = str2double(part);
            if isnan(year)
                error('Tahun tidak valid: %s', part);
            end
            years = [years, year]; %#ok<AGROW>
        end
    end

    % Hapus duplikat dan urutkan
    years = unique(round(years));
end

function [yearList, statusList] = checkLeapYears(years)
    % Cek status kabisat untuk array tahun
    yearList = years(:);  % Konversi ke column vector
    statusList = cell(length(years), 1);

    for i = 1:length(years)
        year = years(i);

        % Validasi tahun
        if year <= 0 || ~isfinite(year) || floor(year) ~= year
            statusList{i} = 'Invalid';
            continue;
        end

        % Cek kabisat menggunakan aturan Gregorian
        if mod(year, 400) == 0
            statusList{i} = 'Kabisat';
        elseif mod(year, 100) == 0
            statusList{i} = 'Bukan Kabisat';
        elseif mod(year, 4) == 0
            statusList{i} = 'Kabisat';
        else
            statusList{i} = 'Bukan Kabisat';
        end
    end
end