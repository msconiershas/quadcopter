`timescale 1ns/1ps
task automatic send_cmd_task(ref reg clk,
                   input reg [7:0] cmd_num,
                   ref reg send_cmd,
                   ref reg [7:0] cmd_to_copter);
    begin
        cmd_to_copter = cmd_num;
        @(negedge clk)
        send_cmd = 1;
        @(negedge clk)
        send_cmd = 0;
    end
endtask

//not working if resp_rdy is a wire? don't use right now.
task automatic check_response_task(ref logic resp_rdy);
    begin
    //wait for response
        fork : chk
            begin
                // Timeout check
                #3000000
                $display("%t : timeout waiting for response", $time);
                $stop;
                disable chk;
            end
            begin
                // Wait on signal
                @(posedge resp_rdy);
                $display("%t : resp received", $time);
                disable chk;
            end
        join
    end
endtask

task check_posack_task(input reg [7:0] resp);
    begin
        if(resp === 8'ha5)begin
            $display("PosAck Received.");
        end else begin
            $display("BAD POSACK RECEIVED. FAILURE. %h",resp);
            $stop;
        end
    end
endtask

task check_batt_task(input reg [7:0] resp, input reg [7:0] expected);
    begin
        if(resp === expected)begin
            $display("good batt Received: %h", resp);
        end else begin
            $display("BAD BATT RECEIVED. FAILURE. %h",resp);
            $stop;
        end
    end
endtask

task automatic init_task(ref reg clk, ref reg RST_n, ref reg send_cmd);
    begin
        clk = 1;
        @(posedge clk)RST_n = 0;
        @(posedge clk)RST_n = 1;
        send_cmd = 0;
    end
endtask

task check_thrust_task(input reg [8:0] thrust, input reg [15:0] expected);
begin
        if(thrust === expected[8:0])begin
            $display("thrust set correctly.");
        end else begin
            $display("BAD THRUST SET. FAILURE. %h",thrust);
            $stop;
        end
    end
endtask

task automatic check_motors_off_task(ref reg clk, input reg motors_off);
begin
	// check that motors are disabled
	if(motors_off === 1) begin
		$display("Motors correctly disabled.");
	end
	else begin
		$display("Motors are not correctly disabled.");
	end
	
	// check that motors stay disbled
	repeat (10) @(posedge clk);
	if(motors_off === 1) begin
		$display("Motors stay disabled.");
	end
	else begin
		$display("Motors do not stay disabled.");
	end
	
	
	
	
end
endtask

task check_pry_task(input reg signed [15:0] pry_start, input reg signed [15:0] expected, input reg signed [15:0] pry_curr);
begin
        if(pry_start <= expected)
        begin
            if (pry_curr > pry_start) 
            begin
                $display("value aymptotically moving towards value set.");
            end else 
            begin 
		$display("BAD VALUE FAILURE. from: %h \t to: %h \t where we were: %h", pry_start, expected, pry_curr);
                $stop;
	    end
        end 
	else 
	begin
	    if (pry_curr < pry_start) 
	    begin
                $display("value aymptotically moving towards value set.");
            end 
	    else 
	    begin 
		$display("BAD VALUE FAILURE. from: %h \t to: %h \t where we were: %h", pry_start, expected, pry_curr);
                $stop;
	    end
        end
end  
endtask



////CHECK BATT//
//task automatic test_batt(ref reg clk,
//                         ref reg send_cmd, 
//                         ref reg [7:0] cmd_to_copter, 
//                         ref reg resp_rdy, 
//                         input reg [7:0] resp);
//    begin
//        send_cmd_task(clk,3'b1,send_cmd,cmd_to_copter);
//       
//        //wait for response
//        check_response_task(resp_rdy);
//        $display("%h", resp);

//        check_batt_task(resp, 8'hC0);

//        //check to make sure decrementing by 1
//        send_cmd_task(clk,3'b1,send_cmd,cmd_to_copter);
//        #3000000
//        check_batt_task(resp, 8'hBF);

//        send_cmd_task(clk,3'b1,send_cmd,cmd_to_copter);
//        #3000000
//        check_batt_task(resp, 8'hBE);

//        $display("Batt Check Test Passed."); 
//    end
//endtask

//CALIBRATE//
//task automatic calibrate(ref reg clk,
//                         ref reg send_cmd,
//                         ref reg [7:0] cmd_to_copter,
//                         ref reg resp_rdy,
//                         ref reg [7:0] resp,
//                         ref reg inertial_cal,
//                         ref reg [11:0] frnt_spd,
//                         ref reg [11:0] back_spd,
//                         ref reg [11:0] left_spd,
//                         ref reg [11:0] rght_spd);
//     begin
//         // send calibrate command
//        send_cmd_task(clk,3'd6,send_cmd,cmd_to_copter);

//        //wait for response
//         fork : chk
//              begin
//                 // Timeout check
//                 #25000000
//                   $display("%t : timeout", $time);
//                    $stop;
//                    disable chk;
//                end
//                begin
//                  //check motor speeds
//                  @(posedge iDUT.ifly.inertial_cal)
//                  if(iDUT.ifly.frnt_spd != 11'h1B0) begin
//                      $display("bad motor speed front, %h", iDUT.ifly.frnt_spd );
//                     $stop;
//                  end
//                    else if(iDUT.ifly.bck_spd != 11'h1B0) begin
//                      $display("bad motor speed front, %h", iDUT.ifly.bck_spd );
//                      $stop;
//                    end
//                   else if(iDUT.ifly.lft_spd != 11'h1B0) begin
//                      $display("bad motor speed front, %h", iDUT.ifly.lft_spd );
//                        $stop;
//                    end
//                  else if(iDUT.ifly.rght_spd != 11'h1B0) begin
//                        $display("bad motor speed front, %h", iDUT.ifly.rght_spd );
//                     $stop;
//                   end
//                   $display("Motor Speeds Good.");
//            

//                   // Wait on signal
//                   @(posedge resp_rdy);
//                   $display("cmd 6 resp received");
//                   disable chk;
//                end
//         join

//        check_posack_task(resp);
//        $display("Calibration Test Passed.");
//    end
//endtask

