
function automatic killf(input [WIDTH_BRM-1:0]          mask,
                         input [$pow(2, WIDTH_BRM)-1:0] kmask);
reg [$pow(2, WIDTH_BRM)-1:0] dmask;
begin
	// decoder
	dmask = 1 << mask;
	//check
	killf = |(dmask & kmask);
end
endfunction

