export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  database: {
    url: process.env.DATABASE_URL,
  },
  supabase: {
    url: process.env.SUPABASE_URL,
    anonKey: process.env.SUPABASE_ANON_KEY,
    serviceKey: process.env.SUPABASE_SERVICE_KEY,
    jwtSecret: process.env.SUPABASE_JWT_SECRET,
  },
  pricing: {
    polygon: {
      apiKey: process.env.POLYGON_API_KEY,
      baseUrl: 'https://api.polygon.io',
    },
    coingecko: {
      apiKey: process.env.COINGECKO_API_KEY,
      baseUrl: 'https://api.coingecko.com/api/v3',
    },
    metalsApi: {
      apiKey: process.env.METALS_API_KEY,
      baseUrl: 'https://metals-api.com/api',
    },
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  },
  revenuecat: {
    webhookSecret: process.env.REVENUECAT_WEBHOOK_SECRET,
  },
  cache: {
    ttl: {
      stock: 15 * 60 * 1000, // 15 minutes
      crypto: 5 * 60 * 1000, // 5 minutes
      commodity: 30 * 60 * 1000, // 30 minutes
    },
  },
  limits: {
    freeAssets: 10,
  },
});
