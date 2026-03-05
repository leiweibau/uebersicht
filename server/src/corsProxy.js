const http = require('http');
const https = require('https');

const HOP_BY_HOP_HEADERS = new Set([
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
]);

function parseAllowlist(value) {
  return (value || '')
    .split(',')
    .map((entry) => entry.trim().toLowerCase())
    .filter(Boolean);
}

function isPrivateIpv4(hostname) {
  const match = hostname.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  if (!match) return false;
  const a = Number(match[1]);
  const b = Number(match[2]);

  if (a === 10 || a === 127) return true;
  if (a === 169 && b === 254) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a === 192 && b === 168) return true;
  if (a === 0) return true;
  return false;
}

function isBlockedHostname(hostname) {
  const lower = (hostname || '').toLowerCase();
  if (!lower) return true;

  if (
    lower === 'localhost' ||
    lower.endsWith('.localhost') ||
    lower.endsWith('.local') ||
    lower === '::1' ||
    lower === '0.0.0.0'
  ) {
    return true;
  }

  return isPrivateIpv4(lower);
}

function isAllowedByAllowlist(hostname, allowlist) {
  if (!allowlist.length) return !isBlockedHostname(hostname);
  const lower = hostname.toLowerCase();

  return allowlist.some((entry) => {
    if (entry.startsWith('*.')) {
      const suffix = entry.slice(2);
      return lower === suffix || lower.endsWith(`.${suffix}`);
    }
    return lower === entry;
  });
}

function setCorsHeaders(res, origin) {
  if (origin) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  } else {
    res.setHeader('Access-Control-Allow-Origin', '*');
  }
  res.setHeader('Vary', 'Origin');
  res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Accept');
}

module.exports = function createCorsProxy(options) {
  const host = options.host || '127.0.0.1';
  const port = Number(options.port || 41417);
  const allowlist = parseAllowlist(process.env.UEBERSICHT_PROXY_ALLOWLIST);
  const allowedOrigins = new Set(options.allowedOrigins || []);

  const server = http.createServer((req, res) => {
    const origin = req.headers.origin;

    const rawTarget = decodeURIComponent((req.url || '').replace(/^\//, ''));

    // Keep compatibility with the old cors-anywhere root endpoint.
    if (!rawTarget) {
      setCorsHeaders(res, origin);
      if (req.method !== 'GET' && req.method !== 'HEAD') {
        res.statusCode = 405;
        return res.end('Method not allowed');
      }
      res.statusCode = 200;
      return res.end(
        'This API enables cross-origin requests to anywhere. Usage: /https://example.com/path'
      );
    }

    const isAllowedOrigin =
      !origin ||
      origin === 'null' ||
      origin === 'Übersicht' ||
      allowedOrigins.has(origin);

    if (!isAllowedOrigin) {
      res.statusCode = 403;
      return res.end('Forbidden origin');
    }

    setCorsHeaders(res, origin);
    if (req.method === 'OPTIONS') {
      res.statusCode = 204;
      return res.end();
    }

    if (req.method !== 'GET' && req.method !== 'HEAD') {
      res.statusCode = 405;
      return res.end('Method not allowed');
    }

    let target;
    try {
      target = new URL(rawTarget);
    } catch (err) {
      res.statusCode = 400;
      return res.end('Invalid target URL');
    }

    if (target.protocol !== 'http:' && target.protocol !== 'https:') {
      res.statusCode = 400;
      return res.end('Only http/https URLs are allowed');
    }

    if (target.username || target.password) {
      res.statusCode = 400;
      return res.end('Credentials in URL are not allowed');
    }

    if (!isAllowedByAllowlist(target.hostname, allowlist)) {
      res.statusCode = 403;
      return res.end('Target host is not allowed');
    }

    const client = target.protocol === 'https:' ? https : http;
    const outbound = client.request(
      {
        protocol: target.protocol,
        hostname: target.hostname,
        port: target.port || undefined,
        path: `${target.pathname}${target.search}`,
        method: req.method,
        headers: {
          accept: req.headers.accept || '*/*',
          'user-agent': req.headers['user-agent'] || 'Uebersicht-Proxy',
        },
        timeout: 10000,
      },
      (proxyRes) => {
        res.statusCode = proxyRes.statusCode || 502;

        Object.entries(proxyRes.headers).forEach(([key, value]) => {
          const lowerKey = key.toLowerCase();
          if (HOP_BY_HOP_HEADERS.has(lowerKey)) return;
          if (lowerKey === 'set-cookie' || lowerKey === 'set-cookie2') return;
          if (value != null) res.setHeader(key, value);
        });

        res.setHeader('x-final-url', target.toString());
        proxyRes.pipe(res);
      }
    );

    outbound.on('timeout', () => outbound.destroy(new Error('Request timeout')));
    outbound.on('error', () => {
      if (!res.headersSent) {
        res.statusCode = 502;
      }
      res.end('Proxy request failed');
    });

    outbound.end();
  });

  server.listen(port, host, () => {
    const allowlistInfo = allowlist.length
      ? allowlist.join(', ')
      : '(public hosts only; set UEBERSICHT_PROXY_ALLOWLIST to restrict further)';
    console.log(`Secure CORS proxy on ${host}:${port} allowlist: ${allowlistInfo}`);
  });

  return server;
};
