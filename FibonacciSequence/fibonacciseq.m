function fibonacciseq
    % Membuat figure GUI
    figure('Position',[500 300 350 250],'Name','Fibonacci Sequence Generator','NumberTitle','off');
    
    % Label dan input untuk angka pertama
    uicontrol('Style','text','Position',[30 200 120 20],'String','Angka pertama:');
    edit1 = uicontrol('Style','edit','Position',[160 200 150 25],'String','0');
    
    % Label dan input untuk angka kedua
    uicontrol('Style','text','Position',[30 160 120 20],'String','Angka kedua:');
    edit2 = uicontrol('Style','edit','Position',[160 160 150 25],'String','1');
    
    % Label dan input untuk panjang deret
    uicontrol('Style','text','Position',[30 120 120 20],'String','Panjang deret:');
    edit3 = uicontrol('Style','edit','Position',[160 120 150 25],'String','10');
    
    % Tombol generate
    uicontrol('Style','pushbutton','Position',[120 70 100 30],'String','Generate',...
        'Callback',@generate_callback);
    
    % Area output (edit multiline)
    output = uicontrol('Style','edit','Position',[30 10 280 50],'Max',2,'Enable','inactive');
    
    function generate_callback(~,~)
        % Ambil input dan konversi ke angka
        a = str2double(get(edit1,'String'));
        b = str2double(get(edit2,'String'));
        n = str2double(get(edit3,'String'));
        
        % Validasi input
        if isnan(a) || isnan(b) || isnan(n) || n<2 || floor(n)~=n
            set(output,'String','Input tidak valid! Panjang deret harus integer >= 2.');
            return;
        end
        
        % Inisialisasi deret
        fib = zeros(1,n);
        fib(1) = a;
        fib(2) = b;
        
        % Hitung deret Fibonacci
        for k = 3:n
            fib(k) = fib(k-1) + fib(k-2);
        end
        
        % Tampilkan hasil
        set(output,'String',num2str(fib));
    end
end