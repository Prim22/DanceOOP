% View class
% handling all things related to showing GUI figure
classdef View < handle
    properties
        gui_h
        modelObj
        controlObj
        screenSize
        musicRawFile
        music
        recommendedImg % cell, hold the images to display
        dancer
        imagesFig
        checkboxes
        selectedImg
        selectedInd
        iniImg
        targetImg
        updateImg
        handImg
        feetImg
        count = 0;
        hfigure
    end
    methods
        function obj = View(modelObj)
            obj.modelObj = modelObj;
            obj.gui_h = guihandles(danceDemo333);   % get gui handle
            obj.screenSize = getScreenSize();
            obj.resetUI();

            obj.controlObj = Controller(obj, obj.modelObj); % create controller
            % set callback function for buttons
            obj.attachToController(obj.controlObj);
            S = load('resource/danceVisualEffects.mat');
            obj.handImg = S.hand;
            obj.feetImg = S.feet;
        end
        
        function resetUI(obj)
            obj.gui_h.editorPanel.Visible = 'on'; % temporary
            obj.gui_h.uiPanel1.Visible = 'off';  % temporary
            set(obj.gui_h.playBtn, 'Enable', 'off');
            set(obj.gui_h.stopBtn, 'Enable', 'off');
            set(obj.gui_h.doneBtn, 'Enable', 'off');
            set(obj.gui_h.selectImagesBtn, 'Enable', 'off');
            % Initial variables
            obj.recommendedImg = [];
            obj.selectedImg = obj.recommendedImg;
            obj.selectedInd = zeros(1,9);
            obj.targetImg = [];
            obj.updateImg = noiseImgGeneration(obj.screenSize);
            imshow(obj.updateImg, 'Parent', obj.gui_h.iniImg);

            obj.music = audioplayer(0, 80);
            obj.musicRawFile = [];
            obj.dancer = [];
            
            % define some images or plots
            obj.imagesFig ={};
            obj.checkboxes = {};
            for i = 1:9
                imgFig = strcat('obj.gui_h.imgFig', num2str(i));
                set(eval(imgFig), 'Visible', 'Off');
                obj.imagesFig{i,1} = eval(imgFig);

                checkbox = strcat('obj.gui_h.checkbox', num2str(i));
                set(eval(checkbox), 'Visible', 'Off');
                obj.checkboxes{i,1} = eval(checkbox);
            end
            obj.count = 0;
        end
        
        function attachToController(obj, controller)
            funcH = @controller.callback_checkBtn;
            set(obj.gui_h.checkBtn, 'callback', funcH);
            funcH = @controller.callback_noiseImgBtn;
            set(obj.gui_h.noiseImgBtn, 'callback', funcH);
            funcH = @controller.callback_userDefinedImgBtn;
            set(obj.gui_h.userDefinedImgBtn, 'callback', funcH);
            funcH = @controller.callback_chooseMusicBtn;
            set(obj.gui_h.chooseMusicBtn, 'callback', funcH);
            funcH = @controller.callback_playBtn;
            set(obj.gui_h.playBtn, 'callback', funcH);
            funcH = @controller.callback_stopBtn;
            set(obj.gui_h.stopBtn, 'callback', funcH);
            funcH = @controller.callback_doneBtn;
            set(obj.gui_h.doneBtn, 'callback', funcH);
            % add listener to sensorUpdated event
            obj.modelObj.addlistener('sensorUpdated', @obj.callback_sensorUpdate);
            % add keyboard esc even listener
            % set(obj.gui_h.figure1,'WindowKeyPressFcn',@controller.callback_keypress);
            
        end
        function callback_sensorUpdate(obj, src, event)
            [data, endTime] = obj.modelObj.runningAverager.getData();
            fprintf('time %5.2f: %2.1f:%2.1f:%2.1f:%2.1f\n', endTime, data(1), data(2), data(3),data(4));
            [HorF, sizing] = obj.modelObj.algorithm.predict(data);
            obj.update_fullscreen(HorF, sizing);
            
            % check if music done
            if ~isplaying(obj.music)
                obj.stopVisualize();
                obj.modelObj.stopEngine();
                set(obj.gui_h.doneBtn,'String', 'Start Dance');
            end
        end
        function startVisualize(obj)
            fullscreen(obj.updateImg, 1);
            global frame_java
            hframe = handle(frame_java, 'CallbackProperties');
            controller = obj.controlObj;
            funcH = @controller.callback_keypress;
            set(hframe, 'KeyPressedCallback', funcH);
            
            % for window figure, instead of full screen
            % s = get(0, 'ScreenSize');
            % controller = obj.controlObj;
            % funcH = @controller.callback_keypress;
            % obj.hfigure = figure('Position', [0 0 s(3) s(4)],'WindowKeyPressFcn',funcH);
            % %set(obj.hfigure,'WindowKeyPressFcn',@obj.controlObj.callback_keypress);
            % imshow(obj.updateImg);
            
            
            play(obj.music);
            imgID = randi(size(obj.recommendedImg,1));
            obj.targetImg = obj.recommendedImg{imgID};
        end
        function stopVisualize(obj)
            closescreen();
            % close(obj.hfigure);
            stop(obj.music);
        end
        function update_fullscreen(obj, HorF, sizing)
            if obj.modelObj.running
                % revise updateImg according to the data
                [handmask, feetmask] = getHandFeet(obj.handImg,obj.feetImg,sizing);
                indSet = zeros(1,2);
                [obj.updateImg, indSet] = rssTrigger(HorF, indSet, handmask, feetmask, obj.updateImg, obj.targetImg);  % 1 = hand, 2=feet, 3 = both
                fullscreen(obj.updateImg, 1);
                % imshow(obj.updateImg);
                obj.count = obj.count + 1;
                if(mod(obj.count,50)==0)            
                    imgID = randi(size(obj.recommendedImg,1));
                    obj.targetImg = obj.recommendedImg{imgID};
                end
            end
        end
    end
end