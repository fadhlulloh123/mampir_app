/**
 * MAMPIR Web - Runtime Configuration
 * Menyimpan URL API Supabase, Anon Key, Google Maps Key, dan endpoint.
 * PERINGATAN KEAMANAN:
 * File ini dieksekusi di sisi klien (browser). JANGAN PERNAH menambahkan
 * SUPABASE_SERVICE_ROLE_KEY, database secret, atau kredensial privat di file ini.
 * Seluruh akses data klien dikontrol oleh Supabase Row Level Security (RLS) menggunakan Anon Key.
 */
const AppConfig = {
  supabaseUrl: 'https://vdqdithxujxvzyybjtpn.supabase.co',
  supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkcWRpdGh4dWp4dnp5eWJqdHBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyMzA2NTIsImV4cCI6MjEwODgwNjY1Mn0.7zE0gLxh0a2DNzdVcRfTj3EZDaqXWZ09kL5gcXTETXY',
  googleMapsApiKey: 'AIzaSyDRpM6qUNluR7y-yP-k0UEhSrNQQ84A9nI',
  googlePlacesApiKey: 'AIzaSyDMJEEWy4XuVJSIzvzEVKS6zfwtVjGSYGk',
  googleRoutesApiKey: 'AIzaSyBucKKuasjZSWCt8DfCCTfw6omaV-qlqX8',

  get placesEndpoint() {
    return `${this.supabaseUrl}/rest/v1/places?select=*&order=name.asc`;
  },

  get authEndpoint() {
    return `${this.supabaseUrl}/auth/v1`;
  },

  get headers() {
    return {
      'apikey': this.supabaseAnonKey,
      'Authorization': `Bearer ${this.supabaseAnonKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    };
  },

  // Titik koordinat pusat Alun-Alun Purwokerto
  centerCoordinates: {
    lat: -7.4243,
    lng: 109.2303,
    zoom: 13
  },

  // Bounding box & radius deteksi GPS Purwokerto dan sekitarnya
  purwokertoBounds: {
    minLat: -7.60,
    maxLat: -7.22,
    minLng: 109.05,
    maxLng: 109.42,
    maxRadiusKm: 28.0
  },

  regions: [
    'Semua Wilayah',
    'Purwokerto Kota',
    'Baturraden',
    'Purwokerto Utara (Unsoed)',
    'Sokaraja',
    'Purwokerto Timur & Sumbang',
    'Purwokerto Barat & Selatan'
  ],

  categories: ['Semua', 'Cafe', 'Warkop', 'Restoran']
};

