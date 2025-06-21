const { Client } = require('pg');

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  const { name, email, amount, currency, message } = JSON.parse(event.body || '{}');

  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();
    await client.query(
      'INSERT INTO donations (name, email, amount, currency, message) VALUES ($1, $2, $3, $4, $5)',
      [name, email, amount, currency, message]
    );
    await client.end();

    return {
      statusCode: 200,
      body: JSON.stringify({ success: true, message: 'Donation received!' }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};