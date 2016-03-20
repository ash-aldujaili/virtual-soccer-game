%% Code Developed by:
% Abdullah Shamil Hashim
% Universiti Teknologi PETRONAS
% April- 2011
% Supervised by: Dr. Aamir Saeed Malik
%% all about the video object
vid = videoinput('winvideo', 1, 'YUY2_640x480');
src = getselectedsource(vid);
vid.TriggerRepeat = Inf;
vid.FramesPerTrigger = 1;
vid.ReturnedColorspace = 'rgb';
%% Output video
hVideoOut= video.DeployableVideoPlayer;
%% Object( Ball)
ball = video.ShapeInserter;
ball.Shape ='Circles';
ball.Fill = true;
ball.FillColorSource= 'Property';
ball.FillColor = 'Custom';
ball.CustomFillColor= [0 0 0];
ball.Opacity= 1;
ball.ROIInputPort= false;
pts=uint32( [480  320  20]);
motion_y = 0.5;
motion_x = -1;
%% Text :
%% CPU score 
cscore=0;
CPU_Score = video.TextInserter('CPU Score: %d');%,cscore);
CPU_Score.Color = [1 1 1];
CPU_Score.FontSize = 24;
CPU_Score.Location = [0 0];
%% Player Score
pscore=0;
Player_Score = video.TextInserter('Player Score: %d');%,pscore);
Player_Score.Color = [1 1 1];
Player_Score.FontSize = 24;
Player_Score.Location = [20 0];
%% YOU WIN
Player_win = video.TextInserter('YOU WON :)');
Player_win.Color = [0 1 1];
Player_win.FontSize = 50;
Player_win.Location = [250  100];
%% YOU LOST
Player_lost = video.TextInserter('YOU LOST :(');
Player_lost.Color = [1 1 0];
Player_lost.FontSize = 50;
Player_lost.Location = [250  100];

%% Initializing
init = video.TextInserter('Initializing...');
init.Color = [1 1 0];
init.FontSize = 50;
init.Location = [250  100];
 %% Store PlayField ( Virtual Place )
%playground=imread('D:\Lecture_Notes\EDX\Virtual Soccer Game\play_ground.jpg');
playground=imread('C:\Users\mOnStEr\Downloads\play_ground.jpg');
first=true;
%% Capturing Initialized frames for the background without the player:
start(vid);
for i=1:10
    array_back=getdata(vid,1);
    flushdata(vid);
    if first 
        stackr=cat(3,array_back(:,:,1));
        stackg=cat(3,array_back(:,:,2));
        stackb=cat(3,array_back(:,:,3));
        first=false;
    else
       stackr=cat(3,stackr,array_back(:,:,1));
        stackg=cat(3,stackg,array_back(:,:,2));
        stackb=cat(3,stackb,array_back(:,:,3));
    end
      
end
stop(vid);
%background median filtering
[r c n]= size(stackr);
background= zeros (r,c,3);

for i=1:r
    for j=1:c
        background(i,j,1)=median(stackr(i,j,:));
        background(i,j,2)=median(stackg(i,j,:));
        background(i,j,3)=median(stackb(i,j,:));
    end
end
%% Store filtered background
background_conv=( uint8(background));
%% Start Capturing...
start(vid);


%% Analyze captured frames
while 1
    % get a frame
    captured_frame= getdata(vid,1);
    
    subtract =im2uint8((abs(background_conv - captured_frame)));   
    % preprocessing (filter sizes are subjective to circumstances)
    subtract(:,:,1) =  spfilt(subtract(:,:,1) ,'min',3,3);
    subtract(:,:,2) =  spfilt(subtract(:,:,2) ,'min',3,3);
    subtract(:,:,3) =  spfilt(subtract(:,:,3) ,'min',3,3);
    % Threshold ( parameter to be chosen subjectively)
    S=(subtract(:,:,1)+subtract(:,:,2)+subtract(:,:,3))>50;
    s_filter =im2bw(spfilt(S,'max',7,7)) ;
    % Find Largest blob (player)
    bw=bwlargestblob(s_filter,4);
    % One more filtering to fill the holes
    final = imfill(255*bw,[1 1 1 ;1 1 1;1 1 1],'holes');
    % Creat a mask (template) image
    mask=cat(3,final,final,final);
    player= (captured_frame).*(uint8(mask));   
    % Flush memory
    flushdata(vid);
%% Shrinking captured frame into goal area:
    shrinked_player_before_reverse = imresize(player, [200 500], 'bicubic');
    shrinked_mask_before_reverse = imresize(1-mask, [200 500], 'bicubic');
  %% reverse side (mirroring the incoming frames to make it more sensible for the player to move around
for j=1:3
  for i=1:500
    shrinked_player(:,i,j)=shrinked_player_before_reverse(:,501-i,j);
    shrinked_mask(:,i,j)=shrinked_mask_before_reverse(:,501-i,j);
  end  
end 
  %% Padding ( to limit the frame captured over the goal area only)
    padded_difference= padarray(shrinked_player,[140   70]);
    padded_mask= padarray(shrinked_mask,[140 70],1);
  %% Overlaying the player and the virtual place  
    playground_affected = playground.*(uint8(padded_mask));
    output_frame= playground_affected+padded_difference;


    %% Ball Movements:
    % For reaching goal or outside goal at the same level
  if(pts(1)< 250 && ((pts(2)> 90 && pts(2)< 540 )||(pts(2)<= 1 || pts(2)> 680 || pts(1)<1) ) )
      motion_x=- 1;
      % increment the socre
     if (pts(2)> 90 && pts(2)< 540 && padded_mask(pts(1),pts(2))==false )
        pscore= pscore +1;
        
     end
     if (pts(2)> 90 && pts(2)< 540 && padded_mask(pts(1),pts(2))==true )
        cscore= cscore +1;
     end
     random_fact= random('Normal',0,0.35);
     motion_y = abs(random_fact);
     pts(1)=500;
     pts(2)=uint32(1000* motion_y);
     if (pts(2)>320)
        motion_y = -(motion_y-0.320);
     end 
  % if it has been blocked
  % in regular motiion  
  else
     pts(1)= uint32(pts(1)+ motion_x *40);
     pts(2)= uint32(pts(2)+ motion_y *200);
  end

    %% Overlaying all the components of the game:  
    imageRect= step (ball,output_frame,pts);
    imgwthtxt= step(Player_Score,imageRect,uint8(pscore));
    imgwthtxt= step(CPU_Score,imgwthtxt,uint8(cscore));
   %% To display game result:
    if (pscore> 10 || cscore>10)
        if (pscore > 10)
            pscore =0;
            imgwthtxt= step(Player_win,output_frame);
        elseif (cscore >10)
             cscore= 0;
             imgwthtxt= step(Player_lost,output_frame); 
        end
        for i=1:30
            step(hVideoOut, imgwthtxt);
        end
    end
  %% Final Display
   step(hVideoOut, imgwthtxt);
   
end
stop(vid);

