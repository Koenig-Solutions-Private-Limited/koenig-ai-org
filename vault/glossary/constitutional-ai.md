---
term: "Constitutional AI"
definition: "Anthropic's alignment method in which a language model critiques and revises its own outputs according to a set of written principles (the 'constitution'), reducing reliance on human feedback for safety training."
seo_description: "Constitutional AI: Anthropic's alignment method where an LLM self-critiques based on written principles, reducing reliance on human safety feedback."
category: "LLM concepts"
related_terms: [constitutional-ai-method, rlhf, direct-preference-optimization, alignment, helpfulness-harmlessness-honesty, red-teaming]
---

Constitutional AI (CAI, Bai et al., 2022) was developed at Anthropic to address the scaling bottleneck of RLHF: human feedback is expensive and hard to scale. Instead, CAI uses a fixed set of principles (the "constitution") to generate AI feedback. The model generates a response, then critiques it against the constitution ("Does this response encourage harm?"), then revises it based on the critique. These revised pairs become training data.

The constitution allows precise control over model behavior through natural language. Anthropic's published constitution includes principles derived from the UN Declaration of Human Rights, considerations of harmlessness and helpfulness, and specific rules about content safety. By encoding values in explicit principles rather than implicit human ratings, CAI makes the alignment process more transparent and auditable.

In production, CAI is combined with RLHF: constitutional principles shape the AI-generated preference data, and human raters validate and supplement it. The result is the Claude model family, which consistently scores highly on both helpfulness and harmlessness evaluations compared to models aligned with RLHF alone.

## Related Terms

- [[glossary/rlhf|Reinforcement Learning from Human Feedback (RLHF)]] — the training technique that uses human preference comparisons to steer model behaviour
- [[glossary/direct-preference-optimization|Direct Preference Optimization]] — an alignment technique that optimises the model directly on preference data without a reward model
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
