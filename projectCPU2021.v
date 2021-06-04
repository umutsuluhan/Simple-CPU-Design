module projectCPU2021(
  clk,
  rst,
  wrEn,
  data_fromRAM,
  addr_toRAM,
  data_toRAM,
  PC,
  W
);

input clk, rst;

input [15:0] data_fromRAM;
output reg [15:0] data_toRAM;
output reg wrEn;

// 12 can be made smaller so that it fits in the FPGA
output reg [12:0] addr_toRAM;
output reg [12:0] PC; // This has been added as an output for TB purposes
output reg [15:0] W; // This has been added as an output for TB purposes

// Your design goes in here

reg [12:0] PCNext;
reg [15:13] opcode, opcodeNext;
reg [12:0] operand1, operand1Next;
reg [15:0] num1, num1Next;
reg [ 2:0] state, stateNext;
reg indirect, indirectNext;
reg [15:0] WPrev;

always @(posedge clk) begin
  state <= #1 stateNext;
  PC <= #1 PCNext;
  opcode <= #1 opcodeNext;
  operand1 <= #1 operand1Next;
  num1 <= #1 num1Next;
  indirect <= #1 indirectNext;
  WPrev <= #1 W;
end

always @* begin
  stateNext = state;
  PCNext = PC;
  opcodeNext = opcode;
  operand1Next = operand1;
  num1Next = num1;
  addr_toRAM = 0;
  wrEn = 0;
  data_toRAM = 0;
  indirectNext = 0;
  W = WPrev;
  if (rst) begin
    stateNext = 0;
    PCNext = 0;
    opcodeNext = 0;
    operand1Next = 0;
    num1Next = 0;
    addr_toRAM = 0;
    wrEn = 0;
	 W = 0;
    data_toRAM = 0;
	 indirectNext = 0;
  end else 
    case (state)
      0: begin         
        PCNext = PC;
        opcodeNext = opcode;
        operand1Next = 0;
        addr_toRAM = PC;
        num1Next = 0;
        wrEn = 0;
        data_toRAM = 0;
		  indirectNext = 0;
        stateNext = 1;
      end
      1: begin          
        PCNext = PC;
        opcodeNext = data_fromRAM[15:13];
        operand1Next = data_fromRAM[12:0];
        addr_toRAM = data_fromRAM[12:0];
        num1Next = 0;
        wrEn = 0;
        data_toRAM = 0;
		  indirectNext = indirect;
		  if(data_fromRAM[12:0] == 0)begin
		    addr_toRAM = 2;
			 indirectNext = 1;
		    stateNext = 4;
		  end
		  else stateNext = 2;
      end
		2: begin         
        if(opcode == 3'b111)begin
		    PCNext = data_fromRAM;
		  end
		  else if(opcode == 3'b100)begin
		    if(data_fromRAM == 0)PCNext = PC + 2;
			 else PCNext = PC + 1;
		  end
		  else PCNext = PC + 1; 
		  opcodeNext = opcode;
        operand1Next = operand1;
        addr_toRAM = operand1;
        num1Next = data_fromRAM;
        if(opcode == 3'b110 && indirect == 1)wrEn = 0;
		  else wrEn = 1;
        data_toRAM = 0;
		  indirectNext = indirect;
        stateNext = 3;
		  
		  if(opcode == 3'b110)begin
			 data_toRAM = W;
		  end
      end
		3: begin         
		  opcodeNext = opcode;
        operand1Next = operand1;
        addr_toRAM = operand1;
        num1Next = num1;
        wrEn = 0;
        data_toRAM = 0;
		  indirectNext = indirect;
        stateNext = 0;
		  
		  if(opcode == 3'b000)W = W + data_fromRAM;
		  else if(opcode == 3'b001)W = ~(W & data_fromRAM); 
		  else if(opcode == 3'b010)begin
		    if(data_fromRAM < 16)begin
			   W = W >> data_fromRAM;
			 end
			 else if(data_fromRAM > 16 && data_fromRAM < 31)begin
				W = W << data_fromRAM[3:0];
			 end
			 else if(data_fromRAM > 32 && data_fromRAM < 47)begin
				if(indirect == 0)W = {W[3:0], W[15:4]};
			   else W = {W[7:0], W[15:8]};
			 end
			 else begin
				W = {W[11:0], W[15:12]};
			 end  
		  end
		  else if(opcode == 3'b011)W = W >= data_fromRAM;
		  else if(opcode == 3'b101)W = data_fromRAM;
      end
		4:begin
		  PCNext = PC;
		  opcodeNext = opcode;
		  operand1Next = operand1;
		  addr_toRAM = data_fromRAM;
		  num1Next = num1;
		  stateNext = 2;
		  indirectNext = indirect;
		  if(opcode == 3'b110)begin
		    wrEn = 1;
			 PCNext = PC + 1;
			 data_toRAM = W;
			 stateNext = 0;
		  end
		  else wrEn = 0;
		  indirectNext = indirect;
		end
	endcase
end
endmodule
