// Scratch harness: renders each exported figure at its poster size so the SVG
// can be proofed with the real Inter font before it goes into poster.typ.
#set page(width: 7.4in, height: 6.9in, margin: 0.2in, fill: white)
#image("fig-pipeline-stages.svg", width: 7in)
#pagebreak()
#image("fig-hil-reliability.svg", width: 7in)
#pagebreak()
#image("fig-feedback-time.svg", width: 7in)
