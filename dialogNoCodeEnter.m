function dialogNoCodeEnter(dancer)
        d = dialog('Position',[700 300 250 150],'Name','Invalid Code');
        toDisplay = strcat('Hello, ', dancer, '! Please enter a valid dance''s code.');
        txt = uicontrol('Parent',d,...
                   'Style','text',...
                   'FontSize', 12, ... 
                   'Position',[20 80 210 40],...
                   'String',toDisplay);

        btn = uicontrol('Parent',d,...
                   'Position',[85 15 75 35],...
                   'FontSize', 14, ... 
                   'String','Sorry!',...
                   'Callback','delete(gcf)');
end