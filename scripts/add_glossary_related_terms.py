#!/usr/bin/env python3
"""Add ## Related Terms sections to glossary entries (Batch 3 — all remaining 136)."""

import os
import re
import sys

GLOSSARY = 'vault/glossary'

HUB_COURSES = {
    'claude-agent-sdk-zero-to-production': 'Claude Agent SDK — Zero to Production',
    'mcp-from-first-principles-to-production': 'MCP from First Principles to Production',
    'gemini-enterprise-agents': 'Gemini Enterprise Agents',
    'claude-tool-use-from-zero': 'Claude Tool Use from Zero',
}

# Per-slug default hub course (pre-determined by category/topic)
SLUG_TO_HUB = {
    # Agentic AI
    'agent-harness': 'claude-agent-sdk-zero-to-production',
    'agent-heartbeat': 'claude-agent-sdk-zero-to-production',
    'agent-lane': 'claude-agent-sdk-zero-to-production',
    'agent-memory': 'claude-agent-sdk-zero-to-production',
    'agent-registry': 'claude-agent-sdk-zero-to-production',
    'agent-scaffolding': 'claude-agent-sdk-zero-to-production',
    'agent-soul': 'claude-agent-sdk-zero-to-production',
    'agentic-loop': 'claude-agent-sdk-zero-to-production',
    'agentic-workflow': 'claude-agent-sdk-zero-to-production',
    'anthropic-agent-sdk': 'claude-agent-sdk-zero-to-production',
    'autonomous-agent': 'claude-agent-sdk-zero-to-production',
    'chunking': 'claude-agent-sdk-zero-to-production',
    'claude-agent-sdk': 'claude-agent-sdk-zero-to-production',
    'coder-agent': 'claude-agent-sdk-zero-to-production',
    'codex': 'claude-agent-sdk-zero-to-production',
    'cognitive-architecture': 'claude-agent-sdk-zero-to-production',
    'context-injection': 'claude-agent-sdk-zero-to-production',
    'cursor': 'claude-agent-sdk-zero-to-production',
    'definition-of-done': 'claude-agent-sdk-zero-to-production',
    'dependency-injection': 'claude-agent-sdk-zero-to-production',
    'episodic-memory': 'claude-agent-sdk-zero-to-production',
    'feature-flag': 'claude-agent-sdk-zero-to-production',
    'guardrails': 'claude-agent-sdk-zero-to-production',
    'hierarchical-agents': 'claude-agent-sdk-zero-to-production',
    'human-in-the-loop': 'claude-agent-sdk-zero-to-production',
    'idempotency': 'claude-agent-sdk-zero-to-production',
    'memory-agent': 'claude-agent-sdk-zero-to-production',
    'memory-bank': 'claude-agent-sdk-zero-to-production',
    'planning-agent': 'claude-agent-sdk-zero-to-production',
    'rag': 'claude-agent-sdk-zero-to-production',
    'reflection-agent': 'claude-agent-sdk-zero-to-production',
    'reranking': 'claude-agent-sdk-zero-to-production',
    'research-agent': 'claude-agent-sdk-zero-to-production',
    'retrieval': 'claude-agent-sdk-zero-to-production',
    'semantic-memory': 'claude-agent-sdk-zero-to-production',
    'sub-agent': 'claude-agent-sdk-zero-to-production',
    'vector-database': 'claude-agent-sdk-zero-to-production',
    'working-memory': 'claude-agent-sdk-zero-to-production',
    'world-model': 'claude-agent-sdk-zero-to-production',
    # MCP / protocol / tool-use
    'ai-gateway': 'mcp-from-first-principles-to-production',
    'api-key': 'mcp-from-first-principles-to-production',
    'api-rate-limit': 'mcp-from-first-principles-to-production',
    'audit-trail': 'mcp-from-first-principles-to-production',
    'caching': 'mcp-from-first-principles-to-production',
    'confidentiality': 'mcp-from-first-principles-to-production',
    'data-residency': 'mcp-from-first-principles-to-production',
    'durable-objects': 'mcp-from-first-principles-to-production',
    'ephemeral-storage': 'mcp-from-first-principles-to-production',
    'function-calling': 'mcp-from-first-principles-to-production',
    'http-sse': 'mcp-from-first-principles-to-production',
    'latency': 'mcp-from-first-principles-to-production',
    'observability': 'mcp-from-first-principles-to-production',
    'parallel-tool-calls': 'mcp-from-first-principles-to-production',
    'privilege': 'mcp-from-first-principles-to-production',
    'rate-limiting': 'mcp-from-first-principles-to-production',
    'rbac': 'mcp-from-first-principles-to-production',
    'sandboxing': 'mcp-from-first-principles-to-production',
    'stdio-transport': 'mcp-from-first-principles-to-production',
    'structured-logging': 'mcp-from-first-principles-to-production',
    'telemetry': 'mcp-from-first-principles-to-production',
    'tool-result': 'mcp-from-first-principles-to-production',
    # ML fundamentals / transformers / training / evals
    'attention-mask': 'gemini-enterprise-agents',
    'attention-mechanism': 'gemini-enterprise-agents',
    'backpropagation': 'gemini-enterprise-agents',
    'beam-search': 'gemini-enterprise-agents',
    'benchmark-suite': 'gemini-enterprise-agents',
    'confusion-matrix': 'gemini-enterprise-agents',
    'constitutional-ai': 'gemini-enterprise-agents',
    'cross-entropy': 'gemini-enterprise-agents',
    'direct-preference-optimization': 'gemini-enterprise-agents',
    'distillation': 'gemini-enterprise-agents',
    'embedding': 'gemini-enterprise-agents',
    'evals': 'gemini-enterprise-agents',
    'f1-score': 'gemini-enterprise-agents',
    'fine-tuning': 'gemini-enterprise-agents',
    'humaneval': 'gemini-enterprise-agents',
    'inference-time-compute': 'gemini-enterprise-agents',
    'instruction-tuning': 'gemini-enterprise-agents',
    'kv-cache': 'gemini-enterprise-agents',
    'lora': 'gemini-enterprise-agents',
    'mixture-of-experts': 'gemini-enterprise-agents',
    'mmlu': 'gemini-enterprise-agents',
    'multi-head-attention': 'gemini-enterprise-agents',
    'perplexity': 'gemini-enterprise-agents',
    'positional-encoding': 'gemini-enterprise-agents',
    'pre-training': 'gemini-enterprise-agents',
    'precision': 'gemini-enterprise-agents',
    'qlora': 'gemini-enterprise-agents',
    'quantization': 'gemini-enterprise-agents',
    'recall': 'gemini-enterprise-agents',
    'rlhf': 'gemini-enterprise-agents',
    'scaling-laws': 'gemini-enterprise-agents',
    'softmax': 'gemini-enterprise-agents',
    'speculative-decoding': 'gemini-enterprise-agents',
    'supervised-fine-tuning': 'gemini-enterprise-agents',
    'swe-bench': 'gemini-enterprise-agents',
    'transformer': 'gemini-enterprise-agents',
    # LLM basics / prompting / completions / tokens
    'alignment-tax': 'claude-tool-use-from-zero',
    'capability-overhang': 'claude-tool-use-from-zero',
    'chain-of-thought': 'claude-tool-use-from-zero',
    'claude': 'claude-tool-use-from-zero',
    'completion': 'claude-tool-use-from-zero',
    'confabulation': 'claude-tool-use-from-zero',
    'context-length': 'claude-tool-use-from-zero',
    'emergent-abilities': 'claude-tool-use-from-zero',
    'few-shot-prompting': 'claude-tool-use-from-zero',
    'frontier-model': 'claude-tool-use-from-zero',
    'gemini': 'claude-tool-use-from-zero',
    'gpt': 'claude-tool-use-from-zero',
    'greedy-decoding': 'claude-tool-use-from-zero',
    'grounding': 'claude-tool-use-from-zero',
    'hallucination': 'claude-tool-use-from-zero',
    'in-context-learning': 'claude-tool-use-from-zero',
    'inference': 'claude-tool-use-from-zero',
    'json-mode': 'claude-tool-use-from-zero',
    'llm': 'claude-tool-use-from-zero',
    'logprobs': 'claude-tool-use-from-zero',
    'multimodal': 'claude-tool-use-from-zero',
    'prompt': 'claude-tool-use-from-zero',
    'prompt-caching': 'claude-tool-use-from-zero',
    'prompt-engineering': 'claude-tool-use-from-zero',
    'react-prompting': 'claude-tool-use-from-zero',
    'reasoning-model': 'claude-tool-use-from-zero',
    'sampling-parameters': 'claude-tool-use-from-zero',
    'self-consistency': 'claude-tool-use-from-zero',
    'speech-to-text': 'claude-tool-use-from-zero',
    'structured-output': 'claude-tool-use-from-zero',
    'system-instruction': 'claude-tool-use-from-zero',
    'system-prompt': 'claude-tool-use-from-zero',
    'temperature': 'claude-tool-use-from-zero',
    'text-to-image': 'claude-tool-use-from-zero',
    'text-to-speech': 'claude-tool-use-from-zero',
    'tokenization': 'claude-tool-use-from-zero',
    'top-k': 'claude-tool-use-from-zero',
    'top-p': 'claude-tool-use-from-zero',
    'vision-language-model': 'claude-tool-use-from-zero',
}

