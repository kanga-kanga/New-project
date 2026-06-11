const SHWARY_BASE_URL = 'https://api.shwary.com/api/v1/merchants';
const COUNTRY_CODE = 'DRC';

function json(statusCode, payload) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    },
    body: JSON.stringify(payload),
  };
}

function getSandboxMode() {
  const value = String(process.env.SHWARY_SANDBOX || '').trim().toLowerCase();
  return ['1', 'true', 'yes', 'on'].includes(value);
}

function getUpstreamPath(pathname) {
  if (pathname.includes('/transactions/')) {
    const transactionId = pathname.split('/').filter(Boolean).pop();
    return `/transactions/${transactionId}`;
  }

  return getSandboxMode()
    ? `/payment/sandbox/${COUNTRY_CODE}`
    : `/payment/${COUNTRY_CODE}`;
}

function getHeaders(event) {
  const incoming = event.headers || {};
  return {
    'Content-Type':
      incoming['content-type'] ||
      incoming['Content-Type'] ||
      'application/json',
    'x-merchant-id': process.env.SHWARY_MERCHANT_ID || '',
    'x-merchant-key': process.env.SHWARY_MERCHANT_KEY || '',
  };
}

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return json(204, {});
  }

  const merchantId = process.env.SHWARY_MERCHANT_ID;
  const merchantKey = process.env.SHWARY_MERCHANT_KEY;
  if (!merchantId || !merchantKey) {
    return json(500, {
      message:
        'Missing SHWARY_MERCHANT_ID or SHWARY_MERCHANT_KEY environment variables.',
    });
  }

  const pathname = event.rawUrl
    ? new URL(event.rawUrl).pathname
    : event.path || '';
  if (
    !pathname.includes('/api/shwary/payment') &&
    !pathname.includes('/api/shwary/transactions/')
  ) {
    return json(404, { message: 'Not found' });
  }

  const upstreamUrl = `${SHWARY_BASE_URL}${getUpstreamPath(pathname)}`;
  const upstreamOptions = {
    method: event.httpMethod,
    headers: getHeaders(event),
  };

  if (event.httpMethod !== 'GET' && event.httpMethod !== 'HEAD') {
    upstreamOptions.body = event.body;
  }

  try {
    const response = await fetch(upstreamUrl, upstreamOptions);
    const body = await response.text();

    return {
      statusCode: response.status,
      headers: {
        'Content-Type': response.headers.get('content-type') || 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body,
    };
  } catch (error) {
    return json(502, { message: String(error?.message || error) });
  }
};
