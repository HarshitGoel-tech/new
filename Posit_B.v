`timescale 1ns / 1ps

module positB(
    input sub,
    input [31:0] in,
    output reg negative, ss,
    output reg [1:0] exp,           
    output reg signed [5:0] regime, // FIXED: Increased to 6 bits to prevent overflow
    output reg [26:0] mantissa,
    output reg sadd_cin, chck
);
    
    wire ctrl;
    reg [4:0] lbc_out;
    reg [5:0] k;                    // FIXED: Match regime width
    reg [30:0] sh_out;   
    wire [30:0] lod_input;  
    
    reg exp_cin;                   // FIXED: Separate exponent carry
    reg reg_cin;                   // FIXED: Separate regime carry
    
    integer i;   
    
    assign ctrl = in[31] ^ in[30];
    assign lod_input = in[30] ? ~in[30:0] : in[30:0];     
    
    always @(*) begin
        lbc_out = 5'b0;
        for (i = 0; i < 31; i = i + 1) begin
            if (lod_input[i] == 1'b1) begin
                lbc_out = 5'b11110 - i;       
            end
        end
        
        // Zero extend lbc_out and ctrl to 6 bits for safe math
        k = {1'b0, lbc_out} - {5'd0, ctrl};
        negative = in[31];
        ss = ~ctrl;
        
        sh_out = in[30:0] << (lbc_out + 5'b00001);
        
        mantissa = sub ? (~(sh_out[28:2]) + sub) : sh_out[28:2]; 
        
        chck = ~|(in[30:0]);
        
        // FIXED: Split the parallel carry logic
        // If mantissa is 0, the 2's comp carry ripples into the exponent
        exp_cin = (~| sh_out[28:2]) & in[31];
        
        // If BOTH mantissa and exp are 0, the carry ripples into the regime
        reg_cin = (~| sh_out[30:2]) & in[31];
        sadd_cin = reg_cin; // Keeping your original output assignment
        
        // FIXED: Added the necessary +1 for 2's complement of negative regimes
        regime = (ctrl ? k : (~k + 1'b1)) + {5'b0, reg_cin}; 
        
        // FIXED: Use the isolated exp_cin
        exp = (in[31] ? ~sh_out[30:29] : sh_out[30:29]) + {1'b0, exp_cin};
    end

endmodule