# Relationship phrase templates — short, context-specific phrases
# Format: (subject_slug, related_slug) -> phrase OR just related_slug -> generic phrase
RELATION_PHRASES = {
    # Generic by related slug — used when no specific pair phrase exists
    'tool-use': 'the protocol Claude follows when invoking external tools from an agent loop',
    'mcp': 'the protocol layer that standardises how agents discover and call tools',
    'agent-loop': 'the iterative perceive-act-observe cycle the harness executes',
    'agent-scaffolding': 'the non-model infrastructure that surrounds the LLM to enable agent behaviour',
    'agent-harness': 'the software framework that runs the agent loop with tools and stopping criteria',
    'agent-heartbeat': 'the periodic liveness signal agents emit to detect stuck or crashed runs',
    'agent-soul': 'the identity document that constrains the agent\'s lane and definition-of-done',
    'agent-lane': 'the defined scope of actions and decisions the agent is authorized to take',
    'agent-memory': 'the persistence layer (working, episodic, semantic) that maintains agent continuity',
    'agent-budget': 'the resource and spend limits enforced to prevent runaway agent consumption',
    'agent-evaluation': 'the structured process for measuring how well an agent meets its goals',
    'agent-orchestration': 'the coordination layer that routes and schedules work across multiple agents',
    'agent-registry': 'the directory service that lets orchestrators discover and route to the right agent',
    'orchestrator': 'the component that owns the task graph and decides which agent handles each step',
    'multi-agent-system': 'the broader architecture in which multiple specialized agents collaborate',
    'autonomous-agent': 'an agent that completes tasks independently without step-by-step human approval',
    'planning-agent': 'the agent responsible for decomposing goals into executable sub-tasks',
    'coder-agent': 'a specialized agent that writes, tests, and debugs code autonomously',
    'reflection-agent': 'an agent that critiques its own prior outputs to improve quality',
    'research-agent': 'an agent that autonomously searches and synthesizes information from external sources',
    'memory-agent': 'a specialized agent that manages long-term knowledge retrieval and storage',
    'sub-agent': 'a child agent spawned by an orchestrator to execute a bounded subtask',
    'hierarchical-agents': 'the pattern of orchestrator-plus-specialist agents with layered authority',
    'human-in-the-loop': 'the checkpoint pattern where a human approves before irreversible agent actions',
    'escalation': 'the mechanism for passing an issue up the chain of command when the agent is blocked',
    'handoff': 'the structured task transfer between agents managed by the orchestrator',
    'definition-of-done': 'the explicit completion criteria that tell the agent when to stop and report',
    'context-injection': 'the technique of loading relevant memory and documents into the active context window',
    'context-window': 'the token buffer the model reads at each step of the loop',
    'context-length': 'the maximum number of tokens the model can process in a single call',
    'working-memory': 'the in-context short-term store for the current task\'s intermediate results',
    'episodic-memory': 'the long-term store of past interactions retrieved to inform future decisions',
    'semantic-memory': 'the persistent factual knowledge base the agent queries during tasks',
    'memory-bank': 'the external storage layer backing episodic and semantic memory retrieval',
    'rag': 'the pattern of retrieving relevant documents and injecting them into the prompt',
    'retrieval': 'the query-time lookup that pulls relevant chunks from an external store',
    'reranking': 'the scoring step that re-orders retrieved candidates by relevance before injection',
    'vector-database': 'the indexed store that enables fast semantic similarity search for retrieval',
    'chunking': 'the pre-processing step that splits documents into segments suited for embedding and retrieval',
    'embedding': 'dense vector representations that power semantic similarity search',
    'claude-agent-sdk': 'Anthropic\'s SDK that wraps the API with agent loop, tool, and multi-turn patterns',
    'anthropic-agent-sdk': 'the broader Anthropic toolkit for evaluation, prompt management, and deployment',
    'claude': 'Anthropic\'s model family that the SDK and harnesses are built around',
    'llm': 'the large language model that generates responses and tool calls inside the loop',
    'transformer': 'the neural architecture underlying virtually all modern LLMs',
    'attention-mechanism': 'the core transformer operation that weights token relationships to compute representations',
    'multi-head-attention': 'the parallel attention computation that lets transformers attend to different representation subspaces',
    'attention-mask': 'the binary mask controlling which token positions the attention mechanism can see',
    'positional-encoding': 'the signal added to token embeddings so the model understands sequence order',
    'softmax': 'the normalisation function that converts raw logits into probability distributions',
    'kv-cache': 'the cached key-value pairs that eliminate redundant attention computation across turns',
    'speculative-decoding': 'the technique of generating draft tokens with a small model and verifying with a large one',
    'greedy-decoding': 'the simplest decoding strategy that always picks the highest-probability next token',
    'beam-search': 'a decoding strategy that maintains multiple candidate sequences in parallel',
    'sampling-parameters': 'the temperature, top-k, and top-p settings that control output randomness',
    'temperature': 'the scaling factor that controls how peaked or flat the token probability distribution is',
    'top-k': 'the sampling strategy that restricts token selection to the K most probable candidates',
    'top-p': 'the nucleus sampling strategy that selects from the smallest set covering cumulative probability p',
    'logprobs': 'the log-probabilities of candidate tokens returned alongside the model\'s chosen token',
    'inference': 'the process of running a trained model forward to generate output',
    'inference-time-compute': 'additional computation at inference time (e.g. chain-of-thought, search) that improves output quality',
    'completion': 'a single forward pass that generates the model\'s next token(s)',
    'prompt': 'the structured input the model receives to generate a completion',
    'system-prompt': 'the top-level instruction block prepended to every conversation turn',
    'system-instruction': 'the operator-supplied directive that shapes model behaviour across the session',
    'prompt-engineering': 'the practice of crafting inputs to elicit reliable, high-quality model outputs',
    'prompt-caching': 'the mechanism that reuses cached key-value state for repeated long prefixes',
    'few-shot-prompting': 'the technique of including worked examples in the prompt to steer model behaviour',
    'chain-of-thought': 'the prompting technique that asks the model to reason step-by-step before answering',
    'in-context-learning': 'the ability to adapt to a task using only examples in the prompt, without weight updates',
    'react-prompting': 'the Reasoning + Acting prompt pattern that interleaves thought and tool-call steps',
    'self-consistency': 'the technique of sampling multiple reasoning paths and taking the majority answer',
    'json-mode': 'the model output mode that constrains generation to valid JSON',
    'structured-output': 'model output constrained to a declared schema for reliable downstream parsing',
    'function-calling': 'the mechanism by which the model emits structured JSON to invoke an external function',
    'parallel-tool-calls': 'the capability to invoke multiple tools simultaneously in a single model turn',
    'tool-result': 'the output returned to the model after a tool call completes',
    'grounding': 'the technique of anchoring model responses in verified external facts or retrieved documents',
    'hallucination': 'the failure mode where a model generates confident but factually incorrect output',
    'confabulation': 'a synonym for hallucination emphasising the unintentional, fluent fabrication pattern',
    'guardrails': 'the input/output filters that prevent harmful, off-policy, or malformed agent responses',
    'constitutional-ai': 'Anthropic\'s training technique where the model critiques itself against a set of principles',
    'alignment-tax': 'the performance reduction that can result from applying safety and alignment training',
    'rlhf': 'the training technique that uses human preference comparisons to steer model behaviour',
    'direct-preference-optimization': 'an alignment technique that optimises the model directly on preference data without a reward model',
    'instruction-tuning': 'the fine-tuning stage that teaches a model to follow natural-language instructions',
    'supervised-fine-tuning': 'the weight-update process that adapts a pre-trained model to a target task using labeled data',
    'fine-tuning': 'the weight-update process that adapts a pre-trained base model for downstream tasks',
    'pre-training': 'the large-scale unsupervised training run that teaches the model language and world knowledge',
    'distillation': 'the technique of training a smaller student model to mimic a larger teacher\'s outputs',
    'lora': 'a parameter-efficient fine-tuning method that trains low-rank weight adaptors instead of full weights',
    'qlora': 'LoRA applied to a quantized model, making fine-tuning feasible on consumer hardware',
    'quantization': 'the process of reducing model weight precision to decrease memory and speed up inference',
    'backpropagation': 'the algorithm that computes gradients through the network to update weights during training',
    'cross-entropy': 'the loss function used to measure the gap between predicted and true token distributions',
    'scaling-laws': 'the empirical relationships between model size, compute, data, and performance',
    'capability-overhang': 'the phenomenon where latent capabilities emerge suddenly as model scale crosses a threshold',
    'emergent-abilities': 'capabilities that appear in large models but are absent in smaller ones at the same task',
    'frontier-model': 'the most capable publicly available model at a given time',
    'reasoning-model': 'a model trained or prompted to perform multi-step deliberate reasoning before answering',
    'mixture-of-experts': 'an architecture where only a sparse subset of experts activates per token, scaling capacity efficiently',
    'multimodal': 'the ability to process and generate content across text, images, audio, and other modalities',
    'vision-language-model': 'a multimodal model that understands and reasons over both images and text',
    'speech-to-text': 'the task of converting spoken audio into written transcriptions',
    'text-to-speech': 'the task of synthesizing natural-sounding audio from written text',
    'text-to-image': 'the task of generating images from natural-language descriptions',
    'evals': 'the structured evaluation framework that measures model quality against defined criteria',
    'benchmark-suite': 'a collection of standardised tasks used to compare model capabilities across dimensions',
    'mmlu': 'the academic benchmark measuring world knowledge across 57 subjects',
    'humaneval': 'the coding benchmark that tests models on 164 Python programming problems',
    'swe-bench': 'the benchmark that evaluates agents on real GitHub software engineering issues',
    'f1-score': 'the harmonic mean of precision and recall used to evaluate information-extraction quality',
    'precision': 'the fraction of positive predictions that are actually correct',
    'recall': 'the fraction of true positives that the model successfully identifies',
    'perplexity': 'the exponentiated average negative log-likelihood used to measure how well a model predicts text',
    'confusion-matrix': 'the matrix that tabulates true/false positive and negative counts for a classifier',
    'observability': 'the practice of capturing traces, logs, and metrics to understand agent runtime behaviour',
    'telemetry': 'the structured runtime signals (traces, spans, metrics) emitted by agents for debugging',
    'structured-logging': 'machine-parseable log output with consistent fields for reliable querying and alerting',
    'audit-trail': 'the immutable chronological record of every action taken, enabling forensic review',
    'ai-gateway': 'the proxy layer that centralises auth, rate-limiting, logging, and model routing',
    'api-rate-limit': 'the server-enforced cap on how many requests a client can make per time window',
    'rate-limiting': 'the policy of capping request throughput to protect service reliability',
    'latency': 'the elapsed time from request submission to first token or full response received',
    'caching': 'storing computed results for reuse to reduce latency and cost on repeated inputs',
    'idempotency': 'the property where repeating an operation produces the same result as executing it once',
    'sandboxing': 'the isolation mechanism that prevents agent code execution from affecting the host system',
    'rbac': 'the access-control model that grants permissions based on role rather than individual identity',
    'privilege': 'the confidentiality protection that restricts access to certain communications',
    'data-residency': 'the legal and policy requirement that data stays within a specified geographic boundary',
    'confidentiality': 'the information-security property that data is accessible only to authorised parties',
    'feature-flag': 'the runtime toggle that enables or disables a capability without a code deployment',
    'dependency-injection': 'the design pattern of supplying dependencies from outside rather than hard-coding them',
    'durable-objects': 'Cloudflare\'s per-object stateful compute that collocates logic and storage at the edge',
    'ephemeral-storage': 'transient storage that exists only for the lifetime of a single agent run',
    'http-sse': 'the long-lived HTTP streaming transport used by MCP for server-to-client event push',
    'stdio-transport': 'the stdin/stdout pipe transport used by MCP when host and server run in the same process',
    'mcp-from-first-principles-to-production': 'the course covering MCP architecture, transports, and production deployment',
    'cognitive-architecture': 'the structural design (perception, memory, planning, action) that shapes an agent\'s reasoning',
    'world-model': 'the agent\'s internal representation of how its environment works',
    'api-key': 'the credential that authenticates API calls to model providers',
    'cursor': 'the AI-native IDE that embeds an agent harness for interactive coding assistance',
    'codex': 'OpenAI\'s code-generation model and the CLI agent built on it',
    'gemini': 'Google\'s family of multimodal frontier models competing with Claude and GPT-4',
    'gpt': 'OpenAI\'s Generative Pre-trained Transformer series, the leading LLM family before Claude 3',
}

