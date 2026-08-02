// Scratch harness: renders each exported figure at its poster size so the SVG
// can be proofed with the real Inter font before it goes into poster.typ.
// 10.67in is one column of the 36x36 poster — the size these actually print at.
#set page(width: 11.1in, height: 8.5in, margin: 0.2in, fill: white)
#image("fig-pipeline-stages.svg", width: 10.67in)
#pagebreak()
#image("fig-hil-reliability.svg", width: 10.67in)
#pagebreak()
#image("fig-feedback-time.svg", width: 10.67in)
