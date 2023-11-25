`timescale 1ns / 1ps



module VGA_top(
    input CLK100MHZ, reset,
    output VGA_HS, VGA_VS,
    output [11:0] vga
    );
   
   
    
    localparam COLOR_WHITE  = 12'b1111_1111_1111;
    localparam COLOR_RED = 12'b0000_0000_1111;
    localparam COLOR_BLACK  = 12'b0000_0000_0000;
    localparam COLOR_BROWN  = 12'b0101_1100_1111;   //바둑판 색깔 
    
    
    localparam BLOCK_BOARD_WIDTH  = 380;        //바둑 판 총 길이 
    localparam BLOCK_BOARD_HEIGHT = 380;
    
    localparam BLOCK_BOARD_S_X    = 130;
    localparam BLOCK_BOARD_S_Y    = 50;

    localparam BLOCK_HORIZONTAL_LINE_WIDTH  = 360;      //가로선 = 360*3
    localparam BLOCK_HORIZONTAL_LINE_HEIGHT = 3;
    
    localparam BLOCK_HORIZONTAL_LINE_S_X    = 20;       //바둑판 선 시작점 = (20,20)
    localparam BLOCK_HORIZONTAL_LINE_S_Y    = 20;
    
    localparam BLOCK_VERTICAL_LINE_WIDTH  = 3;          //세로선 = 3*360
    localparam BLOCK_VERTICAL_LINE_HEIGHT = 360;
    
    localparam BLOCK_VERTICAL_LINE_S_X    = 20;     //바둑판 선 시작점 = (20,20)
    localparam BLOCK_VERTICAL_LINE_S_Y    = 20;    
        
    localparam LINE_OFFSET = 20;                //바둑판 1칸 = 20*20
        
    wire video_on,  block_on_board;
    wire pixel_clk;

    wire [9:0] pixel_x, pixel_y;

    reg [11:0] vga_next, vga_reg;
    
    reg block_pos_x,block_pos_y;
    
    reg [17:0]stone_pos[17:0];
    
    integer i,j;
    
    reg block_on_stone,block_on_line;
    
    wire block_region;
    reg setstone_x, setstone_y;
    
   
    
    
    VGA_controller VGA_controller_1(
        .clk(CLK100MHZ), .reset(reset),
        .hsync(VGA_HS), .vsync(VGA_VS),
        .video_on(video_on), .pixel_clk(pixel_clk),
        .pixel_x(pixel_x), .pixel_y(pixel_y)
    );



    always @(posedge CLK100MHZ, posedge reset)
    begin
        if(reset)
            vga_reg <= 12'd0;
        else
            if(pixel_clk)
                vga_reg <= vga_next;
    end

    always @*
    begin
        vga_next = vga_reg;
        if(~video_on)
            vga_next = COLOR_BLACK;
        else
        begin
            if(block_on_line)
                vga_next = COLOR_BLACK;
            else if(block_on_stone)
                vga_next = COLOR_BLACK;
            else
                vga_next =  COLOR_BROWN;
        end
    end
    
    
    
    /////새로 추가한 부분
    
    
    
    
    always @(posedge CLK100MHZ, posedge reset)  //바둑돌 그리기
    if(reset)
    begin                   
        block_pos_x = 0;
        block_pos_y = 0;
        end 
        
    else if (((pixel_x%20>=4)&&((pixel_x)%20<=18))&&((pixel_y%20>=4)&&(pixel_y%20<=18))&&block_region)
        begin
        block_pos_x = pixel_x/20;       //block_pos_x = 바둑판을 18*18 행렬로 대응시킬 때 x 좌표 
        block_pos_y = pixel_y/20;
        if(stone_pos[block_pos_x][block_pos_y] == 1)        //현재 바둑판 위치에 바둑돌이 있을 대
            block_on_stone = 1;         //바둑돌 그리기
        end
    else if (((pixel_x%20<3)||(pixel_y%20<3))&&block_region)    // 바둑판 선 그리기
        block_on_line = 1;
    
    else
        begin
        block_pos_x = 0;        //else 
        block_pos_y = 0;
        block_on_stone = 0;
        block_on_line = 0;
        end 
    
    always@(posedge CLK100MHZ,posedge reset)    //바둑돌의 위치 정보 맵
    if(reset) begin 
        for(i=0;i<18;i=i+1)begin
            for(j=0;j<18;j=j+1)begin
                 stone_pos[i][j] = 0;       //리셋
            end
         end
     end
     
     else begin
        for(i=0;i<18;i=i+1)begin
            for(j=0;j<18;j=j+1)begin/*
                if(j%2 == 0)
                    stone_pos[i][j] = 1;        //test용
                else 
                    stone_pos[i][j] = 0;*/
            end
         end
     end
     
     always@(setstone_x, setstone_y)        //setstone = 새로운 돌이 놓일 때 마우스를 통해 들어오는 정보
     if(reset)
     stone_pos[setstone_x][setstone_y] = 0;
     else
       stone_pos[setstone_x][setstone_y] = 1;
     

        
     
   
   assign block_region = (BLOCK_HORIZONTAL_LINE_S_X<=pixel_x)&&(pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH+BLOCK_VERTICAL_LINE_WIDTH)&&
          (BLOCK_VERTICAL_LINE_S_Y  <= pixel_y) && (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT+BLOCK_HORIZONTAL_LINE_HEIGHT);
    //block_region = 바둑판 영역
     /*     
    assign block_on_line = ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) &&      //horizontal line 1
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT))||
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 2
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT+ LINE_OFFSET ))||
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 3
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*2 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT+ LINE_OFFSET*2))|| 
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 4
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*3 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT+ LINE_OFFSET*3))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 5
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*4 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT+ LINE_OFFSET*4))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 6
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*5 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*5))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 7
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*6 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*6))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 8
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*7 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*7))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 9
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*8 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*8))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 10
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*9 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*9))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 11
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*10 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*10))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 12
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*11 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*11))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 13
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*12 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*12))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 14
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*13 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*13))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 15
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*14 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*14))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 16
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*15 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*15))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 17
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*16 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*16))||     
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 18
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*17 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*17))||  
                            
                             ((BLOCK_HORIZONTAL_LINE_S_X <= pixel_x ) && //horizontal line 19
                            (pixel_x < BLOCK_HORIZONTAL_LINE_S_X + BLOCK_HORIZONTAL_LINE_WIDTH) && 
                            (BLOCK_HORIZONTAL_LINE_S_Y + LINE_OFFSET*18 <= pixel_y) && 
                            (pixel_y < BLOCK_HORIZONTAL_LINE_S_Y + BLOCK_HORIZONTAL_LINE_HEIGHT + LINE_OFFSET*18))||  
                            
                            
                            
                             ((BLOCK_VERTICAL_LINE_S_X  <= pixel_x ) && //vertical line 1
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH) && 
                            (BLOCK_VERTICAL_LINE_S_Y  <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET<= pixel_x ) && //vertical line 2
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*2 <= pixel_x ) && //vertical line 3
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*2) && 
                            (BLOCK_VERTICAL_LINE_S_Y  <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*3 <= pixel_x ) && //vertical line 4
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*3) && 
                            (BLOCK_VERTICAL_LINE_S_Y  <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))|| 
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*4 <= pixel_x ) && //vertical line 5
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*4) && 
                            (BLOCK_VERTICAL_LINE_S_Y  <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*5 <= pixel_x ) && //vertical line 6
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*5) && 
                            (BLOCK_VERTICAL_LINE_S_Y<= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*6 <= pixel_x ) && //vertical line 7
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*6) && 
                            (BLOCK_VERTICAL_LINE_S_Y<= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*7 <= pixel_x ) && //vertical line 8
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*7) && 
                            (BLOCK_VERTICAL_LINE_S_Y  <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*8 <= pixel_x ) && //vertical line 9
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*8) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*9 <= pixel_x ) && //vertical line 10
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*9) && 
                            (BLOCK_VERTICAL_LINE_S_Y<= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*10 <= pixel_x ) && //vertical line 11
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*10) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*11 <= pixel_x ) && //vertical line 12
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*11) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*12 <= pixel_x ) && //vertical line 13
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*12) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*13 <= pixel_x ) && //vertical line 14
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*13) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*14 <= pixel_x ) && //vertical line 15
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*14) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*15 <= pixel_x ) && //vertical line 16
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*15) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*16 <= pixel_x ) && //vertical line 17
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*16) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*17 <= pixel_x ) && //vertical line 18
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*17) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT))||  
                            
                             ((BLOCK_VERTICAL_LINE_S_X + LINE_OFFSET*18 <= pixel_x ) && //vertical line 19
                            (pixel_x < BLOCK_VERTICAL_LINE_S_X + BLOCK_VERTICAL_LINE_WIDTH + LINE_OFFSET*18) && 
                            (BLOCK_VERTICAL_LINE_S_Y <= pixel_y) && 
                            (pixel_y < BLOCK_VERTICAL_LINE_S_Y + BLOCK_VERTICAL_LINE_HEIGHT));   
                            
    */
    assign vga = vga_reg;

endmodule
