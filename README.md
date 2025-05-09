# a4-fp-repo
# The Topic Tug-of-War: Why LLMs Beat LDA at Making Sense of Conversations  
*Yining Lu*

What do people *really* talk about when they gather on a mailing list? If you're building a classifier to summarize these conversations, you might reach for a tried-and-true method like Latent Dirichlet Allocation (LDA). But today, large language models (LLMs) offer an alternative — and they might just be winning.

To explore this, I analyzed 1,587 messages from the **main mailing list of the Internet Engineering Task Force (IETF)** — the international standards organization responsible for protocols like HTTP, DNS, and SMTP. These messages span a full year leading up to May 2024 and reflect open, real-time conversations on technical proposals, organizational governance, and meeting logistics. Compared to older or proprietary datasets (e.g., the Enron corpus or internal enterprise data), the IETF archive is not only **current and transparent**, but also **publicly accessible and highly relevant** for understanding communication in modern technical communities.

The goal was to compare how LDA and LLM-based approaches classify these messages into thematic clusters — and more importantly, which method better captures what’s really being said.

![Cosine similarity between LDA and LLM topic vectors based on message body text. Darker tiles indicate higher semantic alignment.](figs/llm_vs_lda_semantic_similarity.png)  
*Cosine similarity between LDA and LLM topic vectors based on message body text. Darker tiles indicate higher semantic alignment.*

The figure above reveals a striking pattern: multiple LDA topics clustered around a single LLM theme — particularly *"IPv6 Transition and Internet Infrastructure"*. This tells us that LDA may be over-fragmenting: splitting up similar discussions into several near-duplicate topics based solely on word co-occurrence. The same theme — say, “ietf”, “ipv6”, “wrote” — gets sliced into multiple low-coherence clusters.

Meanwhile, LLM themes like *“Security, Encryption, and Trust Models”* or *“Volunteerism and Leadership”* didn’t match well with any LDA topic at all. This is concerning. These themes aren’t minor; they reflect whole areas of discussion that LDA simply failed to capture.

![Proportion of documents assigned to each LDA topic (rows) and LLM theme (columns). Blank spots indicate missing mappings.](figs/llm_vs_lda_theme_heatmap.png)  
*Proportion of documents assigned to each LDA topic (rows) and LLM theme (columns). Blank spots indicate missing mappings.*

In the proportion heatmap above, LDA missed several of the LLM’s themes entirely. These gaps aren’t just statistical noise — they reflect *conceptual blind spots* in the LDA model. Where LDA failed to identify even one topic, the LLM confidently grouped dozens of messages under coherent thematic umbrellas. This reinforces the idea that LLMs are better at recognizing higher-order structure in language — such as intent, context, and subjectivity — which LDA is blind to.

To go further, I applied a many-to-one greedy mapping, matching each LDA topic to its most semantically similar LLM theme. The result is summarized below:

| LDA Topic                | LLM Theme                                      | Similarity |
|--------------------------|-----------------------------------------------|------------|
| ietf, process, iesg      | Standards Development Process and Governance  | 0.540      |
| ietf, will, meeting      | IPv6 Transition and Internet Infrastructure   | 0.430      |
| ipv, wrote, ietf         | IPv6 Transition and Internet Infrastructure   | 0.513      |
| nomcom, ietf, wrote      | IPv6 Transition and Internet Infrastructure   | 0.345      |
| review, last, call       | Standards Development Process and Governance  | 0.313      |
| rfc, historic, ietf      | IPv6 Transition and Internet Infrastructure   | 0.366      |
| secure, can, dns         | IPv6 Transition and Internet Infrastructure   | 0.632      |
| tls, internet, christian | IPv6 Transition and Internet Infrastructure   | 0.512      |
| Topic NA                 | Standards Development Process and Governance  | 0.299      |
| wrote, ietf, may         | Meeting Logistics, Safety, and Location       | 0.350      |
| wrote, list, email       | IPv6 Transition and Internet Infrastructure   | 0.552      |

Most LDA topics collapsed onto just a few LLM themes — especially “IPv6 Transition and Internet Infrastructure” — while many LLM-generated categories went unmatched. This imbalance highlights that **LDA is more suspicious** here: prone to redundancy, fragmentation, and coverage gaps.

So which should we trust? In this case, the **LLM themes are more credible**. They're not just smarter guesses — they're backed by better semantic consistency, broader coverage, and an ability to group ideas, not just words. LDA, in contrast, appears to be missing the forest for the trees.

There are still caveats. LLM outputs depend heavily on prompting, and can be inconsistent or overconfident in labeling. But in this head-to-head, the evidence suggests that when it comes to classifying complex discussions, **LLMs aren’t just keeping up — they’re leading the conversation.**

*Source data: [IETF Mail Archive](https://mailarchive.ietf.org/arch/)*