def get_brief_phrase(related_slug):
    return RELATION_PHRASES.get(related_slug, f'related concept that intersects with this term in agent workflows')

def parse_frontmatter(content):
    fm_match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not fm_match:
        return {}
    fm = fm_match.group(1)
    result = {}
    # term
    m = re.search(r'^term:\s*[\"\'](.*?)[\"\']', fm, re.MULTILINE)
    if not m:
        m = re.search(r'^term:\s*(.+)', fm, re.MULTILINE)
    if m:
        result['term'] = m.group(1).strip()
    # related_terms inline list
    m = re.search(r'^related_terms:\s*\[([^\]]*)\]', fm, re.MULTILINE)
    if m:
        items = [x.strip().strip('"\'') for x in m.group(1).split(',') if x.strip()]
        result['related_terms'] = items
    else:
        # multi-line list
        m = re.search(r'^related_terms:\s*\n((?:\s*-\s*.+\n?)+)', fm, re.MULTILINE)
        if m:
            items = re.findall(r'-\s*(.+)', m.group(1))
            result['related_terms'] = [x.strip().strip('"\'') for x in items]
    # related_courses inline list
    m = re.search(r'^related_courses:\s*\[([^\]]*)\]', fm, re.MULTILINE)
    if m:
        items = [x.strip().strip('"\'') for x in m.group(1).split(',') if x.strip()]
        result['related_courses'] = items
    else:
        m = re.search(r'^related_courses:\s*\n((?:\s*-\s*.+\n?)+)', fm, re.MULTILINE)
        if m:
            items = re.findall(r'-\s*(.+)', m.group(1))
            result['related_courses'] = [x.strip().strip('"\'') for x in items]
    # category
    m = re.search(r'^category:\s*[\"\'](.*?)[\"\']', fm, re.MULTILINE)
    if not m:
        m = re.search(r'^category:\s*(.+)', fm, re.MULTILINE)
    if m:
        result['category'] = m.group(1).strip()
    return result

