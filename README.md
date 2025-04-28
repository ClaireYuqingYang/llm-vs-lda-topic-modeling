# a4-fp-repo

![LDA vs LLM Topic Distribution](figs/llm_vs_lda_theme_comparison.png)  
*Figure 1. The solid red line shows the proportion of documents assigned to each LDA topic, and the dashed blue line shows the proportion assigned to each LLM-derived theme. And there are documents not classified by both methods, which is shown in the center of the plot. The LDA curve is relatively smooth and flat while the LLM curve fluctuates more dramatically between different topics. This suggests that LLM may capture a wider variety of themes, but LDA distributes document assignments more evenly. *

1. Our chart keeps the design simple by minimizing visual clutter and using only essential elements like lines and points.
2. We arranged the topics in a V-shape: LDA topics are ordered from high to low, LLM topics are ordered from low to high, and they meet at a shared "Not Classified" point in the center to connect the two parts clearly.
3. We used two different but soft colors to separate LDA and LLM results, making them easy to differeniate without being distracting.
4. We connected the points with lines to make trends easy to follow and highlight the structural difference between LDA and LLM topic distributions.
5. We used the same axis scales and clear labels so that it’s easy to compare the proportions across methods at a glance.
