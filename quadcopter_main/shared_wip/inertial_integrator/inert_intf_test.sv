module inert_intf_test (clk, RST_n, NEXT, LED, SS_n, SCLK, MOSI, MISO, INT);
    
    // INPUTS
    input logic clk, RST_n, NEXT, MISO, INT;
    output logic SS_n, SCLK, MOSI;
    output logic [7:0] LED;
    
    // LOCAL VARIABLES
    logic rst_n, next, cal_done, strt_cal, stat, vld;
    logic [1:0] sel;
    logic [7:0] ptch, roll, yaw;
    typedef enum logic [1:0] {CAL, PTCH, ROLL, YAW} state_t;
    state_t state, next_state;

    // INSTANTIATIONS
	reset_synch iRST(.RST_n(RST_n), .clk(clk), .rst_n(rst_n));
	
	PB_release iPB(.clk(clk), .rst_n(rst_n), .PB(NEXT), .released(next));
   
	inert_intf iII(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), 
                   .MISO(MISO), .INT(INT), .strt_cal(strt_cal), .ptch(ptch), 
                   .roll(roll), .yaw(yaw), .cal_done(cal_done), .vld());

    // MUX

    assign LED = (sel == 2'b00) ? stat :
                 (sel == 2'b01) ? ptch :
                 (sel == 2'b10) ? roll : 
                                  yaw;

      ///////////////////
     // STATE MACHINE //
    ///////////////////
    always_ff @ (posedge clk, negedge rst_n)begin
        if ( !rst_n ) begin
            state <= CAL;
        end 
        else begin
            state <= next_state; 
        end
    end

    always_comb begin
    //defaults
    next_state = CAL;
    stat = 0;
	 strt_cal = 0;
	 sel = 0;
	 

    case(state)
        PTCH: begin
            next_state = PTCH;
            sel = 2'b01;
            if (next) begin
                next_state = ROLL;
            end 
        end

        ROLL: begin 
            next_state = ROLL;
            sel = 2'b10;
            if (next) begin
                next_state = YAW;
            end
        end

        YAW: begin
            next_state = YAW;
            sel = 2'b11;
            if (next) begin
                next_state = PTCH;
            end 
        end

        default: begin //THIS IS CAL
            sel = 2'b00;
            stat = 1;
            strt_cal = 1;
            if (cal_done) begin
                next_state = PTCH;
            end
        end
    endcase

    end




endmodule