def get_hub_course(slug, fm):
    # Check if related_courses has a known hub course
    rc = fm.get('related_courses', [])
    for course_slug in rc:
        if course_slug in HUB_COURSES:
            return course_slug
    # Fall back to pre-mapped hub
    return SLUG_TO_HUB.get(slug, 'claude-agent-sdk-zero-to-production')

def get_existing_body_links(body):
    return set(re.findall(r'\[\[glossary/([^\]|]+)', body))

# Build term lookup
term_lookup = {}
for fn in os.listdir(GLOSSARY):
    if not fn.endswith('.md'):
        continue
    slug = fn[:-3]
    path = os.path.join(GLOSSARY, fn)
    with open(path) as f:
        content = f.read()
    fm = parse_frontmatter(content)
    if 'term' in fm:
        term_lookup[slug] = fm['term']

# Target slugs (all 136)
TARGET_SLUGS = [
    'agent-harness', 'agent-heartbeat', 'agent-lane', 'agent-memory', 'agent-registry',
    'agent-scaffolding', 'agent-soul', 'agentic-loop', 'agentic-workflow', 'ai-gateway',
    'alignment-tax', 'anthropic-agent-sdk', 'api-key', 'api-rate-limit', 'attention-mask',
    'attention-mechanism', 'audit-trail', 'autonomous-agent', 'backpropagation', 'beam-search',
    'benchmark-suite', 'caching', 'capability-overhang', 'chain-of-thought', 'chunking',
    'claude-agent-sdk', 'claude', 'coder-agent', 'codex', 'cognitive-architecture',
    'completion', 'confabulation', 'confidentiality', 'confusion-matrix', 'constitutional-ai',
    'context-injection', 'context-length', 'cross-entropy', 'cursor', 'data-residency',
    'definition-of-done', 'dependency-injection', 'direct-preference-optimization', 'distillation',
    'durable-objects', 'embedding', 'emergent-abilities', 'ephemeral-storage', 'episodic-memory',
    'evals', 'f1-score', 'feature-flag', 'few-shot-prompting', 'fine-tuning', 'frontier-model',
    'function-calling', 'gemini', 'gpt', 'greedy-decoding', 'grounding', 'guardrails',
    'hallucination', 'hierarchical-agents', 'http-sse', 'human-in-the-loop', 'humaneval',
    'idempotency', 'in-context-learning', 'inference-time-compute', 'inference', 'instruction-tuning',
    'json-mode', 'kv-cache', 'latency', 'llm', 'logprobs', 'lora', 'memory-agent', 'memory-bank',
    'mixture-of-experts', 'mmlu', 'multi-head-attention', 'multimodal', 'observability',
    'parallel-tool-calls', 'perplexity', 'planning-agent', 'positional-encoding', 'pre-training',
    'precision', 'privilege', 'prompt-caching', 'prompt-engineering', 'prompt', 'qlora',
    'quantization', 'rag', 'rate-limiting', 'rbac', 'react-prompting', 'reasoning-model',
    'recall', 'reflection-agent', 'reranking', 'research-agent', 'retrieval', 'rlhf',
    'sampling-parameters', 'sandboxing', 'scaling-laws', 'self-consistency', 'semantic-memory',
    'softmax', 'speculative-decoding', 'speech-to-text', 'stdio-transport', 'structured-logging',
    'structured-output', 'sub-agent', 'supervised-fine-tuning', 'swe-bench', 'system-instruction',
    'system-prompt', 'telemetry', 'temperature', 'text-to-image', 'text-to-speech', 'tokenization',
    'tool-result', 'top-k', 'top-p', 'transformer', 'vector-database', 'vision-language-model',
    'working-memory', 'world-model',
]

