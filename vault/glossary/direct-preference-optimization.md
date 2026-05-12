---
term: "Direct Preference Optimization"
definition: "An alignment training method that fine-tunes a language model directly on human preference pairs (preferred vs. rejected responses) without requiring a separate reward model, simplifying the RLHF pipeline."
seo_description: "Direct preference optimization (DPO): an alignment method that trains LLMs on preference pairs without a separate reward model, simplifying RLHF."
category: "LLM concepts"
related_terms: [rlhf, reinforcement-learning-from-human-feedback, supervised-fine-tuning, constitutional-ai, alignment]
---

Rafailov et al. (2023) showed that the RLHF objective can be optimized directly in policy space without training an intermediate reward model. DPO reframes preference learning as a classification problem: given a pair of responses (winner, loser) for the same prompt, update the model to increase the probability of the winner relative to a reference policy. The math shows this is equivalent to optimizing a reward-free version of the RL objective.

DPO is simpler to implement and more stable to train than PPO-based RLHF. It does not require the complex reward model training stage, eliminates reward hacking dynamics, and is far less sensitive to hyperparameters. These advantages have made DPO the default alignment method for many open-source projects (Zephyr, Tulu, OpenHermes).

Variants include IPO (Identity Preference Optimization), KTO (Kahneman-Tversky Optimization, which works with scalar ratings rather than pairs), and ORPO (odds-ratio preference optimization, which integrates SFT and alignment into a single training stage). As of 2026, most frontier labs use DPO-family methods for their instruction-following and safety alignment pipelines.
