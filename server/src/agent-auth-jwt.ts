import { createHmac, timingSafeEqual } from "node:crypto";

interface JwtHeader {
  alg: string;
  typ?: string;
}

export interface LocalAgentJwtClaims {
  sub: string;
  company_id: string;
  adapter_type: string;
  run_id: string;
  iat: number;
  exp: number;
  iss?: string;
  aud?: string;
  jti?: string;
}

interface InspectLocalAgentJwtOptions {
  now?: number;
}

export interface LocalAgentJwtInspection {
  expired: boolean;
  runId: string | null;
  agentId: string | null;
  companyId: string | null;
  adapterType: string | null;
  claims: LocalAgentJwtClaims | null;
  hasPaperclipShape: boolean;
  signatureValid: boolean;
}

const JWT_ALGORITHM = "HS256";

function parseNumber(value: string | undefined, fallback: number) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.floor(parsed);
}

function jwtConfig() {
  const secret = process.env.PAPERCLIP_AGENT_JWT_SECRET?.trim() || process.env.BETTER_AUTH_SECRET?.trim();
  if (!secret) return null;

  return {
    secret,
    ttlSeconds: parseNumber(process.env.PAPERCLIP_AGENT_JWT_TTL_SECONDS, 60 * 60 * 48),
    issuer: process.env.PAPERCLIP_AGENT_JWT_ISSUER ?? "paperclip",
    audience: process.env.PAPERCLIP_AGENT_JWT_AUDIENCE ?? "paperclip-api",
  };
}

function base64UrlEncode(value: string) {
  return Buffer.from(value, "utf8").toString("base64url");
}

function base64UrlDecode(value: string) {
  return Buffer.from(value, "base64url").toString("utf8");
}

function signPayload(secret: string, signingInput: string) {
  return createHmac("sha256", secret).update(signingInput).digest("base64url");
}

function parseJson(value: string): Record<string, unknown> | null {
  try {
    const parsed = JSON.parse(value);
    return parsed && typeof parsed === "object" ? parsed as Record<string, unknown> : null;
  } catch {
    return null;
  }
}

function safeCompare(a: string, b: string) {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

export function createLocalAgentJwt(agentId: string, companyId: string, adapterType: string, runId: string) {
  const config = jwtConfig();
  if (!config) return null;

  const now = Math.floor(Date.now() / 1000);
  const claims: LocalAgentJwtClaims = {
    sub: agentId,
    company_id: companyId,
    adapter_type: adapterType,
    run_id: runId,
    iat: now,
    exp: now + config.ttlSeconds,
    iss: config.issuer,
    aud: config.audience,
  };

  const header = {
    alg: JWT_ALGORITHM,
    typ: "JWT",
  };

  const signingInput = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(claims))}`;
  const signature = signPayload(config.secret, signingInput);

  return `${signingInput}.${signature}`;
}

export function verifyLocalAgentJwt(token: string): LocalAgentJwtClaims | null {
  const inspection = inspectLocalAgentJwt(token);
  if (!inspection.signatureValid || !inspection.claims || inspection.expired) return null;
  return inspection.claims;
}

export function inspectLocalAgentJwt(
  token: string,
  options: InspectLocalAgentJwtOptions = {},
): LocalAgentJwtInspection {
  const fallback: LocalAgentJwtInspection = {
    expired: false,
    runId: null,
    agentId: null,
    companyId: null,
    adapterType: null,
    claims: null,
    hasPaperclipShape: false,
    signatureValid: false,
  };

  if (!token) return fallback;
  const config = jwtConfig();
  if (!config) return fallback;

  const parts = token.split(".");
  if (parts.length !== 3) return fallback;
  const [headerB64, claimsB64, signature] = parts;

  const header = parseJson(base64UrlDecode(headerB64));
  if (!header || header.alg !== JWT_ALGORITHM) return fallback;

  const claimsRaw = parseJson(base64UrlDecode(claimsB64));
  if (!claimsRaw) return fallback;

  const agentId = typeof claimsRaw.sub === "string" ? claimsRaw.sub : null;
  const companyId = typeof claimsRaw.company_id === "string" ? claimsRaw.company_id : null;
  const adapterType = typeof claimsRaw.adapter_type === "string" ? claimsRaw.adapter_type : null;
  const runId = typeof claimsRaw.run_id === "string" ? claimsRaw.run_id : null;
  const iat = typeof claimsRaw.iat === "number" ? claimsRaw.iat : null;
  const exp = typeof claimsRaw.exp === "number" ? claimsRaw.exp : null;
  const hasPaperclipShape = Boolean(agentId && companyId && adapterType && runId && iat && exp);

  const now = options.now ?? Math.floor(Date.now() / 1000);
  const expired = typeof exp === "number" ? exp < now : false;
  const signingInput = `${headerB64}.${claimsB64}`;
  const expectedSig = signPayload(config.secret, signingInput);
  const signatureValid = safeCompare(signature, expectedSig);

  if (!hasPaperclipShape || !signatureValid) {
    return {
      ...fallback,
      expired,
      runId,
      agentId,
      companyId,
      adapterType,
      hasPaperclipShape,
      signatureValid,
    };
  }

  const issuer = typeof claimsRaw.iss === "string" ? claimsRaw.iss : undefined;
  const audience = typeof claimsRaw.aud === "string" ? claimsRaw.aud : undefined;
  if (issuer && issuer !== config.issuer) {
    return {
      ...fallback,
      expired,
      runId,
      agentId,
      companyId,
      adapterType,
      hasPaperclipShape,
      signatureValid,
    };
  }
  if (audience && audience !== config.audience) {
    return {
      ...fallback,
      expired,
      runId,
      agentId,
      companyId,
      adapterType,
      hasPaperclipShape,
      signatureValid,
    };
  }

  const claims: LocalAgentJwtClaims = {
    sub: agentId!,
    company_id: companyId!,
    adapter_type: adapterType!,
    run_id: runId!,
    iat: iat!,
    exp: exp!,
    ...(issuer ? { iss: issuer } : {}),
    ...(audience ? { aud: audience } : {}),
    jti: typeof claimsRaw.jti === "string" ? claimsRaw.jti : undefined,
  };

  return {
    expired,
    runId,
    agentId,
    companyId,
    adapterType,
    claims,
    hasPaperclipShape,
    signatureValid,
  };
}