def build_related_terms_section(slug, fm, existing_links):
    lines = ['## Related Terms', '']
    related = fm.get('related_terms', [])
    # Filter to ones that exist in glossary, aren't already linked in body, max 4
    usable = [s for s in related if s in term_lookup and s not in existing_links][:4]
    if not usable:
        # Try all related terms even if already linked — pick first 2
        usable = [s for s in related if s in term_lookup][:2]
    for rt_slug in usable:
        display = term_lookup[rt_slug]
        phrase = get_brief_phrase(rt_slug)
        lines.append(f'- [[glossary/{rt_slug}|{display}]] — {phrase}')
    # Course link
    hub = get_hub_course(slug, fm)
    hub_title = HUB_COURSES[hub]
    lines.append(f'- [[courses/{hub}|Course: {hub_title}]] — hands-on practice with the concepts covered in this entry')
    lines.append('')
    return '\n'.join(lines)

def process_file(slug):
    path = os.path.join(GLOSSARY, f'{slug}.md')
    if not os.path.exists(path):
        return f'MISSING: {path}'
    with open(path) as f:
        content = f.read()
    if '## Related Terms' in content:
        return f'SKIP (already has section): {slug}'
    fm = parse_frontmatter(content)
    # Get body (after frontmatter)
    body = re.sub(r'^---\n.*?\n---\n?', '', content, flags=re.DOTALL)
    existing_links = get_existing_body_links(body)
    section = build_related_terms_section(slug, fm, existing_links)
    # Append to file
    new_content = content.rstrip('\n') + '\n\n' + section
    with open(path, 'w') as f:
        f.write(new_content)
    return f'UPDATED: {slug}'

if __name__ == '__main__':
    results = []
    for slug in TARGET_SLUGS:
        result = process_file(slug)
        results.append(result)
        print(result)
    updated = [r for r in results if r.startswith('UPDATED')]
    skipped = [r for r in results if r.startswith('SKIP')]
    missing = [r for r in results if r.startswith('MISSING')]
    print(f'\nSummary: {len(updated)} updated, {len(skipped)} skipped, {len(missing)} missing')
