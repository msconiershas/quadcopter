///////////////////////////////////////////////////////////////////////////////////////
//    _________    __    ________  ____  ___  ____________   _______________________
//   / ____/   |  / /   /  _/ __ )/ __ \/   |/_  __/ ____/  /_  __/ ____/ ___/_  __/
//  / /   / /| | / /    / // __  / /_/ / /| | / / / __/      / / / __/  \__ \ / /   
// / /___/ ___ |/ /____/ // /_/ / _, _/ ___ |/ / / /___     / / / /___ ___/ // /    
// \____/_/  |_/_____/___/_____/_/ |_/_/  |_/_/ /_____/    /_/ /_____//____//_/                                                                                     
//
//////////////////////////////////////////////////////////////////////////////////////

`include "tb_tasks.sv"	// maybe have a separate file with tasks to help with testing

module QuadCopter_tb_6();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;
wire SS_A2D_n,SCLK_A2D,MOSI_A2D,MISO_A2D;
wire RX,TX;
wire [7:0] resp;				// response from DUT
wire cmd_sent, resp_rdy;
wire frnt_ESC, back_ESC, left_ESC, rght_ESC;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd_to_copter;		// command to Copter via wireless link
reg [15:0] data;				// data associated with command
reg send_cmd;					// asserted to initiate sending of command (to your CommMaster)
reg clr_resp_rdy;				// asserted to knock down resp_rdy

/////// declare any localparams here /////


////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Copter with Inertial sensor //
//////////////////////////////////////////////////////////////	
CycloneIV iQuad(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT),
                .frnt_ESC(frnt_ESC),.back_ESC(back_ESC),.left_ESC(left_ESC),
				.rght_ESC(rght_ESC));				  

///////////////////////////////////////////////////
// Instantiate Model of A2D for battery voltage //
/////////////////////////////////////////////////
ADC128S iA2D(.clk(clk),.rst_n(RST_n),.SS_n(SS_A2D_n),.SCLK(SCLK_A2D),
             .MISO(MISO_A2D),.MOSI(MOSI_A2D));			
	 
////// Instantiate DUT ////////
QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.LED(),.FRNT(frnt_ESC),.BCK(back_ESC),
				.LFT(left_ESC),.RGHT(rght_ESC),.SS_A2D_n(SS_A2D_n),.SCLK_A2D(SCLK_A2D),
				.MOSI_A2D(MOSI_A2D),.MISO_A2D(MISO_A2D));


//// Instantiate Master UART (used to send commands to Copter) //////
CommMaster iMSTR(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                 .cmd(cmd_to_copter), .data(data), .send_cmd(send_cmd),
			     .frm_snt(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));

initial begin
  // get stuff going
  init_task(clk,RST_n,send_cmd);
  // send calibrate command
  send_cmd_task(clk,3'd6,send_cmd,cmd_to_copter);

  //wait for response
  fork : chk
        begin
            // Timeout check
            #25000000
            $display("%t : timeout", $time);
            $stop;
            disable chk;
        end
        begin
            //check motor speeds
            @(posedge iDUT.ifly.inertial_cal)
            if(iDUT.ifly.frnt_spd != 11'h1B0) begin
                $display("bad motor speed front, %h", iDUT.ifly.frnt_spd );
                $stop;
            end
            else if(iDUT.ifly.bck_spd != 11'h1B0) begin
                $display("bad motor speed front, %h", iDUT.ifly.bck_spd );
                $stop;
            end
            else if(iDUT.ifly.lft_spd != 11'h1B0) begin
                $display("bad motor speed front, %h", iDUT.ifly.lft_spd );
                $stop;
            end
            else if(iDUT.ifly.rght_spd != 11'h1B0) begin
                $display("bad motor speed front, %h", iDUT.ifly.rght_spd );
                $stop;
            end
            $display("Motor Speeds Good.");
            

            // Wait on signal
            @(posedge resp_rdy);
            $display("cmd 6 resp received");
            disable chk;
        end
    join

  check_posack_task(resp);



  $display("Calibration Test Passed.");
  $stop;
 
end

always
  #10 clk = ~clk;

endmodule	
