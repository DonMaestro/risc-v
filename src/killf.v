
function automatic killf(input [WIDTH_BRM-1:0]        mask,
                         input [(2 ** WIDTH_BRM)-1:0] kmask);
reg [(2 ** WIDTH_BRM)-1:0] dmask;
begin
	// decoder
	dmask = 1 << mask;
	//check
	killf = |(dmask & kmask);
end
endfunction

