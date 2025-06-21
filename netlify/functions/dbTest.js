const { Client } = require('pg');

exports.handler = async () => {
  const client = new Client({
    connectionString: process.env.DATABASE_URL, // Set this on Netlify
    ssl: {
      rejectUnauthorized: false, // Required for Neon
    },
  });

  try {
    await client.connect();
    const res = await client.query('SELECT NOW() AS server_time');
    await client.end();

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Connected to Neon DB!',
        server_time: res.rows[0].server_time,
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Database connection failed.',
        details: error.message,
      }),
    };
  }
};
